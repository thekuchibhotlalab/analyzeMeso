import os
import re
from pathlib import Path

import h5py
import numpy as np
import scipy.io
import scipy.ndimage as ndimage
import SimpleITK as sitk


FRAMES_PER_SLICE = int(os.environ.get('REFSTACK_FRAMES_PER_SLICE', '20'))
N_SLICES = int(os.environ.get('REFSTACK_N_SLICES', '60'))
ELASTIX_MAX_ITERATIONS = os.environ.get('ELASTIX_MAX_ITERATIONS', '200')
SAVE_STACK_SLICE_TRANSFORMS = os.environ.get('SAVE_STACK_SLICE_TRANSFORMS', '1') != '0'


def log(message):
    print(message, flush=True)


def session_sort_key(path):
    match = re.search(r'session(\d+)', Path(path).stem)
    if match:
        return int(match.group(1))
    return Path(path).stem


def image_corr(img_a, img_b):
    a = np.asarray(img_a, dtype=np.float64)
    b = np.asarray(img_b, dtype=np.float64)
    if a.shape != b.shape:
        raise ValueError(f'Correlation image size mismatch: {a.shape} vs {b.shape}')
    valid = np.isfinite(a) & np.isfinite(b)
    if np.count_nonzero(valid) < 10:
        return np.nan
    a = a[valid].ravel()
    b = b[valid].ravel()
    a = a - np.mean(a)
    b = b - np.mean(b)
    denom = np.sqrt(np.sum(a * a) * np.sum(b * b))
    if denom == 0:
        return np.nan
    return float(np.sum(a * b) / denom)


def enhance_image(input_img, zscore_lim=6, diameter=(3, 3)):
    img = np.asarray(input_img, dtype=np.float32)
    med_size = (int(4 * diameter[0] + 1), int(4 * diameter[1] + 1))
    img_med = ndimage.median_filter(img, size=med_size, mode='nearest')
    highpass = img - img_med
    local_scale = ndimage.median_filter(np.abs(highpass), size=med_size, mode='nearest')
    z_img = highpass / (1e-10 + local_scale)
    out = (z_img + zscore_lim) / (2 * zscore_lim)
    return np.clip(out, 0, 1).astype(np.float32)


def enhance_stack(stack):
    out = np.zeros_like(stack, dtype=np.float32)
    for i in range(stack.shape[2]):
        out[:, :, i] = enhance_image(stack[:, :, i], zscore_lim=6)
    return out


def median_filter_image(input_img, size=3):
    return ndimage.median_filter(np.asarray(input_img, dtype=np.float32), size=(size, size), mode='nearest')


def median_filter_stack(stack, size=3):
    out = np.zeros_like(stack, dtype=np.float32)
    for i in range(stack.shape[2]):
        out[:, :, i] = median_filter_image(stack[:, :, i], size=size)
    return out


def get_parameter_map(transform_name):
    parameter_map = sitk.GetDefaultParameterMap(transform_name)
    parameter_map['MaximumNumberOfIterations'] = [ELASTIX_MAX_ITERATIONS]
    parameter_map['WriteResultImage'] = ['true']
    parameter_map['ResultImageFormat'] = ['tiff']
    return parameter_map


def run_elastix(fixed_array, moving_array, transform_name):
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(sitk.GetImageFromArray(fixed_array.astype(np.float32)))
    elastix.SetMovingImage(sitk.GetImageFromArray(moving_array.astype(np.float32)))
    elastix.SetParameterMap(get_parameter_map(transform_name))
    elastix.LogToConsoleOff()
    elastix.LogToFileOff()
    elastix.Execute()
    result_image = elastix.GetResultImage()
    result_array = sitk.GetArrayFromImage(result_image).astype(np.float32)
    transform_parameter_map = elastix.GetTransformParameterMap()[0]
    return result_image, result_array, transform_parameter_map


def run_rigid_elastix(fixed_array, moving_array):
    return run_elastix(fixed_array, moving_array, 'rigid')


def run_translation_elastix(fixed_array, moving_array):
    return run_elastix(fixed_array, moving_array, 'translation')


