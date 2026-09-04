import os
import re
from pathlib import Path

import numpy as np
import scipy.io
import scipy.ndimage as ndimage
import SimpleITK as sitk

MEDIAN_FILTER_SIZE = int(os.environ.get('ELASTIX_MEDIAN_FILTER_SIZE', '3'))
DIRECT_REF_CORR_THRESHOLD = float(os.environ.get('ELASTIX_DIRECT_REF_CORR_THRESHOLD', '0.2'))


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
        raise ValueError(f'Image size mismatch for correlation: {a.shape} vs {b.shape}')

    mask = np.isfinite(a) & np.isfinite(b)
    if np.count_nonzero(mask) < 2:
        return np.nan

    a = a[mask].ravel()
    b = b[mask].ravel()
    a = a - np.mean(a)
    b = b - np.mean(b)
    denom = np.sqrt(np.sum(a * a) * np.sum(b * b))
    if denom == 0:
        return np.nan
    return float(np.sum(a * b) / denom)


def median_filter_image(image_array):
    image_array = np.asarray(image_array, dtype=np.float32)
    if MEDIAN_FILTER_SIZE <= 1:
        return image_array
    return ndimage.median_filter(
        image_array,
        size=(MEDIAN_FILTER_SIZE, MEDIAN_FILTER_SIZE),
        mode='nearest',
    ).astype(np.float32)


def load_mat_image(path, variable_name):
    mat = scipy.io.loadmat(path)
    if variable_name not in mat:
        raise KeyError(f'Could not find variable {variable_name!r} in {path}')
    return np.asarray(mat[variable_name], dtype=np.float32)


def get_rigid_parameter_map():
    parameter_map = sitk.GetDefaultParameterMap('affine')
    parameter_map['WriteResultImage'] = ['true']
    parameter_map['ResultImageFormat'] = ['tiff']
    return parameter_map


def run_rigid_elastix(fixed_image, moving_image):
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(fixed_image)
    elastix.SetMovingImage(moving_image)
    elastix.SetParameterMap(get_rigid_parameter_map())
    elastix.LogToConsoleOff()
    elastix.LogToFileOff()
    elastix.Execute()
    return elastix


def apply_transform_to_raw(raw_moving_array, transform_parameter_map):
    transformix = sitk.TransformixImageFilter()
    transformix.SetMovingImage(sitk.GetImageFromArray(raw_moving_array.astype(np.float32)))
    transformix.SetTransformParameterMap(transform_parameter_map)
    transformix.LogToConsoleOff()
    transformix.LogToFileOff()
    transformix.Execute()
    return transformix.GetResultImage()


def compute_initial_corr_matrix(ref_array, moving_arrays, labels):
    all_arrays = [ref_array] + moving_arrays
    n_images = len(all_arrays)
    corr_matrix = np.full((n_images, n_images), np.nan, dtype=np.float64)

    for i in range(n_images):
        corr_matrix[i, i] = 1.0
        for j in range(i + 1, n_images):
            corr = image_corr(all_arrays[i], all_arrays[j])
            corr_matrix[i, j] = corr
            corr_matrix[j, i] = corr

    return corr_matrix


def as_matlab_cellstr(strings):
    arr = np.empty((len(strings), 1), dtype=object)
    for idx, value in enumerate(strings):
        arr[idx, 0] = str(value)
    return arr


