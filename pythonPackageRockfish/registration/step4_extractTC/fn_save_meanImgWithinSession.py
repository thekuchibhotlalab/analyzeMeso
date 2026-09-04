import os
from pathlib import Path
from typing import Optional, Tuple

import numpy as np
import scipy.io
import scipy.ndimage


N_MEAN_FRAMES = 200
Z_SCORE_LIMIT = 6
BIN_FILE_NAME = "data_suite2p.bin"
OUTPUT_FILE_NAME = "meanImgWithinSession.mat"


def enhanced_image(input_img: np.ndarray, zscore_lim: float = Z_SCORE_LIMIT,
                   diameter: Tuple[int, int] = (3, 3)) -> np.ndarray:
    """
    Python version of MATLAB enhancedImage.m.

    The default diameter=[3 3] becomes a 13x13 median-filter window, matching:
        diameter = 4 * [spatscale_pix * aspect, spatscale_pix] + 1
    """
    img = input_img.astype(np.float64, copy=False)
    spatscale_pix = diameter[1]
    aspect = diameter[0] / diameter[1]
    filter_size = (
        int(4 * spatscale_pix * aspect + 1),
        int(4 * spatscale_pix + 1),
    )

    img_bg = scipy.ndimage.median_filter(img, size=filter_size, mode="constant", cval=0)
    img_residual = img - img_bg
    img_scale = scipy.ndimage.median_filter(np.abs(img_residual), size=filter_size,
                                            mode="constant", cval=0)
    img_z = img_residual / (1e-10 + img_scale)

    img_enhanced = (img_z + zscore_lim) / (2 * zscore_lim)
    img_enhanced = np.clip(img_enhanced, 0, 1)
    return img_enhanced.astype(np.float32)


def load_suite2p_dims(plane0_dir: Path) -> Tuple[int, int]:
    ops_path = plane0_dir / "ops.npy"
    if not ops_path.is_file():
        raise FileNotFoundError(f"Missing ops.npy: {ops_path}")
    ops = np.load(ops_path, allow_pickle=True).item()
    return int(ops["Ly"]), int(ops["Lx"])


def get_n_frames(bin_path: Path, ly: int, lx: int) -> int:
    bytes_per_frame = ly * lx * np.dtype("int16").itemsize
    file_size = bin_path.stat().st_size
    if file_size % bytes_per_frame != 0:
        raise ValueError(
            f"File size is not divisible by Ly*Lx*int16 bytes: {bin_path} "
            f"file_size={file_size}, Ly={ly}, Lx={lx}"
        )
    return file_size // bytes_per_frame


def mean_frame_block(movie: np.memmap, start_frame: int, n_frames: int) -> np.ndarray:
    if n_frames <= 0:
        raise ValueError("n_frames must be positive.")
    return np.mean(movie[start_frame:start_frame + n_frames, :, :], axis=0).astype(np.float32)


def process_session(session_dir: Path, n_mean_frames: int = N_MEAN_FRAMES) -> Optional[dict]:
    plane0_dir = session_dir / "suite2p" / "plane0"
    bin_path = plane0_dir / BIN_FILE_NAME
    if not bin_path.is_file():
        print(f"Skipping {session_dir.name}: missing {bin_path}")
        return None

    ly, lx = load_suite2p_dims(plane0_dir)
    n_total_frames = get_n_frames(bin_path, ly, lx)
    if n_total_frames == 0:
        print(f"Skipping {session_dir.name}: movie has 0 frames")
        return None

    n_first = min(n_mean_frames, n_total_frames)
    n_last = min(n_mean_frames, n_total_frames)
    last_start = n_total_frames - n_last

    print(
        f"Processing {session_dir.name}: Ly={ly}, Lx={lx}, frames={n_total_frames}, "
        f"first={n_first}, last={n_last}"
    )

    movie = np.memmap(bin_path, dtype="int16", mode="r", shape=(n_total_frames, ly, lx))
    mean_first = mean_frame_block(movie, 0, n_first)
    mean_last = mean_frame_block(movie, last_start, n_last)

    return {
        "sessionName": session_dir.name,
        "binPath": str(bin_path),
        "Ly": ly,
        "Lx": lx,
        "nFrames": n_total_frames,
        "nFirstFramesUsed": n_first,
        "nLastFramesUsed": n_last,
        "meanImgFirst200": mean_first,
        "meanImgLast200": mean_last,
        "meanImgFirst200Enhanced": enhanced_image(mean_first),
        "meanImgLast200Enhanced": enhanced_image(mean_last),
    }


