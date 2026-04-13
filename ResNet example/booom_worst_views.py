import os
import csv
import numpy as np
import matplotlib.pyplot as plt
import trimesh
import torch
import torchvision.transforms as transforms
from torchvision.models import resnet18, ResNet18_Weights

# Import your BOOOM optimizer from separate file booom.py
from booom import booom

# ============================================================
# Helper: clean labels for display
# ============================================================
def clean_label(label: str):
    return "chair" if label == "folding chair" else label


# ============================================================
# BASIC GEOMETRY / RENDERING FUNCTIONS
# ============================================================

def load_and_sample_mesh_with_normals(filepath: str, num_points: int = 50000, seed=None):
    """
    Load a .off mesh file and sample points + normals from its surface.

    Returns
    -------
    X : array, shape (3, N)
        Sampled 3D surface points.
    normals : array, shape (3, N)
        Unit normals at sampled points.
    """
    mesh = trimesh.load(filepath, force="mesh")

    if mesh is None or mesh.faces is None or len(mesh.faces) == 0:
        raise ValueError(f"Could not load a valid mesh from: {filepath}")

    samples, face_indices = trimesh.sample.sample_surface(mesh, num_points)

    X = np.asarray(samples, dtype=np.float64).T
    normals = np.asarray(mesh.face_normals[face_indices], dtype=np.float64).T

    norm_vals = np.linalg.norm(normals, axis=0, keepdims=True)
    norm_vals = np.where(norm_vals == 0, 1.0, norm_vals)
    normals = normals / norm_vals

    return X, normals


def generate_view_matrix(theta_x: float, theta_y: float):
    """
    Create a 3x2 orthonormal matrix U from two angles.
    U is in St(3,2).
    """
    Rx = np.array([
        [1.0, 0.0, 0.0],
        [0.0, np.cos(theta_x), np.sin(theta_x)],
        [0.0, -np.sin(theta_x), np.cos(theta_x)],
    ], dtype=np.float64)

    Ry = np.array([
        [np.cos(theta_y), np.sin(theta_y), 0.0],
        [-np.sin(theta_y), np.cos(theta_y), 0.0],
        [0.0, 0.0, 1.0],
    ], dtype=np.float64)

    R = Ry @ Rx
    U = R[:, :2]

    # Re-orthonormalize for numerical safety
    q, _ = np.linalg.qr(U)
    return q[:, :2]


def render_shaded_orthogonal(
    X: np.ndarray,
    normals: np.ndarray,
    U: np.ndarray,
    image_size=(224, 224),
    ambient: float = 0.2,
):
    """
    Render a simple grayscale orthographic image from viewpoint U.
    """
    if X.shape[0] != 3 or normals.shape[0] != 3 or U.shape != (3, 2):
        raise ValueError("Expected X:(3,N), normals:(3,N), U:(3,2).")

    # Viewing / lighting direction
    u3 = np.cross(U[:, 0], U[:, 1]).astype(np.float64)
    u3_norm = np.linalg.norm(u3)
    if u3_norm == 0:
        raise ValueError("Degenerate U: cross product is zero.")
    u3 = u3 / u3_norm

    depth = u3 @ X
    intensity = normals.T @ u3

    # Ambient + Lambertian shading
    intensity = np.clip(intensity, 0.0, 1.0) * (1.0 - ambient) + ambient
    colors = np.repeat(intensity[np.newaxis, :], 3, axis=0)

    # Project to 2D image plane
    X_2d = U.T @ X

    finite_mask = np.isfinite(X_2d).all(axis=0) & np.isfinite(depth) & np.isfinite(intensity)
    X_2d = X_2d[:, finite_mask]
    depth = depth[finite_mask]
    colors = colors[:, finite_mask]

    if X_2d.shape[1] == 0:
        raise ValueError("No finite projected points found.")

    x_min, x_max = X_2d[0].min(), X_2d[0].max()
    y_min, y_max = X_2d[1].min(), X_2d[1].max()

    dx = x_max - x_min
    dy = y_max - y_min
    max_range = max(dx, dy)
    if max_range <= 0:
        raise ValueError("Projected point cloud has zero range.")

    margin = 0.1
    x_offset = (max_range - dx) / 2.0
    y_offset = (max_range - dy) / 2.0

    W, H = image_size
    xs = np.round(
        (X_2d[0] - x_min + x_offset + margin * max_range)
        / (max_range * (1.0 + 2.0 * margin))
        * (W - 1)
    ).astype(int)

    ys = np.round(
        (X_2d[1] - y_min + y_offset + margin * max_range)
        / (max_range * (1.0 + 2.0 * margin))
        * (H - 1)
    ).astype(int)

    valid = (xs >= 0) & (xs < W) & (ys >= 0) & (ys < H)
    xs = xs[valid]
    ys = ys[valid]
    depth = depth[valid]
    colors = colors[:, valid]

    # Draw farther points first, nearer points later
    sort_idx = np.argsort(depth)
    xs_sorted = xs[sort_idx]
    ys_sorted = ys[sort_idx]
    colors_sorted = colors[:, sort_idx]

    image = np.zeros((H, W, 3), dtype=np.float32)
    image[ys_sorted, xs_sorted] = colors_sorted.T.astype(np.float32)
    image = np.clip(image, 0.0, 1.0)

    return image


