import argparse
import os
from typing import List, Tuple

import numpy as np
import scipy.io
from matplotlib.path import Path


def get_movie_dimensions(bin_file_path: str) -> Tuple[int, int, int]:
    ops_path = os.path.join(os.path.dirname(bin_file_path), "ops.npy")
    ops = np.load(ops_path, allow_pickle=True).item()
    x_pixels = int(ops["Lx"])
    y_pixels = int(ops["Ly"])
    file_size = os.path.getsize(bin_file_path)
    n_frames = file_size // (x_pixels * y_pixels * np.dtype("int16").itemsize)
    return x_pixels, y_pixels, int(n_frames)


def read_movie_summary(bin_file_path: str, x_pixels: int, y_pixels: int,
                       n_frames: int, max_mean_frames=None):
    movie = np.memmap(
        bin_file_path,
        dtype="int16",
        mode="r",
        shape=(n_frames, y_pixels, x_pixels),
    )
    first_frame = np.asarray(movie[0], dtype=np.float32)

    frames_to_average = n_frames
    if max_mean_frames is not None:
        frames_to_average = min(n_frames, int(max_mean_frames))

    mean_img_sum = np.zeros((y_pixels, x_pixels), dtype=np.float64)
    for frame_idx in range(frames_to_average):
        mean_img_sum += movie[frame_idx].astype(np.float64)
    mean_img = mean_img_sum / frames_to_average

    return first_frame, mean_img_sum, mean_img, frames_to_average


def roi_to_mask_row_col(roi_coords: np.ndarray, x_pixels: int, y_pixels: int) -> np.ndarray:
    """MATLAB ROI convention: roi_coords[:, 0] = row, roi_coords[:, 1] = col."""
    if roi_coords.size == 0:
        return np.zeros((y_pixels, x_pixels), dtype=bool)
    roi_coords = np.asarray(roi_coords, dtype=float)
    rows = roi_coords[:, 0] - 1
    cols = roi_coords[:, 1] - 1
    return polygon_to_mask(cols, rows, x_pixels, y_pixels)


def roi_to_mask_swapped_xy(roi_coords: np.ndarray, x_pixels: int, y_pixels: int) -> np.ndarray:
    """Old swapped interpretation: roi_coords[:, 0] = x/col, roi_coords[:, 1] = y/row."""
    if roi_coords.size == 0:
        return np.zeros((y_pixels, x_pixels), dtype=bool)
    roi_coords = np.asarray(roi_coords, dtype=float)
    cols = roi_coords[:, 0] - 1
    rows = roi_coords[:, 1] - 1
    return polygon_to_mask(cols, rows, x_pixels, y_pixels)


def polygon_to_mask(cols: np.ndarray, rows: np.ndarray, x_pixels: int, y_pixels: int) -> np.ndarray:
    xx, yy = np.meshgrid(np.arange(x_pixels), np.arange(y_pixels))
    points = np.vstack((xx.ravel(), yy.ravel())).T
    roi_path = Path(np.column_stack((cols, rows)))
    return roi_path.contains_points(points).reshape((y_pixels, x_pixels))


def load_first_session_rois(base_directory: str, session_idx_zero_based: int) -> List[np.ndarray]:
    roi_mat_path = os.path.join(base_directory, "stackROI_final_tracked.mat")
    if not os.path.exists(roi_mat_path):
        raise FileNotFoundError(f"ROI file not found: {roi_mat_path}")

    roi_mat = scipy.io.loadmat(roi_mat_path, squeeze_me=True, struct_as_record=False)
    roi_cell = roi_mat["roiFinal"]

    if isinstance(roi_cell, np.ndarray) and roi_cell.dtype == object:
        if roi_cell.ndim == 2:
            roi_row = roi_cell[session_idx_zero_based, :]
        elif roi_cell.ndim == 1:
            roi_row = roi_cell
        else:
            raise ValueError(f"Unexpected roiFinal object array shape: {roi_cell.shape}")
        return [np.asarray(roi, dtype=float) for roi in roi_row.ravel()]

    roi_array = np.asarray(roi_cell, dtype=float)
    if roi_array.ndim == 2 and roi_array.shape[1] == 2:
        return [roi_array]
    raise ValueError(f"Unexpected roiFinal shape/type: {type(roi_cell)}, {getattr(roi_cell, 'shape', None)}")


