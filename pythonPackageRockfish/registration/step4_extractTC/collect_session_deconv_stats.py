"""Summarize deconvolution parameters and trace percentiles across sessions.

Run from the animal directory (the parent of imagingSession):
    python /path/to/collect_session_deconv_stats.py
Or supply that directory:
    python collect_session_deconv_stats.py /path/to/animal

Dependencies: numpy >= 1.22, scipy, h5py.
Reads ordinary and MATLAB v7.3 MAT files, loading one signal matrix at a time.
Writes session_deconv_stats.mat in the animal directory, with:
    sessionNames: nSession x 1 MATLAB cell array, alphabetically sorted
    b, g, lam: nSession x nNeuron
    dffPercentiles, allTracesPercentiles, SPercentiles: nSession x nNeuron x 5
    spkPercentiles: alias of SPercentiles for backward compatibility
    percentileLevels: [5, 25, 50, 75, 95]
    nFrames: nSession x 3, in signalNames order
    signalNames, dffVariableNames: input provenance

Neuron columns must identify the same neurons in every session. NaNs are
omitted; all-NaN neurons remain NaN.
The Hazen percentile method matches the MATLAB R2023b prctile convention.
The compact summary is saved as a compressed, MATLAB-compatible v5 MAT file.
"""

import argparse
import os
from pathlib import Path
import tempfile
import warnings

import h5py
import numpy as np
from scipy.io import loadmat, savemat, whosmat


PERCENTILE_LEVELS = np.array([5, 25, 50, 75, 95], dtype=np.float64)
SIGNALS = (
    ("data_dff.mat", ("F", "dff"), "dffPercentiles"),
    ("data_F.mat", ("allTraces",), "allTracesPercentiles"),
    ("data_S.mat", ("S",), "SPercentiles"),
)


def load_numeric_variable(filename, candidates):
    """Read the first available candidate, preserving MATLAB array axes."""
    filename = Path(filename)
    if not filename.is_file():
        raise FileNotFoundError(f"Missing input file: {filename}")
    if h5py.is_hdf5(filename):
        with h5py.File(filename, "r") as mat:
            name = next((name for name in candidates if name in mat), None)
            if name is None:
                raise ValueError(f"{filename} must contain {' or '.join(candidates)}")
            dataset = mat[name]
            if not isinstance(dataset, h5py.Dataset) or dataset.dtype.kind not in "fiu":
                raise ValueError(f"{filename}: {name} must be a real numeric array")
            if dataset.attrs.get("MATLAB_empty", 0):
                raise ValueError(f"{filename}: {name} is empty")
            # MATLAB v7.3 stores dimensions in reverse order relative to h5py.
            values = np.asarray(dataset).T
    else:
        names = {name for name, _, _ in whosmat(filename)}
        name = next((name for name in candidates if name in names), None)
        if name is None:
            raise ValueError(f"{filename} must contain {' or '.join(candidates)}")
        values = loadmat(filename, variable_names=[name])[name]
    if not isinstance(values, np.ndarray) or values.dtype.kind not in "fiu":
        raise ValueError(f"{filename}: {name} must be a real numeric array")
    if values.size == 0:
        raise ValueError(f"{filename}: {name} is empty")
    return name, values


def collect_session_deconv_stats(root_dir=None):
    """Save the combined summary and return its Path."""
    root = Path.cwd() if root_dir is None else Path(root_dir).expanduser().resolve()
    session_root = root / "imagingSession"
    if not session_root.is_dir():
        raise FileNotFoundError(f"Folder does not exist: {session_root}")
    sessions = sorted((p for p in session_root.iterdir() if p.is_dir()), key=lambda p: p.name)
    if not sessions:
        raise ValueError(f"No session subfolders found in {session_root}")

    count = len(sessions)
    summary = {
        "sessionNames": np.array([p.name for p in sessions], dtype=object).reshape(-1, 1),
        "percentileLevels": PERCENTILE_LEVELS.reshape(1, -1),
        "signalNames": np.array([["dff", "allTraces", "S"]], dtype=object),
        "dffVariableNames": np.empty((count, 1), dtype=object),
        "nFrames": np.zeros((count, 3), dtype=np.float64),
    }
    n_neurons = None
    for i, session in enumerate(sessions):
        plane = session / "suite2p" / "plane0"
        for field in ("b", "g", "lam"):
            _, vector = load_numeric_variable(plane / "data_spkOps.mat", (field,))
            if vector.ndim != 2 or 1 not in vector.shape:
                raise ValueError(f"Session {session.name}: {field} must be a vector, got {vector.shape}")
            if n_neurons is None:
                n_neurons = vector.size
                for parameter in ("b", "g", "lam"):
                    summary[parameter] = np.full((count, n_neurons), np.nan)
                for _, _, output_name in SIGNALS:
                    summary[output_name] = np.full((count, n_neurons, 5), np.nan)
            if vector.size != n_neurons:
                raise ValueError(
                    f"Session {session.name}: {field} has {vector.size} neurons; expected {n_neurons}"
                )
            summary[field][i] = vector.reshape(-1)

        for j, (filename, candidates, output_name) in enumerate(SIGNALS):
            variable, values = load_numeric_variable(plane / filename, candidates)
            if values.ndim != 2 or values.shape[1] != n_neurons:
                raise ValueError(
                    f"{plane / filename}: {variable} has shape {values.shape}; "
                    f"expected (nFrame, {n_neurons})"
                )
            summary["nFrames"][i, j] = values.shape[0]
            with warnings.catch_warnings():
                warnings.filterwarnings("ignore", message="All-NaN slice encountered", category=RuntimeWarning)
                # NumPy's default 'linear' interpolation differs from MATLAB.
                percentiles = np.nanpercentile(values, PERCENTILE_LEVELS, axis=0, method="hazen")
            summary[output_name][i] = percentiles.T
            del values
            if j == 0:
                summary["dffVariableNames"][i, 0] = variable
        frame_counts = summary["nFrames"][i]
        if not np.all(frame_counts == frame_counts[0]):
            raise ValueError(
                f"Session {session.name}: dff, allTraces and S have different frame counts: {frame_counts}"
            )
        print(
            f"Summarized {i + 1}/{count}: {session.name} "
            f"({int(frame_counts[0])} frames, {n_neurons} neurons)", flush=True
        )

    # Retain the descriptive name used by the earlier version while also
    # exposing a name that directly matches data_S.mat variable S.
    summary["spkPercentiles"] = summary["SPercentiles"]
    output = root / "session_deconv_stats.mat"
    # Keep any previous result intact if writing the replacement fails.
    with tempfile.NamedTemporaryFile(dir=root, prefix=".session_deconv_stats_", suffix=".mat", delete=False) as temp:
        temporary = Path(temp.name)
    try:
        savemat(temporary, summary, do_compression=True, oned_as="row")
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)
    print(f"Saved {output}", flush=True)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("root_dir", nargs="?", default=None, help="Animal directory containing imagingSession (default: current directory)")
    args = parser.parse_args()
    collect_session_deconv_stats(args.root_dir)


if __name__ == "__main__":
    main()
