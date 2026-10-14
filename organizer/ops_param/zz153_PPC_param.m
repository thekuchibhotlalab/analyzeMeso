myOps.mouse = 'zz153';
myOps.area = 'PPC';
myOps.ID = [myOps.mouse '_' myOps.area];

myOps.TCpath = 'B:\zz153_PPC';
myOps.alignOpsPath = 'B:\zz153_PPC';
myOps.behavPath = 'G:\ziyi\mesoData\zz153_behavior';

myOps.dataAnalyzedPath = 'B:\animal';

myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
myOps.spkname = [myOps.TCpath filesep myOps.ID '_spk.mat'];
myOps.infoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.trackingName = [myOps.TCpath filesep 'stackROI_final_tracked.mat'];
myOps.sessionInfoName = fullfile(myOps.dataAnalyzedPath,'parsedTrial',[myOps.ID '_parsedTrial.mat']);
myOps.sessionInfoBehFile = fullfile(fileparts(myOps.sessionInfoName),[myOps.ID '_parsedTrial_sessionInfoBeh.mat']);
myOps.trialInfoFile = fullfile(fileparts(myOps.sessionInfoName),[myOps.ID '_parsedTrial_trialInfo.mat']);
% Separate metadata-only Animal object; neural sessionInfo stays in the file above.
myOps.animalObjectFile = fullfile(myOps.dataAnalyzedPath,[myOps.ID '_animal.mat']);

myOps.dayLabelName = [myOps.TCpath filesep myOps.ID '_dayLabel.mat'];

myOps.frameRate = 15;

myOps.normSpk = true;

% Existing animal-specific settings for legacy analyses.
myOps.trackingSessionSel = 107;
myOps.chunkDays = {[1 2 3],[4 5],[6 8 9],... % task 1 naive learnig expert
    [10 11 12],[13 14 15 16],[17 18 19],... % task 2 naive leanring expert
    [20 21]}; % interleaved
