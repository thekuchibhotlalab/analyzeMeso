import os
import shutil
from fn_saveh5 import fn_saveh5

def fn_parseROI(mousePath, roiOrder, roiSize):
    if len(roiOrder) != len(roiSize):
        raise ValueError("roiOrder and roiSize must have the same number of entries.")

    for roi in roiOrder:
        os.makedirs(os.path.join(mousePath, f"green_{roi}"), exist_ok=True)

    for sub in os.listdir(mousePath):
        tiffPath = os.path.join(mousePath, sub)
        if not os.path.isdir(tiffPath):
            continue

        for file in os.listdir(tiffPath):
            if not file.endswith(".tif"):
                continue

            print(file)
            try:
                fn_saveh5(mousePath, tiffPath, file, roiOrder, roiSize)
            except Exception as e:
                print(f"{file} not done! ({e})")

    move_stack_folders(mousePath, roiOrder)


def move_stack_folders(mousePath, roiOrder):
    for roi in roiOrder:
        roiPath = os.path.join(mousePath, f"green_{roi}")
        if not os.path.isdir(roiPath):
            continue

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
    #     python fn_parseROI.py

    # Use the folder where this command is run as both input and output.
    # Put this file in the animal/data folder, or cd into that folder first.
    mouse_path_input = os.getcwd()

    # ROI settings, top-to-bottom in the TIFF image.
    # Example: roi_order_input = ["PPC", "AC"]; roi_size_input = [788, 562]
    roi_order_input = ["PPC", "AC"]
    roi_size_input = [788, 562]

    print(f"Input/output folder: {mouse_path_input}")
    print(f"ROI order: {roi_order_input}")
    print(f"ROI sizes: {roi_size_input}")

    fn_parseROI(mouse_path_input, roi_order_input, roi_size_input)