def get_session_directory(base_directory: str, session_idx_zero_based: int) -> str:
    imaging_session_dir = os.path.join(base_directory, "imagingSession")
    if not os.path.exists(imaging_session_dir):
        raise FileNotFoundError(f"Imaging session directory not found: {imaging_session_dir}")

    session_dirs = [
        d for d in os.listdir(imaging_session_dir)
        if os.path.isdir(os.path.join(imaging_session_dir, d))
    ]
    session_dirs.sort()
    if session_idx_zero_based >= len(session_dirs):
        raise IndexError(
            f"Requested session {session_idx_zero_based + 1}, but only found {len(session_dirs)} sessions."
        )
    return os.path.join(imaging_session_dir, session_dirs[session_idx_zero_based])


def rois_to_object_cell(roi_coords_list: List[np.ndarray]) -> np.ndarray:
    roi_cell = np.empty((1, len(roi_coords_list)), dtype=object)
    for idx, coords in enumerate(roi_coords_list):
        roi_cell[0, idx] = coords
    return roi_cell


def main():
    parser = argparse.ArgumentParser(
        description="Debug ROI mask axes for the first tracked session without extracting traces."
    )
    parser.add_argument("--base-dir", default=os.getcwd(), help="Animal/base directory. Defaults to current directory.")
    parser.add_argument("--session", type=int, default=1, help="1-indexed session number to inspect. Defaults to 1.")
    parser.add_argument(
        "--max-mean-frames",
        type=int,
        default=None,
        help="Optional number of frames to average for mean_img. Defaults to all frames.",
    )
    args = parser.parse_args()

    base_directory = os.path.abspath(args.base_dir)
    session_idx_zero_based = args.session - 1
    session_dir = get_session_directory(base_directory, session_idx_zero_based)
    bin_file_path = os.path.join(session_dir, "suite2p", "plane0", "data_suite2p.bin")
    if not os.path.exists(bin_file_path):
        raise FileNotFoundError(f"Python movie file not found: {bin_file_path}")

    x_pixels, y_pixels, n_frames = get_movie_dimensions(bin_file_path)
    first_frame, mean_img_sum, mean_img, mean_frames_used = read_movie_summary(
        bin_file_path,
        x_pixels,
        y_pixels,
        n_frames,
        max_mean_frames=args.max_mean_frames,
    )

    roi_coords_list = load_first_session_rois(base_directory, session_idx_zero_based)
    n_rois = len(roi_coords_list)
    masks_row_col = np.zeros((n_rois, y_pixels, x_pixels), dtype=np.uint8)
    masks_swapped_xy = np.zeros((n_rois, y_pixels, x_pixels), dtype=np.uint8)
    for idx, roi_coords in enumerate(roi_coords_list):
        masks_row_col[idx] = roi_to_mask_row_col(roi_coords, x_pixels, y_pixels).astype(np.uint8)
        masks_swapped_xy[idx] = roi_to_mask_swapped_xy(roi_coords, x_pixels, y_pixels).astype(np.uint8)

    output_dir = os.path.join(base_directory, "roiTracking", "extractTC")
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"debug_session_{args.session:03d}_roi_masks.mat")

    scipy.io.savemat(
        output_path,
        {
            "roi_coords_read": rois_to_object_cell(roi_coords_list),
            "roi_masks_row_col": masks_row_col,
            "roi_masks_swapped_xy": masks_swapped_xy,
            "roi_mask_sum_row_col": np.sum(masks_row_col, axis=0),
            "roi_mask_sum_swapped_xy": np.sum(masks_swapped_xy, axis=0),
            "first_frame_python": first_frame,
            "mean_img_sum_python": mean_img_sum,
            "mean_img_python": mean_img,
            "x_pixels": x_pixels,
            "y_pixels": y_pixels,
            "n_frames": n_frames,
            "mean_frames_used": mean_frames_used,
            "session_dir": session_dir,
            "bin_file_path": bin_file_path,
            "coordinate_note": (
                "roi_masks_row_col uses MATLAB tracked ROI convention [row, col] -> Python image [y, x]. "
                "roi_masks_swapped_xy uses the old swapped interpretation for comparison."
            ),
        },
        do_compression=True,
    )
    print(f"Saved ROI mask axis debug file: {output_path}")


if __name__ == "__main__":
    main()
