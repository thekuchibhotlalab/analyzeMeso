function [dataChunk, fileInfo] = fn_readh5(filename, datasetPath, startFrame, numFrames)
% Reads a specific chunk of frames from a large H5 dataset.
%
% This function is designed to safely read subsets of data from very large
% HDF5 files without loading the entire file into memory, which prevents
% crashes due to insufficient RAM.
%
% INPUTS:
%   filename      - (string) Full path to the HDF5 file.
%   datasetPath   - (string) The path to the dataset within the H5 file
%                   (e.g., '/data').
%   startFrame    - (scalar) The 1-based index of the first frame to read.
%   numFrames     - (scalar) The number of frames to read starting from
%                   startFrame. Use Inf to read all frames until the end.
%
% OUTPUTS:
%   dataChunk     - The subset of the data read from the file. Its size
%                   will be [height, width, numFramesRead].
%   fileInfo      - (struct) The metadata for the dataset, as returned by
%                   h5info. Useful for getting total dimensions.
%
% EXAMPLE USAGE:
%   % Read frames 1001 to 1200 from a file
%   filename = 'my_large_data.h5';
%   [frames_1001_to_1200, info] = readh5_chunk(filename, '/data', 1001, 200);
%
%   % Read all frames from 5000 to the end of the file
%   [last_frames] = readh5_chunk(filename, '/data', 5000, Inf);

% --- Input Validation ---
if ~exist(filename, 'file')
    error('File not found: %s', filename);
end

if ~exist('numFrames'); numFrames = Inf; end 
if ~exist('startFrame'); startFrame = 1; end 


% --- Get File Metadata ---
try
    fileInfo = h5info(filename, datasetPath);
catch ME
    error('Could not read dataset info. Check dataset path: "%s".\nOriginal error: %s', datasetPath, ME.message);
end

totalFrames = fileInfo.Dataspace.Size(3);
fullHeight = fileInfo.Dataspace.Size(1);
fullWidth = fileInfo.Dataspace.Size(2);

% --- Validate Requested Frame Range ---
if startFrame > totalFrames
    error('startFrame (%d) is greater than the total number of frames in the file (%d).', startFrame, totalFrames);
end

% Handle the 'Inf' case for numFrames, which means "read to the end"
if isinf(numFrames)
    numFramesToRead = totalFrames - startFrame + 1;
else
    numFramesToRead = numFrames;
end

% Ensure we don't try to read past the end of the file
if (startFrame + numFramesToRead - 1) > totalFrames
    warning('Requested range exceeds file dimensions. Reading only until the last frame.');
    numFramesToRead = totalFrames - startFrame + 1;
end

if numFramesToRead <= 0
    dataChunk = []; % Return empty if no frames are requested or possible
    return;
end

% --- Core Read Operation ---
% Define the starting coordinate and the amount of data to read
start = [1, 1, startFrame];
count = [fullHeight, fullWidth, numFramesToRead];

fprintf('Reading %d frames from %s...\n', numFramesToRead, filename);

% Read the hyperslab (the data chunk) using the start and count parameters
dataChunk = h5read(filename, datasetPath, start, count);

fprintf('Read complete. Size of loaded data: %d x %d x %d\n', size(dataChunk));

end
