function tests=testAnimalTrialCuration
tests=functiontests(localfunctions);
end

function setupOnce(t)
repo=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'organizer','object_organzier')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'organizer','helper')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'analysis')));
end

function testSeparateNeuralFileAndSavedObject(t)
[id,ops,S]=fn_fixture(t);
fn_parsedFixture(ops,S);
ani=Animal(id);
verifyFalse(t,isprop(ani,'sessionInfo'));
verifyEqual(t,ani.fn_loadSessionInfo(),S);
verifyEqual(t,height(ani.trialInfo),4);
verifyFalse(t,isprop(ani,'trialData'));
verifyFalse(t,any(ismember({'TC','dffStim','dffChoice','dffReward','tuning'}, ...
    ani.sessionInfoBeh.Properties.VariableNames)));
verifyTrue(t,isfile(ops.animalObjectFile));
saved=load(ops.animalObjectFile,'ani');
verifyEqual(t,saved.ani.trialInfo,ani.trialInfo);
verifyEqual(t,saved.ani.sessionInfoBeh,ani.sessionInfoBeh);
verifyEqual(t,who('-file',ops.sessionInfoName),{'sessionInfo'});
% Derived neural arrays must not inflate a saved object either.
ani.dayInfo=S; ani.chunkedDayInfo=S; ani.analysis=struct('neural',ones(10));
ani.fn_saveObject();
saved=load(ops.animalObjectFile,'ani');
verifyEmpty(t,saved.ani.dayInfo);
verifyEmpty(t,saved.ani.chunkedDayInfo);
verifyEmpty(t,saved.ani.analysis);
end

function testObjectQueryAndDeferredNeuralLoad(t)
[id,ops,S]=fn_fixture(t);
fn_parsedFixture(ops,S);
ani=Animal(id);
cfg=fn_expertTrialSelectionConfig(); cfg.verbose=false; cfg.makePlots=false;
cfg.minSessionsPerStage=1; cfg.numSessions=1;
curated=ani.fn_prepareTrialData(cfg);
verifyFalse(t,curated.neuralLoaded);
verifyEqual(t,curated.animalID,string(id));
verifyEqual(t,curated.tracking.selectedSessionRec,10);
neural=ani.fn_prepareNeuralData(curated);
verifyTrue(t,neural.neuralLoaded);
verifyEqual(t,neural.byCondition.T1_S1_L.neuralRaw,S.dffChoice{1}(:,:,1));
verifyEqual(t,neural.byCondition.T1_S2_R.neuralRaw,S.dffChoice{1}(:,:,2));
verifyFalse(t,isprop(ani,'sessionInfo'));
wrong=curated; wrong.animalID="other";
verifyError(t,@()ani.fn_prepareNeuralData(wrong),'Animal:SelectionID');
cfg.loadNeural=true;
oneCall=ani.fn_prepareTrialData(cfg);
verifyTrue(t,oneCall.neuralLoaded);
end

function testLegacyTrialDataMigration(t)
[id,ops,S]=fn_fixture(t);
[sessionInfoBeh,trialInfo]=fn_getBehTrialInfo(S);
old=struct('ID',id,'ops',ops,'trialData',trialInfo, ...
    'sessionInfoBeh',sessionInfoBeh,'sessionInfo',S, ...
    'alignmentOps',struct('refStackSelLoc',[1 2],'unusedImages',ones(10)), ...
    'dayInfo',S,'chunkedDayInfo',S);
ani=Animal.loadobj(old);
verifyEqual(t,ani.trialInfo,trialInfo);
verifyFalse(t,isprop(ani,'trialData'));
verifyFalse(t,isprop(ani,'sessionInfo'));
verifyEmpty(t,ani.dayInfo);
verifyEqual(t,ani.alignmentOps,struct('refStackSelLoc',[1 2]));
payload=saveobj(ani);
verifyEqual(t,sort(fieldnames(payload)), ...
    sort({'ID';'ops';'trialInfo';'sessionInfoBeh';'alignmentOps'}));