# ============================================================
# RESNET / OBJECTIVE FUNCTIONS
# ============================================================

def load_resnet18(device: str = "cpu"):
    """
    Load pretrained ResNet18 and normalization transform.
    """
    weights = ResNet18_Weights.DEFAULT
    model = resnet18(weights=weights).to(device)
    model.eval()

    normalizer = transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225],
    )
    class_names = weights.meta["categories"]
    return model, normalizer, class_names


def get_probs_and_objective(
    image_np: np.ndarray,
    model,
    normalizer,
    true_idx: int,
    device: str = "cpu",
):
    """
    Evaluate:
        objective = P(true class) - max_j P(j)

    We MINIMIZE this to find a worst/adversarial viewpoint.
    Maximizing this gives the best/correct view.
    """
    img_tensor = torch.from_numpy(image_np).permute(2, 0, 1).float()
    input_tensor = normalizer(img_tensor).unsqueeze(0).to(device)

    with torch.no_grad():
        logits = model(input_tensor)
        probs = torch.nn.functional.softmax(logits, dim=1)

    true_prob = probs[0, true_idx].item()
    max_prob = probs[0].max().item()
    objective = true_prob - max_prob

    top_probs, top_indices = torch.topk(probs, k=5, dim=1)

    top5 = []
    for i in range(5):
        idx = top_indices[0, i].item()
        prob = top_probs[0, i].item()
        top5.append((idx, prob))

    return objective, true_prob, max_prob, top5, probs


# ============================================================
# FILE SAVING HELPERS
# ============================================================

def save_matrix_csv(filename: str, mat: np.ndarray):
    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        for row in mat:
            writer.writerow(row.tolist())


def save_top5_csv(filename: str, top5, class_names):
    with open(filename, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["rank", "class_id", "class_name", "probability"])
        for rank, (idx, prob) in enumerate(top5, start=1):
            writer.writerow([rank, idx, class_names[idx], prob])


def get_true_rank_and_score(probs: torch.Tensor, true_idx: int):
    """
    Return 1-based rank of the actual object class and its score.
    """
    sorted_probs, sorted_indices = torch.sort(probs[0], descending=True)
    rank = (sorted_indices == true_idx).nonzero(as_tuple=True)[0].item() + 1
    score = probs[0, true_idx].item()
    return rank, score


def clean_label(label: str):
    if label == "folding chair":
        return "chair"
    return label

