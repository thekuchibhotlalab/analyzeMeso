"""
Ad hoc H5 spatial padding utility.

Run this from an animal/data folder that contains:

    imagingSession/session_folder/*.h5

It pads any spatial /data axis with length 510 up to 512 by adding one pixel
on each side. The padding value is the 10th percentile of the whole /data
dataset, used as a dark baseline value. The original H5 is left untouched;
the padded file is saved as *_parsedPad.h5 in the same session folder.

For the current Rockfish Python-written H5 files, h5py usually sees /data as:

    frames x X x Y

MATLAB h5read/h5info sees dimensions reversed:

    Y x X x frames

So this script does not assume a fixed y-axis index. It detects whichever
spatial axis has size 510, while never padding axis 0 because axis 0 is frames
for these files.
"""

import os
import time
from pathlib import Path

import h5py
import numpy as np


DATASET_PATH = "/data"
BAD_SIZE = 510
GOOD_SIZE = 512
FRAME_CHUNK = int(os.environ.get("H5_FRAME_CHUNK", "1000"))
PERCENTILE_VALUE = 10
MAX_FLOAT_PERCENTILE_SAMPLE = int(os.environ.get("H5_PERCENTILE_SAMPLE", "5000000"))


def main():
    base_dir = Path.cwd().resolve()
    imaging_dir = base_dir / "imagingSession"
    if not imaging_dir.is_dir():
        raise FileNotFoundError(f"Could not find imagingSession under current directory: {base_dir}")

    h5_files = sorted(imaging_dir.glob("*/*.h5"))
    print(f"Base folder: {base_dir}")
    print(f"Found {len(h5_files)} H5 file(s) under {imaging_dir}\\*\\*.h5")

    fixed_count = 0
    skipped_count = 0
    for h5_path in h5_files:
        fixed = pad_h5_if_needed(h5_path)
        if fixed:
            fixed_count += 1
        else:
            skipped_count += 1

    print("\nDone.")
    print(f"  fixed:   {fixed_count}")
    print(f"  skipped: {skipped_count}")


def pad_h5_if_needed(h5_path: Path) -> bool:
    print("\n" + "=" * 80)
    print(f"File: {h5_path}")
    t0 = time.time()
    output_path = make_output_path(h5_path)
    tmp_path = h5_path.with_name(f"{output_path.stem}_tmp{h5_path.suffix}")

    if output_path.exists():
        print(f"  SKIP: output already exists: {output_path}")
        return False

    if tmp_path.exists():
        tmp_path.unlink()

    with h5py.File(h5_path, "r") as src:
        if DATASET_PATH not in src:
            print(f"  SKIP: dataset {DATASET_PATH} not found.")
            return False

        src_data = src[DATASET_PATH]
        old_shape = tuple(src_data.shape)
        print_shape_proof("old", src_data)

        if src_data.ndim != 3:
            print(f"  SKIP: expected 3D /data, got {src_data.ndim}D.")
            return False

        if old_shape[0] == BAD_SIZE:
            print("  SKIP: axis 0 is 510, but axis 0 is treated as frames, not spatial.")
            return False

        pad_axes = [axis for axis in range(1, src_data.ndim) if old_shape[axis] == BAD_SIZE]
        if not pad_axes:
            print("  SKIP: no spatial axis has size 510.")
            return False

        new_shape = list(old_shape)
        for axis in pad_axes:
            new_shape[axis] = GOOD_SIZE
        new_shape = tuple(new_shape)

        print(f"  Padding h5py spatial axis/axes: {pad_axes}")
        print(f"  New h5py shape will be:   {new_shape}")
        print(f"  New MATLAB shape will be: {tuple(reversed(new_shape))}")
        chunk_mb = FRAME_CHUNK * old_shape[1] * old_shape[2] * np.dtype(src_data.dtype).itemsize / 1024**2
        print(f"  streaming frame chunk: {FRAME_CHUNK} frame(s), about {chunk_mb:.1f} MB before padding")
        if src_data.dtype != np.dtype("int16"):
            print(f"  WARNING: source dtype is {src_data.dtype}; output will follow fn_saveh5.py and save /data as int16.")

        pad_value = compute_dataset_percentile(src_data, PERCENTILE_VALUE)
        print(f"  Padding value: {PERCENTILE_VALUE}th percentile = {pad_value}")

        with h5py.File(tmp_path, "w") as dst:
            copy_file_attrs(src, dst)
            copy_root_items_except_data(src, dst)

            # Match fn_saveh5.py: create an extendable int16 dataset, then
            # append frame chunks by resizing along axis 0.
            dset = dst.create_dataset(
                DATASET_PATH,
                shape=(0, new_shape[1], new_shape[2]),
                maxshape=(None,) + new_shape[1:],
                chunks=(int(FRAME_CHUNK), new_shape[1], new_shape[2]),
                dtype="int16",
            )
            copy_dataset_attrs(src_data, dset)
            dset.attrs["spatial_padding"] = f"padded spatial axis/axes {pad_axes} from 510 to 512"
            dset.attrs["padding_value"] = pad_value
            dset.attrs["padding_percentile"] = PERCENTILE_VALUE
            dset.attrs["matlab_axis_order_after_padding"] = "reversed h5py order"

            write_padded_dataset(src_data, dset, pad_axes, pad_value)

    verify_tmp_file(tmp_path, new_shape)
    os.replace(tmp_path, output_path)
    elapsed = time.time() - t0
    print(f"  saved padded H5 in {elapsed:.2f} sec: {output_path}")
    return True


