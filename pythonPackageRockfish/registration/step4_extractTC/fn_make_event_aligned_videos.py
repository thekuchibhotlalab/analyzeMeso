import argparse
import json
import os
import re
from pathlib import Path
from typing import Dict, Iterable, Optional, Tuple

import numpy as np


def make_event_aligned_videos(
    session_dir: str = ".",
    all_data_path: Optional[str] = None,
    output_ext: str = ".mp4",
    frame_rate: float = 15.0,
    pre_sec: float = 2.0,
    post_sec: float = 4.0,
    brightness_percentile: Tuple[float, float] = (0.2, 99.8),
) -> Dict[str, dict]:
    """
    Create trial-averaged event-aligned videos from a registered Suite2p recording.

    Args:
        session_dir: Session folder, e.g.
            B:/zz172_PPC1/imagingSession/zz172_20250808_2AFC3_parsed.
        all_data_path: Optional explicit path to the matching *_allData.mat file.
            If omitted, the function searches inside session_dir.
        output_ext: ".mp4" or ".avi".
        frame_rate: Output video frame rate. Use 15 to preserve original speed.
        pre_sec: Seconds before the aligned event.
        post_sec: Seconds after the aligned event.
        brightness_percentile: Low/high percentiles kept for compatibility.
            The baseline-subtracted display uses 0 as the low limit and the high
            percentile as the bright limit.

    Returns:
        A dictionary with counts, skipped trials, brightness limits, and output paths.

    allData column convention from the behavioral file:
        column 2: stimulus identity
        column 3: action/choice identity
        column 7: stimulus frame
        column 8: choice frame
        column 9: reward frame, NaN for no reward
    """
    session_path = Path(session_dir).expanduser().resolve()
    if output_ext and not output_ext.startswith("."):
        output_ext = "." + output_ext
    output_ext = output_ext.lower()
    if output_ext not in {".mp4", ".avi"}:
        raise ValueError("output_ext must be '.mp4' or '.avi'.")

    region_movies = load_region_movies(session_path)

    if all_data_path is None:
        all_data_path = find_all_data_file(session_path)
    else:
        all_data_path = Path(all_data_path).expanduser().resolve()
    all_data = load_all_data(all_data_path)

    stim = all_data[:, 1]
    action = all_data[:, 2]
    stim_frame = all_data[:, 6]
    choice_frame = all_data[:, 7]
    reward_frame = all_data[:, 8]

    event_groups = {
        "stim1": event_frames_for(stim == 1, stim_frame),
        "stim2": event_frames_for(stim == 2, stim_frame),
        "action1": event_frames_for(action == 1, choice_frame),
        "action2": event_frames_for(action == 2, choice_frame),
        "rewarded": event_frames_for(np.isfinite(reward_frame), reward_frame),
        "miss": event_frames_for(action == 0, stim_frame),
    }

    pre_frames = int(round(pre_sec * frame_rate))
    post_frames = int(round(post_sec * frame_rate))
    offsets = np.arange(-pre_frames, post_frames, dtype=np.int64)
    summary = {
        "session_dir": str(session_path),
        "regions": {
            region: {
                "bin_path": str(info["bin_path"]),
                "ops_path": str(info["ops_path"]),
                "x_pixels": int(info["x_pixels"]),
                "y_pixels": int(info["y_pixels"]),
                "n_frames": int(info["n_frames"]),
            }
            for region, info in region_movies.items()
        },
        "all_data_path": str(all_data_path),
        "frame_rate": frame_rate,
        "pre_sec": pre_sec,
        "post_sec": post_sec,
        "offsets": [int(offsets[0]), int(offsets[-1])],
        "outputs": {},
    }

    print(f"Session: {session_path}")
    for region, info in region_movies.items():
        print(
            f"{region}: {info['n_frames']} frames, "
            f"{info['y_pixels']} x {info['x_pixels']} pixels, {info['bin_path'].name}"
        )
    print(f"Behavior: {all_data_path} ({all_data.shape[0]} trials)")

    for label, event_frames_1based in event_groups.items():
        valid_events_1based, skipped = valid_event_frames_for_all_movies(
            event_frames_1based,
            offsets,
            region_movies,
        )
        if valid_events_1based.size == 0:
            print(f"{label}: no valid trials, skipping video.")
            summary["outputs"][label] = {
                "path": None,
                "n_event": int(len(event_frames_1based)),
                "n_used": 0,
                "n_skipped_edge": int(skipped),
            }
            continue

        region_displays = {}
        baseline_range = None
        for region, info in region_movies.items():
            avg_movie = average_event_movie(info["movie"], valid_events_1based, offsets)
            baseline_movie, baseline_range = make_baseline_subtracted_display_movie(avg_movie, pre_frames)
            raw_vmin, raw_vmax = percentile_limits(avg_movie, brightness_percentile)
            baseline_vmin, baseline_vmax = display_limits(baseline_movie, brightness_percentile[1])
            region_displays[region] = {
                "raw_movie": avg_movie,
                "baseline_movie": baseline_movie,
                "raw_vmin": raw_vmin,
                "raw_vmax": raw_vmax,
                "baseline_vmin": baseline_vmin,
                "baseline_vmax": baseline_vmax,
            }

        event_text = event_text_for_label(label)
        region_only_paths = {}
        if len(region_displays) > 1:
            output_path = session_path / f"event_aligned_{label}{output_ext}"
            write_region_comparison_video(
                output_path,
                region_displays,
                frame_rate,
                event_frame_index=pre_frames,
                event_text=event_text,
            )
            for region in region_displays:
                region_output_path = session_path / f"event_aligned_{label}_{region}{output_ext}"
                write_region_comparison_video(
                    region_output_path,
                    {region: region_displays[region]},
                    frame_rate,
                    event_frame_index=pre_frames,
                    event_text=event_text,
                )
                region_only_paths[region] = str(region_output_path)
        else:
            region = next(iter(region_displays))
            if region in {"AC", "PPC"}:
                output_path = session_path / f"event_aligned_{label}_{region}{output_ext}"
            else:
                output_path = session_path / f"event_aligned_{label}{output_ext}"
            write_region_comparison_video(
                output_path,
                region_displays,
                frame_rate,
                event_frame_index=pre_frames,
                event_text=event_text,
            )

        print(
            f"{label}: saved {output_path.name} "
            f"using {len(valid_events_1based)}/{len(event_frames_1based)} trials "
            f"(skipped {skipped}; baseline frames {baseline_range[0]}:{baseline_range[1]})."
        )
        if region_only_paths:
            print(
                f"{label}: also saved region-only videos: "
                + ", ".join(Path(path).name for path in region_only_paths.values())
            )

        summary["outputs"][label] = {
            "path": str(output_path),
            "region_only_paths": region_only_paths,
            "n_event": int(len(event_frames_1based)),
            "n_used": int(len(valid_events_1based)),
            "n_skipped_edge": int(skipped),
            "event_frames_1based_used": [int(x) for x in valid_events_1based],
            "regions": {
                region: {
                    "raw_display_vmin": float(info["raw_vmin"]),
                    "raw_display_vmax": float(info["raw_vmax"]),
                    "baseline_display_vmin": float(info["baseline_vmin"]),
                    "baseline_display_vmax": float(info["baseline_vmax"]),
                }
                for region, info in region_displays.items()
            },
            "display_baseline_subtracted": True,
            "display_baseline_frames_0based": [int(baseline_range[0]), int(baseline_range[1])],
            "event_text": event_text,
        }

    summary_path = session_path / "event_aligned_video_summary.json"
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
    print(f"Saved summary: {summary_path}")
    return summary


