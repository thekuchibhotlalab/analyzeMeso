import os
import numpy as np
import tifffile
import h5py
from scipy.io import savemat
from parse_frame import parse_frame

class TiffStackReader:
    def __init__(self, tiff_file):
        self.tiff_file = tiff_file
        self.stack = None
        self.tif = None
        self.series = None
        self.mode = "memmap"

        try:
            self.stack = tifffile.memmap(tiff_file)
            self._set_shape(self.stack.shape)
            print(self._shape_message("memmap"))
        except ValueError as exc:
            self.mode = "pages"
            print(f"TIFF is not memory-mappable; using page reader instead. ({exc})")
            self.tif = tifffile.TiffFile(tiff_file)
            self.series = self.tif.series[0]
            self._set_shape(self.series.shape)
            print(self._shape_message("page reader"))

    def _set_shape(self, shape):
        shape = tuple(int(x) for x in shape)
        shape = tuple(x for x in shape if x != 1)
        self.shape = shape
        if len(shape) == 2:
            self.ndim = 2
            self.nSlices = 1
            self.nFramesPerSlice = 1
            self.Y = shape[0]
            self.X = shape[1]
        elif len(shape) == 3:
            self.ndim = 3
            self.nSlices = 1
            self.nFramesPerSlice = shape[0]
            self.Y = shape[1]
            self.X = shape[2]
        elif len(shape) == 4:
            self.ndim = 4
            self.nSlices = shape[0]
            self.nFramesPerSlice = shape[1]
            self.Y = shape[2]
            self.X = shape[3]
        else:
            raise ValueError(f"Expected TIFF shape as (frames, y, x) or (slices, frames, y, x), got {shape}.")
        self.nFrames = self.nSlices * self.nFramesPerSlice

    def _shape_message(self, reader_name):
        if self.nSlices > 1:
            return (
                f"Loaded TIFF by {reader_name}: {self.nSlices} slices x "
                f"{self.nFramesPerSlice} frames/slice, Y={self.Y}, X={self.X}. "
                f"Will save H5 so MATLAB reads it as Y x X x {self.nFrames} flattened planes."
            )
        return f"Loaded TIFF by {reader_name}: {self.nFrames} frames, Y={self.Y}, X={self.X}"

    @staticmethod
    def _as_frame_stack(data):
        data = np.asarray(data)
        data = np.squeeze(data)
        if data.ndim == 2:
            data = data[np.newaxis, :, :]
        if data.ndim != 3:
            raise ValueError(f"Expected chunk as (frames, y, x), got {data.shape}.")
        return data

    def _linear_to_slice_frame(self, frames):
        # Flatten a 4D TIFF shaped (slice, frame, Y, X) into a 3D movie:
        # plane = slice_index * nFramesPerSlice + frame_index.
        # This matches MATLAB's historical behavior and step3_alignRefStack,
        # which reshapes the H5 data with framePerPlane = 20.
        frames = np.asarray(frames, dtype=int)
        slices = frames // self.nFramesPerSlice
        frame_in_slice = frames % self.nFramesPerSlice
        return slices, frame_in_slice

    def read_frames(self, frames, yFrames):
        frames = [int(frame) for frame in frames]
        if self.mode == "memmap":
            if self.nSlices == 1:
                data = np.asarray(self.stack[frames])
                data = self._as_frame_stack(data)
                return data[:, yFrames, :]
            slices, frame_in_slice = self._linear_to_slice_frame(frames)
            return np.stack(
                [np.asarray(self.stack[slc, frame, yFrames, :]) for slc, frame in zip(slices, frame_in_slice)],
                axis=0,
            )

        if len(self.tif.pages) == self.nFrames:
            return np.stack(
                [self.tif.pages[frame].asarray()[yFrames, :] for frame in frames],
                axis=0,
            )

        if self.nSlices > 1 and len(self.tif.pages) == self.nSlices:
            slices, frame_in_slice = self._linear_to_slice_frame(frames)
            slice_cache = {}
            out = []
            for slc, frame in zip(slices, frame_in_slice):
                if slc not in slice_cache:
                    slice_data = np.asarray(self.tif.pages[int(slc)].asarray())
                    slice_data = np.squeeze(slice_data)
                    if slice_data.ndim != 3:
                        raise ValueError(
                            f"Expected TIFF page {slc} as (frames, y, x), got {slice_data.shape}."
                        )
                    slice_cache[slc] = slice_data
                out.append(slice_cache[slc][int(frame), yFrames, :])
            return np.stack(out, axis=0)

        try:
            if self.nSlices == 1:
                data = self.series.asarray(key=frames)
            else:
                slices, frame_in_slice = self._linear_to_slice_frame(frames)
                unique_slices = np.unique(slices)
                data = self.series.asarray(key=unique_slices.tolist())
                data = np.asarray(data)
                if len(unique_slices) == 1 and data.ndim == 3:
                    data = data[np.newaxis, :, :, :]
                slice_lookup = {int(slc): i for i, slc in enumerate(unique_slices)}
                return np.stack(
                    [data[slice_lookup[int(slc)], int(frame), yFrames, :] for slc, frame in zip(slices, frame_in_slice)],
                    axis=0,
                )
        except TypeError:
            data = self.series.asarray()
            data = np.asarray(data)
            data = np.squeeze(data)
            if self.nSlices > 1:
                if data.ndim != 4:
                    raise ValueError(f"Expected full stack as (slices, frames, y, x), got {data.shape}.")
                slices, frame_in_slice = self._linear_to_slice_frame(frames)
                return np.stack(
                    [data[int(slc), int(frame), yFrames, :] for slc, frame in zip(slices, frame_in_slice)],
                    axis=0,
                )
            data = self._as_frame_stack(data)
            data = data[frames, :, :]
        data = self._as_frame_stack(data)
        return data[:, yFrames, :]

    def close(self):
        if self.tif is not None:
            self.tif.close()

