"""Split each TIFF into ROI-specific green/red H5 files, like fn_parseROI.py."""

import shutil
from pathlib import Path

from fn_saveh5_2ch import fn_saveh5_2ch


def fn_parseROI_2ch(mouse_path, roi_order, roi_sizes,
                    channel_order=("green", "red"), save_channels=None,
                    layout="auto", chunk_frames=128, overwrite=False):
    """Convert TIFFs in immediate session subfolders, as in fn_parseROI.py.

    Output: <mouse_path>/<channel>_<ROI>/<renamed_filename>_parsed.h5.
    The trailing number is joined without zero padding: 2AFC_00001 -> 2AFC1.
    """
    root = Path(mouse_path).resolve()
    if not root.is_dir():
        raise NotADirectoryError(root)
    inputs = sorted(file for folder in root.iterdir()
                    if folder.is_dir() and not folder.name.startswith(("green_", "red_"))
                    for file in folder.iterdir()
                    if file.is_file() and file.suffix.lower() in (".tif", ".tiff"))
    if not inputs:
        raise FileNotFoundError(f"No TIFFs in immediate session folders under {root}.")
    outputs = []
    for file in inputs:
        print(file.name)
        try:
            outputs.extend(fn_saveh5_2ch(file, root, roi_order, roi_sizes,
                           channel_order, save_channels, layout, chunk_frames, overwrite))
        except Exception as exc:
            print(f"{file.name} not done! ({exc})")
    channels = channel_order if save_channels is None else save_channels
    move_stack_folders(root, roi_order, channels)
    return outputs


def move_stack_folders(mouse_path, roi_order, channels):
    """Same existing-stack-folder organization as fn_parseROI, for both channels."""
    for channel in channels:
        for roi in roi_order:
            roi_path = Path(mouse_path) / f"{channel}_{roi}"
            if not roi_path.is_dir():
                continue
            stack_path = roi_path / "stack"
            stack_path.mkdir(exist_ok=True)
            for source in roi_path.iterdir():
                if source.name == "stack" or not source.is_dir() or "stack" not in source.name.lower():
                    continue
                destination = stack_path / source.name
                if destination.exists():
                    print(f"Stack folder already exists, skipping: {destination}")
                    continue
                # Both source and destination stay under this ROI output directory.
                if not source.resolve().is_relative_to(roi_path.resolve()):
                    raise ValueError(f"Stack folder points outside ROI output: {source}")
                if not destination.resolve().is_relative_to(roi_path.resolve()):
                    raise ValueError(f"Stack destination points outside ROI output: {destination}")
                print(f"Moving stack folder: {source} -> {destination}")
                shutil.move(str(source), str(destination))


if __name__ == "__main__":
    # Edit these settings for your acquisition, then run this file.
    mouse_path_input = Path.cwd()
    roi_order_input = ["PPC", "AC"]       # Top-to-bottom in the TIFF image.
    roi_sizes_input = [788, 562]          # Height of each ROI, excluding the gap.
    channel_order_input = ("green", "red")  # Change if red is saved first.
    save_channels_input = ("green", "red")  # Or ("green",) to omit the empty red output.
    layout_input = "interleaved"         # Pages 1,3,5,... green; pages 2,4,6,... red.

    print(f"Input/output folder: {mouse_path_input}")
    print(f"ROI order: {roi_order_input}")
    print(f"ROI sizes: {roi_sizes_input}")
    print(f"Channel order: {channel_order_input}")
    fn_parseROI_2ch(mouse_path_input, roi_order_input, roi_sizes_input,
                   channel_order=channel_order_input,
                   save_channels=save_channels_input, layout=layout_input)
