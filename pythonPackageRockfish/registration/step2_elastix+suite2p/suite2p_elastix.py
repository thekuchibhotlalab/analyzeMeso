import os
from pathlib import Path
import numpy as np
import suite2p
import scipy.io as io
from datetime import datetime
import pathlib

ops = suite2p.default_ops() # np.load(ops,'ops.npy')
ops['batch_size'] = 10 # we will decrease the batch_size in case low RAM on computer
ops['threshold_scaling'] = 2.0 # we are increasing the threshold for finding ROIs to limit the number of non-cell ROIs found (sometimes useful in gcamp injections)
ops['fs'] = 15 # sampling rate of recording, determines binning for cell detection
ops['tau'] = 0.2 # timescale of gcamp to use for deconvolution
ops['save_mat'] = 'true'
ops['do_bidiphase'] = 'true'
ops['input_format'] = 'tiff'
#ops['h5py_key'] = 'data'
ops['nimg_init'] = 10
ops['block_size']  = [128, 128]
ops['snr_thresh'] = 1.2
ops['maxregshiftNR'] =  5
ops['roidetect'] =  0

refImg = io.loadmat('refImg.mat')
ops['refImg'] =  refImg['ref']
ops['force_refImg'] =  True

print(ops)
datapath = 'alignedElastix/'
db = {
    'data_path': [datapath],
    }
output_ops = suite2p.run_s2p(ops=ops, db=db)

# now save the .mat file is suite2p does not save it
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

io.savemat(datapath + 'suite2p/plane0/Fall.mat', {'ops':ops_matlab})