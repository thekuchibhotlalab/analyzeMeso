function tests=testLearningChoiceAxes
tests=functiontests(localfunctions);
end
function setupOnce(t)
repo=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'analysis','learningChoiceAxes')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'organizer','trialCuration'),'IncludingSubfolders',true));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'helper_function')));
[T,S,cfg,sc,p]=fixture();
[c,plan]=fn_prepareLearningChoiceData(T,S,S,sc,cfg);
r=fn_analyzeLearningChoiceAxes(c,cfg,p);
t.TestData=struct('T',T,'S',S,'cfg',cfg,'selectionCfg',sc,'plot',p,'curated',c,'plan',plan,'result',r);
end
function testAnchorsAndWindows(t)
d=t.TestData; p=d.plan;
verifyEqual(t,p.t2AnchorRow,41); verifyEqual(t,p.intAnchorRow,201);
verifyEqual(t,p.chunkWidthTrials,40); verifyEqual(t,sum(p.windows.period=="T2"),4);
verifyEqual(t,sum(p.windows.period=="Int"),3);
verifyEqual(t,p.priorT1Rows,(1:40)');
verifyTrue(t,all(ismember(1:40,p.windows.sourceTrialRows{1})));
verifyFalse(t,any(ismember(1:40,p.windows.sourceTrialRows{2})));
verifyFalse(t,any(p.windows.sourceTrialRows{4}>=201));
verifyGreaterThan(t,numel(intersect(p.windows.sourceTrialRows{2},p.windows.sourceTrialRows{3})),0);
verifyEqual(t,p.windows.sourceTrialRows{end}(end),height(d.T));
end
function testFixedCellsAccuracyAndAngle(t)
r=t.TestData.result.animals{1};
verifyEqual(t,r.neuronIDs,(1:4)'); verifyEqual(t,r.choiceFrames,28:30);
verifyGreaterThan(t,min(r.accuracy,[],'all'),.9);
verifyLessThan(t,mean(r.cosine(1:4)),.4);
verifyGreaterThan(t,mean(r.cosine(5:end)),.7);
verifyEqual(t,diag(r.temporalCosine{1}),ones(7,1),'AbsTol',1e-12);
verifyEqual(t,r.accuracySEM,std(r.accuracyByRepeat,0,3)/sqrt(2),'AbsTol',1e-12);
for b=1:7
    for task=1:2
        rows=r.trialRows{b,task,1}; f=r.foldAssignments{b,task,1};
        y=t.TestData.T.action(rows);
        verifyEqual(t,sum(y==1),sum(y==2)); verifyEqual(t,numel(unique(rows)),numel(rows));
        verifyEmpty(t,intersect(rows(f==1),rows(f~=1)));
    end
end
end
function testSVMAndRawCoordinateWeights(t)
cfg=t.TestData.cfg; cfg.decoder='svm'; cfg.repeats=2;
r=fn_analyzeLearningChoiceAxes(t.TestData.curated,cfg,t.TestData.plot);
verifyGreaterThan(t,min(r.animals{1}.accuracy,[],'all'),.9);
verifyLessThan(t,mean(r.animals{1}.cosine(1:4)),.5);
verifyGreaterThan(t,mean(r.animals{1}.cosine(5:end)),.6);
X=[-3 100;-2 105;-1 90;1 110;2 95;3 100]; y=[-1;-1;-1;1;1;1];
for decoder=["lda","svm"]
    cfg.decoder=decoder; m=fn_fitLearningChoiceDecoder(X,y,cfg);
    verifyEqual(t,norm(m.axis),1,'AbsTol',1e-12);
    verifyGreaterThan(t,mean(X(y==1,:)*m.weights)-mean(X(y==-1,:)*m.weights),0);
end
end
function testCompositeMatchesChoiceDecoder(t)
d=t.TestData; sc=d.selectionCfg; sc.neuralField='dffStimChoice';
[c,~]=fn_prepareLearningChoiceData(d.T,d.S,d.S,sc,d.cfg);
verifyEqual(t,c.neuralAlignment.choiceFrame,36); verifyEqual(t,c.cfg.alignedEventFrame,36);
r=fn_analyzeLearningChoiceAxes(c,d.cfg,d.plot);
verifyEqual(t,r.animals{1}.choiceFrames,33:35);
verifyEqual(t,r.animals{1}.accuracy,d.result.animals{1}.accuracy);
verifyEqual(t,r.animals{1}.axesByRepeat,d.result.animals{1}.axesByRepeat);
end
function testMissingTrialsDoNotShiftWindows(t)
d=t.TestData; c=d.curated;
% Remove all T2 choices in early bins. No interpolation or substituted axes.
for k=1:numel(c.neuralSelection)
    s=c.neuralSelection(k); T=s.trialInfoNeural;
    keep=~(ismember(T.stimuli,[3 4])&T.sourceTrialRow<201);
    c.neuralSelection(k).trialInfoNeural=T(keep,:);
    c.neuralSelection(k).neuralRaw=s.neuralRaw(:,:,keep);
end
r=fn_analyzeLearningChoiceAxes(c,d.cfg,d.plot); a=r.animals{1};
verifyEqual(t,a.windows,d.plan.windows);
verifyTrue(t,all(isnan(a.cosine(1:4))));
verifyTrue(t,all(isfinite(a.accuracy(1:4,1))));
verifyTrue(t,all(isnan(a.accuracy(1:4,2))));
end
function testPlotsAndExport(t)
p=t.TestData.plot; p.makePlot=true; p.visible=false;
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture); p.savePath=folder.Folder;
[figs,files]=fn_plotLearningChoiceAxes(t.TestData.result,p);
verifyEmpty(t,figs.group); verifyTrue(t,isfile(files.group.png)); verifyTrue(t,isfile(files.group.fig));
verifyTrue(t,isfile(fullfile(folder.Folder,[p.prefix '_summary.csv'])));
end
function testBinningChangeRequiresPreparation(t)
cfg=t.TestData.cfg; cfg.windowWidthChunks=3;
verifyError(t,@()fn_analyzeLearningChoiceAxes(t.TestData.curated,cfg,t.TestData.plot),'learningAxes:Bins');
end
function testNonfiniteTrialAndSourceClock(t)
d=t.TestData; c=d.curated;
k=find(arrayfun(@(s)~isempty(s.neuralRaw),c.neuralSelection),1);
row=c.neuralSelection(k).trialInfoNeural.sourceTrialRow(1);
c.neuralSelection(k).neuralRaw(1,28,1)=NaN;
state=rng; r=fn_analyzeLearningChoiceAxes(c,d.cfg,d.plot); verifyEqual(t,rng,state);
verifyEqual(t,r.animals{1}.invalidTrialRows,row);
verifyEqual(t,r.animals{1}.windows,d.plan.windows);
verifyEqual(t,r.animals{1}.neuronIDs,(1:4)');
end
function [T,S,cfg,sc,p]=fixture()
[cfg,p,sc]=fn_learningChoiceAxesConfig(); cfg.nT2Bins=4; cfg.folds=2; cfg.repeats=2;
cfg.minTrialsPerClass=4; cfg.verbose=false; p.makePlot=false;
sc.sessionCountMethod='fixed'; sc.numSessions=Inf; sc.trackingMethod='greedy';
sc.verbose=false; sc.useRTFilter=true; sc.RTRange=[.2 .65]; sc.animalID='synthetic';
dayLabel=["T1L";"T2E";"T2M";"T2L";"T1R";"Int";"Int";"Int"];
sessionRec=(1:8)'; date=20260100+sessionRec; goodTracking=true(8,1);
ishere=ones(8,4); offsetMap=repmat({zeros(2)},8,1);
S=table(sessionRec,date,dayLabel,goodTracking,ishere,offsetMap);
row=repelem((1:8)',40); sessionRec=row; date=S.date(row); dayLabel=S.dayLabel(row);
trialInSession=repmat((1:40)',8,1); stimuli=repmat((1:4)',80,1);
stimuli(1:40)=repmat([1;2],20,1); action=1+mod(stimuli+1,2);
taskLabel=repmat("T1",320,1); taskLabel(stimuli>=3)="T2"; RT=.4*ones(320,1);
T=table(sessionRec,date,dayLabel,trialInSession,taskLabel,stimuli,action,RT);
stream=RandStream('mt19937ar','Seed',13); S.dffChoice=cell(8,1); S.dffStim=cell(8,1);
for s=1:8
    X=.3*randn(stream,4,100,40); rows=find(row==s);
    for j=1:40
        direction=[1;0;0;0];
        if T.stimuli(rows(j))>=3&&s<6, direction=[0;1;0;0]; end
        X(:,28:30,j)=X(:,28:30,j)+3*direction*(2*T.action(rows(j))-3);
    end
    S.dffChoice{s}=single(X); S.dffStim{s}=zeros(4,100,40,'single');
end
end
