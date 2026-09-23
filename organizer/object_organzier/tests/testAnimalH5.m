function tests = testAnimalH5
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'..','ops_param'));
folder = tempname; mkdir(folder); mkdir(fullfile(folder,'matlab'));
testCase.TestData.folder = folder;
testCase.TestData.id = 'animalH5Fixture';
addpath(folder);
myOps = struct('ID','animalH5Fixture','mouse','fixture','area','PPC', ...
    'TCpath',folder,'spkname',fullfile(folder,'spk.mat'), ...
    'TCname',fullfile(folder,'dff.mat'),'infoName',fullfile(folder,'sessions.mat'), ...
    'trackingName',fullfile(folder,'tracking.mat'),'alignOpsPath',folder, ...
    'behavPath',folder,'frameRate',15,'normSpk',true,'trackingSessionSel',3);
save(fullfile(folder,'config.mat'),'-struct','myOps');
fid = fopen(fullfile(folder,'animalH5Fixture_param.m'),'w');
fprintf(fid,'myOps = load(fullfile(fileparts(mfilename(''fullpath'')),''config.mat''));\n');
fclose(fid);
spk = {reshape(sin(1:2605*4),2605,4),reshape(cos(1:300*4),300,4),reshape(sin(1:521*4),521,4)};
for k = 1:3; spk{k}(:,4) = 0; end
spk{1}(40,3) = NaN; spk{2}(1,1) = Inf;
save(myOps.spkname,'spk','-v7.3');
dff = cellfun(@(x) x*2,spk,'UniformOutput',false);
save(myOps.TCname,'dff','-v7.3');
testCase.TestData.spk = cellfun(@single,spk,'UniformOutput',false);
sessionInfo = table({'2AFC1';'PT1';'2AFC2'},[20240602;20240601;20240602], ...
    {'2AFC';'PT';'2AFC'},[1;1;2],[2605;300;521], ...
    'VariableNames',{'SessionName','SessionDate','SessionType','SessionNumber','SessionFrames'});
save(myOps.infoName,'sessionInfo');
ishereFinal = [1 1 1 1;1 0 1 1;1 1 1 1];
roiFinal = repmat({struct('xpix',[1 2],'ypix',[3 4])},3,4);
save(myOps.trackingName,'ishereFinal','roiFinal');
ops = struct('offsetMap',ones(2,2,3)*5,'refStackSelLoc',[1 2 3 5], ...
    'unusedImageStack',ones(3,3));
save(fullfile(folder,'ops.mat'),'ops','-v7.3');
allData = zeros(3,9); allData(:,2) = [1;2;1]; allData(:,3) = [1;2;1];
allData(:,4) = 1; allData(:,5) = [1;2;3]; allData(:,6) = [1;2;3]+0.3;
allData(:,7) = [35;70;110]; allData(:,8) = [40;75;115]; allData(:,9) = [43;78;118];
save(fullfile(folder,'matlab','fixture_20240602_2AFCsession1.mat'),'allData');
save(fullfile(folder,'matlab','fixture_20240602_2AFCsession2.mat'),'allData');
save(fullfile(folder,'matlab','fixture_20240603_2AFCsession1.mat'),'allData');
testCase.TestData.ani = Animal(testCase.TestData.id);
end

function teardownOnce(testCase)
folder = testCase.TestData.folder;
rmpath(folder);
if isfolder(folder); rmdir(folder,'s'); end
end

function testMetadataMappingAndReuse(testCase)
ani = testCase.TestData.ani;
verifyFalse(testCase,ismember('TC',ani.sessionInfo.Properties.VariableNames));
verifyFalse(testCase,ismember('dffStim',ani.sessionInfo.Properties.VariableNames));
verifyEqual(testCase,ani.sessionInfo.imagingSessionIdx,[2;1;3;NaN]);
verifyEqual(testCase,ani.sessionInfo.hasRecording,[true;true;true;false]);
verifyEqual(testCase,ani.sessionInfo.hasBehavior,[false;true;true;true]);
verifyFalse(testCase,isfield(ani.alignmentOps,'unusedImageStack'));
metadata = AnimalH5.readMetadata(ani.databasePath);
verifyEqual(testCase,metadata,ani.sessionInfo);
% A cached constructor must work after all original metadata/signal files
% have gone away. The parameter file remains available.
folder = testCase.TestData.folder;
files = {'spk.mat','sessions.mat','tracking.mat','ops.mat'};
for k = 1:numel(files); movefile(fullfile(folder,files{k}),fullfile(folder,[files{k} '.hidden'])); end
restore = onCleanup(@() restoreFiles(folder,files)); %#ok<NASGU>
again = Animal(testCase.TestData.id);
verifyEqual(testCase,again.sessionInfo,ani.sessionInfo);
end

function testPartialReadsAndNormalization(testCase)
ani = testCase.TestData.ani; raw = testCase.TestData.spk;
frames = [2051 2 2050 1]; neurons = [3 1 3];
actual = ani.readImaging('ImagingSessionIdx',1,'Frames',frames,'NeuronIDs',neurons,'Normalize',false);
verifyEqual(testCase,actual,raw{1}(frames,neurons));
weights = cellfun(@(x) size(x,1),raw); weights = weights/sum(weights);
scale = zeros(1,4);
for k = 1:numel(raw)
    for n = 1:4
        v = double(raw{k}(:,n)); v = v(isfinite(v));
        scale(n) = scale(n) + norm(v)*weights(k);
    end