def find_all_data_file(session_path: Path) -> Path:
    candidates = sorted(session_path.glob("*_allData.mat"))
    if not candidates:
        raise FileNotFoundError(f"No *_allData.mat file found in {session_path}")
    if len(candidates) == 1:
        return candidates[0]

    session_name = session_path.name
    date_match = re.search(r"\d{8}", session_name)
    session_match = re.search(r"2AFC(\d+)", session_name, re.IGNORECASE)
    date_text = date_match.group(0) if date_match else ""
    session_text = f"session{session_match.group(1)}" if session_match else ""

    scored = []
    for path in candidates:
        name_lower = path.name.lower()
        score = int(bool(date_text and date_text in path.name))
        score += int(bool(session_text and session_text.lower() in name_lower))
        scored.append((score, path))

    scored.sort(key=lambda x: x[0], reverse=True)
    if len(scored) >= 2 and scored[0][0] == scored[1][0]:
        candidate_text = "\n".join(str(path) for _, path in scored)
        raise ValueError(
            "Multiple *_allData.mat files matched equally. Pass all_data_path explicitly:\n"
            f"{candidate_text}"
        )
    return scored[0][1]


def load_region_movies(session_path: Path) -> Dict[str, dict]:
    region_files = find_region_movie_and_ops_files(session_path)
    region_movies = {}
    for region, paths in region_files.items():
        ops = load_ops(paths["ops_path"])
        x_pixels = int(ops["Lx"])
        y_pixels = int(ops["Ly"])
        bytes_per_frame = x_pixels * y_pixels * np.dtype("int16").itemsize
        n_frames = os.path.getsize(paths["bin_path"]) // bytes_per_frame
        movie = np.memmap(
            paths["bin_path"],
            mode="r",
            dtype="int16",
            shape=(n_frames, y_pixels, x_pixels),
        )
        region_movies[region] = {
            "bin_path": paths["bin_path"],
            "ops_path": paths["ops_path"],
            "x_pixels": x_pixels,
            "y_pixels": y_pixels,
            "n_frames": n_frames,
            "movie": movie,
        }
    return region_movies


