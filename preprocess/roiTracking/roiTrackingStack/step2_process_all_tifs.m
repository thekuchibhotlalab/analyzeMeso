function step2_process_all_tifs(rootFolder)

    % Get current folder
    %rootFolder = pwd;

    % Get all subfolders recursively
    allFolders = dir(rootFolder);
    allFolders = allFolders([allFolders.isdir]);   % keep only folders
    
    % Remove '.' and '..'
    allFolders = allFolders(~ismember({allFolders.name}, {'.','..'}));

    for i = 1:length(allFolders)
        tic;
        
        subfolderPath = fullfile(rootFolder, allFolders(i).name);
        
        % Find all .tif files in this subfolder
        tifFiles = dir(fullfile(subfolderPath, '*.tif'));
        
        for j = 1:length(tifFiles)
            
            tifFullPath = fullfile(subfolderPath, tifFiles(j).name);
            
            fprintf('Processing: %s\n', tifFullPath);
            try
                % ---- CALL YOUR FUNCTION HERE ----
                fn_step2_processMatchImg(tifFullPath);
            catch
                disp('Not Successful')
            
            end
            
        end
        toc;
    end

end
