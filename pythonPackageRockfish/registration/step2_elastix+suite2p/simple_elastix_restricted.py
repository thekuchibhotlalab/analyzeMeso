import os
import re
from pathlib import Path

import SimpleITK as sitk
import numpy as np
import scipy.io
import scipy.ndimage as ndimage

# Two-stage restricted cross-session elastix alignment.
#
# Stage 1:
#   Use only the center crop of fixed/moving images to estimate a rigid transform.
#   This stabilizes the rotation estimate when the edge/FOV has bad mismatch.
#
# Stage 2:
#   Use the stage-1 rigid transform as the initial transform, then estimate only
#   an additional translation on the full image.
#
# Output:
#   The final *_transform.txt is the entry-point transform file. It points to the
#   saved *_rigid_center_transform.txt through InitialTransformParametersFileName,
#   matching the native Elastix multi-stage transform format.

CENTER_CROP_FRACTION = float(os.environ.get('ELASTIX_CENTER_CROP_FRACTION', '0.60'))
MAX_ROTATION_DEG = float(os.environ.get('ELASTIX_MAX_ROTATION_DEG', '5'))
MAX_ITERATIONS = os.environ.get('ELASTIX_MAX_ITERATIONS', '128')
NUMBER_OF_RESOLUTIONS = os.environ.get('ELASTIX_NUMBER_OF_RESOLUTIONS', '3')
NUMBER_OF_SPATIAL_SAMPLES = os.environ.get('ELASTIX_NUMBER_OF_SPATIAL_SAMPLES', '2048')
MEDIAN_FILTER_SIZE = int(os.environ.get('ELASTIX_MEDIAN_FILTER_SIZE', '3'))


def log(message):
    print(message, flush=True)


def session_sort_key(path):
    name = Path(path).name
    match = re.search(r'session(\d+)', name)
    if match:
        return int(match.group(1))
    return name


def get_parameter_map(transform_name):
    parameter_map = sitk.GetDefaultParameterMap(transform_name)
    parameter_map['WriteResultImage'] = ['true']
    parameter_map['ResultImageFormat'] = ['tiff']
    parameter_map['MaximumNumberOfIterations'] = [MAX_ITERATIONS]
    parameter_map['NumberOfResolutions'] = [NUMBER_OF_RESOLUTIONS]
    parameter_map['ImageSampler'] = ['RandomCoordinate']
    parameter_map['NumberOfSpatialSamples'] = [NUMBER_OF_SPATIAL_SAMPLES]
    parameter_map['NewSamplesEveryIteration'] = ['true']
    return parameter_map


def set_output_geometry(parameter_map, reference_image):
    parameter_map['Size'] = [str(v) for v in reference_image.GetSize()]
    parameter_map['Spacing'] = [f'{v:.12g}' for v in reference_image.GetSpacing()]
    parameter_map['Origin'] = [f'{v:.12g}' for v in reference_image.GetOrigin()]
    parameter_map['Direction'] = [f'{v:.12g}' for v in reference_image.GetDirection()]
    parameter_map['Index'] = ['0'] * reference_image.GetDimension()
    return parameter_map