def load_ops(ops_path: Path) -> dict:
    try:
        return np.load(ops_path, allow_pickle=True).item()
    except Exception as exc:
        raise RuntimeError(
            f"Could not load {ops_path}. This script expects Suite2p ops saved as "
            "a NumPy .npy dictionary. If your file is named .py but is actually an "
            ".npy file, np.load should still work; otherwise please save/copy it as ops_REGION.npy."
        ) from exc


def find_region_movie_and_ops_files(session_path: Path) -> Dict[str, dict]:
    """
    Find registered Suite2p binaries and ops files.

    If both data_suite2p_PPC.bin and data_suite2p_AC.bin are present, the output
    contains both regions in left-to-right order: AC, PPC.

    Single-region preferred layout:
        session_dir/data_suite2p.bin
        session_dir/ops.npy

    Fallback layout:
        session_dir/suite2p/plane0/data_suite2p.bin
        session_dir/suite2p/plane0/ops.npy
    """
    candidate_dirs = [
        session_path,
        session_path / "suite2p" / "plane0",
    ]

    checked_dirs = []
    for movie_dir in candidate_dirs:
        checked_dirs.append(str(movie_dir))
        if not movie_dir.exists():
            continue

        paired = find_paired_region_files(movie_dir)
        if paired:
            return paired

        ops_path = first_existing_ops(movie_dir, "")
        if ops_path is None:
            continue
        preferred_bin = movie_dir / "data_suite2p.bin"
        if preferred_bin.exists():
            return {"movie": {"bin_path": preferred_bin, "ops_path": ops_path}}

        bin_files = sorted(movie_dir.glob("*.bin"))
        if len(bin_files) == 1:
            return {"movie": {"bin_path": bin_files[0], "ops_path": ops_path}}
        if len(bin_files) > 1:
            bin_text = "\n".join(str(path) for path in bin_files)
            raise ValueError(
                "Found multiple .bin files but could not identify a PPC/AC pair. "
                "Use data_suite2p_PPC.bin and data_suite2p_AC.bin with matching "
                "ops_PPC.npy and ops_AC.npy, or keep only one target .bin in this folder:\n"
                f"{bin_text}"
            )

    raise FileNotFoundError(
        "Could not find a folder containing both ops.npy and a .bin movie. Checked:\n"
        + "\n".join(checked_dirs)
    )


