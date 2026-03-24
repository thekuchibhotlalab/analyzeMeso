function step3_process_all_tifs(filename_stack,rootFolder,save2path)

    % Get current folder
    %rootFolder = pwd;

    % Get all subfolders recursively
    allFolders = dir(rootFolder);
    allFolders = allFolders([allFolders.isdir]);   % keep only folders
    
    % Remove '.' and '..'
    allFolders = allFolders(~ismember({allFolders.name}, {'.','..'}));

    for i = 1:length(allFolders)
        
        subfolderPath = fullfile(rootFolder, allFolders(i).name);
        
        % Find all .tif files in this subfolder
        tifFiles = dir(fullfile(subfolderPath, '*.mat'));
        
        for j = 1:length(tifFiles)
            
            tifFullPath = fullfile(subfolderPath, tifFiles(j).name);
            
            fprintf('Processing: %s\n', tifFullPath);
            
            % ---- CALL YOUR FUNCTION HERE ----
            try
                fn_step3_matchImgStack(tifFullPath,filename_stack,save2path);
            catch
                disp('session not done!')
            end
            
        end
    end

end