def apply_transform_array(moving_array, transform_parameter_map):
    transformix = sitk.TransformixImageFilter()
    transformix.SetMovingImage(sitk.GetImageFromArray(moving_array.astype(np.float32)))
    transformix.SetTransformParameterMap(transform_parameter_map)
    transformix.LogToConsoleOff()
    transformix.LogToFileOff()
    transformix.Execute()
    result_image = transformix.GetResultImage()
    result_array = sitk.GetArrayFromImage(result_image).astype(np.float32)
    return result_image, result_array


def load_mat_image(path, variable_name):
    mat = scipy.io.loadmat(path)
    if variable_name not in mat:
        raise KeyError(f'Could not find variable {variable_name!r} in {path}')
    return np.asarray(mat[variable_name], dtype=np.float32)


def orient_h5_stack_to_yxframes(data, ref_shape):
    data = np.asarray(data)
    data = np.squeeze(data)
    if data.ndim != 3:
        raise ValueError(f'Expected 3D H5 /data, got shape {data.shape}')

    h, w = ref_shape
    candidates = []
    if data.shape[0:2] == (h, w):
        candidates.append(('Y,X,T', data))
    if data.shape[0:2] == (w, h):
        candidates.append(('X,Y,T -> Y,X,T', np.transpose(data, (1, 0, 2))))
    if data.shape[1:3] == (h, w):
        candidates.append(('T,Y,X -> Y,X,T', np.transpose(data, (1, 2, 0))))
    if data.shape[1:3] == (w, h):
        candidates.append(('T,X,Y -> Y,X,T', np.transpose(data, (2, 1, 0))))

    if not candidates:
        raise ValueError(
            f'Could not orient H5 data shape {data.shape} to reference image shape {ref_shape}.'
        )

    label, oriented = candidates[0]
    log(f'H5 /data original shape: {data.shape}; interpreted as {label}; final Y,X,T shape: {oriented.shape}')
    return oriented.astype(np.float32, copy=False)


def load_refstack_h5(refstack_dir, ref_shape):
    h5_files = sorted(Path(refstack_dir).glob('*.h5'))
    if not h5_files:
        raise FileNotFoundError(f'No .h5 file found under refStack folder: {refstack_dir}')
    if len(h5_files) > 1:
        log(f'WARNING: multiple H5 files found under {refstack_dir}; using {h5_files[0].name}')

    h5_path = h5_files[0]
    log(f'Reading refStack H5: {h5_path}')
    with h5py.File(h5_path, 'r') as h5_file:
        if '/data' not in h5_file:
            raise KeyError(f'Could not find dataset /data in {h5_path}')
        data = h5_file['/data'][()]

    movie = orient_h5_stack_to_yxframes(data, ref_shape)
    expected_frames = FRAMES_PER_SLICE * N_SLICES
    if movie.shape[2] < expected_frames:
        raise ValueError(
            f'RefStack has only {movie.shape[2]} frames, but expected at least '
            f'{N_SLICES} slices x {FRAMES_PER_SLICE} frames/slice = {expected_frames}.'
        )
    if movie.shape[2] > expected_frames:
        log(f'WARNING: refStack has {movie.shape[2]} frames; using first {expected_frames}.')
        movie = movie[:, :, :expected_frames]
    return h5_path, movie


def mean_refstack_slices(refstack_movie):
    h, w, _ = refstack_movie.shape
    mean_stack = np.zeros((h, w, N_SLICES), dtype=np.float32)
    for slice_idx in range(N_SLICES):
        start = slice_idx * FRAMES_PER_SLICE
        stop = start + FRAMES_PER_SLICE
        mean_stack[:, :, slice_idx] = np.nanmean(refstack_movie[:, :, start:stop], axis=2)
    return mean_stack


