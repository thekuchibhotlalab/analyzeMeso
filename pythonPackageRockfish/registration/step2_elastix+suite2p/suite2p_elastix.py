import os
import inspect
from pathlib import Path
import numpy as np
import suite2p
from suite2p.registration import nonrigid as suite2p_nonrigid
import scipy.io as io
from datetime import datetime
import pathlib

HARD_CLIP_NONRIGID_OFFSETS = True


def _clip_shift_array(arr, limit):
    if hasattr(arr, "clamp"):
        return arr.clamp(min=-limit, max=limit)
    return np.clip(arr, -limit, limit)


def _install_nonrigid_hard_clip():
    original_phasecorr = suite2p_nonrigid.phasecorr
    phasecorr_signature = inspect.signature(original_phasecorr)

    def phasecorr_with_hard_clip(*args, **kwargs):
        result = original_phasecorr(*args, **kwargs)
        try:
            bound_args = phasecorr_signature.bind_partial(*args, **kwargs)
            maxregshiftNR = bound_args.arguments.get("maxregshiftNR", None)
        except TypeError:
            maxregshiftNR = kwargs.get("maxregshiftNR", None)

        if maxregshiftNR is None or not isinstance(result, tuple) or len(result) < 2:
            return result

        clipped_result = list(result)
        limit = float(maxregshiftNR)
        clipped_result[0] = _clip_shift_array(clipped_result[0], limit)
        clipped_result[1] = _clip_shift_array(clipped_result[1], limit)
        return tuple(clipped_result)

    suite2p_nonrigid.phasecorr = phasecorr_with_hard_clip
    print(
        "Installed hard clipping for Suite2p nonrigid offsets: "
        "saved/applied xoff1 and yoff1 will be clipped to +/- maxregshiftNR."
    )


def _as_numeric_array(value):
    """Flatten Suite2p offset fields without assuming list/array layout."""
    if value is None:
        return np.array([], dtype=float)
    if isinstance(value, (list, tuple)):
        pieces = [_as_numeric_array(v).ravel() for v in value]
        pieces = [p for p in pieces if p.size > 0]
        return np.concatenate(pieces) if pieces else np.array([], dtype=float)
    arr = np.asarray(value)
    if arr.dtype == object:
        pieces = [_as_numeric_array(v).ravel() for v in arr.ravel()]
        pieces = [p for p in pieces if p.size > 0]
        return np.concatenate(pieces) if pieces else np.array([], dtype=float)
    return arr.astype(float, copy=False).ravel()


def _offset_summary(output_ops, key):
    arr = _as_numeric_array(output_ops.get(key))
    arr = arr[np.isfinite(arr)]
    if arr.size == 0:
        return {
            "n": 0,
            "max_abs": np.nan,
            "p99_abs": np.nan,
        }
    abs_arr = np.abs(arr)
    return {
        "n": int(arr.size),
        "max_abs": float(np.max(abs_arr)),
        "p99_abs": float(np.percentile(abs_arr, 99)),
    }


