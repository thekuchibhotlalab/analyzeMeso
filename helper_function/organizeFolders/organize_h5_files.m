function organize_h5_files(inputFolder)
% ORGANIZE_H5_FILES finds all .h5 files in a folder, creates a new
% subfolder for each, and moves the .h5 file into it.
%
%   organize_h5_files(inputFolder)
%
%   Input:
%       inputFolder - The full path to the directory containing the .h5 files.
%
%   Example:
%       % Suppose you have 'data1.h5' and 'data2.h5' in 'C:\MyData\'
%       organize_h5_files('C:\MyData\')
%       % This will create:
%       % - 'C:\MyData\data1\data1.h5'
%       % - 'C:\MyData\data2\data2.h5'
%

% --- 1. Validate Input Folder ---
if ~isfolder(inputFolder)
    error('Input folder does not exist: %s', inputFolder);
end

fprintf('Scanning folder: %s\n', inputFolder);

% --- 2. Find all .h5 files ---
% We search only in the top level of the inputFolder.
h5Files = dir(fullfile(inputFolder, '*.h5'));

% Filter out any results that are directories
h5Files = h5Files(~[h5Files.isdir]);

if isempty(h5Files)
    fprintf('No .h5 files found in the specified folder.\n');
    return;
end

fprintf('Found %d .h5 files to organize.\n', length(h5Files));
disp('--------------------------------------------------');

% --- 3. Loop through each file, create folder, and move ---
for i = 1:length(h5Files)
    
    currentFileName = h5Files(i).name;
    
    % Get the full path to the original file
    sourceFile = fullfile(inputFolder, currentFileName);
    
    % Get the file name without the .h5 extension to use as the folder name
    [~, newFolderName, ~] = fileparts(currentFileName);
    
    % Define the path for the new subfolder
    targetFolder = fullfile(inputFolder, newFolderName);
    
    % Define the final path for the file inside its new folder
    targetFile = fullfile(targetFolder, currentFileName);
    
    fprintf('Processing: %s\n', currentFileName);
    
    % --- 4. Create new folder and move the file ---
    try
        % Create the new subfolder
        if ~isfolder(targetFolder)
            [success, msg] = mkdir(targetFolder);
            if ~success
                fprintf('  > ERROR: Could not create folder %s. %s\n', targetFolder, msg);
                continue; % Skip to the next file
            end
            fprintf('  > Created folder: %s\n', newFolderName);
        else
            fprintf('  > Warning: Folder %s already exists.\n', newFolderName);
        end
        
        % Move the file
        [success, msg] = movefile(sourceFile, targetFile);
        if ~success
            fprintf('  > ERROR: Could not move file. %s\n', msg);
        else
            fprintf('  > Moved file into new folder.\n');
        end
        
    catch ME
        fprintf('  > An unexpected error occurred: %s\n', ME.message);
    end
end

disp('--------------------------------------------------');
fprintf('Organization complete.\n');

end