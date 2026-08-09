import SimpleITK as sitk
import scipy.io
import scipy.ndimage as ndimage
import numpy as np
import os

def phase_corr_patch(fixed_patch, moving_patch, max_shift=10):
    """
    Computes Phase Correlation between two patches applying Suite2p-style 
    windowing, SNR thresholding, and maximum shift bounds.
    """
    # Reject entirely flat background patches
    if np.std(fixed_patch) == 0 or np.std(moving_patch) == 0:
        return 0, 0, 0
        
    f_zero = fixed_patch - np.mean(fixed_patch)
    g_zero = moving_patch - np.mean(moving_patch)
    
    # 1. Tapering/Windowing: Fades edges to 0 so FFT doesn't wrap boundaries
    h, w = f_zero.shape
    win_y = np.hanning(h)
    win_x = np.hanning(w)
    win = np.outer(win_y, win_x)
    
    f_zero *= win
    g_zero *= win
    
    # 2. Phase Correlation (Spatial Whitening)
    F = np.fft.fft2(f_zero)
    G = np.fft.fft2(g_zero)
    
    R = F * np.conj(G)
    R /= (np.abs(R) + 1e-6)  # Whiten the spectrum to prioritize structures over brightness
    
    corr = np.real(np.fft.ifft2(R))
    corr = np.fft.fftshift(corr)
    
    # 3. Restrict search constraints to max_shift
    cy, cx = h // 2, w // 2
    y0, y1 = max(0, cy - max_shift), min(h, cy + max_shift + 1)
    x0, x1 = max(0, cx - max_shift), min(w, cx + max_shift + 1)
    
    corr_center = corr[y0:y1, x0:x1]
    
    # Find peak location strictly within the allowed shift window
    peak_y_loc, peak_x_loc = np.unravel_index(np.argmax(corr_center), corr_center.shape)
    peak_val = corr_center[peak_y_loc, peak_x_loc]
    
    # 4. Suite2p-Style SNR Calculation 
    # (Ratio of the peak vs. the noise floor outside a 3x3 area around the peak)
    mask = np.ones_like(corr_center, dtype=bool)
    my0, my1 = max(0, peak_y_loc - 1), min(corr_center.shape[0], peak_y_loc + 2)
    mx0, mx1 = max(0, peak_x_loc - 1), min(corr_center.shape[1], peak_x_loc + 2)
    mask[my0:my1, mx0:mx1] = False
    
    noise_max = np.max(corr_center[mask]) if np.sum(mask) > 0 else 1e-6
    snr = peak_val / (noise_max + 1e-6)
    
    # Calculate absolute displacement 
    dy = (peak_y_loc + y0) - cy
    dx = (peak_x_loc + x0) - cx
    
    return dy, dx, snr


