"""Split vertically stacked ROIs and two saved TIFF channels into separate H5s.

Conversion helper for fn_parseROI_2ch.py.
Channel order means SAVED order; it is not inferred from image brightness.
Dependencies: numpy, tifffile, h5py, scipy. The original converter is unchanged.
"""

from pathlib import Path
import re

import h5py
import numpy as np
import tifffile
from scipy.io import savemat


def parsed_filename_stem(filename):
    """Match the original numbering: zz180_20260302_2AFC_00001 -> ..._2AFC1."""
    stem = Path(filename).stem
    return re.sub(r"_(\d+)$", lambda match: str(int(match.group(1))), stem)


def _channel_pages(tif, layout):
    """Return channel-to-page indices, plus an optional channel axis IN a page."""
    if layout not in ("auto", "interleaved"):
        raise ValueError("layout must be 'auto' or 'interleaved'.")
    pages = tif.pages
    shape = pages[0].shape
    if any(page.shape != shape or page.dtype != pages[0].dtype for page in pages):
        raise ValueError("All TIFF pages must have the same shape and dtype.")

    # Some TIFFs store both channels inside each page (Y,X,C or C,Y,X).
    if len(shape) == 3:
        axes = pages[0].axes
        sample_axis = next((i for i, a in enumerate(axes) if a in "CS"), None)
        if (layout == "interleaved" or sample_axis is None or
                shape[sample_axis] != 2 or axes.replace(axes[sample_axis], "") != "YX"):
            raise ValueError(f"Unsupported page shape/axes: {shape}, {axes}.")
        print(f"  Channels inside each page: {axes}, {len(pages)} frames/channel")
        return [np.arange(len(pages))] * 2, sample_axis

    if len(shape) != 2:
        raise ValueError(f"Expected 2D pages or pages with two channel samples, got {shape}.")

    series = tif.series[0]
    if layout == "auto" and "C" in series.axes:
        # Handles TCYX, CTYX, ZTCYX, etc., without treating C as time or depth.
        axis = series.axes.index("C")
        if (len(tif.series) != 1 or not series.axes.endswith("YX") or
                series.shape[axis] != 2 or np.prod(series.shape[:-2]) != len(pages)):
            raise ValueError(f"Cannot map two channels from {series.axes} {series.shape}.")
        grid = np.arange(len(pages)).reshape(series.shape[:-2])
        indices = [np.take(grid, c, axis=axis).reshape(-1) for c in range(2)]
        print(f"  Channel dimension from metadata: {series.axes}, {len(indices[0])} frames/channel")
        return indices, None

    # Plain TIFFs often have no channel-axis metadata. Each file must start
    # with channel_order[0], with complete pairs: G,R,G,R,... (or R,G,...).
    if len(pages) % 2:
        raise ValueError("Interleaved TIFF has an odd page count; cannot form complete channel pairs.")
    print(f"  Using alternating pages: {len(pages) // 2} frames/channel")
    return [np.arange(c, len(pages), 2) for c in range(2)], None


