function step3_checkOffsetMap(folderPath)
    % RENAME_SESSIONS_TO_PADDED Finds all session_X.mat files in true numerical 
    % order and renames them to a zero-padded lexicographical format (e.g., session_001.mat).
    %
    % Input:
    %   folderPath - (Optional) Path to the directory containing the .mat files.
    
    if nargin < 1 || isempty(folderPath)
        folderPath = pwd; % Default to current working directory
    end
    
    % 1. Find all session_*.mat files
    files = dir(fullfile(folderPath, 'session_*.mat'));
    if isempty(files)
        error('No session_*.mat files found in directory: %s', folderPath);
    end
    
    % 2. Extract numbers to enforce strict numerical sorting
    sessionNums = zeros(length(files), 1);
    isValid = false(length(files), 1);
    
    for i = 1:length(files)
        % Use regex to isolate the digit sequence from the filename
        tokens = regexp(files(i).name, '^session_(\d+)\.mat$', 'tokens');
        if ~isempty(tokens)
            sessionNums(i) = str2double(tokens{1}{1});
            isValid(i) = true;
        end
    end
    
    % Filter out any files that didn't match the strict session_X.mat pattern
    files = files(isValid);
    sessionNums = sessionNums(isValid);
    
    % Sort numerically to ensure proper order (e.g., session_2 before session_10)
    [sortedNums, sortIdx] = sort(sessionNums);
    sortedFiles = files(sortIdx);
    
    fprintf('Found %d session files. Processing renames...\n', length(sortedFiles));
    
    % 3. Calculate dynamic padding based on the highest session number
    maxNum = max(sortedNums);
    numDigits = max(3, floor(log10(maxNum)) + 1); % Minimum of 3 digits padding (001)
    fmt = sprintf('session_%%0%dd.mat', numDigits);
    
    % 4. Perform the file renaming on disk
    renameCount = 0;
    for i = 1:length(sortedFiles)
        oldName = sortedFiles(i).name;
        newName = sprintf(fmt, sortedNums(i));
        
        oldFull = fullfile(sortedFiles(i).folder, oldName);
        newFull = fullfile(sortedFiles(i).folder, newName);
        
        if ~strcmp(oldName, newName)
            % Safety check to prevent accidentally overwriting an existing file
            if exist(newFull, 'file')
                error('Target filename already exists: %s. Aborting to protect data.', newName);
            end
            
            movefile(oldFull, newFull);
            fprintf('Renamed: %s -> %s\n', oldName, newName);
            renameCount = renameCount + 1;
        end
    end
    
    fprintf('\nProcessing complete. Total files renamed: %d\n', renameCount);
end