def align_refstack_to_refimg(ref_img, mean_stack, refstack_dir):
    translated_stack = np.zeros_like(mean_stack, dtype=np.float32)
    aligned_stack = np.zeros_like(mean_stack, dtype=np.float32)
    corr_to_ref_before = np.full(N_SLICES, np.nan, dtype=np.float64)
    corr_to_ref_after = np.full(N_SLICES, np.nan, dtype=np.float64)
    corr_to_middle_before = np.full(N_SLICES, np.nan, dtype=np.float64)
    corr_to_middle_after = np.full(N_SLICES, np.nan, dtype=np.float64)
    translation_transform_files = []
    rigid_transform_file = ''
    middle_slice_idx = N_SLICES // 2

    stack_param_dir = Path(refstack_dir) / 'refStack_to_refImg_param'
    if SAVE_STACK_SLICE_TRANSFORMS:
        stack_param_dir.mkdir(parents=True, exist_ok=True)

    middle_slice = mean_stack[:, :, middle_slice_idx]
    log(
        f'First aligning refStack slices to middle slice {middle_slice_idx + 1}/{N_SLICES} '
        'using translation-only registration.'
    )
    for slice_idx in range(N_SLICES):
        moving_slice = mean_stack[:, :, slice_idx]
        corr_to_ref_before[slice_idx] = image_corr(ref_img, moving_slice)
        corr_to_middle_before[slice_idx] = image_corr(middle_slice, moving_slice)
        _, translated_array, translation_map = run_translation_elastix(middle_slice, moving_slice)
        translated_stack[:, :, slice_idx] = translated_array
        corr_to_middle_after[slice_idx] = image_corr(middle_slice, translated_array)

        if SAVE_STACK_SLICE_TRANSFORMS:
            transform_path = stack_param_dir / f'refStack_slice{slice_idx + 1:03d}_to_middle_translation.txt'
            sitk.WriteParameterFile(translation_map, str(transform_path))
            translation_transform_files.append(str(transform_path))
        else:
            translation_transform_files.append('')

        log(
            f'  refStack slice {slice_idx + 1:03d}/{N_SLICES}: '
            f'corr-to-middle before={corr_to_middle_before[slice_idx]:.4f}, '
            f'after={corr_to_middle_after[slice_idx]:.4f}'
        )

    log(
        f'Now registering translated middle slice {middle_slice_idx + 1}/{N_SLICES} '
        'to refImg.mat using rigid registration.'
    )
    translated_middle = translated_stack[:, :, middle_slice_idx]
    _, rigid_middle_array, rigid_map = run_rigid_elastix(ref_img, translated_middle)
    middle_corr_before = image_corr(ref_img, translated_middle)
    middle_corr_after = image_corr(ref_img, rigid_middle_array)
    log(f'Middle slice to refImg corr before={middle_corr_before:.4f}, after={middle_corr_after:.4f}')

    if SAVE_STACK_SLICE_TRANSFORMS:
        rigid_path = stack_param_dir / f'refStack_middleSlice{middle_slice_idx + 1:03d}_to_refImg_rigid.txt'
        sitk.WriteParameterFile(rigid_map, str(rigid_path))
        rigid_transform_file = str(rigid_path)

    log('Applying the shared middle-slice rigid transform to every translated refStack slice.')
    for slice_idx in range(N_SLICES):
        _, final_array = apply_transform_array(translated_stack[:, :, slice_idx], rigid_map)
        aligned_stack[:, :, slice_idx] = final_array
        corr_to_ref_after[slice_idx] = image_corr(ref_img, final_array)
        log(
            f'  final refStack slice {slice_idx + 1:03d}/{N_SLICES}: '
            f'corr-to-ref before={corr_to_ref_before[slice_idx]:.4f}, '
            f'after={corr_to_ref_after[slice_idx]:.4f}'
        )

    return {
        'translated_stack': translated_stack,
        'aligned_stack': aligned_stack,
        'corr_to_ref_before': corr_to_ref_before,
        'corr_to_ref_after': corr_to_ref_after,
        'corr_to_middle_before': corr_to_middle_before,
        'corr_to_middle_after': corr_to_middle_after,
        'translation_transform_files': translation_transform_files,
        'rigid_transform_file': rigid_transform_file,
        'middle_slice_idx_python': middle_slice_idx,
        'middle_slice_idx_matlab': middle_slice_idx + 1,
    }