ani.fn_saveObject();
saved=load(ops.animalObjectFile,'ani');
verifyEqual(t,saved.ani.trialInfo,trialInfo);
% Cache reuse must not read any neural or sidecar files during migration.
again=Animal(id);
verifyEqual(t,again.trialInfo,trialInfo);
verifyFalse(t,isfile(ops.sessionInfoName));
end

function testManualCountUsesAnimalIdentityBeforeSelecting(t)
[id,ops,S]=fn_fixture(t);
fn_parsedFixture(ops,S);
ani=Animal(id);
cfg=fn_expertTrialSelectionConfig(); cfg.verbose=false; cfg.makePlots=false;
cfg.minSessionsPerStage=1;
cfg.sessionCountMethod='manual'; cfg.manualSessionCounts.(id)=1;
cfg.animalID='wrongInputID'; % The object is authoritative for its own identity.
c=ani.fn_prepareTrialData(cfg);
verifyEqual(t,c.tracking.numSessionsSelected,1);
verifyEqual(t,c.tracking.sessionCountSelection.animalID,string(id));
verifyEqual(t,c.cfg.animalID,string(id));
verifyFalse(t,c.neuralLoaded);
end

function testCanonicalTrialsTakePriorityDuringMigration(t)
[~,~,S]=fn_fixture(t);
[sessionInfoBeh,trialInfo]=fn_getBehTrialInfo(S);
old=struct('sessionInfoBeh',sessionInfoBeh,'trialData',trialInfo, ...
    'trialInfo',trialInfo(1,:));
ani=Animal.loadobj(old);
verifyEqual(t,ani.trialInfo,trialInfo(1,:));
% An intentionally empty selection must not restore all the old trials.
old.trialInfo=trialInfo([],:);
ani=Animal.loadobj(old);
verifyEqual(t,ani.trialInfo,trialInfo([],:));
end

function testLegacySessionOnlyMetadataMigration(t)
[~,~,S]=fn_fixture(t);
[sessionInfoBeh,trialInfo]=fn_getBehTrialInfo(S);
ani=Animal.loadobj(struct('sessionInfo',S));
verifyEqual(t,ani.sessionInfoBeh,sessionInfoBeh);
verifyEqual(t,ani.trialInfo,trialInfo);
verifyError(t,@()Animal.loadobj(struct('ID','invalid')),'Animal:Cache');
end

function testSidecarsAvoidNeuralReads(t)
[id,ops,S]=fn_fixture(t);
[sessionInfoBeh,trialInfo]=fn_getBehTrialInfo(S);
save(ops.sessionInfoBehFile,'sessionInfoBeh'); save(ops.trialInfoFile,'trialInfo');
% Existing but unreadable as MAT: any accidental neural load will fail.
fid=fopen(ops.sessionInfoName,'w'); fprintf(fid,'not a MAT file'); fclose(fid);
ani=Animal(id);
verifyEqual(t,ani.trialInfo,trialInfo);
cfg=fn_expertTrialSelectionConfig(); cfg.verbose=false; cfg.makePlots=false;
cfg.minSessionsPerStage=1;
c=ani.fn_prepareTrialData(cfg);
verifyEqual(t,sum(c.selectionQC.NSelected),4);
verifyFalse(t,c.neuralLoaded);
% A saved object wins even when ALL source files are unavailable.
delete(ops.sessionInfoBehFile); delete(ops.trialInfoFile); delete(ops.sessionInfoName);
again=Animal(id);
verifyEqual(t,again.trialInfo,trialInfo);
verifyFalse(t,isfile(ops.sessionInfoBehFile));
verifyFalse(t,isfile(ops.trialInfoFile));
end