def find_paired_region_files(movie_dir: Path) -> Dict[str, dict]:
    paired = {}
    for region in ("PPC", "AC"):
        bin_path = movie_dir / f"data_suite2p_{region}.bin"
        ops_path = first_existing_ops(movie_dir, region)
        if bin_path.exists() and ops_path is not None:
            paired[region] = {"bin_path": bin_path, "ops_path": ops_path}

    if len(paired) >= 1:
        return paired
    return {}


def first_existing_ops(movie_dir: Path, region: str) -> Optional[Path]:
    candidates = []
    if region:
        candidates.extend([
            movie_dir / f"ops_{region}.npy",
            movie_dir / f"ops_{region}.py",
        ])
    candidates.append(movie_dir / "ops.npy")
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def load_all_data(mat_path: Path) -> np.ndarray:
    try:
        import scipy.io
    except ImportError as exc:
        scipy_import_error = exc
        scipy_io = None
    else:
        scipy_import_error = None
        scipy_io = scipy.io

    if scipy_io is None:
        try:
            return load_all_data_h5(mat_path)
        except Exception as h5_error:
            raise ImportError(
                "Could not read the MATLAB file. Install scipy for normal .mat files, "
                "or h5py for MATLAB v7.3 files."
            ) from scipy_import_error or h5_error

    try:
        mat = scipy_io.loadmat(mat_path)
        if "allData" not in mat:
            raise KeyError(f"'allData' not found in {mat_path}")
        all_data = np.asarray(mat["allData"], dtype=float)
    except NotImplementedError:
        all_data = load_all_data_h5(mat_path)

    if all_data.ndim != 2 or all_data.shape[1] < 9:
        raise ValueError(
            f"Expected allData as trials x >=9 columns, got shape {all_data.shape}."
        )
    return all_data


def load_all_data_h5(mat_path: Path) -> np.ndarray:
    try:
        import h5py
    except ImportError as exc:
        raise ImportError(
            "This appears to be a MATLAB v7.3 file. Install h5py in this Python "
            "environment, or save the behavior mat file in non-v7.3 format."
        ) from exc

    with h5py.File(mat_path, "r") as f:
        if "allData" not in f:
            raise KeyError(f"'allData' not found in {mat_path}")
        all_data = np.asarray(f["allData"]).T.astype(float)

    if all_data.ndim != 2 or all_data.shape[1] < 9:
        raise ValueError(
            f"Expected allData as trials x >=9 columns, got shape {all_data.shape}."
        )
    return all_data


def event_frames_for(mask: np.ndarray, frame_column: np.ndarray) -> np.ndarray:
    frame_values = np.asarray(frame_column[mask], dtype=float)
    frame_values = frame_values[np.isfinite(frame_values)]
    return np.rint(frame_values).astype(np.int64)


def valid_event_frames_for_all_movies(
    event_frames_1based: Iterable[int],
    offsets: np.ndarray,
    region_movies: Dict[str, dict],
) -> Tuple[np.ndarray, int]:
    event_frames_0based = np.asarray(event_frames_1based, dtype=np.int64) - 1
    keep = np.ones(event_frames_0based.shape, dtype=bool)
    for info in region_movies.values():
        n_frames = int(info["n_frames"])
        keep &= (
            (event_frames_0based + offsets[0] >= 0)
            & (event_frames_0based + offsets[-1] < n_frames)
        )
    valid_events_0based = event_frames_0based[keep]
    valid_events_1based = valid_events_0based + 1
    skipped = int(np.sum(~keep))
    return valid_events_1based, skipped


def average_event_movie(
    movie: np.memmap,
    valid_events_1based: Iterable[int],
    offsets: np.ndarray,
) -> np.ndarray:
    valid_events_0based = np.asarray(valid_events_1based, dtype=np.int64) - 1
    avg_movie = np.empty((len(offsets), movie.shape[1], movie.shape[2]), dtype=np.float32)
    for i_offset, offset in enumerate(offsets):
        frame_idx = valid_events_0based + offset
        avg_movie[i_offset] = np.mean(movie[frame_idx].astype(np.float32), axis=0)
    return avg_movie