def refStack_elastix(base_path=None):
    if base_path is None:
        base_path = os.getcwd()
    
    fixed_image_path = os.path.join(base_path, 'elastix', 'refImg.mat')
    moving_stack_path = os.path.join(base_path, 'roiTracking', 'refStack', 'refStack.mat')
    elastix_output_path = os.path.join(base_path, 'roiTracking', 'refStack', 'refStackAligned_elastix.mat')
    final_output_path = os.path.join(base_path, 'roiTracking', 'refStack', 'refStackAligned.mat')
    coord_output_path = os.path.join(base_path, 'roiTracking', 'refStack', 'refStackAligned_coordinate.mat')

    if not os.path.exists(fixed_image_path) or not os.path.exists(moving_stack_path):
        print("Error: Input files not found.")
        return

    # Load references
    fixed_mat = scipy.io.loadmat(fixed_image_path)
    fixed_image_array = fixed_mat['ref'].astype(np.float32)
    fixed_image = sitk.GetImageFromArray(fixed_image_array)
    h, w = fixed_image_array.shape

    moving_mat = scipy.io.loadmat(moving_stack_path)
    moving_stack_array = moving_mat['refStack'].astype(np.float32)
    _, _, n_planes = moving_stack_array.shape
    
    elastix_stack = np.zeros_like(moving_stack_array)
    final_stack = np.zeros_like(moving_stack_array)
    all_dy_maps = np.zeros_like(moving_stack_array)
    all_dx_maps = np.zeros_like(moving_stack_array)

    print(f"Starting Stage 1: Global Affine alignment for {n_planes} planes...")
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(fixed_image)
    affine_parameter_map = sitk.GetDefaultParameterMap('affine')
    affine_parameter_map["MaximumNumberOfIterations"] = ["200"] 
    elastix.SetParameterMap(affine_parameter_map)

    for i in range(n_planes):
        moving_plane = moving_stack_array[:, :, i]
        moving_image = sitk.GetImageFromArray(moving_plane)
        elastix.SetMovingImage(moving_image)
        try:
            elastix.Execute()
            elastix_stack[:, :, i] = sitk.GetArrayFromImage(elastix.GetResultImage())
        except Exception as e:
            elastix_stack[:, :, i] = moving_plane 

    print("\nStarting Stage 2: Local Patch-Based Phase Correlation...")

    patch_size = 100
    stride = 10
    
    y_starts = np.arange(0, h - patch_size + 1, stride)
    x_starts = np.arange(0, w - patch_size + 1, stride)
    
    for i in range(n_planes):
        moving_slice = elastix_stack[:, :, i]
        
        shifts_y = np.zeros((len(y_starts), len(x_starts)))
        shifts_x = np.zeros((len(y_starts), len(x_starts)))
        snr_map = np.zeros((len(y_starts), len(x_starts)))
        
        for iy, ys in enumerate(y_starts):
            for ix, xs in enumerate(x_starts):
                fixed_patch = fixed_image_array[ys:ys+patch_size, xs:xs+patch_size]
                moving_patch = moving_slice[ys:ys+patch_size, xs:xs+patch_size]
                
                # Use Suite2p constraints: 10px max rigid shift
                dy, dx, snr = phase_corr_patch(fixed_patch, moving_patch, max_shift=10)
                shifts_y[iy, ix] = dy
                shifts_x[iy, ix] = dx
                snr_map[iy, ix] = snr
        
        # 5a. Reject low SNR Blocks (Suite2p uses a threshold around 1.2)
        snr_thresh = 1.2
        bad_blocks = snr_map < snr_thresh
        shifts_y[bad_blocks] = 0
        shifts_x[bad_blocks] = 0
        
        # 5b. Outlier Removal: Median Filter across the block grid to catch wild border shifts
        shifts_y = ndimage.median_filter(shifts_y, size=3)
        shifts_x = ndimage.median_filter(shifts_x, size=3)
        
        # 5c. Bilinear Upsampling back to the image resolution
        # order=1 means bilinear. mode='nearest' safely pads the extreme outer edges straight out.
        zoom_factors = (h / shifts_y.shape[0], w / shifts_y.shape[1])
        dy_map = ndimage.zoom(shifts_y, zoom_factors, order=1, mode='nearest')
        dx_map = ndimage.zoom(shifts_x, zoom_factors, order=1, mode='nearest')
        
        # (Removed the huge Gaussian filter previously here, as bilinear interpolation 
        # is vastly smoother out-of-the-box and doesn't drag edge coordinates out of bounds)
        
        y_grid, x_grid = np.meshgrid(np.arange(h), np.arange(w), indexing='ij')
        coords = np.array([y_grid - dy_map, x_grid - dx_map])
        
        final_stack[:, :, i] = ndimage.map_coordinates(
            moving_slice, coords, order=1, mode='constant', cval=0
        )
        
        all_dy_maps[:, :, i] = dy_map
        all_dx_maps[:, :, i] = dx_map
        print(f"Plane {i+1}/{n_planes} non-rigid patched.")

    scipy.io.savemat(elastix_output_path, {'refStackAligned_elastix': elastix_stack})
    scipy.io.savemat(final_output_path, {'refStackAligned': final_stack})
    scipy.io.savemat(coord_output_path, {'x_offsets': all_dx_maps, 'y_offsets': all_dy_maps})
    print("\nAlignment Complete.")

if __name__ == "__main__":
    refStack_elastix()