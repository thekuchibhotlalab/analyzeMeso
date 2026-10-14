function tests=testTrialCuration
tests=functiontests(localfunctions);
end

function setupOnce(testCase)
root=fileparts(fileparts(mfilename('fullpath')));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(root));
for folder={ '', 'config', 'helper', 'tracking' }
    testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,'trialCuration',folder{1})));
end
end

function testMetadataFilesAndGreedyPrefix(testCase)
[trialInfo,sessionInfoBeh,cfg]=fixture();
folder=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
trialFile=fullfile(folder.Folder,'animal_trialInfo.mat');
behFile=fullfile(folder.Folder,'animal_sessionInfoBeh.mat');
save(trialFile,'trialInfo'); save(behFile,'sessionInfoBeh');
cfg.sessionInfoFile=fullfile(folder.Folder,'DOES_NOT_EXIST_parsedTrial.mat');
c=fn_prepareTrialData(trialFile,behFile,cfg);
verifyFalse(testCase,c.neuralLoaded);
verifyEmpty(testCase,c.neuralSelection);
verifyEqual(testCase,c.tracking.sessions.sessionRec(1:2),[10;30]);
verifyEqual(testCase,c.tracking.curve.nTrials,[2;4;6;8]);
verifyEqual(testCase,c.tracking.curve.nTrackedNeurons(1:2),[4;3]);
c=fn_chooseTrackedSessions(c,2);
verifyEqual(testCase,c.tracking.selectedSessionRec,[10;30]);
verifyEqual(testCase,c.tracking.selectedNeuronIDs,[1;2;3]);
verifyEqual(testCase,sum(c.selectionQC.NSelected),4);
verifyEqual(testCase,sort(unique(c.sessionExcludedTrials.dropReason)), ...
    sort(["badTracking";"missingOffsetMap";"sessionNotSelected"]));
% Choosing a longer prefix restores trials from the original metadata selection.
c=fn_chooseTrackedSessions(c,Inf);
verifyEqual(testCase,sum(c.selectionQC.NSelected),8);
end

function testErrorUsesEqualSessionMedian(testCase)
[T,S,cfg]=fixture();
cfg.trackingMethod='error';
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.tracking.referenceOffsetMap,15*ones(2));
verifyEqual(testCase,c.tracking.sessions.sessionRec(1),20);
verifyEqual(testCase,c.tracking.sessions.meanSquaredOffset(1),225);
verifyEqual(testCase,c.tracking.minimumPrefixLength,2);
verifyEqual(testCase,c.tracking.curve.nSessionsByPhase(2,:),[1 1]);
end

function testLookaheadUsesConfigAndReleasesPhaseMatching(testCase)
[T,S,cfg]=fixture();
cfg.trackingMethod='lookahead'; cfg.matchRemaining=true;
cfg.lookaheadWeight=0.6; cfg.lookaheadSessions=2;
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.tracking.method,"lookahead");
verifyEqual(testCase,c.tracking.lookaheadWeight,0.6);
verifyEqual(testCase,c.tracking.lookaheadSessions,2);
verifyEqual(testCase,c.tracking.curve.nSessionsByPhase(2,:),[1 1]);
verifyFalse(testCase,c.cfg.matchRemaining);
verifyFalse(testCase,c.tracking.matchRemaining);
verifyEqual(testCase,c.tracking.sessions.selectionScore, ...
    c.tracking.sessions.nTrackedAfterSelection+0.6*c.tracking.sessions.lookaheadMeanShared);
end

function testDeferredExtractionReorderedRows(testCase)
[T,S,cfg]=fixture();
c=fn_chooseTrackedSessions(fn_prepareTrialData(T,S,cfg),2);
sessionInfo=S([3 1 4 2 5 6],:);
sessionInfo.dffChoice=cell(height(sessionInfo),1);
for s=1:height(sessionInfo)
    sessionInfo.dffChoice{s}=cat(3, ...
        ones(4,3,'single')*(sessionInfo.sessionRec(s)+1), ...
        ones(4,3,'single')*(sessionInfo.sessionRec(s)+2));