def matlab_cellstr(strings):
    arr = np.empty((len(strings), 1), dtype=object)
    for idx, item in enumerate(strings):
        arr[idx, 0] = str(item)
    return arr


def save_refstack_debug(
    refstack_dir,
    h5_path,
    mean_stack,
    mean_stack_filtered,
    mean_stack_enhanced,
    stack_alignment,
):
    save_path = Path(refstack_dir) / 'refStack_depthMatched_debug.mat'
    scipy.io.savemat(
        save_path,
        {
            'refStackH5Path': str(h5_path),
            'framePerPlane': np.array([[FRAMES_PER_SLICE]], dtype=np.float64),
            'nSlices': np.array([[N_SLICES]], dtype=np.float64),
            'refStackMean': mean_stack,
            'refStackMeanMedianFiltered': mean_stack_filtered,
            'refStackMeanEnhanced': mean_stack_enhanced,
            'refStackTranslatedToMiddle': stack_alignment['translated_stack'],
            'refStackAlignedToRefImg': stack_alignment['aligned_stack'],
            'refStackAlignedToRefImgEnhanced': stack_alignment['aligned_stack'],
            'refStackCorrToRefBefore': stack_alignment['corr_to_ref_before'].reshape(-1, 1),
            'refStackCorrToRefAfter': stack_alignment['corr_to_ref_after'].reshape(-1, 1),
            'refStackCorrToMiddleBefore': stack_alignment['corr_to_middle_before'].reshape(-1, 1),
            'refStackCorrToMiddleAfter': stack_alignment['corr_to_middle_after'].reshape(-1, 1),
            'refStackMiddleSliceIdx': np.array([[stack_alignment['middle_slice_idx_matlab']]], dtype=np.float64),
            'refStackTranslationTransformFiles': matlab_cellstr(stack_alignment['translation_transform_files']),
            'refStackRigidMiddleToRefImgTransformFile': stack_alignment['rigid_transform_file'],
        },
        do_compression=True,
    )
    log(f'Saved refStack debugging MAT: {save_path}')
    return save_path


def register_recording_to_best_depth(moving_file, fixed_stack, output_dir, transform_dir):
    moving_array_original = load_mat_image(moving_file, 'meanImg')
    moving_array_for_registration = median_filter_image(moving_array_original, size=3)
    best_corr = -np.inf
    best_slice_idx = None
    best_transform_map = None
    slice_corrs = np.full(fixed_stack.shape[2], np.nan, dtype=np.float64)

    for slice_idx in range(fixed_stack.shape[2]):
        fixed_slice = fixed_stack[:, :, slice_idx]
        _, result_array, transform_map = run_rigid_elastix(fixed_slice, moving_array_for_registration)
        corr = image_corr(fixed_slice, result_array)
        slice_corrs[slice_idx] = corr
        if np.isfinite(corr) and corr > best_corr:
            best_corr = corr
            best_slice_idx = slice_idx
            best_transform_map = transform_map

    if best_slice_idx is None:
        raise RuntimeError(f'No valid slice correlation found for {moving_file}')

    stem = Path(moving_file).stem
    output_path = Path(output_dir) / f'{stem}.tiff'
    transform_path = Path(transform_dir) / f'{stem}_transform.txt'

    # The transform is estimated from the filtered session image, but applied to
    # the original session image so the saved image preserves the actual data.
    best_result_image, best_result_array = apply_transform_array(moving_array_original, best_transform_map)
    sitk.WriteImage(best_result_image, str(output_path))
    sitk.WriteParameterFile(best_transform_map, str(transform_path))

    return {
        'file': str(moving_file),
        'output_path': str(output_path),
        'transform_path': str(transform_path),
        'best_slice_idx_python': best_slice_idx,
        'best_slice_idx_matlab': best_slice_idx + 1,
        'best_corr': best_corr,
        'slice_corrs': slice_corrs,
        'best_result_array': best_result_array,
    }