def _draw_left_mixed_text(ax, x, y, left_text, mid_text, right_text, fontsize=13):
    """
    Draw a 3-part line left-aligned from x:
      left_text (black) + quoted mid_text (blue,bold) + right_text (black)
    """
    fig = ax.figure
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()

    mid_display = f"'{mid_text}'"

    t_left = ax.text(
        0, 0, left_text,
        transform=ax.transAxes,
        fontsize=fontsize, color="black", alpha=0.0
    )
    t_mid = ax.text(
        0, 0, mid_display,
        transform=ax.transAxes,
        fontsize=fontsize, color="blue", fontweight="bold", alpha=0.0
    )

    w_left = t_left.get_window_extent(renderer=renderer).width
    w_mid = t_mid.get_window_extent(renderer=renderer).width

    t_left.remove()
    t_mid.remove()

    x0_disp, y_disp = ax.transAxes.transform((x, y))
    x_mid_axes = ax.transAxes.inverted().transform((x0_disp + w_left, y_disp))[0]
    x_right_axes = ax.transAxes.inverted().transform((x0_disp + w_left + w_mid, y_disp))[0]

    ax.text(
        x, y, left_text,
        transform=ax.transAxes,
        ha="left", va="center",
        fontsize=fontsize, color="black"
    )
    ax.text(
        x_mid_axes, y, mid_display,
        transform=ax.transAxes,
        ha="left", va="center",
        fontsize=fontsize, color="blue", fontweight="bold"
    )
    ax.text(
        x_right_axes, y, right_text,
        transform=ax.transAxes,
        ha="left", va="center",
        fontsize=fontsize, color="black"
    )

def make_panel_title(
    panel_name: str,
    objective_value: float,
    top5,
    probs,
    true_idx: int,
    class_names,
):
    identified_idx = top5[0][0]
    identified_label = clean_label(class_names[identified_idx])
    identified_score = top5[0][1] * 100.0

    actual_label = clean_label(class_names[true_idx])
    actual_rank, actual_score = get_true_rank_and_score(probs, true_idx)
    actual_score *= 100.0

    return {
        "panel_name": panel_name,
        "objective_line": f"f(U)={objective_value:.4f}",
        "identified_prefix": "Top prediction: ",
        "identified_label": identified_label,
        "identified_suffix": f", score: {identified_score:.1f}%",
        "actual_prefix": "",
        "actual_label": actual_label,
        "actual_suffix": f" rank: {actual_rank}, score: {actual_score:.1f}%",
    }


def _draw_centered_mixed_text(ax, y, left_text, mid_text, right_text, fontsize=15):
    """
    Draw a 3-part line centered as a whole:
      left_text (black) + mid_text (blue,bold) + right_text (black)
    """
    fig = ax.figure
    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()

    # invisible texts for width measurement
    t_left = ax.text(
        0, 0, left_text, transform=ax.transAxes,
        fontsize=fontsize, color="black", alpha=0.0
    )
    t_mid = ax.text(
        0, 0, mid_text, transform=ax.transAxes,
        fontsize=fontsize, color="blue", fontweight="bold", alpha=0.0
    )
    t_right = ax.text(
        0, 0, right_text, transform=ax.transAxes,
        fontsize=fontsize, color="black", alpha=0.0
    )

    w_left = t_left.get_window_extent(renderer=renderer).width
    w_mid = t_mid.get_window_extent(renderer=renderer).width
    w_right = t_right.get_window_extent(renderer=renderer).width

    t_left.remove()
    t_mid.remove()
    t_right.remove()

    total_w = w_left + w_mid + w_right

    # center in display coordinates
    x_center_disp, y_disp = ax.transAxes.transform((0.5, y))
    x_left_disp = x_center_disp - total_w / 2.0

    # back to axes coordinates
    x_left_axes = ax.transAxes.inverted().transform((x_left_disp, y_disp))[0]
    x_mid_axes = ax.transAxes.inverted().transform((x_left_disp + w_left, y_disp))[0]
    x_right_axes = ax.transAxes.inverted().transform((x_left_disp + w_left + w_mid, y_disp))[0]

    ax.text(
        x_left_axes, y, left_text,
        transform=ax.transAxes,
        ha="left", va="bottom",
        fontsize=fontsize, color="black"
    )
    ax.text(
        x_mid_axes, y, mid_text,
        transform=ax.transAxes,
        ha="left", va="bottom",
        fontsize=fontsize, color="blue", fontweight="bold"
    )
    ax.text(
        x_right_axes, y, right_text,
        transform=ax.transAxes,
        ha="left", va="bottom",
        fontsize=fontsize, color="black"
    )


