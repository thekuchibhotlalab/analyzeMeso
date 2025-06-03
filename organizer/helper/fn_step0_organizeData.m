function fn_step0_organizeData(inputDir, outputDir)
% extract_and_resave_data - Reads data_F.mat from each subfolder and compiles traces and session info.
% Saves a .mat file containing allTraces (cell array), sessionInfo (table), and animalID (string).

% Get animal ID from parent directory name
[parentDir, animalID] = fileparts(fileparts(inputDir));

% List subfolders in inputDir
subFolders = dir(inputDir);
subFolders = subFolders([subFolders.isdir] & ~startsWith({subFolders.name}, '.'));

dff = {};
spk = {};
sessionNames = {};
sessionDates = [];
sessionTypes = {};
sessionNumbers = [];
sessionFrames = [];

for i = 1:length(subFolders)
    sessionFolder = fullfile(inputDir, subFolders(i).name);
    s2pPath = fullfile(sessionFolder, 'suite2p', 'plane0');
    dataFile = fullfile(s2pPath, 'data_dff.mat');
    spkFile = fullfile(s2pPath, 'data_S.mat');
    fallFile = fullfile(s2pPath, 'Fall.mat');

    if ~isfile(dataFile) || ~isfile(fallFile)
        warning('Missing data_F.mat or Fall.mat in %s', s2pPath);
        continue;
    end
    disp(['Processing ' subFolders(i).name])

    data = load(dataFile, 'dff');
    dataSpk = load(spkFile, 'S');
    fall = load(fallFile, 'ops');
    ops = fall.ops;

    if contains(subFolders(i).name, '_')
        % New-style naming with _ (e.g. animal_20240516_sessionX)
        tokens = split(subFolders(i).name, '_');
        sessionDateNum = str2double(tokens{2});
        sessionNameFull = tokens{3};
        sessionType = sessionNameFull(1:end-1);
        sessionNum = str2double(sessionNameFull(end));

        dff{end+1} = data.dff;
        spk{end+1} = dataSpk.S;
        sessionDates(end+1) = sessionDateNum;
        sessionNames{end+1} = sessionNameFull;
        sessionTypes{end+1} = sessionType;
        sessionNumbers(end+1) = sessionNum;
        sessionFrames(end+1) = ops.nframes_per_folder;
    else
        % Old-style, one folder with multiple sessions
        sessionDateNum = str2double(subFolders(i).name);
        nFramesList = ops.nframes_per_folder;
        traces = data.dff;
        tracesSpk = dataSpk.S;
        filelist = ops.filelist;

        startIdx = 1;
        for k = 1:size(filelist,1)
            rawPath = strtrim(filelist(k,:));
            [~, rawName, ~] = fileparts(rawPath);
            tokens = split(rawName, '_');
            sessionNameFull = tokens{3};
            sessionType = sessionNameFull(1:end-1);
            sessionNum = str2double(sessionNameFull(end));

            frames = nFramesList(k);
            endIdx = startIdx + frames - 1;
            dff{end+1} = traces(startIdx:endIdx, :);
            spk{end+1} = tracesSpk(startIdx:endIdx, :);
            sessionDates(end+1) = sessionDateNum;
            sessionNames{end+1} = sessionNameFull;
            sessionTypes{end+1} = sessionType;
            sessionNumbers(end+1) = sessionNum;
            sessionFrames(end+1) = frames;

            startIdx = endIdx + 1;
        end
    end
end
dff = cellfun(@single,dff,'UniformOutput',false);
% Create session info table
sessionInfo = table(sessionNames', sessionDates', sessionTypes', sessionNumbers', sessionFrames', ...
    'VariableNames', {'SessionName','SessionDate','SessionType','SessionNumber','SessionFrames'});

% Output file name and save
outputFile = fullfile(outputDir, [animalID '_TC.mat']);
save(outputFile, 'dff', '-v7.3');

outputFile = fullfile(outputDir, [animalID '_sessionInfo.mat']);
save(outputFile, 'sessionInfo', 'animalID');

outputFile = fullfile(outputDir, [animalID '_spk.mat']);
save(outputFile, 'spk','-v7.3');

fprintf('Saved data to %s\n', outputFile);
end