def fn_fastAlign(stack):
    # Placeholder: identity alignment
    # Replace with your real alignment if needed
    return stack

def nanmean_frames(frame_stack):
    frame_stack = frame_stack.astype(np.float64, copy=False)
    valid_count = np.sum(np.isfinite(frame_stack), axis=0)
    frame_sum = np.nansum(frame_stack, axis=0)
    mean_img = np.divide(
        frame_sum,
        valid_count,
        out=np.full(frame_sum.shape, np.nan, dtype=np.float64),
        where=valid_count > 0,
    )
    return mean_img

def compute_mean_images(reader, yFrames, frameParseG):
    mean_sum = None
    mean_count = None

    print("  Computing full-file mean image...")
    for frames in frameParseG:
        temp = reader.read_frames(frames, yFrames).astype(np.float64, copy=False)
        temp_count = np.sum(np.isfinite(temp), axis=0)
        temp_sum = np.nansum(temp, axis=0)
        if mean_sum is None:
            mean_sum = temp_sum
            mean_count = temp_count
        else:
            mean_sum += temp_sum
            mean_count += temp_count

    mean_img = np.divide(
        mean_sum,
        mean_count,
        out=np.full(mean_sum.shape, np.nan, dtype=np.float64),
        where=mean_count > 0,
    )

    mat_data = {"meanImg": mean_img}
    if reader.nSlices > 1:
        middle_slice_idx = (reader.nSlices - 1) // 2
        middle_slice_frames = middle_slice_idx * reader.nFramesPerSlice + np.arange(reader.nFramesPerSlice)
        print(f"  Computing middle-slice mean image: slice {middle_slice_idx + 1}/{reader.nSlices}")
        middle_slice_stack = reader.read_frames(middle_slice_frames, yFrames)
        mat_data["meanImgMiddleSlice"] = nanmean_frames(middle_slice_stack)
        mat_data["middleSliceIndex"] = np.array([[middle_slice_idx + 1]], dtype=np.int16)
    return mat_data

def fn_saveh5(mousePath, tiffPath, filename, roiOrder, roiSize):
    tiff_file = os.path.join(tiffPath, filename)
    reader = TiffStackReader(tiff_file)

    nFrames, Y, X = reader.nFrames, reader.Y, reader.X
    gFrames = np.arange(nFrames)
    frameBin = 2000
    frameParseG = parse_frame(gFrames, frameBin)

    # ---- ROI Y calculation (faithful to MATLAB) ----
    if sum(roiSize) > Y:
        reader.close()
        raise ValueError(f"Sum of ROI sizes ({sum(roiSize)}) is larger than TIFF Y dimension ({Y}).")
    stripeSize = 0 if len(roiSize) == 1 else (Y - sum(roiSize)) // (len(roiSize) - 1)
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
        h5_chunk_frames = frameBin

        saveFilename = os.path.join(
            mousePath, f"green_{roi}", f"{tempSplitName}_parsed.h5"
        )
        saveImgname = os.path.join(
            mousePath, f"green_{roi}", f"{tempSplitName}_meanImg.mat"
        )

        os.makedirs(os.path.dirname(saveFilename), exist_ok=True)
        print(
            f"  {roi}: processing {frameBin} planes/read; "
            f"MATLAB H5 chunk = {len(yFrames)} x {X} x {h5_chunk_frames}"
        )

        # ---- Mean image ----
        mean_img_data = compute_mean_images(reader, yFrames, frameParseG)
        savemat(saveImgname, mean_img_data)

        # ---- HDF5 writing ----
        with h5py.File(saveFilename, "w") as h5:
            dset = None

            for j, frames in enumerate(frameParseG):
                print(f"  {roi}: writing chunk {j + 1}/{len(frameParseG)} ({len(frames)} flattened planes)")
                tempStack = reader.read_frames(frames, yFrames)
                # h5py writes dimensions in C/Python order. MATLAB h5read/h5info
                # sees these dimensions reversed. Store as T x X x Y on disk so
                # MATLAB reads the dataset as Y x X x T, matching fn_saveh5.m.
                tempStack = np.transpose(tempStack, (0, 2, 1)).astype(np.int16)

                if j == 0:
                    dset = h5.create_dataset(
                        "/data",
                        shape=(0, X, len(yFrames)),
                        maxshape=(None, X, len(yFrames)),
                        chunks=(int(h5_chunk_frames), X, len(yFrames)),
                        dtype="int16"
                    )
                    dset.attrs["source_tiff_shape"] = np.asarray(reader.shape, dtype=np.int64)
                    dset.attrs["source_axis_order"] = "slice,frame,Y,X" if reader.ndim == 4 else "frame,Y,X"
                    dset.attrs["h5py_disk_axis_order"] = "flattened_plane,X,Y"
                    dset.attrs["matlab_h5read_axis_order"] = "Y,X,flattened_plane"
                    dset.attrs["flattened_plane_order"] = "plane=slice*nFramesPerSlice+frame"
                    dset.attrs["n_slices"] = int(reader.nSlices)
                    dset.attrs["n_frames_per_slice"] = int(reader.nFramesPerSlice)

                dset.resize(dset.shape[0] + tempStack.shape[0], axis=0)
                dset[totalFrame:totalFrame+tempStack.shape[0], :, :] = tempStack
                totalFrame += tempStack.shape[0]

    reader.close()

