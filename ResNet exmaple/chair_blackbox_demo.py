# ============================================================
# IMPORTS
# ============================================================
from booom import booom
import argparse
import numpy as np
import matplotlib.pyplot as plt
import trimesh
import torch
import torchvision.transforms as transforms
from torchvision.models import resnet18, ResNet18_Weights


# ============================================================
# STEP 1: LOAD MESH AND SAMPLE POINTS
# ============================================================
def load_and_sample_mesh_with_normals(filepath: str, num_points: int = 50000):
    print("\n[STEP 1] Loading mesh from .off file...")

    mesh = trimesh.load(filepath, force="mesh")

    if mesh is None or mesh.faces is None or len(mesh.faces) == 0:
        raise ValueError(f"Invalid mesh: {filepath}")

    print("[STEP 1] Sampling surface points...")
    samples, face_indices = trimesh.sample.sample_surface(mesh, num_points)

    # Convert to shape (3, N)
    X = np.asarray(samples).T

    # Normals (direction of surface)
    normals = np.asarray(mesh.face_normals[face_indices]).T

    # Normalize normals
    normals = normals / np.linalg.norm(normals, axis=0, keepdims=True)

    print(f"[STEP 1 DONE] Sampled {X.shape[1]} points")
    return X, normals


# ============================================================
# STEP 2: GENERATE VIEW MATRIX (YOUR VARIABLE U)
# ============================================================
def generate_view_matrix(theta_x: float, theta_y: float):
    print("\n[STEP 2] Generating orthogonal matrix U (viewpoint)...")

    Rx = np.array([
        [1, 0, 0],
        [0, np.cos(theta_x), np.sin(theta_x)],
        [0, -np.sin(theta_x), np.cos(theta_x)],
    ])

    Ry = np.array([
        [np.cos(theta_y), np.sin(theta_y), 0],
        [-np.sin(theta_y), np.cos(theta_y), 0],
        [0, 0, 1],
    ])

    R = Ry @ Rx
    U = R[:, :2]  # take first 2 columns

    print("[STEP 2 DONE] U shape:", U.shape)
    return U


# ============================================================
# STEP 3: RENDER IMAGE FROM 3D POINT CLOUD
# ============================================================
def render_shaded_orthogonal(X, normals, U, image_size=(224, 224)):
    print("\n[STEP 3] Rendering image from viewpoint U...")

    # Compute viewing direction (camera direction)
    u3 = np.cross(U[:, 0], U[:, 1])
    u3 = u3 / np.linalg.norm(u3)

    # Depth of points
    depth = u3 @ X

    # Lighting (Lambertian shading)
    intensity = normals.T @ u3
    intensity = np.clip(intensity, 0, 1)

    colors = np.repeat(intensity[np.newaxis, :], 3, axis=0)

    # Project to 2D
    X_2d = U.T @ X

    # Normalize to pixel grid
    x_min, x_max = X_2d[0].min(), X_2d[0].max()
    y_min, y_max = X_2d[1].min(), X_2d[1].max()

    W, H = image_size
    xs = np.round((X_2d[0] - x_min) / (x_max - x_min) * (W - 1)).astype(int)
    ys = np.round((X_2d[1] - y_min) / (y_max - y_min) * (H - 1)).astype(int)

    # Create image
    image = np.zeros((H, W, 3))
    valid = (xs >= 0) & (xs < W) & (ys >= 0) & (ys < H)

    image[ys[valid], xs[valid]] = colors[:, valid].T

    print("[STEP 3 DONE] Image rendered")
    return image


# ============================================================
# STEP 4: LOAD RESNET MODEL
# ============================================================
def load_resnet18():
    print("\n[STEP 4] Loading pretrained ResNet18...")

    model = resnet18(weights=ResNet18_Weights.DEFAULT)
    model.eval()

    normalizer = transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )

    class_names = ResNet18_Weights.DEFAULT.meta["categories"]

    print("[STEP 4 DONE] Model loaded")
    return model, normalizer, class_names


# ============================================================
# STEP 5: EVALUATE OBJECTIVE f(U)
# ============================================================
def evaluate_objective(image_np, model, normalizer, true_idx):
    print("\n[STEP 5] Evaluating objective f(U)...")

    # Convert to tensor
    img_tensor = torch.from_numpy(image_np).permute(2, 0, 1).float()
    input_tensor = normalizer(img_tensor).unsqueeze(0)

    with torch.no_grad():
        logits = model(input_tensor)
        probs = torch.nn.functional.softmax(logits, dim=1)

    # Extract probabilities
    true_prob = probs[0, true_idx].item()
    max_prob = probs[0].max().item()

    # Objective
    objective = true_prob - max_prob

    print(f"[STEP 5 DONE] f(U) = {objective:.4f}")
    return objective, probs


# ============================================================
# MAIN PIPELINE
# ============================================================
def main():
    print("\n================= START PROGRAM =================")

    # Arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--mesh", default="chair_0001.off")
    parser.add_argument("--num_points", type=int, default=50000)
    args = parser.parse_args()

    # STEP 1
    X, normals = load_and_sample_mesh_with_normals(args.mesh, args.num_points)

    # STEP 2
    U = generate_view_matrix(theta_x=0.5, theta_y=-1.0)

    # STEP 3
    image = render_shaded_orthogonal(X, normals, U)

    # STEP 4
    model, normalizer, class_names = load_resnet18()

    # STEP 5
    TRUE_IDX = 559  # folding chair
    objective, probs = evaluate_objective(image, model, normalizer, TRUE_IDX)

    print("\n[SEARCH] Looking for viewpoint with objective close to 0...")

    best_val = -1e9
    best_angles = None

    for _ in range(30):  # keep small for now
        theta_x = np.random.uniform(-np.pi, np.pi)
        theta_y = np.random.uniform(-np.pi, np.pi)

        U = generate_view_matrix(theta_x, theta_y)
        img = render_shaded_orthogonal(X, normals, U)

        val, probs = evaluate_objective(img, model, normalizer, TRUE_IDX)

        if val > best_val:
            best_val = val
            best_angles = (theta_x, theta_y)

    print("\n[SEARCH DONE]")
    print(f"Best objective found: {best_val:.10f}")
    print("Best angles:", best_angles)

    # Recompute everything at the BEST viewpoint,
    # so the reported predictions actually match best_val / best_angles
    theta_x_best, theta_y_best = best_angles
    U_best = generate_view_matrix(theta_x_best, theta_y_best)
    image_best = render_shaded_orthogonal(X, normals, U_best)

    best_objective, best_probs = evaluate_objective(
        image_best, model, normalizer, TRUE_IDX
    )

    print("\n[CHECK BEST VIEWPOINT]")
    print(f"Recomputed best objective: {best_objective:.10f}")

    # Print top predictions at the BEST viewpoint
    print("\nTop predictions at best viewpoint:")
    top_probs, top_indices = torch.topk(best_probs, k=5, dim=1)
    for i in range(5):
        idx = top_indices[0, i].item()
        print(f"{i + 1}: {class_names[idx]} ({top_probs[0, i].item():.4f})")

    # Save the BEST rendered image, not the old one
    plt.imsave("rendered_view_best.png", image_best)
    print("\nSaved rendered image to rendered_view_best.png")
    print("\n================= END PROGRAM =================")

# ============================================================
# RUN
# ============================================================
if __name__ == "__main__":
    main()

