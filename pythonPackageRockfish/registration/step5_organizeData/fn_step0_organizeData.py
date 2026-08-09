import argparse
import os
from dataclasses import dataclass
from datetime import datetime
from typing import Any, List, Optional, Sequence, Tuple

import numpy as np


@dataclass
class TraceEntry:
    session_dir: str
    trace_file: str
    trace_var: str
    start: Optional[int]
    stop: Optional[int]
    session_name: str
    session_date: int
    session_type: str
    session_number: int
    session_frames: int
    spk_file: Optional[str]
    spk_var: str


def import_scipy_io():
    try:
        import scipy.io
    except ImportError as exc:
        raise ImportError(
            "scipy is required to read Suite2p/Fall .mat files and save sessionInfo. "
            "Install scipy in the Python environment used to run this script."
        ) from exc
    return scipy.io


def import_h5py():
    try:
        import h5py
    except ImportError as exc:
        raise ImportError(
            "h5py is required for memory-friendly MATLAB v7.3 output. "
            "Install h5py in the Python environment used to run this script."
        ) from exc
    return h5py


def get_struct_field(obj: Any, field_name: str) -> Any:
    if hasattr(obj, field_name):
        return getattr(obj, field_name)
    if isinstance(obj, np.ndarray) and obj.dtype.names and field_name in obj.dtype.names:
        return obj[field_name].squeeze()
    if isinstance(obj, dict) and field_name in obj:
        return obj[field_name]
    raise KeyError(f"Could not find field '{field_name}' in MATLAB struct.")


def load_ops(fall_file: str):
    scipy_io = import_scipy_io()
    mat = scipy_io.loadmat(fall_file, squeeze_me=True, struct_as_record=False)
    if "ops" not in mat:
        raise KeyError(f"'ops' was not found in {fall_file}")
    return mat["ops"]


def load_mat_variable(mat_file: str, variable_name: str,
                      row_slice: Optional[Tuple[int, int]] = None) -> np.ndarray:
    """Load a MATLAB variable, with optional row slicing for HDF5/v7.3 files."""
    scipy_io = import_scipy_io()
    try:
        mat = scipy_io.loadmat(mat_file, variable_names=[variable_name])
        if variable_name not in mat:
            raise KeyError
        arr = np.asarray(mat[variable_name])
        if row_slice is not None:
            arr = arr[row_slice[0]:row_slice[1], :]
        return arr
    except (NotImplementedError, ValueError):
        pass
    except KeyError as exc:
        raise KeyError(f"Variable '{variable_name}' was not found in {mat_file}") from exc

    h5py = import_h5py()
    with h5py.File(mat_file, "r") as h5:
        if variable_name not in h5:
            raise KeyError(f"Variable '{variable_name}' was not found in {mat_file}")
        dset = h5[variable_name]
        if row_slice is None:
            arr = dset[()]
        else:
            # MATLAB v7.3 stores numeric arrays transposed relative to NumPy.
            arr = dset[:, row_slice[0]:row_slice[1]][()]
        if arr.ndim == 2:
            arr = arr.T
        return np.asarray(arr)


def normalize_nframes(nframes: Any) -> np.ndarray:
    frames = np.asarray(nframes).astype(np.int64).ravel()
    return frames


def normalize_filelist(filelist: Any) -> List[str]:
    arr = np.asarray(filelist)
    if arr.dtype.kind in ("U", "S", "O"):
        return [str(x).strip() for x in arr.ravel()]
    if arr.dtype.kind in ("u", "i") and arr.ndim == 2:
        return ["".join(chr(int(v)) for v in row if int(v) != 0).strip() for row in arr]
    if arr.dtype.kind in ("U", "S") and arr.ndim == 2:
        return ["".join(row).strip() for row in arr]
    return [str(filelist).strip()]


def parse_session_name_from_folder(folder_name: str) -> Tuple[int, str, str, int]:
    tokens = folder_name.split("_")
    if len(tokens) < 3:
        raise ValueError(f"Could not parse new-style session folder name: {folder_name}")
    session_date = int(tokens[1])
    session_name = tokens[2]
    session_type = session_name[:-1]
    session_number = int(session_name[-1])
    return session_date, session_name, session_type, session_number


def parse_session_name_from_raw_path(raw_path: str, folder_name: str) -> Tuple[int, str, str, int]:
    raw_name = os.path.splitext(os.path.basename(raw_path))[0]
    tokens = raw_name.split("_")
    if len(tokens) < 3:
        raise ValueError(f"Could not parse raw file name from ops.filelist: {raw_name}")
    session_date = int(folder_name)
    session_name = tokens[2]
    session_type = session_name[:-1]
    session_number = int(session_name[-1])
    return session_date, session_name, session_type, session_number