function testSavedObjectTakesPriorityWithoutRewritingFiles(t)
[id,ops,S]=fn_fixture(t);
fn_parsedFixture(ops,S);
ani=Animal(id);
ani.trialInfo=ani.trialInfo(1,:); % Saved object differs from the sidecar.
ani.fn_saveObject();
beforeObject=dir(ops.animalObjectFile);
beforeTrials=dir(ops.trialInfoFile);
again=Animal(id);
verifyEqual(t,again.trialInfo,ani.trialInfo);
sidecar=load(ops.trialInfoFile,'trialInfo');
verifyEqual(t,height(sidecar.trialInfo),4);
afterObject=dir(ops.animalObjectFile);
afterTrials=dir(ops.trialInfoFile);
verifyEqual(t,afterObject.datenum,beforeObject.datenum);
verifyEqual(t,afterTrials.datenum,beforeTrials.datenum);
end

function testIncompleteParsedSetRebuildsFromRaw(t)
% Each missing file, and both absent sidecars, force a full rebuild.
missing={{'sessionInfoName'},{'sessionInfoBehFile'},{'trialInfoFile'}, ...
    {'sessionInfoBehFile','trialInfoFile'}};
for k=1:numel(missing)
    [id,ops,S]=fn_fixture(t);
    fn_rawFixture(ops);
    fn_parsedFixture(ops,S);
    for name=missing{k}, delete(ops.(name{1})); end
    ani=Animal(id,'actType','dff');
    verifyEqual(t,ani.sessionInfoBeh.sessionRec,[1;2]); % Cached fixture was 10,20.
    verifyEqual(t,ani.sessionInfoBeh.dayLabel,{'T1E';'T1E'});
    verifyTrue(t,isfile(ops.sessionInfoName)&&isfile(ops.sessionInfoBehFile)&& ...
        isfile(ops.trialInfoFile)&&isfile(ops.animalObjectFile));
end
end

function testCombinedFileAloneAlsoRebuilds(t)
[id,ops,sessionInfo]=fn_fixture(t);
fn_rawFixture(ops);
[sessionInfoBeh,trialInfo]=fn_getBehTrialInfo(sessionInfo);
save(ops.sessionInfoName,'sessionInfo','sessionInfoBeh','trialInfo');
ani=Animal(id,'actType','dff');
verifyEqual(t,ani.sessionInfoBeh.sessionRec,[1;2]);
verifyEqual(t,who('-file',ops.sessionInfoName),{'sessionInfo'});
end

function testExplicitSaveAndTrialInfo(t)
[id,ops,S]=fn_fixture(t);
fn_parsedFixture(ops,S);
ani=Animal(id);
S.dffChoice{1}=S.dffChoice{1}*2;
ani=ani.fn_saveSessionInfo(S);
saved=ani.fn_loadSessionInfo();
verifyEqual(t,saved.dffChoice{1},S.dffChoice{1});
subset=ani.trialInfo(1,:);
ani.trialInfo=subset;
verifyEqual(t,ani.trialInfo,subset);
ani.fn_saveObject();
saved=load(ops.animalObjectFile,'ani');
verifyEqual(t,saved.ani.trialInfo,subset);
end

function testFreshConstruction(t)
[id,ops,~]=fn_fixture(t);
fn_rawFixture(ops);
ani=Animal(id,'actType','dff');
verifyTrue(t,isfile(ops.sessionInfoName));
verifyTrue(t,isfile(ops.animalObjectFile));
verifyEqual(t,height(ani.trialInfo),4);
verifyFalse(t,isprop(ani,'sessionInfo'));
S=ani.fn_loadSessionInfo();
verifyTrue(t,ismember('dffChoice',S.Properties.VariableNames));
verifyFalse(t,ismember('TC',S.Properties.VariableNames));
verifySize(t,S.dffChoice{1},[3 100 2]);
verifyEqual(t,fieldnames(ani.alignmentOps),{'refStackSelLoc'});
verifyEqual(t,S.dayLabel,{'T1E';'T1E'}); % No manual labels: automatic detection.
% Legacy explicit parsing is harmless when activity is already parsed.
again=ani.parseTrial();
verifyEqual(t,again.trialInfo,ani.trialInfo);
end