def percentile_limits(movie: np.ndarray, percentiles: Tuple[float, float]) -> Tuple[float, float]:
    vmin, vmax = np.percentile(movie[np.isfinite(movie)], percentiles)
    if not np.isfinite(vmin) or not np.isfinite(vmax) or vmax <= vmin:
        vmin = float(np.nanmin(movie))
        vmax = float(np.nanmax(movie))
    if vmax <= vmin:
        vmax = vmin + 1.0
    return float(vmin), float(vmax)


def make_baseline_subtracted_display_movie(
    avg_movie: np.ndarray,
    pre_frames: int,
) -> Tuple[np.ndarray, Tuple[int, int]]:
    """
    Convert the averaged raw movie into a darker display movie.

    The baseline image is the mean of the pre-event period. It is subtracted from
    every frame, then negative values are clipped to zero so pre-event frames are
    mostly dark and post-event changes use more of the display dynamic range.
    """
    baseline_stop = max(1, min(pre_frames, avg_movie.shape[0]))
    baseline_image = np.nanmean(avg_movie[:baseline_stop], axis=0)
    display_movie = avg_movie.astype(np.float32) - baseline_image.astype(np.float32)
    display_movie[~np.isfinite(display_movie)] = 0
    display_movie[display_movie < 0] = 0
    return display_movie, (0, baseline_stop - 1)


def display_limits(movie: np.ndarray, high_percentile: float) -> Tuple[float, float]:
    finite = movie[np.isfinite(movie)]
    finite_positive = finite[finite > 0]
    if finite_positive.size == 0:
        return 0.0, 1.0
    vmax = float(np.percentile(finite_positive, high_percentile))
    if not np.isfinite(vmax) or vmax <= 0:
        vmax = float(np.nanmax(finite_positive))
    if not np.isfinite(vmax) or vmax <= 0:
        vmax = 1.0
    return 0.0, vmax


def event_text_for_label(label: str) -> str:
    if label.startswith("stim") or label == "miss":
        return "stim"
    if label.startswith("action"):
        return "action"
    if label == "rewarded":
        return "reward"
    return "event"


def movie_to_uint8(movie: np.ndarray, vmin: float, vmax: float) -> np.ndarray:
    movie8 = (movie.astype(np.float32) - vmin) / (vmax - vmin)
    movie8 = np.clip(movie8, 0, 1)
    return np.rint(movie8 * 255).astype(np.uint8)