def find_trace_file(s2p_path: str, preferred_file: str, preferred_var: str) -> Tuple[str, str]:
    preferred_path = os.path.join(s2p_path, preferred_file)
    if os.path.isfile(preferred_path):
        return preferred_path, preferred_var

    fallbacks = [
        ("data_F.mat", "allTraces"),
        ("data_dff.mat", "dff"),
    ]
    for filename, variable in fallbacks:
        path = os.path.join(s2p_path, filename)
        if os.path.isfile(path):
            return path, variable

    raise FileNotFoundError(f"Could not find {preferred_file}, data_F.mat, or data_dff.mat in {s2p_path}")


def build_entries(input_dir: str, trace_file_name: str, trace_var_name: str,
                  spk_file_name: str, spk_var_name: str) -> List[TraceEntry]:
    imaging_dir = os.path.join(input_dir, "imagingSession")
    if not os.path.isdir(imaging_dir):
        raise FileNotFoundError(f"Could not find imagingSession folder: {imaging_dir}")

    session_folders = [
        name for name in os.listdir(imaging_dir)
        if os.path.isdir(os.path.join(imaging_dir, name)) and not name.startswith(".")
    ]
    session_folders.sort()

    entries: List[TraceEntry] = []
    for folder_name in session_folders:
        session_dir = os.path.join(imaging_dir, folder_name)
        s2p_path = os.path.join(session_dir, "suite2p", "plane0")
        fall_file = os.path.join(s2p_path, "Fall.mat")
        if not os.path.isfile(fall_file):
            print(f"Warning: missing Fall.mat in {s2p_path}; skipping.")
            continue

        try:
            trace_file, trace_var = find_trace_file(s2p_path, trace_file_name, trace_var_name)
        except FileNotFoundError as exc:
            print(f"Warning: {exc}; skipping.")
            continue

        spk_file = os.path.join(s2p_path, spk_file_name)
        if not os.path.isfile(spk_file):
            spk_file = None

        print(f"Indexing {folder_name}")
        ops = load_ops(fall_file)
        nframes = normalize_nframes(get_struct_field(ops, "nframes_per_folder"))

        if "_" in folder_name:
            session_date, session_name, session_type, session_number = parse_session_name_from_folder(folder_name)
            entries.append(
                TraceEntry(
                    session_dir=session_dir,
                    trace_file=trace_file,
                    trace_var=trace_var,
                    start=None,
                    stop=None,
                    session_name=session_name,
                    session_date=session_date,
                    session_type=session_type,
                    session_number=session_number,
                    session_frames=int(nframes[0] if nframes.size else 0),
                    spk_file=spk_file,
                    spk_var=spk_var_name,
                )
            )
        else:
            filelist = normalize_filelist(get_struct_field(ops, "filelist"))
            start = 0
            for idx, raw_path in enumerate(filelist):
                frames = int(nframes[idx])
                stop = start + frames
                session_date, session_name, session_type, session_number = parse_session_name_from_raw_path(
                    raw_path,
                    folder_name,
                )
                entries.append(
                    TraceEntry(
                        session_dir=session_dir,
                        trace_file=trace_file,
                        trace_var=trace_var,
                        start=start,
                        stop=stop,
                        session_name=session_name,
                        session_date=session_date,
                        session_type=session_type,
                        session_number=session_number,
                        session_frames=frames,
                        spk_file=spk_file,
                        spk_var=spk_var_name,
                    )
                )
                start = stop

    return entries


def write_mat73_header(path: str) -> None:
    description = (
        f"MATLAB 7.3 MAT-file, Platform: Python, Created on: "
        f"{datetime.now().strftime('%a %b %d %H:%M:%S %Y')} HDF5 schema 1.00 ."
    ).encode("ascii", errors="replace")
    header = description[:116].ljust(116, b" ")
    header += b"\x00" * 8
    header += b"\x00\x02IM"
    header = header.ljust(512, b"\x00")
    with open(path, "r+b") as handle:
        handle.seek(0)
        handle.write(header)