def center_crop(image, crop_fraction):
    if not (0 < crop_fraction <= 1):
        raise ValueError(f'ELASTIX_CENTER_CROP_FRACTION must be in (0, 1], got {crop_fraction}.')

    size = list(image.GetSize())
    crop_size = [max(8, int(round(s * crop_fraction))) for s in size]
    crop_size = [min(c, s) for c, s in zip(crop_size, size)]
    crop_index = [(s - c) // 2 for s, c in zip(size, crop_size)]
    return sitk.RegionOfInterest(image, crop_size, crop_index)


def median_filter_array(image_array):
    if MEDIAN_FILTER_SIZE <= 1:
        return np.asarray(image_array, dtype=np.float32)
    return ndimage.median_filter(
        np.asarray(image_array, dtype=np.float32),
        size=(MEDIAN_FILTER_SIZE, MEDIAN_FILTER_SIZE),
        mode='nearest',
    )


def run_elastix(fixed_image, moving_image, transform_name, initial_transform_file=None):
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(fixed_image)
    elastix.SetMovingImage(moving_image)
    elastix.SetParameterMap(get_parameter_map(transform_name))
    log(f'Using elastix transform: {transform_name}')
    log(
        'Elastix budget: '
        f'resolutions={NUMBER_OF_RESOLUTIONS}, '
        f'iterations={MAX_ITERATIONS}, '
        f'samples={NUMBER_OF_SPATIAL_SAMPLES}'
    )
    if initial_transform_file is not None:
        initial_transform_file = Path(initial_transform_file).resolve()
        log(f'Using initial transform file: {initial_transform_file}')
        elastix.SetInitialTransformParameterFileName(str(initial_transform_file))
    elastix.Execute()
    log(f'Finished elastix transform: {transform_name}')
    return elastix


def apply_transform(moving_image, transform_parameter_map):
    log('Applying transform with transformix...')
    transformix = sitk.TransformixImageFilter()
    transformix.SetMovingImage(moving_image)
    transformix.SetTransformParameterMap(transform_parameter_map)
    transformix.LogToConsoleOff()
    transformix.LogToFileOff()
    transformix.Execute()
    log('Finished transformix apply.')
    return transformix.GetResultImage()


def write_image_checked(image, output_path, label):
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    log(f'Saving {label}: {output_path}')
    sitk.WriteImage(image, str(output_path))
    if not output_path.is_file():
        raise RuntimeError(f'WriteImage reported no error, but file was not created: {output_path}')
    log(f'Saved {label}: {output_path} ({output_path.stat().st_size} bytes)')


def rigid_rotation_deg(transform_parameter_map):
    try:
        transform_name = str(transform_parameter_map['Transform'][0])
        log(f'Rigid transform type returned by elastix: {transform_name}')
        if 'EulerTransform' not in transform_name:
            return None
        transform_parameters = transform_parameter_map['TransformParameters']
        log(f'Rigid transform parameters returned by elastix: {list(transform_parameters)}')
        angle_rad = float(transform_parameters[0])
        return float(np.degrees(angle_rad))
    except Exception as exc:
        log(f'Could not parse rigid rotation from elastix parameter map: {exc}')
        return None


def register_one_image(
    fixed_image_original,
    fixed_image_filtered,
    moving_image_original,
    moving_image_filtered,
    moving_image_file,
    registered_images_dir,
    transform_params_dir,
):
    stem = Path(moving_image_file).stem
    rigid_transform_file = Path(transform_params_dir) / f'{stem}_rigid_center_transform.txt'
    final_transform_file = Path(transform_params_dir) / f'{stem}_transform.txt'
    registered_image_path = Path(registered_images_dir) / f'{stem}.tiff'

    log('=' * 80)
    log(f'Processing moving image: {moving_image_file}')
    log(f'Output image will be: {registered_image_path}')
    log(f'Rigid transform will be: {rigid_transform_file}')
    log(f'Final transform will be: {final_transform_file}')
    log(f'Full image size: fixed={fixed_image_original.GetSize()}, moving={moving_image_original.GetSize()}')
    log(f'Using temporary {MEDIAN_FILTER_SIZE}x{MEDIAN_FILTER_SIZE} median-filtered images for registration.')

    fixed_crop = center_crop(fixed_image_filtered, CENTER_CROP_FRACTION)
    moving_crop = center_crop(moving_image_filtered, CENTER_CROP_FRACTION)
    log(f'Center crop fraction: {CENTER_CROP_FRACTION:.3f}')
    log(f'Center crop size: fixed={fixed_crop.GetSize()}, moving={moving_crop.GetSize()}')

    log('Starting stage 1: center-crop rigid registration...')
    rigid_elastix = run_elastix(fixed_crop, moving_crop, 'rigid')
    rigid_map = rigid_elastix.GetTransformParameterMap()[0]
    rotation_deg = rigid_rotation_deg(rigid_map)

    if rotation_deg is None:
        log(
            f'WARNING: could not parse center-crop rigid rotation for {moving_image_file}. '
            'Continuing and saving the registration anyway.'
        )
    else:
        log(f'Center-crop rigid rotation estimate: {rotation_deg:.3f} deg')
        if abs(rotation_deg) > MAX_ROTATION_DEG:
            log(
                f'WARNING: center-crop rigid rotation {rotation_deg:.3f} deg exceeds '
                f'ELASTIX_MAX_ROTATION_DEG={MAX_ROTATION_DEG:.3f}. '
                'Continuing and saving the registration anyway.'
            )

    rigid_map = set_output_geometry(rigid_map, fixed_image_original)
    log(f'Saving center-crop rigid transform: {rigid_transform_file}')
    sitk.WriteParameterFile(rigid_map, str(rigid_transform_file))

    log('Starting stage 2: full-image translation registration with rigid transform as initialization...')
    translation_elastix = run_elastix(
        fixed_image_filtered,
        moving_image_filtered,
        'translation',
        initial_transform_file=rigid_transform_file,
    )
    translation_map = translation_elastix.GetTransformParameterMap()[0]
    translation_map = set_output_geometry(translation_map, fixed_image_original)
    translation_map['InitialTransformParametersFileName'] = [str(rigid_transform_file.resolve())]

    log(f'Saving final chained transform: {final_transform_file}')
    sitk.WriteParameterFile(translation_map, str(final_transform_file))
    if not final_transform_file.is_file():
        raise RuntimeError(f'Could not create final transform file: {final_transform_file}')

    # Always save the direct filtered registration result first. This guarantees
    # that a completed elastix registration leaves an inspectable TIFF even if
    # applying the transform to the original image fails.
    filtered_result_image = translation_elastix.GetResultImage()
    write_image_checked(filtered_result_image, registered_image_path, 'filtered-registration fallback image')

    try:
        log('Applying filtered-estimated transform to original unfiltered moving image for final saving...')
        result_image = apply_transform(moving_image_original, translation_map)
        write_image_checked(result_image, registered_image_path, 'unfiltered original image transformed with filtered-estimated transform')
    except Exception as exc:
        log(
            f'WARNING: could not apply transform to original unfiltered image for {moving_image_file}: {exc}. '
            f'Keeping filtered-registration fallback image at {registered_image_path}.'
        )

    log(f'Rigid center transform saved to {rigid_transform_file}')
    log(f'Final chained transform saved to {final_transform_file}')
    log(f'Registered {moving_image_file} and saved to {registered_image_path}')


def register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir):
    fixed_image_path = Path(fixed_image_path).resolve()
    moving_images_dir = Path(moving_images_dir).resolve()
    registered_images_dir = Path(registered_images_dir).resolve()
    transform_params_dir = Path(transform_params_dir).resolve()

    if not fixed_image_path.is_file():
        raise FileNotFoundError(f'Fixed image file not found: {fixed_image_path}')
    if not moving_images_dir.is_dir():
        raise FileNotFoundError(f'Moving image folder not found: {moving_images_dir}')

    registered_images_dir.mkdir(parents=True, exist_ok=True)
    transform_params_dir.mkdir(parents=True, exist_ok=True)

    log(f'Working directory: {Path.cwd().resolve()}')
    log(f'Fixed image file: {fixed_image_path}')
    log(f'Moving image folder: {moving_images_dir}')
    log(f'Registered image output folder: {registered_images_dir}')
    log(f'Transform parameter output folder: {transform_params_dir}')

    fixed_mat = scipy.io.loadmat(fixed_image_path)
    fixed_image_array = fixed_mat['ref'].astype(np.float32)
    fixed_image_filtered_array = median_filter_array(fixed_image_array)
    fixed_image = sitk.GetImageFromArray(fixed_image_array)
    fixed_image_filtered = sitk.GetImageFromArray(fixed_image_filtered_array)
    log(f'Using temporary {MEDIAN_FILTER_SIZE}x{MEDIAN_FILTER_SIZE} median filter for refImg and session images.')

    moving_image_files = sorted(
        [
            moving_images_dir / f
            for f in os.listdir(moving_images_dir)
            if f.endswith('.mat')
        ],
        key=session_sort_key,
    )
    log(f'Found {len(moving_image_files)} moving image file(s).')
    for idx, moving_image_file in enumerate(moving_image_files):
        log(f'  {idx + 1:03d}: {moving_image_file}')

    saved_count = 0
    skipped_count = 0
    for idx, moving_image_file in enumerate(moving_image_files):
        log(f'Starting file {idx + 1}/{len(moving_image_files)}: {moving_image_file}')
        moving_mat = scipy.io.loadmat(moving_image_file)
        moving_image_array = moving_mat['meanImg'].astype(np.float32)
        moving_image_filtered_array = median_filter_array(moving_image_array)
        moving_image = sitk.GetImageFromArray(moving_image_array)
        moving_image_filtered = sitk.GetImageFromArray(moving_image_filtered_array)

        try:
            register_one_image(
                fixed_image,
                fixed_image_filtered,
                moving_image,
                moving_image_filtered,
                moving_image_file,
                registered_images_dir,
                transform_params_dir,
            )
            saved_count += 1
        except Exception as exc:
            skipped_count += 1
            log(f'{moving_image_file} not done! ({exc})')

    saved_tiffs = sorted(registered_images_dir.glob('*.tif*'))
    saved_txts = sorted(transform_params_dir.glob('*_transform.txt'))
    log('=' * 80)
    log(f'Registration summary: saved={saved_count}, skipped={skipped_count}')
    log(f'TIFF files currently in output folder: {len(saved_tiffs)}')
    log(f'Transform txt files currently in output folder: {len(saved_txts)}')
    if saved_tiffs:
        log(f'First saved TIFF: {saved_tiffs[0]}')
        log(f'Last saved TIFF: {saved_tiffs[-1]}')


fixed_image_path = 'refImg.mat'
moving_images_dir = 'rawElastix/'
registered_images_dir = 'alignedElastix/'
transform_params_dir = 'alignedElastix_param/'

register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir)
