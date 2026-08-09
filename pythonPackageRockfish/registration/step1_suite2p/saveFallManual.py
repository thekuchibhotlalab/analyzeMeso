import os
import numpy as np
import scipy.io as io
from datetime import datetime
import pathlib

subfolders = sorted([f.path for f in os.scandir('reparse/') if f.is_dir()])

for folder in subfolders:
    print(f"Processing {folder}", flush=True)
    output_ops = np.load( folder + '/suite2p/plane0/ops.npy', allow_pickle=True)
    # now save the .mat file if suite2p does not save it
    output_ops = output_ops.item()

    ops_matlab = output_ops.copy()
    if ops_matlab.get("date_proc"):
        try:
            ops_matlab["date_proc"] = str(
                datetime.strftime(ops_matlab["date_proc"], "%Y-%m-%d %H:%M:%S.%f"))
        except:
            pass
    for k in ops_matlab.keys():
        if isinstance(ops_matlab[k], (pathlib.WindowsPath, pathlib.PosixPath)):
            ops_matlab[k] = os.fspath(ops_matlab[k].absolute())
        elif isinstance(ops_matlab[k], list) and len(ops_matlab[k]) > 0:
            if isinstance(ops_matlab[k][0], (pathlib.WindowsPath, pathlib.PosixPath)):
                ops_matlab[k] = [os.fspath(p.absolute()) for p in ops_matlab[k]]
                print(k, ops_matlab[k])

    save_path = folder + '/suite2p/plane0/Fall.mat'
    io.savemat(save_path, {'ops':ops_matlab})
    print(f"Saved {save_path}", flush=True)

print("saveFallManual.py complete", flush=True)