def register_all_recordings(base_dir='.'):
    base_dir = Path(base_dir).resolve()
    fixed_image_path = base_dir / 'refImg.mat'
    moving_images_dir = base_dir / 'rawElastix'
    registered_images_dir = base_dir / 'alignedElastix'
    transform_params_dir = base_dir / 'alignedElastix_param'
    refstack_dir = base_dir / 'refStack'

    registered_images_dir.mkdir(parents=True, exist_ok=True)
    transform_params_dir.mkdir(parents=True, exist_ok=True)

    log(f'Base directory: {base_dir}')
    log(f'Fixed ref image: {fixed_image_path}')
    log(f'Moving image folder: {moving_images_dir}')
    log(f'RefStack folder: {refstack_dir}')
    log(f'Aligned output folder: {registered_images_dir}')
    log(f'Transform output folder: {transform_params_dir}')

    ref_img = load_mat_image(fixed_image_path, 'ref')
    h5_path, refstack_movie = load_refstack_h5(refstack_dir, ref_img.shape)
    mean_stack = mean_refstack_slices(refstack_movie)
    mean_stack_filtered = median_filter_stack(mean_stack, size=3)
    mean_stack_enhanced = enhance_stack(mean_stack_filtered)
    log('Using 3x3 median-filtered + enhanced refStack mean slices for refImg alignment and depth-matched registration.')
    stack_alignment = align_refstack_to_refimg(ref_img, mean_stack_enhanced, refstack_dir)
    aligned_stack = stack_alignment['aligned_stack']
    debug_mat_path = save_refstack_debug(
        refstack_dir,
        h5_path,
        mean_stack,
        mean_stack_filtered,
        mean_stack_enhanced,
        stack_alignment,
    )

    moving_files = sorted(moving_images_dir.glob('*.mat'), key=session_sort_key)
    if not moving_files:
        raise RuntimeError(f'No moving .mat files found under {moving_images_dir}')

    log(f'Starting depth-matched rigid registration for {len(moving_files)} image(s).')
    best_slice_matlab = np.zeros((len(moving_files), 1), dtype=np.float64)
    best_corr = np.full((len(moving_files), 1), np.nan, dtype=np.float64)
    all_slice_corrs = np.full((len(moving_files), N_SLICES), np.nan, dtype=np.float64)
    output_files = []
    transform_files = []
    skipped_files = []

    for file_idx, moving_file in enumerate(moving_files):
        log('=' * 80)
        log(f'Processing {file_idx + 1}/{len(moving_files)}: {moving_file.name}')
        try:
            result = register_recording_to_best_depth(
                moving_file,
                aligned_stack,
                registered_images_dir,
                transform_params_dir,
            )
            best_slice_matlab[file_idx, 0] = result['best_slice_idx_matlab']
            best_corr[file_idx, 0] = result['best_corr']
            all_slice_corrs[file_idx, :] = result['slice_corrs']
            output_files.append(result['output_path'])
            transform_files.append(result['transform_path'])
            log(
                f"Saved best registration: slice {result['best_slice_idx_matlab']:03d}, "
                f"corr={result['best_corr']:.4f}, output={result['output_path']}"
            )
        except Exception as exc:
            skipped_files.append(str(moving_file))
            output_files.append('')
            transform_files.append('')
            log(f'{moving_file} not done! ({exc})')

    summary_path = transform_params_dir / 'depth_matched_registration_summary.mat'
    scipy.io.savemat(
        summary_path,
        {
            'movingFiles': matlab_cellstr([str(p) for p in moving_files]),
            'outputFiles': matlab_cellstr(output_files),
            'transformFiles': matlab_cellstr(transform_files),
            'skippedFiles': matlab_cellstr(skipped_files),
            'bestSliceIdx': best_slice_matlab,
            'bestCorr': best_corr,
            'allSliceCorrs': all_slice_corrs,
            'refStackDebugMat': str(debug_mat_path),
        },
        do_compression=True,
    )

    log('=' * 80)
    log(f'Depth-matched registration complete. Saved {len(moving_files) - len(skipped_files)}; skipped {len(skipped_files)}.')
    log(f'Summary saved to: {summary_path}')


if __name__ == '__main__':
    register_all_recordings('.')
