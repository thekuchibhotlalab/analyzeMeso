function [fileSizesGB, folderNames, fileNames] = fn_tempCheckBaselineSize(mainFolder)
% get_baseline_tif_sizes Loops through subfolders to find TIFFs and get their FILE SIZE.
%
%   [fileSizesGB, folderNames, fileNames] = get_baseline_tif_sizes(mainFolder)
%
%   This function iterates through all subfolders in 'mainFolder'. In each
%   subfolder, it searches for the first .tif or .tiff file that
%   ends with '_baseline_00001'.
%
%   It then uses 'dir' to efficiently get the file size in bytes
%   (without loading the file) and converts it to Gigabytes (GB).
%
%   Input:
%       mainFolder - The full path to the directory containing session subfolders.
%
%   Output:
%       fileSizesGB - A numeric array of file sizes in Gigabytes.
%       folderNames - A cell array of the corresponding subfolder names.
%       fileNames   - A cell array of the corresponding .tif file names found.
%
%   Example:
%       [sizes, folders, files] = get_baseline_tif_sizes('G:\rockfish\ziyi\zz170_AC1\imagingSession\')
%       % Display results as a table
%       if ~isempty(sizes)
%           T = table(sizes, folders, files, 'VariableNames', {'Size_GB', 'Folder', 'File'});
%           disp(T);
%       end

% --- 1. Find all subfolders ---
if ~isfolder(mainFolder)
    error('Input folder does not exist: %s', mainFolder);
end

d = dir(mainFolder);
% Get only directories, and filter out '.' and '..'
subFolders = d([d.isdir] & ~ismember({d.name}, {'.', '..'}));

if isempty(subFolders)
    fprintf('No subfolders found in: %s\n', mainFolder);
    fileSizesGB = [];
    folderNames = {};
    fileNames = {};
    return;
end

% --- 2. Initialize Output ---
% We will store results in parallel arrays
fileSizesGB = [];
folderNames = {};
fileNames = {};
k = 1; % Index for our results array

fprintf('Starting search in: %s\n', mainFolder);
disp('--------------------------------------------------');

% --- 3. Loop through each subfolder ---
for i = 1:length(subFolders)
    folderName = subFolders(i).name;
    folderPath = fullfile(mainFolder, folderName);
    
    fprintf('Processing: %s\n', folderName);
    
    % Define the search pattern
    filePatternTif = '*_baseline_00001.tif';
    filePatternTiff = '*_baseline_00001.tiff';
    
    % Search for both extensions
    targetFileTif = dir(fullfile(folderPath, filePatternTif));
    targetFileTiff = dir(fullfile(folderPath, filePatternTiff));
    
    targetFile = [targetFileTif; targetFileTiff]; % Combine results
    
    % --- 4. Check if file was found ---
    if ~isempty(targetFile)
        % Use the first file found if multiple (e.g., .tif and .tiff)
        if length(targetFile) > 1
            fprintf('  > Warning: Found multiple matching files. Using first one: %s\n', targetFile(1).name);
        end
        
        fileName = targetFile(1).name;
        
        % --- 5. Get file size in bytes from the 'dir' output ---
        % This does NOT load the file, it just reads metadata from the
        % file system.
        try
            fileBytes = targetFile(1).bytes;
            fileSizeGB = fileBytes / (1024^3); % Convert Bytes to Gigabytes
            
            % Store results in parallel arrays
            fileSizesGB(k,1) = fileSizeGB; % Store as column vector
            folderNames{k,1} = folderName; % Store as column cell
            fileNames{k,1} = fileName;   % Store as column cell
            k = k + 1;
            
            fprintf('  > Found: %s, Size: %.2f GB\n', fileName, fileSizeGB); % <-- Updated log
            
        catch ME
            fprintf('  > Error reading file size for %s: %s\n', fileName, ME.message);
        end
        
    else
        % File not found
        fprintf('  > No file matching "*_baseline_00001.tif(f)" found.\n');
    end
end

disp('--------------------------------------------------');
fprintf('Search complete. Found %d matching files.\n', length(fileSizesGB));

% Optional: Display as a table if you like
if ~isempty(fileSizesGB)
    disp('Summary:');
    try
        % Create a table for clean display
        T = table(fileSizesGB, folderNames, fileNames, 'VariableNames', {'Size_GB', 'Folder', 'File'});
        disp(T);
    catch
        % Fallback for older MATLAB versions without 'table'
        disp('Could not display table. Outputting raw arrays:');
        disp('File Sizes (GB):');
        disp(fileSizesGB);
        disp('Folder Names:');
        disp(folderNames);
    end
end

end