def write_cell_mat73(output_path: str, variable_name: str, entries: Sequence[TraceEntry],
                     source_kind: str) -> None:
    h5py = import_h5py()
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with h5py.File(output_path, "w", userblock_size=512) as h5:
        refs_group = h5.create_group("#refs#")
        refs = np.empty((len(entries), 1), dtype=h5py.ref_dtype)

        for idx, entry in enumerate(entries):
            if source_kind == "trace":
                source_file = entry.trace_file
                source_var = entry.trace_var
            else:
                source_file = entry.spk_file
                source_var = entry.spk_var

            if source_file is None:
                data = np.empty((0, 0), dtype=np.float32)
            else:
                row_slice = None if entry.start is None else (entry.start, entry.stop)
                data = load_mat_variable(source_file, source_var, row_slice=row_slice)
                data = np.asarray(data, dtype=np.float32)

            dataset_name = f"{idx:08d}"
            dset = refs_group.create_dataset(
                dataset_name,
                data=data.T,
                compression="gzip",
                compression_opts=4,
                shuffle=True,
            )
            dset.attrs["MATLAB_class"] = np.bytes_("single")
            refs[idx, 0] = dset.ref
            print(f"  wrote {variable_name}{{{idx + 1}}}: {data.shape[0]} frames x {data.shape[1] if data.ndim == 2 else 1} traces")

        cell = h5.create_dataset(variable_name, data=refs)
        cell.attrs["MATLAB_class"] = np.bytes_("cell")

    write_mat73_header(output_path)


def write_session_info(output_path: str, entries: Sequence[TraceEntry], animal_id: str) -> None:
    scipy_io = import_scipy_io()
    dtype = [
        ("SessionName", "O"),
        ("SessionDate", "O"),
        ("SessionType", "O"),
        ("SessionNumber", "O"),
        ("SessionFrames", "O"),
    ]
    session_info = np.empty((len(entries), 1), dtype=dtype)
    for idx, entry in enumerate(entries):
        session_info[idx, 0]["SessionName"] = entry.session_name
        session_info[idx, 0]["SessionDate"] = float(entry.session_date)
        session_info[idx, 0]["SessionType"] = entry.session_type
        session_info[idx, 0]["SessionNumber"] = float(entry.session_number)
        session_info[idx, 0]["SessionFrames"] = float(entry.session_frames)

    scipy_io.savemat(
        output_path,
        {
            "sessionInfo": session_info,
            "animalID": animal_id,
        },
        long_field_names=True,
        do_compression=True,
    )


def organize_data(input_dir: str, trace_file_name: str = "data_F.mat",
                  trace_var_name: str = "allTraces",
                  spk_file_name: str = "data_S.mat",
                  spk_var_name: str = "S") -> None:
    input_dir = os.path.abspath(input_dir)
    output_dir = input_dir
    animal_id = os.path.basename(os.path.normpath(input_dir))

    entries = build_entries(input_dir, trace_file_name, trace_var_name, spk_file_name, spk_var_name)
    if not entries:
        raise RuntimeError(f"No valid sessions were found under {os.path.join(input_dir, 'imagingSession')}")

    tc_file = os.path.join(output_dir, f"{animal_id}_TC.mat")
    session_info_file = os.path.join(output_dir, f"{animal_id}_sessionInfo.mat")
    spk_file = os.path.join(output_dir, f"{animal_id}_spk.mat")

    print(f"Saving trace cell array to {tc_file}")
    write_cell_mat73(tc_file, "dff", entries, source_kind="trace")

    print(f"Saving session info to {session_info_file}")
    write_session_info(session_info_file, entries, animal_id)

    if any(entry.spk_file is not None for entry in entries):
        print(f"Saving spike cell array to {spk_file}")
        write_cell_mat73(spk_file, "spk", entries, source_kind="spk")
    else:
        print("Warning: no data_S.mat files were found; skipping spk output.")

    print(f"Saved organized data under {output_dir}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Python replacement for fn_step0_organizeData. Reads session data from "
            "<inputDir>/imagingSession and saves organized .mat files directly under <inputDir>."
        )
    )
    parser.add_argument(
        "inputDir",
        nargs="?",
        default=os.getcwd(),
        help="Animal/base folder containing imagingSession. Defaults to the current directory.",
    )
    parser.add_argument("--trace-file", default="data_F.mat", help="Per-session trace .mat filename.")
    parser.add_argument("--trace-var", default="allTraces", help="Trace variable inside --trace-file.")
    parser.add_argument("--spk-file", default="data_S.mat", help="Per-session spike .mat filename.")
    parser.add_argument("--spk-var", default="S", help="Spike variable inside --spk-file.")
    args = parser.parse_args()

    organize_data(
        args.inputDir,
        trace_file_name=args.trace_file,
        trace_var_name=args.trace_var,
        spk_file_name=args.spk_file,
        spk_var_name=args.spk_var,
    )


if __name__ == "__main__":
    main()
