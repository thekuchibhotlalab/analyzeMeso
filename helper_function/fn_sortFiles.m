function fn_sortFiles(sourceFolder)
% groupH5FilesByDate organizes .h5 files into folders based on the date in their filenames.
% 
% Arguments:
% - sourceFolder: Path to the folder containing .h5 files (string).

% Get a list of all .h5 files in the folder
fileList = dir(fullfile(sourceFolder, '*.h5'));

% Create a new folder for each unique date
for i = 1:length(fileList)
    % Extract the filename
    fileName = fileList(i).name;
    
    % Parse the date from the filename (assumes format like zz151_20240315_Duration1_parsed.h5)
    tokens = regexp(fileName, '^[^_]+_([0-9]{8})_', 'tokens');
    
    if isempty(tokens) || length(tokens{1}) < 1
        warning('Filename %s does not match expected pattern. Skipping.', fileName);
        continue;
    end
    
    dateStr = tokens{1}{1}; % Extract the date string
    
    % Create a new folder for this date if it doesn't already exist
    targetFolder = fullfile(sourceFolder, dateStr);
    if ~exist(targetFolder, 'dir')
        mkdir(targetFolder);
    end

    % Move the file into the appropriate folder
    sourceFilePath = fullfile(sourceFolder, fileName);
    targetFilePath = fullfile(targetFolder, fileName);
    movefile(sourceFilePath, targetFilePath);
end

fprintf('Files have been grouped into folders by date.\n');
end