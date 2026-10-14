myOps.mouse = 'zz172';
myOps.area = 'PPC1';
myOps.ID = [myOps.mouse '_' myOps.area];

myOps.TCpath = 'B:\zz172_PPC1';
myOps.alignOpsPath = 'B:\zz172_PPC1';
myOps.behavPath = 'G:\ziyi\mesoData\zz172_behavior';

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
myOps.trackingSessionSel = 166;
myOps.chunkDays = {[1 2],[ 3 4 5 6],[7 8 9 10 11 12 13],... % T1 naive to expert
    [14 15],[21:32], [35:38],... % T2 naive to expert
    [ 39]}; % interleave days
