function fn_splitSuite2pSessionImg(parentFolder, saveFolder)
    % Process Suite2p binary files in subfolders of `parentFolder` under `suite2p/plane0/`.
    % Calculate mean images for each session and save them as .mat files in `saveFolder`.
    %
    % Args:
    %   parentFolder - Path to the folder containing subfolders with Suite2p data.
    %   saveFolder - Path to the folder where .mat files will be saved.

    % Get list of subfolders in the parent folder
    folderList = dir(parentFolder);
    folderList = folderList([folderList.isdir]);  % Keep only directories
    folderList = folderList(~ismember({folderList.name}, {'.', '..'}));  % Exclude '.' and '..'

    % Ensure save folder exists
    if ~exist(saveFolder, 'dir')
        mkdir(saveFolder);
    end
    allSession = 0;
    % Loop through each folder
    for iFolder = 1:length(folderList)
        disp(['Current folder:' folderList(iFolder).name])
        currentFolder = fullfile(parentFolder, folderList(iFolder).name);
        suite2pPath = fullfile(currentFolder, 'suite2p', 'plane0');

        % Skip folders without 'suite2p/plane0/'
        if ~exist(suite2pPath, 'dir')
            fprintf('Skipping folder: %s (no suite2p/plane0 found)\n', currentFolder);
            continue;
        end

        % Locate .bin file and ops.npy
        binFile = dir(fullfile(suite2pPath, '*.bin'));
        opsFile = fullfile(suite2pPath, 'Fall.mat');

        if isempty(binFile) || ~isfile(opsFile)
            fprintf('Skipping folder: %s (no .bin or ops.npy found)\n', suite2pPath);
            continue;
        end

        % Load ops.npy
        ops = load(opsFile,'ops');
        ops = ops.ops; 

        % Extract frame information
        nframes_per_folder = ops.nframes_per_folder;
        filelist = ops.filelist;
        frameStarts = double([0; cumsum(nframes_per_folder(:))]);  % Compute start frames for each session
        disp(nframes_per_folder)
        % Dimensions of the image
        Lx = ops.Lx;
        Ly = ops.Ly;
        frameSize = double(Lx * Ly);

        % Path to the binary file
        binFilePath = fullfile(suite2pPath, binFile(1).name);
        fid = fopen(binFilePath, 'r');

        % Loop through each session
        for iSession = 1:length(nframes_per_folder)
            allSession = allSession+1;
            startFrame = frameStarts(iSession) + 1;
            nFramesToRead = min(3000, nframes_per_folder(iSession));

            % Seek to the start of the session
            fseek(fid, (startFrame - 1) * frameSize * 2, 'bof');  % *2 for uint16

            % Read the frames for this session
            data = fread(fid, [frameSize, nFramesToRead], 'uint16');
            data = reshape(data, Lx, Ly, nFramesToRead);

            % Compute the mean image
            meanImg = nanmean(data, 3);

            % Save the mean image
            sessionName = filelist(iSession,:);
            saveFilePath = fullfile(saveFolder, sprintf('session%02d.mat', allSession));
            save(saveFilePath, 'meanImg', 'sessionName');
            fprintf('Saved mean image for session %02d: %s\n', allSession, saveFilePath);
        end

        fclose(fid);
    end
end

% Helper function to read .npy files
function data = readNPY(filename)
    % Reads .npy files (from Python) into MATLAB
    data = py.numpy.load(filename).tolist();  % Requires Python with NumPy installed
end
