import os
import shutil

import h5py
import numpy as np
from scipy.io import savemat

from fn_saveh5 import TiffStackReader, compute_mean_images
from parse_frame import parse_frame


def fn_parseOneROI(mousePath, yStart, yEnd, roiName="ROI"):
    yStart = int(yStart)
    yEnd = int(yEnd)
    if yStart < 1 or yEnd < yStart:
        raise ValueError("yStart and yEnd should be 1-based inclusive pixel positions, with yEnd >= yStart.")

    roiDir = os.path.join(mousePath, f"green_{roiName}")
    os.makedirs(roiDir, exist_ok=True)

    for sub in os.listdir(mousePath):
        tiffPath = os.path.join(mousePath, sub)
        if not os.path.isdir(tiffPath):
            continue

        for file in os.listdir(tiffPath):
            if not file.lower().endswith(".tif"):
                continue

            print(file)
            try:
                fn_saveh5_one_roi(mousePath, tiffPath, file, yStart, yEnd, roiName)
            except Exception as e:
                print(f"{file} not done! ({e})")

    move_stack_folders(mousePath, roiName)


def fn_saveh5_one_roi(mousePath, tiffPath, filename, yStart, yEnd, roiName):
    tiff_file = os.path.join(tiffPath, filename)
    reader = TiffStackReader(tiff_file)

    try:
        nFrames, Y, X = reader.nFrames, reader.Y, reader.X
        if yEnd > Y:
            raise ValueError(f"Requested yEnd ({yEnd}) is larger than TIFF Y dimension ({Y}).")

        # Inputs are MATLAB-style 1-based inclusive pixel positions.
        yFrames = np.arange(yStart - 1, yEnd)
        gFrames = np.arange(nFrames)
        frameBin = 2000
        frameParseG = parse_frame(gFrames, frameBin)

        base = filename.split(".")[0].split("_")
        name = "_".join(base[:-1])
        num = base[3].lstrip("0")
        tempSplitName = f"{name}{num}"

        saveFilename = os.path.join(
            mousePath, f"green_{roiName}", f"{tempSplitName}_parsed.h5"
        )
        saveImgname = os.path.join(
            mousePath, f"green_{roiName}", f"{tempSplitName}_meanImg.mat"
        )

        os.makedirs(os.path.dirname(saveFilename), exist_ok=True)
        print(
            f"  {roiName}: y pixels {yStart}-{yEnd} ({len(yFrames)} px); "
            f"processing {frameBin} planes/read; MATLAB H5 chunk = {len(yFrames)} x {X} x {frameBin}"
        )

        mean_img_data = compute_mean_images(reader, yFrames, frameParseG)
        mean_img_data["yStart"] = np.array([[yStart]], dtype=np.int32)
        mean_img_data["yEnd"] = np.array([[yEnd]], dtype=np.int32)
        savemat(saveImgname, mean_img_data)

        totalFrame = 0
        with h5py.File(saveFilename, "w") as h5:
            dset = None

            for j, frames in enumerate(frameParseG):
                print(f"  {roiName}: writing chunk {j + 1}/{len(frameParseG)} ({len(frames)} flattened planes)")
                tempStack = reader.read_frames(frames, yFrames)
                # Match fn_saveh5.py: Python disk order is T x X x Y so
                # MATLAB h5read sees Y x X x T.
                tempStack = np.transpose(tempStack, (0, 2, 1)).astype(np.int16)

                if j == 0:
                    dset = h5.create_dataset(
                        "/data",
                        shape=(0, X, len(yFrames)),
                        maxshape=(None, X, len(yFrames)),
                        chunks=(int(frameBin), X, len(yFrames)),
                        dtype="int16",
                    )
                    dset.attrs["source_tiff_shape"] = np.asarray(reader.shape, dtype=np.int64)
                    dset.attrs["source_axis_order"] = "slice,frame,Y,X" if reader.ndim == 4 else "frame,Y,X"
                    dset.attrs["h5py_disk_axis_order"] = "flattened_plane,X,Y"
                    dset.attrs["matlab_h5read_axis_order"] = "Y,X,flattened_plane"
                    dset.attrs["flattened_plane_order"] = "plane=slice*nFramesPerSlice+frame"
                    dset.attrs["n_slices"] = int(reader.nSlices)
                    dset.attrs["n_frames_per_slice"] = int(reader.nFramesPerSlice)
                    dset.attrs["roi_name"] = roiName
                    dset.attrs["roi_y_start_1based_inclusive"] = int(yStart)
                    dset.attrs["roi_y_end_1based_inclusive"] = int(yEnd)

                dset.resize(dset.shape[0] + tempStack.shape[0], axis=0)
                dset[totalFrame:totalFrame + tempStack.shape[0], :, :] = tempStack
                totalFrame += tempStack.shape[0]
    finally:
        reader.close()


def move_stack_folders(mousePath, roiName):
    roiPath = os.path.join(mousePath, f"green_{roiName}")
    if not os.path.isdir(roiPath):
        return

    stackPath = os.path.join(roiPath, "stack")
    os.makedirs(stackPath, exist_ok=True)

    for item in os.listdir(roiPath):
        sourcePath = os.path.join(roiPath, item)
        if item == "stack" or not os.path.isdir(sourcePath):
            continue
        if "stack" not in item.lower():
            continue

        destPath = os.path.join(stackPath, item)
        if os.path.exists(destPath):
            print(f"Stack folder already exists, skipping: {destPath}")
            continue

        print(f"Moving stack folder: {sourcePath} -> {destPath}")
        shutil.move(sourcePath, destPath)


if __name__ == "__main__":
    # Edit only this section for a new dataset, then run:
    #     python fn_parseOneROI.py

    # Use the folder where this command is run as both input and output.
    # Put this file in the animal/data folder, or cd into that folder first.
    mouse_path_input = os.getcwd()

    # MATLAB-style 1-based inclusive y-pixel crop, along the same axis used by
    # fn_parseROI.py.
    y_start_input = 499
    y_end_input = 1174

    # Output folder will be green_<roi_name_input>.
    roi_name_input = "ROI"

    print(f"Input/output folder: {mouse_path_input}")
    print(f"ROI name: {roi_name_input}")
    print(f"Y crop: {y_start_input}-{y_end_input} (1-based inclusive)")

    fn_parseOneROI(mouse_path_input, y_start_input, y_end_input, roi_name_input)
