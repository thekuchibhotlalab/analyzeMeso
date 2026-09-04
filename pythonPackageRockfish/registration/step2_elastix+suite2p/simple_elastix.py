import SimpleITK as sitk
import scipy.io
import os


def get_affine_parameter_map():
    parameter_map = sitk.GetDefaultParameterMap('affine')
    parameter_map['WriteResultImage'] = ['true']
    parameter_map['ResultImageFormat'] = ['tiff']
    return parameter_map


def run_elastix(fixed_image, moving_image):
    elastix = sitk.ElastixImageFilter()
    elastix.SetFixedImage(fixed_image)
    elastix.SetMovingImage(moving_image)
    elastix.SetParameterMap(get_affine_parameter_map())
    print("Using elastix transform: affine")
    elastix.Execute()
    return elastix


def register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir):

    # Load the fixed image from a MAT file
    fixed_mat = scipy.io.loadmat(fixed_image_path)
    fixed_image_array = fixed_mat['ref']  # Replace with the actual variable name in the MAT file
    fixed_image = sitk.GetImageFromArray(fixed_image_array)

    # Get a list of moving image file paths
    moving_image_files = [os.path.join(moving_images_dir, f) for f in os.listdir(moving_images_dir) if f.endswith('.mat')]

    # Create a directory to save registered images
    # Create a directory to save registered images and transformation parameters
    
    #os.makedirs(registered_images_dir, exist_ok=True)
    #os.makedirs(transform_params_dir, exist_ok=True)

    # Loop through each moving image and perform registration
    for moving_image_file in moving_image_files:
        # Load the moving image from a MAT file
        moving_mat = scipy.io.loadmat(moving_image_file)
        moving_image_array = moving_mat['meanImg']  # Replace with the actual variable name in the MAT file
        moving_image = sitk.GetImageFromArray(moving_image_array)

        elastix = run_elastix(fixed_image, moving_image)
        transform_parameter_map = elastix.GetTransformParameterMap()

        # Get the result image
        result_image = elastix.GetResultImage()

        # Save the registered image
        registered_image_path = os.path.join(registered_images_dir, os.path.basename(moving_image_file).replace('.mat', '.tiff'))
        sitk.WriteImage(result_image, registered_image_path)
        
        # Save the transformation parameters used for the final registered image
        transform_param_file = os.path.join(transform_params_dir, os.path.basename(moving_image_file).replace('.mat', '_transform.txt'))
        sitk.WriteParameterFile(transform_parameter_map[0], transform_param_file)

        print(f'Transformation parameters saved to {transform_param_file}')
        print(f'Registered {moving_image_file} and saved to {registered_image_path}')


# Define paths to your fixed image and the directory containing the moving images
fixed_image_path = 'refImg.mat'
moving_images_dir = 'rawElastix/'
registered_images_dir = 'alignedElastix/'
transform_params_dir = 'alignedElastix_param/'

register_images(fixed_image_path, moving_images_dir, registered_images_dir, transform_params_dir)