end
folder=testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(folder.Folder,'neural.mat'); save(file,'sessionInfo');
c=fn_prepareNeuralData(c,file);
verifyTrue(testCase,c.neuralLoaded);
for k=1:numel(c.neuralSelection)
    item=c.neuralSelection(k); trials=item.trialInfoNeural;
    verifyEqual(testCase,item.nNeuralTrials,height(trials));
    if isempty(trials), verifyEmpty(testCase,item.neuralRaw); continue; end
    verifyEqual(testCase,size(item.neuralRaw,3),height(trials));
    verifyEqual(testCase,reshape(item.neuralRaw(1,1,:),[],1), ...
        single(trials.sessionRec+trials.trialInSession));
    verifyEqual(testCase,sessionInfo.sessionRec(trials.sessionInfoRow),trials.sessionRec);
    verifyEqual(testCase,S.sessionRec(trials.metadataSessionRow),trials.sessionRec);
end
verifyEqual(testCase,c.trackedNeuronQC.nPresentAllSessions,3);
verifyError(testCase,@()fn_chooseTrackedSessions(c,1),'trialCuration:AlreadyLoaded');
end

function testEmptyAndZeroSelections(testCase)
[T,S,cfg]=fixture();
c=fn_chooseTrackedSessions(fn_prepareTrialData(T,S,cfg),0);
verifyEqual(testCase,sum(c.selectionQC.NSelected),0);
verifyEmpty(testCase,c.tracking.selectedNeuronIDs);
c=fn_prepareTrialData(T([],:),S,cfg);
verifyEqual(testCase,sum(c.selectionQC.NSelected),0);
verifyFalse(testCase,isfield(c.tracking,'sessions'));
S.goodTracking(:)=false;
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,sum(c.selectionQC.NSelected),0);
verifyEqual(testCase,height(c.sessionExcludedTrials),height(T));
end

function testTrackingDisabledAndIdentityCheck(testCase)
[T,S,cfg]=fixture();
cfg.selectSessionsByTracking=false;
S=removevars(S,{'offsetMap','ishere'});
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,sum(c.selectionQC.NSelected),10);
verifyError(testCase,@()fn_chooseTrackedSessions(c,2),'trialCuration:TrackingDisabled');
S.dayLabel(1)="WRONG";
verifyError(testCase,@()fn_prepareTrialData(T,S,cfg),'trialCuration:Identity');
end

function testDuplicateConditionsCountOnceInCurve(testCase)
[T,S,cfg]=fixture();
% Intentional overlap with original T1 conditions.
cfg.conditionDef(7).dayLabels="T1L";
cfg.conditionDef(8).dayLabels="T1L";
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.tracking.curve.nTrials(end),8);
verifyEqual(testCase,sum(c.selectionQC.NSelected),12);
end

function testSingleTrialAndAllMissingExtraction(testCase)
[T,S,cfg]=fixture();
cfg.selectSessionsByTracking=false;
T=T(T.sessionRec==10 & T.trialInSession==1,:);
S=S(1,:); S.dffChoice={ones(4,3,'single')};
c=fn_prepareTrialData(T,S,cfg);
loaded=fn_prepareNeuralData(c,S);
verifyEqual(testCase,loaded.neuralSelection(1).nNeuralTrials,1);
S.dffChoice={[]};
loaded=fn_prepareNeuralData(c,S);
verifyEqual(testCase,loaded.neuralSelection(1).nNeuralTrials,0);
verifyEqual(testCase,loaded.neuralSelection(1).nMissingNeural,1);
end

function testCustomConditions(testCase)
[T,S,cfg]=fixture();
cfg.conditionDef=cfg.conditionDef([1 3]);
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,numel(c.selection),2);
verifyEqual(testCase,string({c.selection.name}),["T1_S1_L","T2_S3_L"]);
verifyTrue(testCase,all(c.selection(1).trials.stimuli==1));
verifyTrue(testCase,all(c.selection(2).trials.stimuli==3));
verifyEqual(testCase,c.tracking.curve.nTrials(end),4);
end

