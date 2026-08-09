function fn_organize_h5_bin(masterFolder)
% organizeMesoData Reorganizes .h5 and suite2p .bin files from subfolders.
%
% Input:
%   masterFolder - String path to the master directory containing the N subfolders.

    % Validate input
    if ~isfolder(masterFolder)
        error('Provided path is not a valid directory: %s', masterFolder);
    end

    % Define names and paths for the 3 new target directories
    h5TargetDir = fullfile(masterFolder, 'all_h5_files');
    binTargetDir = fullfile(masterFolder, 'all_data_bin');
    elastixTargetDir = fullfile(masterFolder, 'all_data_elastix_bin');

    % Create the directories if they don't already exist
    if ~isfolder(h5TargetDir); mkdir(h5TargetDir); end
    if ~isfolder(binTargetDir); mkdir(binTargetDir); end
    if ~isfolder(elastixTargetDir); mkdir(elastixTargetDir); end

    % Get all items in the master folder
    items = dir(masterFolder);

    % Loop through each item in the master folder
    for i = 1:length(items)
        folderName = items(i).name;
        
        % Skip if it's not a directory, or if it's the current/parent directory ('.' or '..')
        if ~items(i).isdir || strcmp(folderName, '.') || strcmp(folderName, '..')
            continue;
        end

        % Skip the newly created target folders
        if strcmp(folderName, 'all_h5_files') || ...
           strcmp(folderName, 'all_data_bin') || ...
           strcmp(folderName, 'all_data_elastix_bin')
            continue;
        end

        fprintf('Processing folder: %s\n', folderName);
        subfolderPath = fullfile(masterFolder, folderName);

        % Construct expected source paths for the 3 files
        h5_src = fullfile(subfolderPath, sprintf('%s.h5', folderName));
        bin_src = fullfile(subfolderPath, 'suite2p', 'plane0', 'data.bin');
        elastix_src = fullfile(subfolderPath, 'suite2p', 'plane0', 'data_elastix.bin');

        % Construct target paths (attaching folderName for the .bin files)
        h5_dst = fullfile(h5TargetDir, sprintf('%s.h5', folderName));
        bin_dst = fullfile(binTargetDir, sprintf('%s_data.bin', folderName));
        elastix_dst = fullfile(elastixTargetDir, sprintf('%s_data_elastix.bin', folderName));

        % 1. Move .h5 file
        if isfile(h5_src)
            movefile(h5_src, h5_dst);
            fprintf('  -> Moved .h5 file\n');
        else
            fprintf('  -> [WARNING] Could not find %s\n', h5_src);
        end

        % 2. Move data.bin file
        if isfile(bin_src)
            movefile(bin_src, bin_dst);
            fprintf('  -> Moved data.bin file\n');
        else
            fprintf('  -> [WARNING] Could not find %s\n', bin_src);
        end

        % 3. Move data_elastix.bin file
        if isfile(elastix_src)
            movefile(elastix_src, elastix_dst);
            fprintf('  -> Moved data_elastix.bin file\n');
        else
            fprintf('  -> [WARNING] Could not find %s\n', elastix_src);
        end
        
        fprintf('\n'); % Add a blank line for readability in console
    end

    fprintf('====== Data organization complete! ======\n');
end