def fn_saveh5_2ch(tiff_file, output_root, roi_order, roi_sizes,
                 channel_order=("green", "red"), save_channels=None,
                 layout="auto", chunk_frames=128, overwrite=False):
    """Convert one TIFF. Return paths of the H5 files created.

    ROIs run top-to-bottom, separated by an equal-height blank stripe, as in
    fn_parseROI. TIFF metadata determines a named C axis; without one, auto
    assumes alternating pages. Use layout='interleaved' to force page pairing.
    Both channels are saved unless save_channels=('green',) is specified.
    """
    tiff_file = Path(tiff_file)
    output_root = Path(output_root)
    roi_order = tuple(roi_order)
    roi_sizes = tuple(roi_sizes)
    channel_order = tuple(channel_order)
    save_channels = channel_order if save_channels is None else tuple(save_channels)
    if (not roi_order or len(roi_order) != len(roi_sizes) or
            len(set(roi_order)) != len(roi_order)):
        raise ValueError("Provide one unique ROI name per ROI height.")
    if any(not isinstance(s, (int, np.integer)) or s <= 0 for s in roi_sizes):
        raise ValueError("ROI heights must be positive integers.")
    if len(channel_order) != 2 or set(channel_order) != {"green", "red"}:
        raise ValueError("channel_order must be ('green','red') or ('red','green').")
    if (not save_channels or len(set(save_channels)) != len(save_channels) or
            not set(save_channels) <= set(channel_order)):
        raise ValueError("save_channels must select green, red, or both.")
    if not isinstance(chunk_frames, (int, np.integer)) or chunk_frames < 1:
        raise ValueError("chunk_frames must be a positive integer.")
    if any(not name or name in (".", "..") or "/" in name or "\\" in name for name in roi_order):
        raise ValueError("ROI names must be simple folder-name components.")

    print(f"Converting {tiff_file} (saved channel order: {channel_order})")
    with tifffile.TiffFile(tiff_file) as tif:
        indices, sample_axis = _channel_pages(tif, layout)
        page_shape = tif.pages[0].shape
        spatial_shape = tuple(s for i, s in enumerate(page_shape) if i != sample_axis)
        height, width = spatial_shape
        extra = height - sum(roi_sizes)
        if extra < 0 or (len(roi_sizes) > 1 and extra % (len(roi_sizes) - 1)):
            raise ValueError("ROI heights must fit the image with equal whole-pixel gaps.")
        gap = extra // (len(roi_sizes) - 1) if len(roi_sizes) > 1 else 0
        starts = np.cumsum((0,) + tuple(s + gap for s in roi_sizes[:-1]))
        n_frames = len(indices[0])
        name = parsed_filename_stem(tiff_file.name)

        outputs = []
        for channel in save_channels:
            for roi in roi_order:
                folder = output_root / f"{channel}_{roi}"
                outputs.append((channel, roi, folder / f"{name}_parsed.h5",
                                folder / f"{name}_meanImg.mat"))
        if not overwrite:
            for _, _, h5_path, mean_path in outputs:
                if h5_path.exists() or mean_path.exists():
                    raise FileExistsError(f"Output already exists: {h5_path} or {mean_path}")

        for channel, roi, h5_path, mean_path in outputs:
            channel_index = channel_order.index(channel)
            roi_index = roi_order.index(roi)
            y0 = int(starts[roi_index])
            y1 = y0 + roi_sizes[roi_index]
            h5_path.parent.mkdir(parents=True, exist_ok=True)
            # Write temporary files so interrupted outputs are not mistaken for complete files.
            h5_temp = h5_path.with_suffix(".h5.partial")
            mean_temp = mean_path.with_suffix(".mat.partial")
            sums = np.zeros((y1 - y0, width), dtype=np.float64)
            counts = np.zeros((y1 - y0, width), dtype=np.int64)
            try:
                with h5py.File(h5_temp, "w") as h5:
                    data = h5.create_dataset("data", (n_frames, width, y1 - y0),
                                             dtype=tif.pages[0].dtype,
                                             chunks=(min(chunk_frames, n_frames), width, y1 - y0))
                    data.attrs["channel"] = channel
                    data.attrs["saved_channel_index_0based"] = channel_index
                    data.attrs["channel_order"] = ",".join(channel_order)
                    data.attrs["source_tiff"] = str(tiff_file.resolve())
                    data.attrs["source_tiff_shape"] = tif.series[0].shape
                    data.attrs["source_axis_order"] = tif.series[0].axes
                    h5.create_dataset("source_page_indices_0based", data=indices[channel_index])
                    data.attrs["h5py_disk_axis_order"] = "frame,X,Y"
                    data.attrs["matlab_h5read_axis_order"] = "Y,X,frame"
                    data.attrs["roi_y_start_1based_inclusive"] = y0 + 1
                    data.attrs["roi_y_end_1based_inclusive"] = y1
                    for start in range(0, n_frames, chunk_frames):
                        frame_list = []
                        for page_index in indices[channel_index][start:start + chunk_frames]:
                            frame = tif.pages[int(page_index)].asarray()
                            if sample_axis is not None:
                                frame = np.take(frame, channel_index, axis=sample_axis)
                            frame_list.append(frame[y0:y1, :])
                        chunk = np.stack(frame_list)
                        # Same orientation as fn_saveh5.py, preserving original pixel dtype.
                        data[start:start + len(chunk)] = chunk.transpose(0, 2, 1)
                        sums += np.where(np.isfinite(chunk), chunk, 0).sum(axis=0, dtype=np.float64)
                        counts += np.isfinite(chunk).sum(axis=0)
                mean = np.divide(sums, counts, out=np.full_like(sums, np.nan), where=counts > 0)
                savemat(str(mean_temp), {"meanImg": mean, "channel": channel,
                        "nFrames": n_frames, "roiYStart": y0 + 1, "roiYEnd": y1}, appendmat=False)
                h5_temp.replace(h5_path)
                mean_temp.replace(mean_path)
            finally:
                h5_temp.unlink(missing_ok=True)
                mean_temp.unlink(missing_ok=True)
            print(f"  Saved {channel}/{roi}: {n_frames} frames -> {h5_path}")
    return [entry[2] for entry in outputs]