def draw_panel_text(ax, title_info, fontsize=13):
    """
    Stable 4-line layout inside a dedicated text-only axis.
    """
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")

    # Fixed line centers with enough vertical separation
    y1 = 0.90   # panel name
    y2 = 0.64   # f(U)
    y3 = 0.36   # Top prediction line
    y4 = 0.10   # rank line

    x_left = 0.02

    ax.text(
        0.5, y1,
        title_info["panel_name"],
        transform=ax.transAxes,
        ha="center", va="center",
        fontsize=fontsize + 6,
        fontweight="bold",
        color="black",
    )

    ax.text(
        0.5, y2,
        title_info["objective_line"],
        transform=ax.transAxes,
        ha="center", va="center",
        fontsize=fontsize + 4,
        color="black",
    )

    _draw_left_mixed_text(
        ax=ax,
        x=x_left,
        y=y3,
        left_text=title_info["identified_prefix"],
        mid_text=title_info["identified_label"],
        right_text=title_info["identified_suffix"],
        fontsize=fontsize + 2,
    )

    _draw_left_mixed_text(
        ax=ax,
        x=x_left,
        y=y4,
        left_text=title_info["actual_prefix"],
        mid_text=title_info["actual_label"],
        right_text=title_info["actual_suffix"],
        fontsize=fontsize + 2,
    )


def save_three_panel_publishable_figure(
    filename_prefix: str,
    image_initial,
    image_best,
    image_worst,
    initial_objective,
    best_objective,
    worst_objective,
    top5_initial,
    top5_best,
    top5_worst,
    probs_initial,
    probs_best,
    probs_worst,
    true_idx,
    class_names,
):
    fig = plt.figure(figsize=(14.4, 6.2), constrained_layout=False)
    gs = fig.add_gridspec(
        nrows=2, ncols=3,
        height_ratios=[1.55, 5.0],
        wspace=0.02, hspace=0.02
    )

    title_fs = 13

    info_initial = make_panel_title(
        "Initial view",
        initial_objective,
        top5_initial,
        probs_initial,
        true_idx,
        class_names,
    )
    info_best = make_panel_title(
        "Best view (via BOOOM)",
        best_objective,
        top5_best,
        probs_best,
        true_idx,
        class_names,
    )
    info_worst = make_panel_title(
        "Worst view (via BOOOM)",
        worst_objective,
        top5_worst,
        probs_worst,
        true_idx,
        class_names,
    )

    # text row
    ax_t1 = fig.add_subplot(gs[0, 0])
    ax_t2 = fig.add_subplot(gs[0, 1])
    ax_t3 = fig.add_subplot(gs[0, 2])

    draw_panel_text(ax_t1, info_initial, fontsize=title_fs)
    draw_panel_text(ax_t2, info_best, fontsize=title_fs)
    draw_panel_text(ax_t3, info_worst, fontsize=title_fs)

    # image row
    ax_i1 = fig.add_subplot(gs[1, 0])
    ax_i2 = fig.add_subplot(gs[1, 1])
    ax_i3 = fig.add_subplot(gs[1, 2])

    ax_i1.imshow(image_initial)
    ax_i1.axis("off")

    ax_i2.imshow(image_best)
    ax_i2.axis("off")

    ax_i3.imshow(image_worst)
    ax_i3.axis("off")

    fig.subplots_adjust(
        left=0.02,
        right=0.985,
        bottom=0.03,
        top=0.98
    )

    fig.savefig(f"{filename_prefix}_comparison_initial_best_worst.png", dpi=400, bbox_inches="tight")
    fig.savefig(f"{filename_prefix}_comparison_initial_best_worst.pdf", bbox_inches="tight")
    plt.close(fig)


# ============================================================
# OBJECTIVE RECORDER
# ============================================================

