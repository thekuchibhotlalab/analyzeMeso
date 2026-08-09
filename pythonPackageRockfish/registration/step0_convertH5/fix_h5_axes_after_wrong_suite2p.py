import os
import shutil
import time
from pathlib import Path

import h5py
import numpy as np


# Run this script from the animal folder:
#     python fix_h5_axes_after_wrong_suite2p.py
#
# It expects:
#     current_folder/imagingSession/session_folder/*.h5
#     current_folder/imagingSession/session_folder/suite2p
#
# The bad Python-created H5 files are seen by MATLAB as X x Y x T.
# This rewrites them so MATLAB h5info/h5read sees Y x X x T, matching the
# old MATLAB fn_saveh5.m output used by step3_alignRefStack.

DATASET_PATH = "/data"
FRAME_CHUNK = 2000


def main():
    base_dir = Path.cwd().resolve()
    imaging_dir = base_dir / "imagingSession"
    if not imaging_dir.is_dir():
        raise FileNotFoundError(f"Could not find imagingSession under current directory: {base_dir}")

    session_dirs = sorted(p for p in imaging_dir.iterdir() if p.is_dir())
    print(f"Base folder: {base_dir}")
    print(f"Imaging session folder: {imaging_dir}")
    print(f"Found {len(session_dirs)} session folder(s).")

    for session_dir in session_dirs:
        process_session(session_dir)


def process_session(session_dir):
    print("\n" + "=" * 80)
    print(f"Session: {session_dir.name}")

    h5_files = sorted(session_dir.glob("*.h5"))
    if not h5_files:
        print("  No H5 file directly inside this session folder; skipping H5 repair.")
    else:
        for h5_path in h5_files:
            repair_h5_in_place(h5_path)

    rename_suite2p_folder(session_dir)


def repair_h5_in_place(h5_path):
    t0 = time.time()
    tmp_path = h5_path.with_name(f"{h5_path.stem}_axisfix_tmp{h5_path.suffix}")

    if tmp_path.exists():
        tmp_path.unlink()

    with h5py.File(h5_path, "r") as src:
        if DATASET_PATH not in src:
            print(f"  {h5_path.name}: dataset {DATASET_PATH} not found; skipping.")
            return

        src_data = src[DATASET_PATH]
        old_h5py_shape = tuple(src_data.shape)
        if src_data.ndim != 3:
            print(f"  {h5_path.name}: expected 3D /data, got {old_h5py_shape}; skipping.")
            return

        n_frames, old_y, old_x = old_h5py_shape
        new_h5py_shape = (n_frames, old_x, old_y)
        old_matlab_shape = tuple(reversed(old_h5py_shape))
        new_matlab_shape = tuple(reversed(new_h5py_shape))

        print(f"  Repairing: {h5_path.name}")
        print(f"    old h5py shape:   {old_h5py_shape}")
        print(f"    old MATLAB shape: {old_matlab_shape}")
        print(f"    new h5py shape:   {new_h5py_shape}")
        print(f"    new MATLAB shape: {new_matlab_shape}")

        with h5py.File(tmp_path, "w") as dst:
            copy_file_attrs(src, dst)
            copy_root_items_except_data(src, dst)

            chunk_frames = min(FRAME_CHUNK, n_frames)
            dset = dst.create_dataset(
                DATASET_PATH,
                shape=new_h5py_shape,
                maxshape=(None, old_x, old_y),
                chunks=(chunk_frames, old_x, old_y),
                dtype=src_data.dtype,
            )
            copy_dataset_attrs(src_data, dset)
            dset.attrs["axis_repair"] = "transposed h5py /data from T,Y,X to T,X,Y"
            dset.attrs["matlab_axis_order_after_repair"] = "Y,X,T"

            for start in range(0, n_frames, FRAME_CHUNK):
                stop = min(start + FRAME_CHUNK, n_frames)
                chunk = src_data[start:stop, :, :]
                dset[start:stop, :, :] = np.transpose(chunk, (0, 2, 1))
                print(f"    wrote frames {start + 1}-{stop}/{n_frames}")

    os.replace(tmp_path, h5_path)
    elapsed = time.time() - t0
    print(f"    replaced original H5 in {elapsed:.2f} sec")


def copy_file_attrs(src, dst):
    for key, value in src.attrs.items():
        dst.attrs[key] = value


def copy_dataset_attrs(src_dset, dst_dset):
    for key, value in src_dset.attrs.items():
        dst_dset.attrs[key] = value


def copy_root_items_except_data(src, dst):
    for key in src.keys():
        if src[key].name == DATASET_PATH:
            continue
        src.copy(key, dst)


def rename_suite2p_folder(session_dir):
    suite2p_dir = session_dir / "suite2p"
    suite2p_old_dir = session_dir / "suite2p_old"

    if not suite2p_dir.exists():
        print("  No suite2p folder to rename.")
        return

    if suite2p_old_dir.exists():
        print("  suite2p_old already exists; leaving current suite2p folder unchanged.")
        return

    shutil.move(str(suite2p_dir), str(suite2p_old_dir))
    print("  Renamed suite2p -> suite2p_old")


if __name__ == "__main__":
    main()
