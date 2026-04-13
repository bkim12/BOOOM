import os
import numpy as np
import matplotlib.pyplot as plt
import trimesh


def load_and_sample_mesh_with_normals(filepath: str, num_points: int = 50000):
    """
    Load a .off mesh, sample points on the surface, and return:
      X       : (3, N) sampled 3D points
      normals : (3, N) unit normals at sampled points
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
    Create a 3x2 orthonormal viewing matrix U from two rotation angles.
    U lies in St(3,2).
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
    Render a grayscale orthographic view of a sampled point cloud.
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
    intensity = np.clip(intensity, 0.0, 1.0) * (1.0 - ambient) + ambient
    colors = np.repeat(intensity[np.newaxis, :], 3, axis=0)

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


def main():
    # Three chair files to compare side-by-side
    chair_files = [
        "chair_0001.off",
        "chair_0004.off",
        "chair_0006.off",
    ]

    # Same viewpoint for all chairs, so comparison is fair
    theta_x = np.pi * 0.2
    theta_y = -np.pi * 0.5
    U = generate_view_matrix(theta_x, theta_y)

    # Faster first-pass rendering
    num_points = 50000

    fig, axes = plt.subplots(1, 3, figsize=(12, 4))

    for ax, chair_file in zip(axes, chair_files):
        if not os.path.exists(chair_file):
            ax.axis("off")
            ax.set_title(f"{chair_file}\nNOT FOUND", fontsize=10)
            continue

        print(f"Rendering {chair_file} ...")
        X, normals = load_and_sample_mesh_with_normals(chair_file, num_points=num_points)
        image = render_shaded_orthogonal(X, normals, U, image_size=(224, 224))

        ax.imshow(image)
        ax.axis("off")
        ax.set_title(chair_file, fontsize=10)

    plt.suptitle("Side-by-side comparison of 3 chair meshes", fontsize=14)
    plt.tight_layout()
    plt.savefig("see_chairs.png", dpi=200, bbox_inches="tight")
    print("Saved figure to see_chairs.png")
    plt.show()


if __name__ == "__main__":
    main()