class ObjectiveRecorder:
    """
    Wrap the objective function so BOOOM evaluations are stored in memory.
    We use these records for plotting traces and extracting best/worst views.
    """
    def __init__(self, X, normals, model, normalizer, true_idx, class_names, device="cpu"):
        self.X = X
        self.normals = normals
        self.model = model
        self.normalizer = normalizer
        self.true_idx = true_idx
        self.class_names = class_names
        self.device = device

        self.eval_count = 0
        self.records = []

    def __call__(self, U: np.ndarray) -> float:
        self.eval_count += 1

        image = render_shaded_orthogonal(self.X, self.normals, U)
        objective, true_prob, max_prob, top5, probs = get_probs_and_objective(
            image, self.model, self.normalizer, self.true_idx, self.device
        )

        top1_idx = top5[0][0]
        top1_prob = top5[0][1]

        record = {
            "eval": self.eval_count,
            "objective": objective,
            "true_prob": true_prob,
            "max_prob": max_prob,
            "top1_idx": top1_idx,
            "top1_label": self.class_names[top1_idx],
            "top1_prob": top1_prob,
            "U": U.copy(),
            "probs": probs.clone(),
        }
        self.records.append(record)

        return objective


# ============================================================
# MAIN PER-CHAIR BOOOM ROUTINE
# ============================================================

