import os
import re
from pathlib import Path

import numpy as np
import scipy.io
import scipy.ndimage as ndimage
import SimpleITK as sitk


MEDIAN_FILTER_SIZE = int(os.environ.get('ELASTIX_MEDIAN_FILTER_SIZE', '3'))
MAX_ROTATION_DEG = float(os.environ.get('ELASTIX_MAX_ROTATION_DEG', '2'))
TRANSLATION_ONLY_FIRST_N = int(os.environ.get('ELASTIX_TRANSLATION_ONLY_FIRST_N', '50'))


def log(message):
    print(message, flush=True)


def session_sort_key(path):
    match = re.search(r'session(\d+)', Path(path).stem)
    if match:
        return int(match.group(1))
    return Path(path).stem


def median_filter_image(image_array):
    image_array = np.asarray(image_array, dtype=np.float32)
    if MEDIAN_FILTER_SIZE <= 1:
        return image_array
    return ndimage.median_filter(
        image_array,
        size=(MEDIAN_FILTER_SIZE, MEDIAN_FILTER_SIZE),
        mode='nearest',
    ).astype(np.float32)


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


def matlab_cellstr(strings):
    arr = np.empty((len(strings), 1), dtype=object)
    for idx, item in enumerate(strings):
        arr[idx, 0] = str(item)
    return arr


def get_parameter_map(transform_name):
    parameter_map = sitk.GetDefaultParameterMap(transform_name)
    parameter_map['WriteResultImage'] = ['true']
    parameter_map['ResultImageFormat'] = ['tiff']
    return parameter_map


def run_elastix(fixed_filtered_array, moving_filtered_array, transform_name):
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(sitk.GetImageFromArray(fixed_filtered_array.astype(np.float32)))
    elastix.SetMovingImage(sitk.GetImageFromArray(moving_filtered_array.astype(np.float32)))
    elastix.SetParameterMap(get_parameter_map(transform_name))
    elastix.LogToConsoleOff()
    elastix.LogToFileOff()
    elastix.Execute()
    return elastix.GetTransformParameterMap()[0]


def clamp_rigid_angle(transform_map, max_rotation_deg):
    transform_name = str(transform_map['Transform'][0])
    if 'EulerTransform' not in transform_name:
        raise RuntimeError(f'Rigid registration returned unexpected transform: {transform_name}')

    params = [float(x) for x in transform_map['TransformParameters']]
    angle_rad = params[0]
    angle_deg = float(np.degrees(angle_rad))
    clamped_deg = float(np.clip(angle_deg, -max_rotation_deg, max_rotation_deg))

    if clamped_deg != angle_deg:
        log(
            f'Rotation {angle_deg:.3f} deg exceeds +/-{max_rotation_deg:.3f} deg; '
            f'clamping to {clamped_deg:.3f} deg.'
        )
        params[0] = float(np.radians(clamped_deg))
        transform_map['TransformParameters'] = [f'{x:.12g}' for x in params]
    else:
        log(f'Rotation {angle_deg:.3f} deg within +/-{max_rotation_deg:.3f} deg.')

    return transform_map, angle_deg, clamped_deg


def apply_transform_to_raw(raw_moving_array, transform_map):
    transformix = sitk.TransformixImageFilter()
    transformix.SetMovingImage(sitk.GetImageFromArray(raw_moving_array.astype(np.float32)))
    transformix.SetTransformParameterMap(transform_map)
    transformix.LogToConsoleOff()
    transformix.LogToFileOff()
    transformix.Execute()
    return transformix.GetResultImage()


def apply_transform_to_array(moving_array, transform_map):
    result_image = apply_transform_to_raw(moving_array, transform_map)
    return sitk.GetArrayFromImage(result_image).astype(np.float32)


