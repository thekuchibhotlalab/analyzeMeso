% Find imagingSession folder under current directory
rootPath = 'G:\rockfish\ziyi\zz170_AC2';
imagingPath = fullfile(rootPath, 'imagingSession');

if ~exist(imagingPath, 'dir')
    error('Folder "imagingSession" not found under current directory.');
end

% Create h5 folder inside imagingSession
h5Path = fullfile(imagingPath, 'h5');
if ~exist(h5Path, 'dir')
    mkdir(h5Path);
end

% List subfolders in imagingSession
subDirs = dir(imagingPath);

for i = 1:length(subDirs)
    if ~subDirs(i).isdir
        continue
    end

    subName = subDirs(i).name;

    % Skip '.' '..' and 'h5'
    if strcmp(subName,'.') || strcmp(subName,'..') || strcmp(subName,'h5')
        continue
    end

    subPath = fullfile(imagingPath, subName);

    % Find .h5 files in this subfolder
    h5Files = dir(fullfile(subPath, '*.h5'));

    for j = 1:length(h5Files)
        src = fullfile(subPath, h5Files(j).name);
        dst = fullfile(h5Path, h5Files(j).name);

        movefile(src, dst);
        fprintf('Moved %s → h5/\n', h5Files(j).name);
    end
end

disp('Done collecting all .h5 files.');