def optimize_single_chair_worst_view(
    mesh_path: str,
    model,
    normalizer,
    class_names,
    output_dir: str = ".",
    true_idx: int = 559,
    num_points: int = 50000,
    init_theta_x: float = np.pi * 0.2,
    init_theta_y: float = -np.pi * 0.5,
    device: str = "cpu",
    booom_MaxTime: float = 120,
    booom_MaxRuns: int = 2,
    booom_MaxIter: int = 100,
    booom_sInitial: float = 1.0,
    booom_rho: float = 2.0,
    booom_TolFun1: float = 1e-6,
    booom_TolFun2: float = 1e-10,
    booom_phi: float = 1e-12,
    seed: int = None
):
    """
    For one chair mesh:
      1) load sampled point cloud
      2) define initial view
      3) run BOOOM minimization to find worst view
      4) compute best view from stored evaluations
      5) save all outputs with prefix BOOOM_output
    """
    os.makedirs(output_dir, exist_ok=True)

    chair_name = os.path.splitext(os.path.basename(mesh_path))[0]
    prefix = os.path.join(output_dir, f"BOOOM_output_{chair_name}")

    print(f"\n===================================================")
    print(f"Processing chair: {mesh_path}")
    print(f"===================================================")

    # ------------------------------------------------
    # Load point cloud once for this chair
    # ------------------------------------------------
    print("[1/7] Loading chair mesh and sampling points...")
    X, normals = load_and_sample_mesh_with_normals(mesh_path, num_points=num_points, seed=seed)

    # ------------------------------------------------
    # Initial viewpoint
    # ------------------------------------------------
    print("[2/7] Building initial viewpoint...")
    U_initial = generate_view_matrix(init_theta_x, init_theta_y)

    image_initial = render_shaded_orthogonal(X, normals, U_initial)
    initial_objective, initial_true_prob, initial_max_prob, top5_initial, probs_initial = get_probs_and_objective(
        image_initial, model, normalizer, true_idx, device
    )

    # Save initial outputs
    plt.imsave(f"{prefix}_initial_view.png", image_initial)
    save_matrix_csv(f"{prefix}_U_initial.csv", U_initial)
    save_top5_csv(f"{prefix}_top5_initial.csv", top5_initial, class_names)

    # ------------------------------------------------
    # BOOOM optimization
    # ------------------------------------------------
    print("[3/7] Running BOOOM minimization for worst view...")
    recorder = ObjectiveRecorder(
        X=X,
        normals=normals,
        model=model,
        normalizer=normalizer,
        true_idx=true_idx,
        class_names=class_names,
        device=device,
    )

    U_opt, fval_opt, comp_time = booom(
        obj_fun=recorder,
        O_initial=U_initial,
        MaxTime=booom_MaxTime,
        MaxRuns=booom_MaxRuns,
        MaxIter=booom_MaxIter,
        sInitial=booom_sInitial,
        rho=booom_rho,
        TolFun1=booom_TolFun1,
        TolFun2=booom_TolFun2,
        phi=booom_phi,
        DisplayUpdate=1,
        DisplayEvery=2.0,
        PrintStepSize=1,
        PrintSolution=0,
    )

    # ------------------------------------------------
    # Recompute final/worst view exactly at U_opt
    # ------------------------------------------------
    print("[4/7] Recomputing worst view outputs...")
    image_opt = render_shaded_orthogonal(X, normals, U_opt)
    final_objective, final_true_prob, final_max_prob, top5_final, probs_worst = get_probs_and_objective(
        image_opt, model, normalizer, true_idx, device
    )

    plt.imsave(f"{prefix}_worst_view.png", image_opt)
    save_matrix_csv(f"{prefix}_U_worst.csv", U_opt)
    save_top5_csv(f"{prefix}_top5_worst.csv", top5_final, class_names)

    # ------------------------------------------------
    # Best view from recorded evaluations
    # Require: f(U) ~ 0 and true-class prob >= 0.50 if possible
    # ------------------------------------------------
    print("[5/7] Extracting best view from evaluated BOOOM points...")

    tol_zero = 1e-8
    min_true_prob = 0.50

    # Candidate 1: true class is top-1 (f(U) ~ 0) AND true prob >= 0.50
    best_candidates_strict = [
        r for r in recorder.records
        if abs(r["objective"]) <= tol_zero and r["true_prob"] >= min_true_prob
    ]

    # Candidate 2: true class is top-1 (f(U) ~ 0), regardless of probability
    best_candidates_zero = [
        r for r in recorder.records
        if abs(r["objective"]) <= tol_zero
    ]

    if len(best_candidates_strict) > 0:
        best_record = max(best_candidates_strict, key=lambda r: r["true_prob"])
        print(f"Found best view with f(U)≈0 and true_prob >= {min_true_prob:.2f}.")
    elif len(best_candidates_zero) > 0:
        best_record = max(best_candidates_zero, key=lambda r: r["true_prob"])
        print("No best view with true_prob >= 0.50 found; using best f(U)≈0 candidate.")
    else:
        best_record = max(recorder.records, key=lambda r: r["objective"])
        print("No f(U)≈0 candidate found; using largest-objective evaluated view.")

    U_best = best_record["U"]

    image_best = render_shaded_orthogonal(X, normals, U_best)
    best_objective, best_true_prob, best_max_prob, top5_best, probs_best = get_probs_and_objective(
        image_best, model, normalizer, true_idx, device
    )

    plt.imsave(f"{prefix}_best_view.png", image_best)
    save_matrix_csv(f"{prefix}_U_best.csv", U_best)
    save_top5_csv(f"{prefix}_top5_best.csv", top5_best, class_names)

    # ------------------------------------------------
    # Save comparison figures and traces
    # ------------------------------------------------
    print("[6/7] Saving comparison figures and traces...")

    # Initial vs best
    fig, axes = plt.subplots(1, 2, figsize=(10, 4))
    axes[0].imshow(image_initial)
    axes[0].axis("off")
    axes[0].set_title(
        f"Initial view\nf(U)={initial_objective:.4f}\nTop-1: {class_names[top5_initial[0][0]]}"
    )

    axes[1].imshow(image_best)
    axes[1].axis("off")
    axes[1].set_title(
        f"Best BOOOM-evaluated view\nf(U)={best_objective:.4f}\nTop-1: {class_names[top5_best[0][0]]}"
    )

    plt.tight_layout()
    plt.savefig(f"{prefix}_comparison_initial_best.png", dpi=200, bbox_inches="tight")
    plt.close()

    # Initial vs worst
    fig, axes = plt.subplots(1, 2, figsize=(10, 4))
    axes[0].imshow(image_initial)
    axes[0].axis("off")
    axes[0].set_title(
        f"Initial view\nf(U)={initial_objective:.4f}\nTop-1: {class_names[top5_initial[0][0]]}"
    )

    axes[1].imshow(image_opt)
    axes[1].axis("off")
    axes[1].set_title(
        f"Worst BOOOM view\nf(U)={final_objective:.4f}\nTop-1: {class_names[top5_final[0][0]]}"
    )

    plt.tight_layout()
    plt.savefig(f"{prefix}_comparison_initial_worst.png", dpi=200, bbox_inches="tight")
    plt.close()

    # Best vs worst
    fig, axes = plt.subplots(1, 2, figsize=(10, 4))
    axes[0].imshow(image_best)
    axes[0].axis("off")
    axes[0].set_title(
        f"Best BOOOM-evaluated view\nf(U)={best_objective:.4f}\nTop-1: {class_names[top5_best[0][0]]}"
    )

    axes[1].imshow(image_opt)
    axes[1].axis("off")
    axes[1].set_title(
        f"Worst BOOOM view\nf(U)={final_objective:.4f}\nTop-1: {class_names[top5_final[0][0]]}"
    )

    plt.tight_layout()
    plt.savefig(f"{prefix}_comparison_best_worst.png", dpi=200, bbox_inches="tight")
    plt.close()

    # New requested 3-panel plot: Initial | Best | Worst
    save_three_panel_publishable_figure(
        filename_prefix=prefix,
        image_initial=image_initial,
        image_best=image_best,
        image_worst=image_opt,
        initial_objective=initial_objective,
        best_objective=best_objective,
        worst_objective=final_objective,
        top5_initial=top5_initial,
        top5_best=top5_best,
        top5_worst=top5_final,
        probs_initial=probs_initial,
        probs_best=probs_best,
        probs_worst=probs_worst,
        true_idx=true_idx,
        class_names=class_names,
    )

    # Objective trace across all evaluations
    eval_ids = [r["eval"] for r in recorder.records]
    obj_vals = [r["objective"] for r in recorder.records]

    plt.figure(figsize=(6, 4))
    plt.plot(eval_ids, obj_vals, marker="o", markersize=2)
    plt.xlabel("Objective evaluation")
    plt.ylabel("f(U)")
    plt.title(f"{chair_name}: objective trace")
    plt.tight_layout()
    plt.savefig(f"{prefix}_objective_trace.png", dpi=200, bbox_inches="tight")
    plt.close()

    # Best-so-far trace for minimization
    best_so_far = []
    current_best = np.inf
    for v in obj_vals:
        current_best = min(current_best, v)
        best_so_far.append(current_best)

    plt.figure(figsize=(6, 4))
    plt.plot(eval_ids, best_so_far, marker="o", markersize=2)
    plt.xlabel("Objective evaluation")
    plt.ylabel("Best-so-far f(U)")
    plt.title(f"{chair_name}: BOOOM best-so-far trace")
    plt.tight_layout()
    plt.savefig(f"{prefix}_best_so_far_trace.png", dpi=200, bbox_inches="tight")
    plt.close()

    # Best-so-far trace for maximization
    max_so_far = []
    current_max = -np.inf
    for v in obj_vals:
        current_max = max(current_max, v)
        max_so_far.append(current_max)

    plt.figure(figsize=(6, 4))
    plt.plot(eval_ids, max_so_far, marker="o", markersize=2)
    plt.xlabel("Objective evaluation")
    plt.ylabel("Best-so-far max f(U)")
    plt.title(f"{chair_name}: best-view trace")
    plt.tight_layout()
    plt.savefig(f"{prefix}_best_view_trace.png", dpi=200, bbox_inches="tight")
    plt.close()

    # ------------------------------------------------
    # Summary dictionary for later overall CSV
    # ------------------------------------------------
    print("[7/7] Saving summary row...")
    summary = {
        "chair_name": chair_name,
        "mesh_path": mesh_path,
        "num_points": num_points,
        "true_idx": true_idx,
        "true_label": class_names[true_idx],

        "initial_objective": initial_objective,
        "initial_true_prob": initial_true_prob,
        "initial_max_prob": initial_max_prob,
        "initial_top1_idx": top5_initial[0][0],
        "initial_top1_label": class_names[top5_initial[0][0]],
        "initial_top1_prob": top5_initial[0][1],

        "best_objective": best_objective,
        "best_true_prob": best_true_prob,
        "best_max_prob": best_max_prob,
        "best_top1_idx": top5_best[0][0],
        "best_top1_label": class_names[top5_best[0][0]],
        "best_top1_prob": top5_best[0][1],

        "final_objective": final_objective,
        "final_true_prob": final_true_prob,
        "final_max_prob": final_max_prob,
        "final_top1_idx": top5_final[0][0],
        "final_top1_label": class_names[top5_final[0][0]],
        "final_top1_prob": top5_final[0][1],

        "total_evaluations": len(recorder.records),
        "booom_reported_fval": fval_opt,
        "comp_time_sec": comp_time,

        "initial_view_png": f"{prefix}_initial_view.png",
        "best_view_png": f"{prefix}_best_view.png",
        "worst_view_png": f"{prefix}_worst_view.png",

        "comparison_initial_best_png": f"{prefix}_comparison_initial_best.png",
        "comparison_initial_worst_png": f"{prefix}_comparison_initial_worst.png",
        "comparison_best_worst_png": f"{prefix}_comparison_best_worst.png",
        "comparison_initial_best_worst_png": f"{prefix}_comparison_initial_best_worst.png",
        "comparison_initial_best_worst_pdf": f"{prefix}_comparison_initial_best_worst.pdf",

        "objective_trace_png": f"{prefix}_objective_trace.png",
        "best_so_far_trace_png": f"{prefix}_best_so_far_trace.png",
        "best_view_trace_png": f"{prefix}_best_view_trace.png",

        "top5_initial_csv": f"{prefix}_top5_initial.csv",
        "top5_best_csv": f"{prefix}_top5_best.csv",
        "top5_worst_csv": f"{prefix}_top5_worst.csv",

        "U_initial_csv": f"{prefix}_U_initial.csv",
        "U_best_csv": f"{prefix}_U_best.csv",
        "U_worst_csv": f"{prefix}_U_worst.csv",
    }

    print(f"Done with {chair_name}.")
    print(f"Initial objective: {initial_objective:.6f}")
    print(f"Best objective:    {best_objective:.6f}")
    print(f"Worst objective:   {final_objective:.6f}")
    print(f"Top-1 initial: {class_names[top5_initial[0][0]]}")
    print(f"Top-1 best:    {class_names[top5_best[0][0]]}")
    print(f"Top-1 worst:   {class_names[top5_final[0][0]]}")

    return summary