def write_image_checked(image, output_path):
    output_path = Path(output_path)
    sitk.WriteImage(image, str(output_path))
    if not output_path.is_file():
        raise RuntimeError(f'WriteImage did not create output file: {output_path}')
    log(f'Saved image: {output_path} ({output_path.stat().st_size} bytes)')


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
    log(f'Median filter size for registration only: {MEDIAN_FILTER_SIZE}x{MEDIAN_FILTER_SIZE}')
    log(f'Max rigid rotation: +/-{MAX_ROTATION_DEG:.3f} deg')
    log(f'Hard-coded registration mode: first {TRANSLATION_ONLY_FIRST_N} sorted images use translation; later images use rigid.')

    fixed_mat = scipy.io.loadmat(fixed_image_path)
    fixed_raw = np.asarray(fixed_mat['ref'], dtype=np.float32)
    fixed_filtered = median_filter_image(fixed_raw)

    moving_image_files = sorted(moving_images_dir.glob('*.mat'), key=session_sort_key)
    log(f'Found {len(moving_image_files)} moving image file(s).')

    saved_count = 0
    skipped_count = 0
    session_indices = []
    moving_file_names = []
    registration_modes = []
    corr_before = []
    corr_after_filtered = []
    angle_estimated = []
    angle_saved = []
    output_files = []
    transform_files = []
    skipped_files = []

    for idx, moving_image_file in enumerate(moving_image_files):
        stem = moving_image_file.stem
        output_path = registered_images_dir / f'{stem}.tiff'
        transform_path = transform_params_dir / f'{stem}_transform.txt'
        session_index = idx + 1
        transform_name = 'translation' if session_index <= TRANSLATION_ONLY_FIRST_N else 'rigid'

        log('=' * 80)
        log(f'Processing {session_index}/{len(moving_image_files)}: {moving_image_file.name}')
        log(f'Registration mode: {transform_name}')
        log(f'Output image: {output_path}')
        log(f'Transform file: {transform_path}')

        session_indices.append(session_index)
        moving_file_names.append(str(moving_image_file))
        registration_modes.append(transform_name)
        output_files.append(str(output_path))
        transform_files.append(str(transform_path))

        try:
            moving_mat = scipy.io.loadmat(moving_image_file)
            moving_raw = np.asarray(moving_mat['meanImg'], dtype=np.float32)
            moving_filtered = median_filter_image(moving_raw)

            before_corr = image_corr(fixed_filtered, moving_filtered)
            transform_map = run_elastix(fixed_filtered, moving_filtered, transform_name)
            if transform_name == 'rigid':
                transform_map, angle_deg, clamped_deg = clamp_rigid_angle(transform_map, MAX_ROTATION_DEG)
            else:
                angle_deg = np.nan
                clamped_deg = np.nan

            transformed_filtered = apply_transform_to_array(moving_filtered, transform_map)
            after_corr = image_corr(fixed_filtered, transformed_filtered)

            result_image = apply_transform_to_raw(moving_raw, transform_map)
            write_image_checked(result_image, output_path)
            sitk.WriteParameterFile(transform_map, str(transform_path))
            if not transform_path.is_file():
                raise RuntimeError(f'Could not create transform file: {transform_path}')

            corr_before.append(before_corr)
            corr_after_filtered.append(after_corr)
            angle_estimated.append(angle_deg)
            angle_saved.append(clamped_deg)
            log(
                f'Saved transform: {transform_path} | '
                f'corr before={before_corr:.4f}, corr after={after_corr:.4f}, '
                f'estimated angle={angle_deg:.3f}, saved angle={clamped_deg:.3f}'
            )
            saved_count += 1
        except Exception as exc:
            skipped_count += 1
            skipped_files.append(str(moving_image_file))
            corr_before.append(np.nan)
            corr_after_filtered.append(np.nan)
            angle_estimated.append(np.nan)
            angle_saved.append(np.nan)
            log(f'{moving_image_file} not done! ({exc})')

    summary_path = transform_params_dir / 'rigid_filtered_registration_summary.mat'
    scipy.io.savemat(
        summary_path,
        {
            'sessionIndex': np.asarray(session_indices, dtype=np.float64).reshape(-1, 1),
            'movingFiles': matlab_cellstr(moving_file_names),
            'registrationMode': matlab_cellstr(registration_modes),
            'corrBeforeFiltered': np.asarray(corr_before, dtype=np.float64).reshape(-1, 1),
            'corrAfterFiltered': np.asarray(corr_after_filtered, dtype=np.float64).reshape(-1, 1),
            'angleEstimatedDeg': np.asarray(angle_estimated, dtype=np.float64).reshape(-1, 1),
            'angleSavedDeg': np.asarray(angle_saved, dtype=np.float64).reshape(-1, 1),
            'outputFiles': matlab_cellstr(output_files),
            'transformFiles': matlab_cellstr(transform_files),
            'skippedFiles': matlab_cellstr(skipped_files),
            'translationOnlyFirstN': np.array([[TRANSLATION_ONLY_FIRST_N]], dtype=np.float64),
            'medianFilterSize': np.array([[MEDIAN_FILTER_SIZE]], dtype=np.float64),
            'maxRotationDeg': np.array([[MAX_ROTATION_DEG]], dtype=np.float64),
        },
        do_compression=True,
    )

    log('=' * 80)
    log(f'Registration summary: saved={saved_count}, skipped={skipped_count}')
    log(f'Correlation/registration summary saved to: {summary_path}')


fixed_image_path = 'refImg.mat'
moving_images_dir = 'rawElastix/'
registered_images_dir = 'alignedElastix/'
transform_params_dir = 'alignedElastix_param/'

register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir)