def make_output_path(h5_path: Path) -> Path:
    stem = h5_path.stem
    if stem.endswith("_parsed"):
        output_stem = stem[:-len("_parsed")] + "_parsedPad"
    else:
        output_stem = stem + "_parsedPad"
    return h5_path.with_name(output_stem + h5_path.suffix)


def compute_dataset_percentile(src_data, percentile: float) -> float:
    if np.issubdtype(src_data.dtype, np.integer):
        return compute_integer_dataset_percentile(src_data, percentile)
    return compute_sampled_dataset_percentile(src_data, percentile)


def compute_integer_dataset_percentile(src_data, percentile: float) -> float:
    n_frames = src_data.shape[0]
    dtype_info = np.iinfo(src_data.dtype)
    offset = -int(dtype_info.min)
    counts = np.zeros(int(dtype_info.max) - int(dtype_info.min) + 1, dtype=np.int64)
    total_count = 0

    for start in range(0, n_frames, FRAME_CHUNK):
        stop = min(start + FRAME_CHUNK, n_frames)
        chunk = np.asarray(src_data[start:stop, :, :])
        shifted = chunk.astype(np.int64, copy=False).ravel() + offset
        counts += np.bincount(shifted, minlength=counts.size)
        total_count += shifted.size
        print(f"  percentile scan frames {start + 1}-{stop}/{n_frames}")
        del chunk, shifted

    target_count = int(np.ceil(percentile / 100 * total_count))
    target_count = max(1, target_count)
    value_idx = int(np.searchsorted(np.cumsum(counts), target_count))
    return float(value_idx - offset)


def compute_sampled_dataset_percentile(src_data, percentile: float) -> float:
    n_frames = src_data.shape[0]
    samples = []
    total_sampled = 0
    for start in range(0, n_frames, FRAME_CHUNK):
        stop = min(start + FRAME_CHUNK, n_frames)
        chunk = np.asarray(src_data[start:stop, :, :]).reshape(-1)
        remaining = MAX_FLOAT_PERCENTILE_SAMPLE - total_sampled
        if remaining <= 0:
            break
        if chunk.size > remaining:
            step = max(1, chunk.size // remaining)
            chunk = chunk[::step][:remaining]
        samples.append(chunk.astype(np.float32, copy=False))
        total_sampled += chunk.size
        print(f"  percentile sample frames {start + 1}-{stop}/{n_frames}, sampled={total_sampled}")

    if not samples:
        raise RuntimeError("Could not sample any values for percentile estimate.")
    return float(np.percentile(np.concatenate(samples), percentile))


def write_padded_dataset(src_data, dst_data, pad_axes, pad_value) -> None:
    n_frames = src_data.shape[0]
    total_frame = 0
    for start in range(0, n_frames, FRAME_CHUNK):
        stop = min(start + FRAME_CHUNK, n_frames)
        chunk = np.asarray(src_data[start:stop, :, :])

        pad_width = [(0, 0)] * chunk.ndim
        for axis in pad_axes:
            pad_width[axis] = (1, 1)

        padded_chunk = np.pad(chunk, pad_width=pad_width, mode="constant", constant_values=pad_value)
        padded_chunk = padded_chunk.astype(np.int16, copy=False)
        dst_data.resize(dst_data.shape[0] + padded_chunk.shape[0], axis=0)
        dst_data[total_frame:total_frame + padded_chunk.shape[0], :, :] = padded_chunk
        total_frame += padded_chunk.shape[0]
        print(f"  wrote padded frames {start + 1}-{stop}/{n_frames}")


def print_shape_proof(label: str, dset) -> None:
    h5py_shape = tuple(dset.shape)
    matlab_shape = tuple(reversed(h5py_shape))
    print(f"  {label} h5py shape:   {h5py_shape}")
    print(f"  {label} MATLAB shape: {matlab_shape}")
    print(f"  {label} dtype:        {dset.dtype}")
    print(f"  attrs h5py_disk_axis_order:    {dset.attrs.get('h5py_disk_axis_order', 'unknown')}")
    print(f"  attrs matlab_h5read_axis_order: {dset.attrs.get('matlab_h5read_axis_order', 'unknown')}")


def verify_tmp_file(tmp_path: Path, expected_shape) -> None:
    with h5py.File(tmp_path, "r") as h5:
        if DATASET_PATH not in h5:
            raise RuntimeError(f"Verification failed: {DATASET_PATH} missing in {tmp_path}")
        dset = h5[DATASET_PATH]
        shape = tuple(dset.shape)
        if shape != expected_shape:
            raise RuntimeError(f"Verification failed for {tmp_path}: expected {expected_shape}, got {shape}")
        if dset.dtype != np.dtype("int16"):
            raise RuntimeError(
                f"Verification failed for {tmp_path}: expected dtype int16, got {dset.dtype}"
            )
        if BAD_SIZE in shape[1:]:
            raise RuntimeError(f"Verification failed for {tmp_path}: spatial axis still has size {BAD_SIZE}: {shape}")
        print(f"  verification passed: /data shape is {shape}, dtype is {dset.dtype}")


def copy_file_attrs(src, dst) -> None:
    for key, value in src.attrs.items():
        dst.attrs[key] = value


def copy_dataset_attrs(src_dset, dst_dset) -> None:
    for key, value in src_dset.attrs.items():
        dst_dset.attrs[key] = value


def copy_root_items_except_data(src, dst) -> None:
    for key in src.keys():
        if src[key].name == DATASET_PATH:
            continue
        src.copy(key, dst)


if __name__ == "__main__":
    main()
