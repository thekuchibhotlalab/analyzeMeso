import SimpleITK as sitk
import scipy.io
import scipy.ndimage as ndimage
import numpy as np
import os


def get_translation_parameter_map():
    parameter_map = sitk.GetDefaultParameterMap('translation')
    parameter_map["MaximumNumberOfIterations"] = ["200"]
    parameter_map["WriteResultImage"] = ["true"]
    parameter_map["ResultImageFormat"] = ["tiff"]
    return parameter_map


def get_affine_parameter_map():
    parameter_map = sitk.GetDefaultParameterMap('affine')
    parameter_map["MaximumNumberOfIterations"] = ["200"]
    parameter_map["WriteResultImage"] = ["true"]
    parameter_map["ResultImageFormat"] = ["tiff"]
    return parameter_map


def run_elastix(fixed_array, moving_array, parameter_map):
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(sitk.GetImageFromArray(fixed_array.astype(np.float32)))
    elastix.SetMovingImage(sitk.GetImageFromArray(moving_array.astype(np.float32)))
    elastix.SetParameterMap(parameter_map)
    elastix.Execute()
    return elastix


def image_corr(fixed_image_array, moving_image_array):
    fixed = fixed_image_array.astype(np.float32)
    moving = moving_image_array.astype(np.float32)
    valid = np.isfinite(fixed) & np.isfinite(moving)
    if np.sum(valid) < 10:
        return -np.inf
    fixed = fixed[valid]
    moving = moving[valid]
    if np.std(fixed) == 0 or np.std(moving) == 0:
        return -np.inf
    return float(np.corrcoef(fixed, moving)[0, 1])


def select_best_matching_plane(fixed_image_array, moving_stack_array):
    _, _, n_planes = moving_stack_array.shape
    corr_values = np.zeros(n_planes, dtype=np.float64)
    for i in range(n_planes):
        corr_values[i] = image_corr(fixed_image_array, moving_stack_array[:, :, i])

    best_plane_idx = int(np.nanargmax(corr_values))
    middle_plane_idx = n_planes // 2
    print("Ref-stack slice correlation to suite2p reference:")
    for i, corr_value in enumerate(corr_values):
        marker = " <== selected" if i == best_plane_idx else ""
        middle_marker = " (middle)" if i == middle_plane_idx else ""
        print(f"  plane {i + 1:03d}/{n_planes}: corr={corr_value:.4f}{middle_marker}{marker}")
    return best_plane_idx, corr_values


def apply_transform_to_plane(moving_plane, transform_parameter_map):
    transformix = sitk.TransformixImageFilter()
    transformix.SetMovingImage(sitk.GetImageFromArray(moving_plane.astype(np.float32)))
    transformix.SetTransformParameterMap(transform_parameter_map)
    transformix.Execute()
    return sitk.GetArrayFromImage(transformix.GetResultImage())


def transform_parameters_to_print(transform_parameter_map):
    try:
        transform_map = transform_parameter_map[0]
        if "TransformParameters" in transform_map:
            return transform_map["TransformParameters"]
    except Exception:
        pass
    return ["unknown"]


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
    
    final_stack = np.zeros_like(moving_stack_array)
    all_dy_maps = np.zeros_like(moving_stack_array)
    all_dx_maps = np.zeros_like(moving_stack_array)

    middle_plane_idx = n_planes // 2
    middle_plane = moving_stack_array[:, :, middle_plane_idx]
    translated_stack = np.zeros_like(moving_stack_array)
    slice_translation_params = []

    print(f"Starting Stage 1: translation-only alignment of {n_planes} planes to middle plane.")
    print(f"Middle plane: {middle_plane_idx + 1}/{n_planes}")
    for i in range(n_planes):
        if i == middle_plane_idx:
            translated_stack[:, :, i] = moving_stack_array[:, :, i]
            slice_translation_params.append(["middle_slice_identity"])
            print(f"Plane {i + 1}/{n_planes}: middle plane, no slice translation.")
            continue

        try:
            elastix = run_elastix(
                middle_plane,
                moving_stack_array[:, :, i],
                get_translation_parameter_map(),
            )
            translation_map = elastix.GetTransformParameterMap()
            translated_stack[:, :, i] = sitk.GetArrayFromImage(elastix.GetResultImage())
            slice_translation_params.append(transform_parameters_to_print(translation_map))
            print(
                f"Plane {i + 1}/{n_planes}: translation parameters "
                f"{slice_translation_params[-1]}"
            )
        except Exception as e:
            translated_stack[:, :, i] = moving_stack_array[:, :, i]
            slice_translation_params.append(["translation_failed"])
            print(f"Plane {i + 1}/{n_planes}: translation failed, using raw slice. Error: {e}")

    print("\nStarting Stage 2: affine alignment of middle plane to Suite2p reference.")
    try:
        affine_elastix = run_elastix(
            fixed_image_array,
            translated_stack[:, :, middle_plane_idx],
            get_affine_parameter_map(),
        )
        affine_transform_map = affine_elastix.GetTransformParameterMap()
        affine_parameters = transform_parameters_to_print(affine_transform_map)
        print(f"Middle-to-reference affine parameters: {affine_parameters}")

        for i in range(n_planes):
            final_stack[:, :, i] = apply_transform_to_plane(translated_stack[:, :, i], affine_transform_map)
            print(f"Applied shared affine transform to plane {i + 1}/{n_planes}.")
    except Exception as e:
        final_stack = translated_stack.copy()
        affine_transform_map = None
        affine_parameters = ["affine_failed"]
        print(f"Affine middle-to-reference alignment failed; saving translated stack. Error: {e}")

    scipy.io.savemat(
        elastix_output_path,
        {
            'refStackTranslated_to_middle': translated_stack,
            'refStackAligned_elastix': final_stack,
            'middle_plane_idx_python': middle_plane_idx,
            'middle_plane_idx_matlab': middle_plane_idx + 1,
            'slice_translation_params': np.array(slice_translation_params, dtype=object),
            'middle_to_ref_affine_params': np.array(affine_parameters, dtype=object),
            'elastix_transform': 'slice_translation_then_shared_affine',
        }
    )
    scipy.io.savemat(final_output_path, {'refStackAligned': final_stack})
    scipy.io.savemat(coord_output_path, {'x_offsets': all_dx_maps, 'y_offsets': all_dy_maps})
    print("\nAlignment Complete.")

if __name__ == "__main__":
    refStack_elastix()