def _print_and_save_registration_check(output_ops, requested_ops, save_dir):
    keys = ["nonrigid", "block_size", "maxregshift", "maxregshiftNR", "snr_thresh"]
    print("\nSuite2p registration settings check:")
    for key in keys:
        print(f"  {key}: requested={requested_ops.get(key)} saved={output_ops.get(key)}")

    summaries = {key: _offset_summary(output_ops, key) for key in ["yoff", "xoff", "yoff1", "xoff1"]}
    print("\nSuite2p offset summary:")
    for key, summary in summaries.items():
        print(
            f"  {key}: n={summary['n']}, "
            f"p99_abs={summary['p99_abs']:.3f}, max_abs={summary['max_abs']:.3f}"
        )

    nr_limit = float(requested_ops["maxregshiftNR"])
    yoff1 = _as_numeric_array(output_ops.get("yoff1"))
    xoff1 = _as_numeric_array(output_ops.get("xoff1"))
    # Suite2p's native subpixel refinement can exceed maxregshiftNR by the
    # padding size. When HARD_CLIP_NONRIGID_OFFSETS is enabled, this wrapper
    # clips the offsets before Suite2p applies/saves them.
    hard_limit = nr_limit + (1e-6 if HARD_CLIP_NONRIGID_OFFSETS else 0.5)
    bad_y = int(np.sum(np.abs(yoff1[np.isfinite(yoff1)]) > hard_limit))
    bad_x = int(np.sum(np.abs(xoff1[np.isfinite(xoff1)]) > hard_limit))

    check_path = save_dir / "suite2p_elastix_registration_check.mat"
    io.savemat(
        check_path,
        {
            "requested_maxregshiftNR": nr_limit,
            "saved_maxregshiftNR": output_ops.get("maxregshiftNR", np.nan),
            "requested_maxregshift": requested_ops.get("maxregshift", np.nan),
            "saved_maxregshift": output_ops.get("maxregshift", np.nan),
            "max_abs_yoff": summaries["yoff"]["max_abs"],
            "max_abs_xoff": summaries["xoff"]["max_abs"],
            "max_abs_yoff1": summaries["yoff1"]["max_abs"],
            "max_abs_xoff1": summaries["xoff1"]["max_abs"],
            "n_yoff1_over_limit": bad_y,
            "n_xoff1_over_limit": bad_x,
            "hard_check_limit": hard_limit,
            "hard_clip_nonrigid_offsets": HARD_CLIP_NONRIGID_OFFSETS,
        },
    )
    print(f"Saved registration check to: {check_path}")

    if bad_y or bad_x:
        print(
            "WARNING: Suite2p nonrigid offsets exceed the hard check limit. "
            f"Requested limit={nr_limit}, hard check limit={hard_limit}, "
            f"n_yoff1_over_limit={bad_y}, "
            f"n_xoff1_over_limit={bad_x}. Check that old suite2p outputs and "
            "crossSessionSuite2p.mat files were regenerated from this run, "
            "and that this wrapper is the script being executed."
        )


ops = suite2p.default_ops() # np.load(ops,'ops.npy')
ops['batch_size'] = 10 # we will decrease the batch_size in case low RAM on computer
ops['threshold_scaling'] = 2.0 # we are increasing the threshold for finding ROIs to limit the number of non-cell ROIs found (sometimes useful in gcamp injections)
ops['fs'] = 15 # sampling rate of recording, determines binning for cell detection
ops['tau'] = 0.2 # timescale of gcamp to use for deconvolution
ops['save_mat'] = True
ops['do_bidiphase'] = True
ops['input_format'] = 'tiff'
#ops['h5py_key'] = 'data'
ops['nimg_init'] = 10
ops['nonrigid'] = True
ops['block_size']  = [256, 256]
ops['snr_thresh'] = 1.2
ops['maxregshift'] = 0.01
ops['maxregshiftNR'] =  1
ops['roidetect'] =  0

refImg = io.loadmat('refImg.mat')
ops['refImg'] =  refImg['ref']
ops['force_refImg'] =  True

datapath = 'alignedElastix/'
suite2p_output_dir = Path(datapath) / 'suite2p'
if suite2p_output_dir.exists():
    print(
        f"WARNING: existing Suite2p output folder found: {suite2p_output_dir}\n"
        "If you are checking a changed maxregshiftNR, make sure this folder and "
        "any exported crossSessionSuite2p.mat files are from the new run."
    )

print(ops)
if HARD_CLIP_NONRIGID_OFFSETS:
    _install_nonrigid_hard_clip()

db = {
    'data_path': [datapath],
    }
output_ops = suite2p.run_s2p(ops=ops, db=db)

plane0_dir = Path(datapath) / 'suite2p' / 'plane0'
_print_and_save_registration_check(output_ops, ops, plane0_dir)

# now save the .mat file is suite2p does not save it
ops_matlab = output_ops.copy()
if ops_matlab.get("date_proc"):
    try:
        ops_matlab["date_proc"] = str(
            datetime.strftime(ops_matlab["date_proc"], "%Y-%m-%d %H:%M:%S.%f"))
    except:
        pass
for k in ops_matlab.keys():
    if isinstance(ops_matlab[k], (pathlib.WindowsPath, pathlib.PosixPath)):
        ops_matlab[k] = os.fspath(ops_matlab[k].absolute())
    elif isinstance(ops_matlab[k], list) and len(ops_matlab[k]) > 0:
        if isinstance(ops_matlab[k][0], (pathlib.WindowsPath, pathlib.PosixPath)):
            ops_matlab[k] = [os.fspath(p.absolute()) for p in ops_matlab[k]]
            print(k, ops_matlab[k])

io.savemat(datapath + 'suite2p/plane0/Fall.mat', {'ops':ops_matlab})
