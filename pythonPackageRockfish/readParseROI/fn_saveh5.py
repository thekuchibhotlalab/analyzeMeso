import os
import numpy as np
import tifffile
import h5py
from scipy.io import savemat
from parse_frame import parse_frame

def fn_fastAlign(stack):
    # Placeholder: identity alignment
    # Replace with your real alignment if needed
    return stack

def fn_saveh5(mousePath, tiffPath, filename, roiOrder, roiSize):
    tiff_file = os.path.join(tiffPath, filename)
    stack = tifffile.memmap(tiff_file)  # (frames, y, x)

    nFrames, H, W = stack.shape
    gFrames = np.arange(nFrames)
    frameBin = 2000
    frameParseG = parse_frame(gFrames, frameBin)

    # ---- ROI Y calculation (faithful to MATLAB) ----
    stripeSize = (H - sum(roiSize)) // (len(roiSize) - 1)
    roiY = []
    start = 0
    for sz in roiSize:
        idx = np.arange(start, start + sz)
        roiY.append(idx)
        start = idx[-1] + stripeSize + 1

    # ---- filename parsing ----
    base = filename.split('.')[0].split('_')
    name = "_".join(base[:-1])
    num = base[3].lstrip('0')
    tempSplitName = f"{name}{num}"

    for k, roi in enumerate(roiOrder):
        yFrames = roiY[k]
        totalFrame = 0

        saveFilename = os.path.join(
            mousePath, f"green_{roi}", f"{tempSplitName}_parsed.h5"
        )
        saveImgname = os.path.join(
            mousePath, f"green_{roi}", f"{tempSplitName}_meanImg.mat"
        )

        os.makedirs(os.path.dirname(saveFilename), exist_ok=True)

        # ---- Mean image ----
        meanImgFrames = min(200, nFrames)
        temp = stack[:meanImgFrames, yFrames, :]
        temp = np.transpose(temp, (1, 2, 0))  # (y,x,frame)
        temp = fn_fastAlign(temp)
        meanImg = np.nanmean(temp, axis=2)
        savemat(saveImgname, {"meanImg": meanImg})

        # ---- HDF5 writing ----
        with h5py.File(saveFilename, "w") as h5:
            dset = None

            for j, frames in enumerate(frameParseG):
                tempStack = stack[frames][:, yFrames, :]
                tempStack = np.transpose(tempStack, (1, 2, 0))
                tempStack = tempStack.astype(np.int16)

                if j == 0:
                    dset = h5.create_dataset(
                        "/data",
                        shape=(*tempStack.shape[:2], 0),
                        maxshape=(*tempStack.shape[:2], None),
                        chunks=(*tempStack.shape[:2], frameBin),
                        dtype="int16"
                    )

                dset.resize(dset.shape[2] + tempStack.shape[2], axis=2)
                dset[:, :, totalFrame:totalFrame+tempStack.shape[2]] = tempStack
                totalFrame += tempStack.shape[2]

