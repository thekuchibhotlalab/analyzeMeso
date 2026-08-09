def read_avi_metadata(video_path):
    """Open an AVI file, print its metadata, and return it as a dictionary."""
    from pathlib import Path

    import cv2

    path = Path(video_path).expanduser().resolve()
    if not path.is_file():
        raise FileNotFoundError(f"AVI file not found: {path}")
    if path.suffix.lower() != ".avi":
        raise ValueError(f"Expected an .avi file, received: {path.name}")

    video = cv2.VideoCapture(str(path))
    if not video.isOpened():
        raise RuntimeError(f"OpenCV could not open AVI file: {path}")

    try:
        frame_count = int(video.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = float(video.get(cv2.CAP_PROP_FPS))
        width = int(video.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(video.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fourcc_value = int(video.get(cv2.CAP_PROP_FOURCC))
        codec = "".join(chr((fourcc_value >> (8 * i)) & 0xFF) for i in range(4))
        codec = codec.replace("\x00", "").strip() or "unknown"
        duration_seconds = frame_count / fps if fps > 0 else None
        backend = video.getBackendName()
    finally:
        video.release()

    metadata = {
        "path": str(path),
        "frame_count": frame_count,
        "fps": fps,
        "width": width,
        "height": height,
        "duration_seconds": duration_seconds,
        "codec": codec,
        "backend": backend,
        "file_size_bytes": path.stat().st_size,
    }

    print(f"AVI file: {metadata['path']}")
    print(f"Frames: {metadata['frame_count']:,}")
    print(f"Resolution: {metadata['width']} x {metadata['height']} pixels")
    print(f"Frame rate: {metadata['fps']:.6g} fps")
    if metadata["duration_seconds"] is None:
        print("Duration: unavailable")
    else:
        print(f"Duration: {metadata['duration_seconds']:.3f} seconds")
    print(f"Codec: {metadata['codec']}")
    print(f"OpenCV backend: {metadata['backend']}")
    print(f"File size: {metadata['file_size_bytes']:,} bytes")

    return metadata


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Read an AVI file and print its frame count and metadata."
    )
    parser.add_argument("video_path", help="Path to the .avi file")
    arguments = parser.parse_args()
    read_avi_metadata(arguments.video_path)