# ============================================================
# RUN ALL THREE CHAIRS
# ============================================================

def main():
    # --------------------------------------------
    # Settings you can tweak later
    # --------------------------------------------
    output_dir = "."
    device = "cpu"
    seed = 2027
    np.random.seed(seed)
    torch.manual_seed(seed)

    # Keep modest initially because objective evaluation is expensive
    num_points = 50000

    # Default initial view
    init_theta_x = np.pi * 0.2
    init_theta_y = -np.pi * 0.5

    # BOOOM settings for first-pass runs
    booom_MaxTime = 120
    booom_MaxRuns = 2
    booom_MaxIter = 100
    booom_sInitial = 1.0
    booom_rho = 2.0
    booom_TolFun1 = 1e-6
    booom_TolFun2 = 1e-10
    booom_phi = 1e-12

    # Chair list
    chair_files = [
        "chair_0001.off",
        "chair_0004.off",
        "chair_0006.off",
    ]

    # Load model ONCE and reuse for all chairs
    print("Loading pretrained ResNet18 once...")
    model, normalizer, class_names = load_resnet18(device=device)

    all_summaries = []

    for chair_file in chair_files:
        if not os.path.exists(chair_file):
            print(f"Skipping missing file: {chair_file}")
            continue

        summary = optimize_single_chair_worst_view(
            mesh_path=chair_file,
            model=model,
            normalizer=normalizer,
            class_names=class_names,
            output_dir=output_dir,
            true_idx=559,  # folding chair
            num_points=num_points,
            init_theta_x=init_theta_x,
            init_theta_y=init_theta_y,
            device=device,
            booom_MaxTime=booom_MaxTime,
            booom_MaxRuns=booom_MaxRuns,
            booom_MaxIter=booom_MaxIter,
            booom_sInitial=booom_sInitial,
            booom_rho=booom_rho,
            booom_TolFun1=booom_TolFun1,
            booom_TolFun2=booom_TolFun2,
            booom_phi=booom_phi,
            seed=seed
        )
        all_summaries.append(summary)

    # Save one master summary CSV across all chairs
    if len(all_summaries) > 0:
        summary_file = os.path.join(output_dir, "BOOOM_output_all_chairs_summary.csv")
        fieldnames = list(all_summaries[0].keys())
        with open(summary_file, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(all_summaries)

        print("\nSaved overall summary to:")
        print(summary_file)

    print("\nAll done.")


if __name__ == "__main__":
    main()