def register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir):
    fixed_image_path = Path(fixed_image_path).resolve()
    moving_images_dir = Path(moving_images_dir).resolve()
    registered_images_dir = Path(registered_images_dir).resolve()
    transform_params_dir = Path(transform_params_dir).resolve()

    registered_images_dir.mkdir(parents=True, exist_ok=True)
    transform_params_dir.mkdir(parents=True, exist_ok=True)

    log(f'Working directory: {Path.cwd().resolve()}')
    log(f'Fixed image file: {fixed_image_path}')
    log(f'Moving image folder: {moving_images_dir}')
    log(f'Registered image output folder: {registered_images_dir}')
    log(f'Transform parameter output folder: {transform_params_dir}')
    log(f'Median filter size for correlation/registration only: {MEDIAN_FILTER_SIZE}x{MEDIAN_FILTER_SIZE}')
    log(f'Direct refImg alignment threshold: corr_to_refImg > {DIRECT_REF_CORR_THRESHOLD:.3f}')

    ref_array_raw = load_mat_image(fixed_image_path, 'ref')
    ref_array_filtered = median_filter_image(ref_array_raw)
    ref_image_filtered = sitk.GetImageFromArray(ref_array_filtered)

    moving_files = sorted(moving_images_dir.glob('*.mat'), key=session_sort_key)
    if not moving_files:
        raise RuntimeError(f'No .mat moving images found in {moving_images_dir}')

    log(f'Loading {len(moving_files)} moving image(s)...')
    moving_arrays_raw = [load_mat_image(path, 'meanImg') for path in moving_files]
    moving_arrays_filtered = [median_filter_image(img) for img in moving_arrays_raw]
    labels = ['refImg'] + [path.stem for path in moving_files]
    corr_matrix = compute_initial_corr_matrix(ref_array_filtered, moving_arrays_filtered, labels)

    order_indices = []
    selected_corrs = []
    corr_after_filtered = []
    reference_modes = []
    reference_indices = []
    reference_files = []
    reference_correlations = []
    saved_files = []
    skipped_files = []
    registered_filtered_arrays = {}

    corr_to_ref = corr_matrix[0, 1:]
    sorted_indices = sorted(
        range(len(moving_files)),
        key=lambda idx: (-np.inf if np.isnan(corr_to_ref[idx]) else corr_to_ref[idx]),
        reverse=True,
    )

    log('Registration order: sessions sorted once by correlation to original refImg.')
    for order_idx, selected_idx in enumerate(sorted_indices):
        log(
            f'  {order_idx + 1:03d}: {moving_files[selected_idx].name} | '
            f'corr_to_refImg={corr_to_ref[selected_idx]:.6f}'
        )
    log('Registration order compact:')
    log(' -> '.join(moving_files[idx].stem for idx in sorted_indices))

    log('Starting fixed-order correlation-chain rigid registration.')
    for order_idx, selected_idx in enumerate(sorted_indices):
        corr = corr_to_ref[selected_idx]
        moving_file = moving_files[selected_idx]
        moving_array_raw = moving_arrays_raw[selected_idx]
        moving_array_filtered = moving_arrays_filtered[selected_idx]
        stem = moving_file.stem
        output_image_path = registered_images_dir / f'{stem}.tiff'
        transform_file_path = transform_params_dir / f'{stem}_transform.txt'

        if corr > DIRECT_REF_CORR_THRESHOLD or not registered_filtered_arrays:
            reference_mode = 'refImg'
            reference_idx = 0
            reference_file = 'refImg'
            reference_corr = corr
            fixed_array_filtered = ref_array_filtered
            fixed_image_filtered = ref_image_filtered
        else:
            candidates = []
            for registered_idx in registered_filtered_arrays:
                candidate_corr = corr_matrix[registered_idx + 1, selected_idx + 1]
                candidates.append((candidate_corr, registered_idx))
            candidates.sort(
                key=lambda item: (-np.inf if np.isnan(item[0]) else item[0]),
                reverse=True,
            )
            reference_corr, reference_idx = candidates[0]
            reference_mode = 'reEstablished'
            reference_file = moving_files[reference_idx].name
            fixed_array_filtered = registered_filtered_arrays[reference_idx]
            fixed_image_filtered = sitk.GetImageFromArray(fixed_array_filtered)

        log('=' * 80)
        log(f'Processing chain item {order_idx + 1}/{len(sorted_indices)}: {moving_file.name}')
        log(f'corr_to_refImg={corr:.6f}')
        if reference_mode == 'refImg':
            log(f'Alignment reference: refImg directly | corr_to_refImg={reference_corr:.6f}')
        else:
            log(
                f'Alignment reference re-established: {reference_file} '
                f'| precomputed corr(current, reference)={reference_corr:.6f}'
            )
        log(f'Output image: {output_image_path}')
        log(f'Transform txt: {transform_file_path}')

        try:
            moving_image_filtered = sitk.GetImageFromArray(moving_array_filtered)
            elastix = run_rigid_elastix(fixed_image_filtered, moving_image_filtered)
            transform_parameter_map = elastix.GetTransformParameterMap()[0]
            filtered_result_image = elastix.GetResultImage()
            filtered_result_array = sitk.GetArrayFromImage(filtered_result_image).astype(np.float32)
            after_corr = image_corr(fixed_array_filtered, filtered_result_array)

            raw_result_image = apply_transform_to_raw(moving_array_raw, transform_parameter_map)

            sitk.WriteImage(raw_result_image, str(output_image_path))
            sitk.WriteParameterFile(transform_parameter_map, str(transform_file_path))

            registered_filtered_arrays[selected_idx] = filtered_result_array
            order_indices.append(selected_idx + 1)
            selected_corrs.append(corr)
            corr_after_filtered.append(after_corr)
            reference_modes.append(reference_mode)
            reference_indices.append(reference_idx)
            reference_files.append(reference_file)
            reference_correlations.append(reference_corr)
            saved_files.append(str(output_image_path))
            log(f'Saved registered image: {output_image_path}')
            log(f'Saved transform file: {transform_file_path}')
            log(
                f'Filtered corr to selected reference: '
                f'before={reference_corr:.6f}, after={after_corr:.6f}'
            )
        except Exception as exc:
            skipped_files.append(str(moving_file))
            log(f'{moving_file} not done! ({exc})')

    order_path = transform_params_dir / 'correlation_chain_order.mat'
    scipy.io.savemat(
        order_path,
        {
            'labels': as_matlab_cellstr(labels),
            'initialCorrMatrix': corr_matrix,
            'orderIndices': np.asarray(order_indices, dtype=np.float64).reshape(-1, 1),
            'orderFiles': as_matlab_cellstr([moving_files[idx - 1].name for idx in order_indices]),
            'selectedCorrelations': np.asarray(selected_corrs, dtype=np.float64).reshape(-1, 1),
            'corrAfterFilteredRegistration': np.asarray(corr_after_filtered, dtype=np.float64).reshape(-1, 1),
            'referenceMode': as_matlab_cellstr(reference_modes),
            'referenceIndices': np.asarray(reference_indices, dtype=np.float64).reshape(-1, 1),
            'referenceFiles': as_matlab_cellstr(reference_files),
            'referenceCorrelations': np.asarray(reference_correlations, dtype=np.float64).reshape(-1, 1),
            'savedFiles': as_matlab_cellstr(saved_files),
            'skippedFiles': as_matlab_cellstr(skipped_files),
            'medianFilterSize': np.array([[MEDIAN_FILTER_SIZE]], dtype=np.float64),
            'directRefCorrThreshold': np.array([[DIRECT_REF_CORR_THRESHOLD]], dtype=np.float64),
        },
    )

    log('=' * 80)
    log(f'Finished correlation-chain rigid registration.')
    log(f'Saved images: {len(saved_files)}')
    log(f'Skipped images: {len(skipped_files)}')
    log(f'Chain diagnostics saved to: {order_path}')


fixed_image_path = 'refImg.mat'
moving_images_dir = 'rawElastix/'
registered_images_dir = 'alignedElastix/'
transform_params_dir = 'alignedElastix_param/'

register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir)