function testCombinedConfigPeriodsTypesAndRT(testCase)
[T,S,cfg]=fixture();
cfg.conditionDef=cfg.conditionDef(1:2);
for k=1:2, cfg.conditionDef(k).dayLabels=["T1E";"T1M"]; end
S.dayLabel(1:2)=["T1E";"T1M"];
T.dayLabel(1:4)=["T1E";"T1E";"T1M";"T1M"];
cfg.selectSessionsByTracking=false;
cfg.RTRange=[0.35 0.65];
T.RT(1:4)=[0.35;0.349;0.651;0.65];
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.selection(1).trials.sourceTrialRow,1);
verifyEqual(testCase,c.selection(2).trials.sourceTrialRow,4);
verifyEqual(testCase,c.conditionDef,cfg.conditionDef);
cfg.useRTFilter=false;
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.selection(1).trials.sourceTrialRow,[1;3]);
verifyEqual(testCase,c.selection(2).trials.sourceTrialRow,[2;4]);
end

function testPartialConfigUsesCombinedDefinitions(testCase)
[T,S,cfg]=fixture();
defaults=fn_defaultTrialSelectionConfig(); cfg.conditionDef=defaults.conditionDef;
expected=fn_prepareTrialData(T,S,cfg);
cfg=rmfield(cfg,'conditionDef');
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.conditionDef,expected.conditionDef);
verifyEqual(testCase,c.selectionQC,expected.selectionQC);
cfg.conditionDef=[];
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.cfg.conditionDef,expected.conditionDef);
end

function testSingleConditionLabel(testCase)
[T,S,cfg]=fixture();
cfg.conditionDef=cfg.conditionDef(1);
cfg.conditionDef.name="T1, S1, L";
verifyFalse(testCase,isfield(cfg.conditionDef,'displayName'));
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.selection.displayName,"T1, S1, L");
S.dffChoice=repmat({ones(4,3,2,'single')},height(S),1);
c=fn_prepareNeuralData(c,S);
key=matlab.lang.makeValidName('T1, S1, L');
verifyEqual(testCase,fieldnames(c.byCondition),{key});
verifyEqual(testCase,c.byCondition.(key).displayName,"T1, S1, L");
verifyEqual(testCase,size(c.byCondition.(key).neuralRaw,3),2);
% Older saved configurations still accept their explicit displayName.
cfg.conditionDef.displayName="Old display label";
c=fn_prepareTrialData(T,S,cfg);
verifyEqual(testCase,c.selection.displayName,"Old display label");
end

function testConditionLabelCollisions(testCase)
[T,S,cfg]=fixture();
cfg.conditionDef=cfg.conditionDef(1:2);
cfg.conditionDef(1).name="A-B";
cfg.conditionDef(2).name="A_B";
verifyError(testCase,@()fn_prepareTrialData(T,S,cfg),'trialCuration:ConditionLabel');
cfg.conditionDef(1).name="";
verifyError(testCase,@()fn_prepareTrialData(T,S,cfg),'trialCuration:ConditionLabel');
end

function [T,S,cfg]=fixture()
cfg=fn_expertTrialSelectionConfig(); cfg.makePlots=false; cfg.verbose=false;
cfg.minSessionsPerStage=1; cfg.matchRemaining=false;
cfg.phaseOrder=["T1L","T2L"];
sessionRec=[10;20;30;40;50;60];
dayLabel=["T1L";"T1L";"T2L";"T2L";"T1L";"T2L"];
goodTracking=[true;true;true;true;false;true];
ishere=[1 1 1 1;1 1 0 0;1 1 1 0;1 0 1 0;1 1 1 1;1 1 1 1];
offsetMap={100*ones(2);zeros(2);10*ones(2);20*ones(2);zeros(2);[]};
S=table(sessionRec,dayLabel,goodTracking,ishere,offsetMap);
row=repelem((1:6)',2);
sessionRec=S.sessionRec(row); dayLabel=S.dayLabel(row);
trialInSession=repmat([1;2],6,1);
taskLabel=repmat("T1",12,1); taskLabel(dayLabel=="T2L")="T2";
stimuli=trialInSession; stimuli(dayLabel=="T2L")=stimuli(dayLabel=="T2L")+2;
action=trialInSession; RT=repmat(0.5,12,1);
T=table(sessionRec,trialInSession,dayLabel,taskLabel,stimuli,action,RT);
end