def write_region_comparison_video(
    output_path: Path,
    region_displays: Dict[str, dict],
    frame_rate: float,
    event_frame_index: Optional[int] = None,
    event_text: str = "event",
) -> None:
    region_order = [region for region in ("AC", "PPC") if region in region_displays]
    region_order.extend(region for region in region_displays.keys() if region not in region_order)

    raw_panels = []
    baseline_panels = []
    for region in region_order:
        info = region_displays[region]
        raw8 = movie_to_uint8(info["raw_movie"], info["raw_vmin"], info["raw_vmax"])
        baseline8 = movie_to_uint8(
            info["baseline_movie"],
            info["baseline_vmin"],
            info["baseline_vmax"],
        )
        raw_rgb = np.repeat(raw8[:, :, :, None], 3, axis=3)
        baseline_rgb = np.repeat(baseline8[:, :, :, None], 3, axis=3)

        raw_rgb = add_panel_label(raw_rgb, f"{region} raw", panel_top=0)
        baseline_rgb = add_panel_label(
            baseline_rgb,
            f"{region} baseline subtracted",
            panel_top=0,
        )
        if event_frame_index is not None:
            raw_rgb = add_event_overlay(raw_rgb, event_frame_index, event_text, frame_rate)
            baseline_rgb = add_event_overlay(baseline_rgb, event_frame_index, event_text, frame_rate)
        raw_panels.append(raw_rgb)
        baseline_panels.append(baseline_rgb)

    raw_panels = pad_panels_to_same_height(raw_panels)
    baseline_panels = pad_panels_to_same_height(baseline_panels)
    raw_row = np.concatenate(raw_panels, axis=2)
    baseline_row = np.concatenate(baseline_panels, axis=2)
    movie8 = np.concatenate([raw_row, baseline_row], axis=1)

    try:
        import imageio.v2 as imageio

        imageio.mimwrite(output_path, movie8, fps=frame_rate, macro_block_size=1)
        return
    except Exception as imageio_error:
        try:
            import cv2
        except ImportError as exc:
            raise RuntimeError(
                "Could not write video. Install imageio with ffmpeg support or opencv-python."
            ) from imageio_error if imageio_error else exc

        if output_path.suffix.lower() == ".mp4":
            fourcc = cv2.VideoWriter_fourcc(*"mp4v")
        else:
            fourcc = cv2.VideoWriter_fourcc(*"MJPG")

        writer = cv2.VideoWriter(
            str(output_path),
            fourcc,
            frame_rate,
            (movie8.shape[2], movie8.shape[1]),
            isColor=True,
        )
        if not writer.isOpened():
            raise RuntimeError(f"OpenCV could not open video writer for {output_path}")
        for frame in movie8:
            frame = frame[:, :, ::-1]
            writer.write(frame)
        writer.release()


def pad_panels_to_same_height(panels: Iterable[np.ndarray]) -> list:
    panels = list(panels)
    target_height = max(panel.shape[1] for panel in panels)
    padded = []
    for panel in panels:
        pad_height = target_height - panel.shape[1]
        if pad_height <= 0:
            padded.append(panel)
            continue
        pad = np.zeros((panel.shape[0], pad_height, panel.shape[2], panel.shape[3]), dtype=panel.dtype)
        padded.append(np.concatenate([panel, pad], axis=1))
    return padded