end
scale(scale == 0) = 1;
actual = ani.readImaging('ImagingSessionIdx',1,'Frames',frames,'NeuronIDs',neurons);
verifyEqual(testCase,actual,raw{1}(frames,neurons)./single(scale(neurons)),'AbsTol',single(1e-6));
multiple = ani.readImaging('ImagingSessionIdx',[3 1],'Frames',[4 8],'Normalize',false);
verifyEqual(testCase,multiple,{raw{3}([4 8],:);raw{1}([4 8],:)});
end

function testTrialQueriesAndMissingFrames(testCase)
ani = testCase.TestData.ani; raw = testCase.TestData.spk;
[actual,selection] = ani.readImaging('ImagingSessionIdx',1,'Trials',[3 1], ...
    'WindowFrames',[-2 2],'NeuronIDs',[3 1],'Normalize',false);
expected = cat(3,raw{1}(108:112,[3 1])',raw{1}(33:37,[3 1])');
verifyEqual(testCase,actual,expected);
verifyEqual(testCase,selection.trialIDs,[3;1]);
actual = ani.readImaging('ImagingSessionIdx',1,'Trials',1,'Align','reward', ...
    'WindowFrames',[0 1],'Normalize',false);
verifyEqual(testCase,actual,raw{1}(43:44,:)');
actual = ani.readImaging('ImagingSessionIdx',1,'Trials',1,'WindowFrames',[-36 -32],'Normalize',false);
verifyTrue(testCase,all(isnan(actual(:,1:2)),'all'));
verifyEqual(testCase,actual(:,3:5),raw{1}(1:3,:)');
verifySize(testCase,ani.readImaging('ImagingSessionIdx',1,'Trials',[]),[4 100 0]);
verifySize(testCase,ani.readImaging('ImagingSessionIdx',1,'Frames',[]),[0 4]);
verifyError(testCase,@() ani.readImaging('SessionRows',4),'Animal:NoRecording');
end

function testVirtualPadding(testCase)
ani = testCase.TestData.ani;
row = find(ani.sessionInfo.imagingSessionIdx == 3);
ani.sessionInfo.neuralPaddingFrames(row) = 10;
ani.sessionInfo.nFrames(row) = ani.sessionInfo.nFrames(row)+10;
actual = ani.readImaging('SessionRows',row,'Frames',520:531,'Normalize',false);
verifyEqual(testCase,actual(1:2,:),testCase.TestData.spk{3}(520:521,:));
verifyTrue(testCase,all(isnan(actual(3:end,:)),'all'));
end

function testMetadataSelectionAndLegacyParsing(testCase)
ani = testCase.TestData.ani;
ani = ani.parseDay();
verifyEqual(testCase,height(ani.dayInfo),1);
verifyFalse(testCase,ismember('dffStim',ani.dayInfo.Properties.VariableNames));
verifyEqual(testCase,ani.dayInfo.imagingSessionIdx{1},[1;3]);
[~,~,sessions] = ani.selTracking('unrestrained');
verifyFalse(testCase,any(sessions{end} == 4));
ani = ani.parseTrial();
verifyFalse(testCase,ismember('TC',ani.sessionInfo.Properties.VariableNames));
verifySize(testCase,ani.sessionInfo.dffStim{2},[4 100 3]);
end

function testMetadataOnlyWithoutDatabase(testCase)
ani = Animal(testCase.TestData.id,'databasePath',fullfile(testCase.TestData.folder,'not_created.h5'),'loadNeural',false);
verifyFalse(testCase,isfile(ani.databasePath));
verifyFalse(testCase,ismember('TC',ani.sessionInfo.Properties.VariableNames));
verifyEqual(testCase,ani.sessionInfo.imagingSessionIdx,[2;1;3;NaN]);
end

function testDffAndFailedRebuild(testCase)
file = fullfile(testCase.TestData.folder,'both_signals.h5');
ani = Animal(testCase.TestData.id,'databasePath',file,'actType','dff');
actual = ani.readImaging('ImagingSessionIdx',3,'Frames',[1 7]);
verifyEqual(testCase,actual,testCase.TestData.spk{3}([1 7],:)*2);
bad = ani.sessionInfo; bad.badMetadata = repmat({@sin},height(bad),1);
sources = struct('spk',ani.ops.spkname);
verifyError(testCase,@() AnimalH5.create(file,ani.ID,bad,ani.alignmentOps,sources,15),'AnimalH5:MetadataType');
verifyEqual(testCase,AnimalH5.readMetadata(file),ani.sessionInfo);
end

function testRecordingCorrectionsWithoutTC(testCase)
t = table([20240624;20240629;20240716;20240716],[1;2;1;2], ...
    {'2AFC';'2AFC';'2AFC';'2AFC'},{'2AFC1';'2AFC2';'2AFC1';'2AFC2'}, ...
    'VariableNames',{'date','session','sessionType','sessionName'});
t = dealExceptions(t,'zz159');
verifyEqual(testCase,t.session,[3;2;2;3]);
verifyEqual(testCase,t.neuralPaddingFrames,[0;3000;0;0]);
verifyFalse(testCase,ismember('TC',t.Properties.VariableNames));
end

function restoreFiles(folder,files)
for k = 1:numel(files)
    source = fullfile(folder,[files{k} '.hidden']);
    if isfile(source); movefile(source,fullfile(folder,files{k})); end
end
end
