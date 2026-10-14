myOps.mouse = 'zz173';
myOps.area = 'PPC';
myOps.ID = [myOps.mouse '_' myOps.area];

myOps.TCpath = 'B:\zz173_PPC';
myOps.alignOpsPath = 'B:\zz173_PPC';
myOps.behavPath = 'G:\ziyi\mesoData\zz173_behavior';

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
myOps.trackingSessionSel = 100;
myOps.chunkDays = {[1],[ 2 3],[9 10],... % T1 naive to expert
    [11 12],[16 18 ], [21:24],... % T2 naive to expert
    [ 25]}; % interleave days
