from pathlib import Path
import numpy as np
from oasis.functions import deconvolve
import os
import scipy.io as sio

def process_mat_files_in_directory(parent_directory):
    parent_path = Path(parent_directory) / 'imagingSession'
    print(parent_path)
    for folder in parent_path.iterdir():
        print(folder)
        if folder.is_dir():
            mat_file_path = folder / 'suite2p' / 'plane0' / 'data_F.mat'
            save_path = folder / 'suite2p' / 'plane0'
            if mat_file_path.exists():
                print(f"Processing {mat_file_path}")
                
                # Load allTraces
                mat_contents = sio.loadmat(mat_file_path)
                if 'allTraces' not in mat_contents:
                    print(f"'allTraces' not found in {mat_file_path}")
                    continue
                allTraces = mat_contents['allTraces']  # shape: (T, N)

                dff = compute_dff(allTraces, baseline_correction_window=1000)
                sio.savemat(save_path / 'data_dff.mat', {'dff': dff})

                T, N = dff.shape
                C = np.zeros((T, N))
                S = np.zeros((T, N))
                Bs = []
                Gs = []
                Lams = []

                print ("Deconvolving " + str(N) + " neurons")
                # Loop through each neuron (column)
                for i in range(N):
                    trace = dff[:, i]
                    try:
                        c, s, b, g, lam = deconvolve(trace, penalty=1,  b_nonneg=False  )
                    except Exception as e:
                        print(f"Deconvolution failed for neuron {i}: {e}")
                        c = s = np.full(trace.shape, np.nan)
                        b = g = lam = np.nan
                        
                    C[:, i] = c
                    S[:, i] = s
                    Bs.append(b)
                    Gs.append(g)
                    Lams.append(lam)

                # Save results
                sio.savemat(save_path / 'data_C.mat', {'C': C})
                sio.savemat(save_path / 'data_S.mat', {'S': S})
                sio.savemat(save_path / 'data_spkOps.mat', {
                    'b': np.array(Bs),
                    'g': np.array(Gs),
                    'lam': np.array(Lams)
                })

import numpy as np
from scipy.ndimage import uniform_filter1d

def compute_dff(rawTC, baseline_correction_window=1000):
    """
    Compute ΔF/F from raw fluorescence traces with baseline correction.

    Parameters:
    - rawTC: 2D numpy array of shape (n_frames, n_neurons)
    - baseline_correction_window: int, window size (in frames) for moving average baseline correction

    Returns:
    - dff: ΔF/F matrix, same shape as rawTC
    """
    # Step 1: Calculate 25th percentile baseline for each neuron
    baseline = np.percentile(rawTC, 25, axis=0)  # shape: (n_neurons,)

    # Step 2: Compute dF/F = (F - F0) / F0 = F / F0 - 1
    dff = rawTC / baseline[np.newaxis, :] - 1  # shape: (n_frames, n_neurons)

    # Step 3: Smooth dF/F to get a slow fluctuating baseline (moving average)
    baseline_smooth = uniform_filter1d(dff, size=baseline_correction_window, axis=0, mode='nearest')

    baseline = uniform_filter1d(dff, size=baseline_correction_window, axis=0, mode='nearest')

    # Step 2: Subtract the mean across time (for each neuron), keeping the shape
    baseline = baseline - np.nanmean(baseline, axis=0, keepdims=True)
    
    # Step 5: Subtract smooth baseline from original dF/F
    dff_corrected = dff - baseline_smooth

    return dff_corrected

if __name__ == "__main__":
    process_mat_files_in_directory(os.getcwd())