function outputDir = createImagingSessionDeconv(baseDir, overwrite)
%CREATEIMAGINGSESSIONDECONV Copy only extracted fluorescence files by session.
%   createImagingSessionDeconv('B:\zz153_AC') creates:
%     imagingSessionDeconv/<session>/suite2p/plane0/data_F.mat
%   from the matching path under imagingSession. Existing destination files
%   are skipped. Pass true as the second argument to overwrite them.
%   Source files and unrelated destination files are never removed.

if nargin < 2
    overwrite = false;
end
validateattributes(overwrite, {'logical'}, {'scalar'}, mfilename, 'overwrite');
baseDir = char(baseDir);
sourceDir = fullfile(baseDir, 'imagingSession');
outputDir = fullfile(baseDir, 'imagingSessionDeconv');
if ~isfolder(sourceDir)
    error('createImagingSessionDeconv:MissingSource', ...
        'Source directory does not exist: %s', sourceDir);
end
ensureFolder(outputDir);

sessions = dir(sourceDir);
sessions = sessions([sessions.isdir] & ...
    ~ismember({sessions.name}, {'.', '..'}));
nCopied = 0;
nSkipped = 0;
nMissing = 0;
for i = 1:numel(sessions)
    sessionName = sessions(i).name;
    destinationPlane = fullfile(outputDir, sessionName, 'suite2p', 'plane0');
    ensureFolder(destinationPlane);
    sourceFile = fullfile(sourceDir, sessionName, 'suite2p', 'plane0', 'data_F.mat');
    destinationFile = fullfile(destinationPlane, 'data_F.mat');

    if ~isfile(sourceFile)
        warning('createImagingSessionDeconv:MissingFile', ...
            'No data_F.mat found for session %s: %s', sessionName, sourceFile);
        nMissing = nMissing + 1;
        continue
    end
    if isfile(destinationFile) && ~overwrite
        fprintf('Skipped existing: %s\n', sessionName);
        nSkipped = nSkipped + 1;
        continue
    end

    [ok, message] = copyfile(sourceFile, destinationFile);
    if ~ok
        error('createImagingSessionDeconv:CopyFailed', ...
            'Could not copy %s: %s', sourceFile, message);
    end
    fprintf('Copied: %s\n', sessionName);
    nCopied = nCopied + 1;
end
fprintf('Finished: %d copied, %d existing, %d missing.\nDestination: %s\n', ...
    nCopied, nSkipped, nMissing, outputDir);
end

function ensureFolder(folder)
if ~isfolder(folder)
    [ok, message] = mkdir(folder);
    if ~ok
        error('createImagingSessionDeconv:CreateFolderFailed', ...
            'Could not create %s: %s', folder, message);
    end
end
end