def entries_to_mat(entries: list[dict]) -> dict:
    session_names = np.array([entry["sessionName"] for entry in entries], dtype=object)
    bin_paths = np.array([entry["binPath"] for entry in entries], dtype=object)
    ly = np.array([entry["Ly"] for entry in entries], dtype=np.int32)
    lx = np.array([entry["Lx"] for entry in entries], dtype=np.int32)
    n_frames = np.array([entry["nFrames"] for entry in entries], dtype=np.int64)
    n_first = np.array([entry["nFirstFramesUsed"] for entry in entries], dtype=np.int32)
    n_last = np.array([entry["nLastFramesUsed"] for entry in entries], dtype=np.int32)

    same_size = len(set(zip(ly.tolist(), lx.tolist()))) == 1
    if same_size:
        mean_first = np.stack([entry["meanImgFirst200"] for entry in entries], axis=2)
        mean_last = np.stack([entry["meanImgLast200"] for entry in entries], axis=2)
        enh_first = np.stack([entry["meanImgFirst200Enhanced"] for entry in entries], axis=2)
        enh_last = np.stack([entry["meanImgLast200Enhanced"] for entry in entries], axis=2)
    else:
        print("WARNING: not all sessions have the same image size; saving image fields as cell arrays.")
        mean_first = np.array([entry["meanImgFirst200"] for entry in entries], dtype=object)
        mean_last = np.array([entry["meanImgLast200"] for entry in entries], dtype=object)
        enh_first = np.array([entry["meanImgFirst200Enhanced"] for entry in entries], dtype=object)
        enh_last = np.array([entry["meanImgLast200Enhanced"] for entry in entries], dtype=object)

    return {
        "sessionName": session_names,
        "binPath": bin_paths,
        "Ly": ly,
        "Lx": lx,
        "nFrames": n_frames,
        "nFirstFramesUsed": n_first,
        "nLastFramesUsed": n_last,
        "meanImgFirst200": mean_first,
        "meanImgLast200": mean_last,
        "meanImgFirst200Enhanced": enh_first,
        "meanImgLast200Enhanced": enh_last,
        "note": (
            "Images are read from suite2p/plane0/data_suite2p.bin as int16 frames "
            "with shape [Ly, Lx] using suite2p/plane0/ops.npy. Enhanced images follow "
            "MATLAB enhancedImage.m defaults: zscoreLim=6, diameter=[3 3]."
        ),
    }


def save_mean_images(base_dir: Optional[Path] = None) -> Path:
    if base_dir is None:
        base_dir = Path(os.getcwd())
    base_dir = Path(base_dir).resolve()
    imaging_dir = base_dir / "imagingSession"
    if not imaging_dir.is_dir():
        raise FileNotFoundError(f"Could not find imagingSession folder under: {base_dir}")

    session_dirs = sorted(p for p in imaging_dir.iterdir() if p.is_dir())
    if not session_dirs:
        raise FileNotFoundError(f"No session subfolders found under: {imaging_dir}")

    print(f"Base directory: {base_dir}")
    print(f"Imaging session directory: {imaging_dir}")
    print(f"Found {len(session_dirs)} session folders.")

    entries = []
    for session_dir in session_dirs:
        try:
            entry = process_session(session_dir)
            if entry is not None:
                entries.append(entry)
        except Exception as exc:
            print(f"Skipping {session_dir.name}: {exc}")

    if not entries:
        raise RuntimeError("No sessions were processed successfully.")

    output_path = imaging_dir / OUTPUT_FILE_NAME
    scipy.io.savemat(output_path, entries_to_mat(entries), do_compression=True)
    print(f"Saved {len(entries)} sessions to: {output_path}")
    return output_path


if __name__ == "__main__":
    save_mean_images()