function testUnparsedActivityAndBehaviorOnlyCreation(t)
[id,ops,~]=fn_fixture(t);
fn_rawFixture(ops);
ani=Animal(id,'loadNeural',false);
verifyFalse(t,isfile(ops.sessionInfoName));
verifyEqual(t,height(ani.trialInfo),4);
verifyFalse(t,ismember('TC',ani.sessionInfoBeh.Properties.VariableNames));
% Remove the saved metadata object to request reconstruction with neural data.
delete(ops.animalObjectFile);
ani=Animal(id,'actType','dff','parseTrial',false);
S=ani.fn_loadSessionInfo();
verifyTrue(t,ismember('TC',S.Properties.VariableNames));
verifyFalse(t,ismember('TC',ani.sessionInfoBeh.Properties.VariableNames));
ani=ani.parseTrial();
S=ani.fn_loadSessionInfo();
verifyTrue(t,ismember('dffChoice',S.Properties.VariableNames));
verifyFalse(t,ismember('TC',S.Properties.VariableNames));
end

function testManualLabelsSurviveParsing(t)
[id,ops,~]=fn_fixture(t);
fn_rawFixture(ops);
ops.dayLabel=["T1L","T1R"]; % Row vectors also become a session column.
ops.dayLabelName=fullfile(ops.alignOpsPath,'manualLabels.mat');
dayLabel={'ignored';'ignored'}; save(ops.dayLabelName,'dayLabel');
save(fullfile(ops.alignOpsPath,'config.mat'),'-struct','ops');
ani=Animal(id,'actType','dff','parseTrial',false);
ani=ani.parseTrial();
S=ani.fn_loadSessionInfo();
verifyEqual(t,S.dayLabel,{'T1L';'T1R'});
verifyEqual(t,ani.sessionInfoBeh.dayLabel,S.dayLabel);
verifyEqual(t,ani.trialInfo.dayLabel,{'T1L';'T1L';'T1R';'T1R'});
verifyEqual(t,S.taskLabel,{'T1';'T1'});
verifyEqual(t,S.T1nTrial,[2;2]);
% Cached metadata remains authoritative on a subsequent constructor call.
ops.dayLabel=["changed","changed"];
save(fullfile(ops.alignOpsPath,'config.mat'),'-struct','ops');
again=Animal(id);
verifyEqual(t,again.sessionInfoBeh.dayLabel,{'T1L';'T1R'});
end

function testManualLabelFileDuringConstruction(t)
[id,ops,~]=fn_fixture(t);
fn_rawFixture(ops);
ops.dayLabelName=fullfile(ops.alignOpsPath,'manualLabels.mat');
dayLabel={'T1M';'Int'}; save(ops.dayLabelName,'dayLabel');
save(fullfile(ops.alignOpsPath,'config.mat'),'-struct','ops');
ani=Animal(id,'actType','dff');
S=ani.fn_loadSessionInfo();
verifyEqual(t,S.dayLabel,dayLabel);
verifyEqual(t,ani.trialInfo.dayLabel,{'T1M';'T1M';'Int';'Int'});
end

function testBareDayLabelInParameterScript(t)
[id,ops,~]=fn_fixture(t);
fn_rawFixture(ops);
fid=fopen(fullfile(ops.alignOpsPath,[id '_param.m']),'a');
fprintf(fid,'dayLabel={''customA'';''customB''};\n'); fclose(fid);
ani=Animal(id,'loadNeural',false);
verifyEqual(t,ani.sessionInfoBeh.dayLabel,{'customA';'customB'});
verifyFalse(t,isfile(ops.sessionInfoName));
end

function testManualLabelLengthIsValidated(t)
[id,ops,~]=fn_fixture(t);
fn_rawFixture(ops);
ops.dayLabel="oneLabelForTwoSessions";
save(fullfile(ops.alignOpsPath,'config.mat'),'-struct','ops');
verifyError(t,@()Animal(id,'loadNeural',false),'Animal:DayLabelCount');
verifyFalse(t,isfile(ops.animalObjectFile));
end

