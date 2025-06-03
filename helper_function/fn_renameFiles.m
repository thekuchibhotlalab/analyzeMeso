function fn_renameFiles(folderPath)

    % Get a list of all files in the folder
    files = dir(folderPath);
    mkdir([folderPath filesep 'stack']);
    
    % Loop through all files in the folder
    for i = 1:length(files)
        % Get the file name and its path
        oldFileName = files(i).name;
        oldFilePath = fullfile(folderPath, oldFileName);
        
        % Check if it's a file (not a directory)
        if ~files(i).isdir
            % Get the file extension
            [~,fname,ext] = fileparts(oldFileName);
            fname_split = strsplit(fname,'_');

            fname = strjoin(fname_split,'_');
            % Create the new file name
            newFileName = [fname, ext];
                
            if contains(fname_split{3},'stack') || contains(fname_split{3},'ref') || contains(fname_split{3},'Ref')
                newFilePath = fullfile([folderPath filesep 'stack'], newFileName);
            else 
                newFilePath = fullfile(folderPath, newFileName);
            end 
                
            if ~strcmp(oldFilePath,newFilePath)
                % Rename the file
                movefile(oldFilePath, newFilePath);
                fprintf('Renamed %s to %s\n', oldFileName, newFileName);
            end 
        end
    end
end