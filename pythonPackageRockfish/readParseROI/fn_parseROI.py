import os
from fn_saveh5 import fn_saveh5

def fn_parseROI(mousePath, roiOrder, roiSize):
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