def add_event_overlay(
    movie_rgb: np.ndarray,
    event_frame_index: int,
    event_text: str,
    frame_rate: float,
    panel_tops: Tuple[int, ...] = (0,),
) -> np.ndarray:
    n_frames, y_pixels, x_pixels, _ = movie_rgb.shape
    cue_duration_frames = max(5, int(round(0.3 * frame_rate)))
    cue_start = max(0, int(event_frame_index))
    cue_stop = min(n_frames, cue_start + cue_duration_frames)

    margin = max(6, min(x_pixels, y_pixels) // 40)
    bar_width = max(20, x_pixels // 8)
    bar_height = max(3, y_pixels // 120)
    x1 = max(0, x_pixels - margin - bar_width)
    x2 = x_pixels - margin

    for panel_top in panel_tops:
        y1 = panel_top + margin
        y2 = min(y_pixels, y1 + bar_height)
        movie_rgb[cue_start:cue_stop, y1:y2, x1:x2, :] = 255

        movie_rgb[cue_start:cue_stop] = draw_text(
            movie_rgb[cue_start:cue_stop],
            event_text,
            x=max(0, x2 - max(60, len(event_text) * 12)),
            y=min(y_pixels - 1, y2 + margin // 2 + 2),
            anchor="left",
        )
    return movie_rgb


def add_panel_label(movie_rgb: np.ndarray, text: str, panel_top: int) -> np.ndarray:
    margin = max(6, min(movie_rgb.shape[2], movie_rgb.shape[1]) // 50)
    return draw_text(movie_rgb, text, x=margin, y=panel_top + margin, anchor="left")


def draw_text(frames_rgb: np.ndarray, text: str, x: int, y: int, anchor: str = "left") -> np.ndarray:
    try:
        import cv2

        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.45
        thickness = 1
        for i_frame in range(frames_rgb.shape[0]):
            frame = frames_rgb[i_frame]
            text_size, _ = cv2.getTextSize(text, font, font_scale, thickness)
            if anchor == "right":
                x_text = max(0, x - text_size[0])
            else:
                x_text = max(0, x)
            y_text = min(frame.shape[0] - 1, y + text_size[1])
            cv2.putText(frame, text, (x_text, y_text), font, font_scale, (255, 255, 255), thickness, cv2.LINE_AA)
        return frames_rgb
    except Exception:
        pass

    try:
        from PIL import Image, ImageDraw

        for i_frame in range(frames_rgb.shape[0]):
            image = Image.fromarray(frames_rgb[i_frame])
            draw = ImageDraw.Draw(image)
            bbox = draw.textbbox((0, 0), text)
            text_width = bbox[2] - bbox[0]
            if anchor == "right":
                x_text = max(0, x - text_width)
            else:
                x_text = max(0, x)
            draw.text((x_text, y), text, fill=(255, 255, 255))
            frames_rgb[i_frame] = np.asarray(image)
        return frames_rgb
    except Exception:
        pass

    return draw_block_text(frames_rgb, text, x, y, anchor=anchor)


def draw_block_text(frames_rgb: np.ndarray, text: str, x: int, y: int, anchor: str = "left") -> np.ndarray:
    font = tiny_font()
    text = text.lower()
    char_width = 5
    char_height = 7
    spacing = 1
    scale = 2
    width = sum((char_width + spacing) for char in text if char in font) * scale
    if anchor == "right":
        x = max(0, x - width)
    else:
        x = max(0, x)

    for char in text:
        if char not in font:
            x += (char_width + spacing) * scale
            continue
        pattern = font[char]
        for row, line in enumerate(pattern):
            for col, pixel in enumerate(line):
                if pixel == "1":
                    yy1 = y + row * scale
                    yy2 = min(frames_rgb.shape[1], yy1 + scale)
                    xx1 = x + col * scale
                    xx2 = min(frames_rgb.shape[2], xx1 + scale)
                    frames_rgb[:, yy1:yy2, xx1:xx2, :] = 255
        x += (char_width + spacing) * scale
    return frames_rgb


def tiny_font() -> Dict[str, Tuple[str, ...]]:
    return {
        "a": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
        "c": ("01111", "10000", "10000", "10000", "10000", "10000", "01111"),
        "d": ("11110", "10001", "10001", "10001", "10001", "10001", "11110"),
        "e": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
        "i": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
        "m": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
        "n": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
        "o": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
        "r": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
        "s": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
        "t": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
        "w": ("10001", "10001", "10001", "10101", "10101", "10101", "01010"),
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create averaged event-aligned videos from a Suite2p registered binary."
    )
    parser.add_argument(
        "session_dir",
        nargs="?",
        default=os.getcwd(),
        help=(
            "Session folder containing data_suite2p.bin and ops.npy. "
            "Defaults to the current directory."
        ),
    )
    parser.add_argument("--all-data", default=None, help="Optional explicit path to *_allData.mat.")
    parser.add_argument("--ext", default=".mp4", choices=[".mp4", "mp4", ".avi", "avi"])
    parser.add_argument("--fps", type=float, default=15.0)
    parser.add_argument("--pre-sec", type=float, default=2.0)
    parser.add_argument("--post-sec", type=float, default=4.0)
    parser.add_argument(
        "--low-prctile",
        type=float,
        default=0.2,
        help="Kept for compatibility; baseline-subtracted videos use 0 as the low display limit.",
    )
    parser.add_argument(
        "--high-prctile",
        type=float,
        default=99.8,
        help="High percentile for scaling positive baseline-subtracted activity.",
    )
    args = parser.parse_args()
    print(f"Using session_dir: {Path(args.session_dir).expanduser().resolve()}")

    make_event_aligned_videos(
        args.session_dir,
        all_data_path=args.all_data,
        output_ext=args.ext,
        frame_rate=args.fps,
        pre_sec=args.pre_sec,
        post_sec=args.post_sec,
        brightness_percentile=(args.low_prctile, args.high_prctile),
    )


if __name__ == "__main__":
    main()
