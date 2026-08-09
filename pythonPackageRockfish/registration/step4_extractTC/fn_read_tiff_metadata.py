def read_tiff_metadata(tiff_path):
    """Open a TIFF file, print its frame count and metadata, and return them."""
    from pathlib import Path

    from PIL import Image

    path = Path(tiff_path).expanduser().resolve()
    if not path.is_file():
        raise FileNotFoundError(f"TIFF file not found: {path}")
    if path.suffix.lower() not in {".tif", ".tiff"}:
        raise ValueError(f"Expected a .tif or .tiff file, received: {path.name}")

    with Image.open(path) as image:
        frame_count = int(getattr(image,"n_frames",1))
        width,height = image.size
        samples_per_pixel = image.tag_v2.get(277)
        bits_per_sample = image.tag_v2.get(258)
        compression = image.info.get("compression",image.tag_v2.get(259))
        with path.open("rb") as file:
            header = file.read(4)
        byte_order = "little" if header[:2] == b"II" else "big"
        tiff_version = int.from_bytes(header[2:4],byteorder=byte_order)
        metadata = {
            "path": str(path),
            "frame_count": frame_count,
            "shape": (frame_count,height,width),
            "image_mode": image.mode,
            "format": image.format,
            "width": width,
            "height": height,
            "samples_per_pixel": samples_per_pixel,
            "bits_per_sample": bits_per_sample,
            "compression": str(compression),
            "byte_order": byte_order,
            "is_bigtiff": tiff_version == 43,
            "file_size_bytes": path.stat().st_size,
        }

    print(f"TIFF file: {metadata['path']}")
    print(f"Frames/pages: {metadata['frame_count']:,}")
    print(f"Stack shape: {metadata['shape']}")
    print(f"Image mode: {metadata['image_mode']}")
    print(f"Format: {metadata['format']}")
    print(f"Resolution: {metadata['width']} x {metadata['height']} pixels")
    print(f"Samples per pixel: {metadata['samples_per_pixel']}")
    print(f"Bits per sample: {metadata['bits_per_sample']}")
    print(f"Compression: {metadata['compression']}")
    print(f"Byte order: {metadata['byte_order']}")
    print(f"BigTIFF: {metadata['is_bigtiff']}")
    print(f"File size: {metadata['file_size_bytes']:,} bytes")

    return metadata


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Read a TIFF file and print its frame count and metadata."
    )
    parser.add_argument("tiff_path", help="Path to the .tif or .tiff file")
    arguments = parser.parse_args()
    read_tiff_metadata(arguments.tiff_path)