function [id,ops,S]=fn_fixture(t)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
t.applyFixture(matlab.unittest.fixtures.PathFixture(f.Folder));
[~,tag]=fileparts(f.Folder); id=['fixture_' matlab.lang.makeValidName(tag)];
ops=struct('ID',id,'mouse','fixture','normSpk',false,'frameRate',15, ...
    'sessionInfoName',fullfile(f.Folder,'neural.mat'), ...
    'animalObjectFile',fullfile(f.Folder,'animal.mat'), ...
    'sessionInfoBehFile',fullfile(f.Folder,'behavior.mat'), ...
    'trialInfoFile',fullfile(f.Folder,'trials.mat'), ...
    'TCname',fullfile(f.Folder,'dff.mat'),'spkname',fullfile(f.Folder,'spk.mat'), ...
    'infoName',fullfile(f.Folder,'rawSessions.mat'), ...
    'trackingName',fullfile(f.Folder,'tracking.mat'), ...
    'alignOpsPath',f.Folder,'behavPath',f.Folder,'trackingSessionSel',2);
save(fullfile(f.Folder,'config.mat'),'-struct','ops');
fid=fopen(fullfile(f.Folder,[id '_param.m']),'w');
fprintf(fid,'myOps=load(fullfile(fileparts(mfilename(''fullpath'')),''config.mat''));\n');
fclose(fid);
S=table([10;20],[20240101;20240102],{'2AFC1';'2AFC1'},{'2AFC';'2AFC'}, ...
    [1;2],{'T1';'T1'},{'T1L';'T1L'},[true;true], ...
    {[1 1 1];[1 1 0]},{zeros(2);ones(2)}, ...
    'VariableNames',{'sessionRec','date','sessionName','sessionType','day', ...
    'taskLabel','dayLabel','goodTracking','ishere','offsetMap'});
B=table([1;2],[1;2],[.5;.5],[true;true],[false;false], ...
    'VariableNames',{'stimuli','action','RT','correct','miss'});
S.behSel={B;B};
S.dffChoice={reshape(single(1:24),3,4,2);reshape(single(25:48),3,4,2)};
S.dffStim=S.dffChoice; S.dffReward=S.dffChoice;
end

function fn_parsedFixture(ops,sessionInfo)
[sessionInfoBeh,trialInfo]=fn_getBehTrialInfo(sessionInfo);
save(ops.sessionInfoName,'sessionInfo','-v7.3');
save(ops.sessionInfoBehFile,'sessionInfoBeh');
save(ops.trialInfoFile,'trialInfo');
end

function fn_rawFixture(ops)
sessionInfo=table({'2AFC1';'2AFC1'},[20240101;20240102],{'2AFC';'2AFC'},[1;1], ...
    'VariableNames',{'sessionName','date','sessionType','session'});
save(ops.infoName,'sessionInfo');
dff={reshape(single(1:900),300,3),reshape(single(901:1800),300,3)};
save(ops.TCname,'dff');
ishereFinal=[1 1 1;1 1 0]; roiFinal=cell(2,3);
save(ops.trackingName,'ishereFinal','roiFinal');
alignment=struct('offsetMap',cat(3,zeros(2),ones(2)),'refStackSelLoc',[1 2 3 4]);
alignment.unusedImages=ones(20);
folder=ops.alignOpsPath;
ops=alignment; save(fullfile(folder,'ops.mat'),'ops');
mkdir(fullfile(folder,'matlab'));
allData=zeros(2,9); allData(:,2)=[1;2]; allData(:,3)=[1;2]; allData(:,4)=1;
allData(:,5)=[1;2]; allData(:,6)=[1.5;2.5];
allData(:,7)=[40;150]; allData(:,8)=[45;155]; allData(:,9)=[48;158];
save(fullfile(folder,'matlab','fixture_20240101_2AFCsession1.mat'),'allData');
save(fullfile(folder,'matlab','fixture_20240102_2AFCsession1.mat'),'allData');
end
