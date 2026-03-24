function fn_organizeParsedH5(rootPath)
% Reorganizes a complex imaging data folder structure.
%
% This function performs two main phases:
% 1. CONSOLIDATION: It scans through date-specific subfolders (e.g., '0604'),
%    finds all .tif, .h5, and .mat files, and moves them into new, organized
%    folders at the top level of rootPath.
%    - .tif files go into a 'tif' folder.
%    - .h5 files go into folders named after their area (e.g., 'green_AC1').
%    - .mat files go into folders named after their area with a suffix
%      (e.g., 'green_AC1_mat').
%
% 2. H5 REORGANIZATION: It then goes into each of the new consolidated .h5
%    area folders and further organizes the files.
%    - 'stack' and 'WF' session files are moved into an 'archive' subfolder.
%    - All other .h5 files are moved into their own individual subfolders,
%      named after the file itself.
%
% USAGE:
%   organizeImagingData('C:/path/to/your/main_data_folder');

% --- Input Validation ---
if ~isfolder(rootPath)
    error('The provided root path is not a valid folder: %s', rootPath);
end
fprintf('--- Starting Data Organization for Folder: %s ---\n', rootPath);

%% --- PHASE 1: CONSOLIDATE FILES FROM DATE FOLDERS ---
fprintf('\n--- PHASE 1: Consolidating files into top-level folders ---\n');

% Get all items in the root directory
dirContents = dir(rootPath);
subFolders = dirContents([dirContents.isdir]); % Keep only directories

% Loop through each item, looking for the date folders (e.g., '0604')
for i = 1:length(subFolders)
    folderName = subFolders(i).name;
    % Skip '.' and '..' directories and any newly created folders
    if strcmp(folderName, '.') || strcmp(folderName, '..') || strcmp(folderName, 'tif') || contains(folderName, 'green_')
        continue;
    end
    
    dateFolderPath = fullfile(rootPath, folderName);
    fprintf('Scanning date folder: %s\n', dateFolderPath);
    
    % --- A) Move all .tif files ---
    tifFiles = dir(fullfile(dateFolderPath, '**', '*.tif'));
    if ~isempty(tifFiles)
        tifDestPath = fullfile(rootPath, 'tif');
        if ~isfolder(tifDestPath), mkdir(tifDestPath); end
        
        for f = 1:length(tifFiles)
            sourceFile = fullfile(tifFiles(f).folder, tifFiles(f).name);
            fprintf('  -> Moving TIF: %s\n', tifFiles(f).name);
            movefile(sourceFile, tifDestPath);
        end
    end
    
    % --- B) Move all .h5 and .mat files from area subfolders ---
    areaFolders = dir(dateFolderPath);
    areaFolders = areaFolders([areaFolders.isdir] & startsWith({areaFolders.name}, 'green_'));
    
    for k = 1:length(areaFolders)
        areaName = areaFolders(k).name;
        areaFolderPath = fullfile(dateFolderPath, areaName);
        
        % Move .h5 files
        h5Files = dir(fullfile(areaFolderPath, '*.h5'));
        if ~isempty(h5Files)
            h5DestPath = fullfile(rootPath, areaName);
            if ~isfolder(h5DestPath), mkdir(h5DestPath); end
            for f = 1:length(h5Files)
                sourceFile = fullfile(h5Files(f).folder, h5Files(f).name);
                fprintf('  -> Moving H5: %s to %s\n', h5Files(f).name, areaName);
                movefile(sourceFile, h5DestPath);
            end
        end
        
        % Move .mat files
        matFiles = dir(fullfile(areaFolderPath, '*.mat'));
        if ~isempty(matFiles)
            matDestName = [areaName, '_mat'];
            matDestPath = fullfile(rootPath, matDestName);
            if ~isfolder(matDestPath), mkdir(matDestPath); end
            for f = 1:length(matFiles)
                sourceFile = fullfile(matFiles(f).folder, matFiles(f).name);
                fprintf('  -> Moving MAT: %s to %s\n', matFiles(f).name, matDestName);
                movefile(sourceFile, matDestPath);
            end
        end
    end
end

%% --- PHASE 2: REORGANIZE CONSOLIDATED H5 FILES ---
fprintf('\n--- PHASE 2: Reorganizing consolidated H5 files ---\n');

% Get the list of consolidated 'green_*' folders
dirContents = dir(rootPath);
h5AreaFolders = dirContents([dirContents.isdir] & startsWith({dirContents.name}, 'green_') & ~endsWith({dirContents.name}, '_mat'));

for i = 1:length(h5AreaFolders)
    areaFolderPath = fullfile(rootPath, h5AreaFolders(i).name);
    fprintf('Organizing H5 files in: %s\n', areaFolderPath);
    
    % Create the archive subfolder
    archivePath = fullfile(areaFolderPath, 'archive');
    if ~isfolder(archivePath), mkdir(archivePath); end
    
    % Get all H5 files in the current area folder
    h5Files = dir(fullfile(areaFolderPath, '*.h5'));
    
    for j = 1:length(h5Files)
        fileName = h5Files(j).name;
        sourceFile = fullfile(areaFolderPath, fileName);
        
        % Parse filename to check session type
        parts = strsplit(fileName, '_');
        if length(parts) < 3
            fprintf('    ! Skipping malformed filename: %s\n', fileName);
            continue;
        end
        sessionType = parts{3};
        
        % Move 'stack' and 'WF' files to archive
        if startsWith(sessionType, 'stack', 'IgnoreCase', true) || startsWith(sessionType, 'WF', 'IgnoreCase', true)
            fprintf('  -> Archiving: %s\n', fileName);
            movefile(sourceFile, archivePath);
        else
            % Move other files into their own named subfolder
            newFolderName = erase(fileName, '.h5');
            newFolderPath = fullfile(areaFolderPath, newFolderName);
            
            fprintf('  -> Isolating: %s\n', fileName);
            if ~isfolder(newFolderPath), mkdir(newFolderPath); end
            movefile(sourceFile, newFolderPath);
        end
    end
end

fprintf('\n--- Organization Complete ---\n');
end
