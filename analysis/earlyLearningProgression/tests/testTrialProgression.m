function tests=testTrialProgression
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
repo=fileparts(fileparts(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'organizer','trialCuration','config')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'organizer','trialCuration','helper')));
end
function testSelectionConfigWithEmptyProbeCells(t)
selectionCfg=fn_earlyT1TrialSelectionConfig();
[c,p]=fn_trialProgressionConfig(); c.verbose=false; p.makePlot=false;
c.time=0:3; c.startTrials=1:2; c.nEndTrials=2;
c.nProgressionTrials=30;
c.animalLabels="mouse"+string(1:6);
A=cell(numel(selectionCfg.conditionDef),6);
for k=1:size(A,1)
    for a=1:5 % Entire sixth animal column is empty.
        A{k,a}=repmat(reshape(1:35,1,1,[]),a+2,4,1)*(k+a)/10;
    end
end
A(5,1:3)={[]}; A{5,4}=A{5,4}(:,:,1:9); A{5,5}=A{5,5}(:,:,1:14);
A{6,4}=A{6,4}(:,:,1); % A singleton cannot supply a trial-variance estimate.
A(12,:)={[]}; % A completely missing probe condition retains its row/label.
r=fn_analyzeTrialProgression(A,selectionCfg,c,p);
verifyEqual(t,size(r.trialCounts),[12 6]);
verifyEqual(t,r.conditions.conditionName,string({selectionCfg.conditionDef.name})');
verifyTrue(t,all(ismember({'dayLabels','stimulus','action','responseTypes'},r.conditions.Properties.VariableNames)));
verifyEqual(t,r.byCondition(5).nProgressionTrials,9);
verifyEqual(t,r.byCondition(5).animalAudit.included,[false;false;false;true;true;false]);
verifyEqual(t,unique(r.byCondition(5).neurons.animalIndex),[4;5]);
verifyEqual(t,unique(r.byCondition(5).neurons.animalLabel),["mouse4";"mouse5"]);
verifyFalse(t,r.byCondition(6).animalAudit.included(4));
verifyEqual(t,r.byCondition(12).status,"no usable neurons");
verifyEmpty(t,r.byCondition(12).allPopulation);
verifyEqual(t,r.byCondition(1).nProgressionTrials,30);
r2=fn_analyzeTrialProgression(A,selectionCfg.conditionDef,c,p);
verifyEqual(t,r2.conditions,r.conditions);
verifyError(t,@()fn_analyzeTrialProgression(A,selectionCfg.conditionDef(1:2),c,p),'trialProgression:Conditions');
end
function testVarianceAtFixedTimeAndConditionSelection(t)
[A,T,c,p]=fixture(); r=fn_analyzeTrialProgression(A,T,c,p);
S=r.byCondition(1); verifyEqual(t,S.nProgressionTrials,30);
verifyEqual(t,S.neurons.varianceScore(1),0,'AbsTol',1e-12); % Strong PSTH alone is not trial variance.
verifyEqual(t,S.neurons.varianceScore(2),var(1:30,0),'AbsTol',1e-12);
verifyEqual(t,S.neurons.varianceScore(3),4*var(1:30,0),'AbsTol',1e-12);
verifyEqual(t,find(S.selectedNeuronMask),3);
verifyEqual(t,find(r.byCondition(2).selectedNeuronMask),2);
verifyEqual(t,S.allPopulation.displayPsth(:,1),mean(A{1}(:,:,1),1)');
verifyEqual(t,S.allPopulation.endPsth,mean(mean(A{1}(:,:,36:40),3),1)');
verifyEqual(t,S.animalAudit.endTrials{1},36:40);
verifyFalse(t,isfield(r,'figures'));
end
function testProgressionDirectionAndComparison(t)
[A,T,c,p]=fixture(); c.selectionMethod='progression'; c.comparisonReference='progression';
r=fn_analyzeTrialProgression(A,T,c,p); S=r.byCondition(1);
verifyEqual(t,find(S.selectedNeuronMask),2); verifyEqual(t,S.animalAudit.endTrials{1},26:30);
verifyEqual(t,S.neurons.meanSlopePerTrial,[0;1;-2],'AbsTol',1e-12);
c.progressionDirection='negative'; c.endTrials=12:15;
r=fn_analyzeTrialProgression(A,T,c,p);
verifyEqual(t,find(r.byCondition(1).selectedNeuronMask),3);
verifyEqual(t,r.byCondition(1).animalAudit.endTrials{1},12:15);
end
function testPoolingAndShortTrials(t)
[A,T,c,p]=fixture(); A=[A A]; A{1,2}=A{1,2}(:,:,1:12); A{2,2}=[];
A{1,2}(1,1,1)=NaN; c.comparisonReference='progression';
r=fn_analyzeTrialProgression(A,T,c,p); S=r.byCondition(1);
verifyEqual(t,S.nProgressionTrials,12); verifyEqual(t,S.allPopulation.nNeurons,5);
verifyEqual(t,S.neurons.animalIndex,[1;1;1;2;2]);
verifyEqual(t,S.neurons.rowInAnimal,[1;2;3;2;3]);
verifyEqual(t,S.animalAudit.nDroppedNeurons,[0;1]);
verifyEqual(t,r.byCondition(2).allPopulation.nNeurons,3);
end
function testConstantAndHiddenPlots(t)
[A,T,c,p]=fixture(); A{2}=zeros(size(A{2}));
A{3,1}=[]; T=[T;table(3,'VariableNames',{'stimulus'})];
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
before=findall(groot,'Type','figure'); [r,f]=fn_analyzeTrialProgression(A,T,c,p);
verifyFalse(t,any(r.byCondition(2).selectedNeuronMask));
verifyEqual(t,r.byCondition(2).selectedPopulation.nNeurons,0);
verifyTrue(t,isfile(r.plotFiles.allNeurons)); verifyFalse(t,isfield(r.plotFiles,'selectedNeurons'));
verifyEmpty(t,f.allNeurons); verifyEqual(t,findall(groot,'Type','figure'),before);
end
function [A,T,c,p]=fixture()
[c,p]=fn_trialProgressionConfig(); c.verbose=false; c.time=0:3;
c.nProgressionTrials=30; c.startTrials=1:5; c.nEndTrials=5; c.comparisonReference='all';
c.nSelectedNeurons=1; p.makePlot=false; p.showAnimals=false;
T=table([1;2],'VariableNames',{'stimulus'}); A=cell(2,1);
base=[0 10 20 30];
for trial=1:40
    A{1}(:,:,trial)=[base;ones(1,4)*trial;-2*ones(1,4)*trial];
    A{2}(:,:,trial)=[base;3*ones(1,4)*trial;ones(1,4)*trial];
end
end

function testPhaseOutcomeChronologyAndDefaults(t)
[A,T,info,c,p]=groupFixture();
verifyEqual(t,c.nProgressionTrials,50); verifyEqual(t,c.startTrials,1:10);
verifyEqual(t,c.nEndTrials,10); verifyEqual(t,c.comparisonReference,'progression');
r=fn_analyzeTrialProgression(A,T,c,p,info);
verifyEqual(t,r.conditions.conditionName,["T1E_rewarded";"T1E_incorrect";"T1E_probe"]);
verifyEqual(t,r.trialCounts,[120 0;45 0;75 0]);
for g=1:3
    M=r.trialMap{g,1}; R=r.byCondition(g).nProgressionTrials;
    verifyTrue(t,issorted(M.sourceTrialRow));
    verifyEqual(t,unique(M.responseType),r.conditions.responseType(g));
    expected=1.5*M.sourceTrialRow(1:R)';
    verifyEqual(t,r.byCondition(g).allPopulation.trialPsth,repmat(expected,4,1));
    verifyEqual(t,r.byCondition(g).allPopulation.meanPsth,repmat(mean(expected),4,1));
end
verifyEqual(t,r.byCondition(1).animalAudit.endTrials{1},41:50);
verifyEqual(t,r.byCondition(2).animalAudit.endTrials{1},36:45);
% Probe outcomes in the incorrect-choice source row must join the probe group.
verifyTrue(t,any(r.trialMap{3,1}.sourceCondition==3));
verifyEqual(t,r.sourceConditions,T);
% Keep phases separate even when stimulus definitions have identical labels.
T.dayLabels(4)="T1M"; info{4,1}.dayLabel(:)="T1M";
r=fn_analyzeTrialProgression(A,T,c,p,info);
verifyEqual(t,r.conditions.conditionName(4:6),["T1M_rewarded";"T1M_incorrect";"T1M_probe"]);
verifyEqual(t,r.trialCounts(3,1),15); verifyEqual(t,r.trialCounts(6,1),60);
verifyEqual(t,r.byCondition(4).status,"no usable neurons");
end

function testGroupingRejectsMisalignedOrOverlappingTrials(t)
[A,T,info,c,p]=groupFixture();
verifyError(t,@()fn_analyzeTrialProgression(A,T,c,p),'trialProgression:TrialInfo');
bad=info; bad{1,1}=bad{1,1}(1:end-1,:);
verifyError(t,@()fn_analyzeTrialProgression(A,T,c,p,bad),'trialProgression:TrialInfo');
bad=info; bad{2,1}.sourceTrialRow(1)=bad{1,1}.sourceTrialRow(1);
verifyError(t,@()fn_analyzeTrialProgression(A,T,c,p,bad),'trialProgression:DuplicateTrial');
end

function testConcatenatePhasesInExplicitOrder(t)
[A,T,info,c,p]=groupFixture(); c.groupBy='outcome'; c.nProgressionTrials=Inf;
for k=1:4
    % Deliberately interleave phase labels and reverse source rows in the input.
    info{k,1}.dayLabel=repmat(["T1L";"T1E";"T1M"],20,1);
end
r=fn_analyzeTrialProgression(A,T,c,p,info);
verifyEqual(t,r.conditions.conditionName,["rewarded";"incorrect";"probe"]);
verifyEqual(t,r.trialCounts,[120 0;45 0;75 0]);
for g=1:3
    M=r.trialMap{g,1}; [~,phaseRank]=ismember(M.dayLabel,c.phaseOrder);
    verifyTrue(t,issorted(phaseRank));
    for phase=c.phaseOrder
        verifyTrue(t,issorted(M.sourceTrialRow(M.dayLabel==phase)));
    end
    verifyEqual(t,r.byCondition(g).nProgressionTrials,height(M));
    verifyEqual(t,r.byCondition(g).allPopulation.trialPsth, ...
        repmat(1.5*M.sourceTrialRow',4,1));
end
verifyEqual(t,r.byCondition(1).animalAudit.endTrials{1},111:120);
% The configured limit applies to the concatenated sequence, never per phase.
c.nProgressionTrials=50; limited=fn_analyzeTrialProgression(A,T,c,p,info);
verifyEqual(t,limited.byCondition(1).allPopulation.trialPsth, ...
    r.byCondition(1).allPopulation.trialPsth(:,1:50));
% Multiple phases still produce just one overview row and three heatmaps.
p.makePlot=true; p.visible=true;
f=fn_plotTrialProgression(r,p); handles=struct2cell(f);
cleanup=onCleanup(@()close([handles{:}])); %#ok<NASGU>
verifyNumElements(t,findall(f.outcomeComparison,'Type','axes'),1);
verifyNumElements(t,findall(f.allNeurons,'Type','image'),3);
c.phaseOrder=["T1E","T1M"];
verifyError(t,@()fn_analyzeTrialProgression(A,T,c,p,info),'trialProgression:PhaseOrder');
end

function testTimeWindowMatchesManualCrop(t)
[A,T,c,p]=fixture();
A{1}(1,1,:)=100*(1:40); % Large variation outside the requested window.
A{1}(3,4,:)=NaN;       % Nonfinite values outside the window must not drop a neuron.
c.timeWindow=[1 2]; c.scoreTimeWindow=[1.5 2];
r=fn_analyzeTrialProgression(A,T,c,p);
cropped=cellfun(@(x)x(:,2:3,:),A,'UniformOutput',false);
c.time=[1 2]; c.timeWindow=[];
manual=fn_analyzeTrialProgression(cropped,T,c,p);
verifyEqual(t,r.time,[1 2]); verifyEqual(t,r.inputTimeBins,[2 3]);
verifyEqual(t,r.scoreBins,2); verifyEqual(t,r.byCondition,manual.byCondition);
verifyEqual(t,r.byCondition(1).animalAudit.nDroppedNeurons,0);
% The frame-rate/event-frame path selects the same original input bins.
c.time=[]; c.frameRate=1; c.eventFrame=1; c.timeWindow=[1 2];
inferred=fn_analyzeTrialProgression(A,T,c,p);
verifyEqual(t,inferred.byCondition,r.byCondition);
c.timeWindow=[10 11];
verifyError(t,@()fn_analyzeTrialProgression(A,T,c,p),'trialProgression:Time');
c.timeWindow=[1 2]; c.scoreTimeWindow=[3 4];
verifyError(t,@()fn_analyzeTrialProgression(A,T,c,p),'trialProgression:Time');
end

function testTimeWindowRestrictsEveryTimePlot(t)
[A,T,info,c,p]=groupFixture(); c.timeWindow=[1 2];
r=fn_analyzeTrialProgression(A,T,c,p,info);
p.makePlot=true; p.visible=true;
f=fn_plotTrialProgression(r,p); handles=struct2cell(f);
cleanup=onCleanup(@()close([handles{:}])); %#ok<NASGU>
nTimeAxes=0;
for fig=[handles{:}]
    axesList=findall(fig,'Type','axes');
    for ax=reshape(axesList,1,[])
        if ~strcmp(ax.XLabel.String,'Time (s)'), continue; end
        nTimeAxes=nTimeAxes+1; verifyEqual(t,ax.XLim,[1 2]);
        for h=reshape(findall(ax,'Type','line'),1,[])
            verifyEqual(t,h.XData,[1 2]);
        end
        for h=reshape(findall(ax,'Type','image'),1,[])
            verifyEqual(t,size(h.CData,2),2);
        end
    end
end
verifyEqual(t,nTimeAxes,12); % Nine main time panels + one outcome + two stimulus panels.
end

function testBinnedAndSmoothedOutcomePlots(t)
[A,T,info,c,p]=groupFixture(); r=fn_analyzeTrialProgression(A,T,c,p,info);
oldVisible=get(groot,'DefaultFigureVisible'); set(groot,'DefaultFigureVisible','off');
cleanup=onCleanup(@()set(groot,'DefaultFigureVisible',oldVisible)); %#ok<NASGU>
p.makePlot=true; p.visible=true;
for method={'bin','smooth','none'}
    p.heatmapMethod=method{1}; f=fn_plotTrialProgression(r,p);
    handles=struct2cell(f); closer=onCleanup(@()close([handles{:}]));
    verifyTrue(t,isgraphics(f.outcomeComparison));
    im=findall(f.allNeurons,'Type','image'); verifyNumElements(t,im,3);
    raw=r.byCondition(1).allPopulation.trialPsth;
    switch method{1}
        case 'bin', expected=reshape(mean(reshape(raw,4,5,10),2),4,10)';
        case 'smooth', expected=movmean(raw,5,2,'Endpoints','shrink')';
        case 'none', expected=raw';
    end
    verifyTrue(t,any(arrayfun(@(h)isequal(h.CData,expected),im)));
    clear closer;
end
end

function testEqualCountStimulusBinsUseAllTrialsPerAnimal(t)
[A,T,info,c,p]=groupFixture(); c.groupBy='outcome'; c.nProgressionTrials=5;
c.timeWindow=[1 2]; c.startTrials=1:2; c.nEndTrials=2;
for k=1:4
    n=[13 20 10 0]; A{k,1}=A{k,1}(:,:,1:n(k)); info{k,1}=info{k,1}(1:n(k),:);
    info{k,1}.stimuli=repmat(T.stimulus(k),n(k),1);
    phases=repmat(["T1L";"T1E";"T1M"],ceil(n(k)/3),1);
    info{k,1}.dayLabel=phases(1:n(k));
end
A{1,2}=A{1,1}(:,:,1:7)+1000; info{1,2}=info{1,1}(1:7,:);
% Actual metadata must override the per-condition stimulus definition.
T.stimulus(:)=99;
r=fn_analyzeTrialProgression(A,T,c,p,info); B=r.stimulusBins;
verifyEqual(t,B.conditions.stimulus,[1;2]);
verifyEqual(t,B.trialCounts,[23 7;20 0]);
verifyEqual(t,size(B.meanPsth),[2 10 2 2]);
verifyEqual(t,B.binCounts(:,1,1),diff(floor((0:10)'*23/10)));
verifyEqual(t,sum(B.binCounts(:,1,2)),7);
verifyTrue(t,all(isnan(B.meanPsth(:,B.binCounts(:,1,2)==0,1,2)),'all'));
verifyTrue(t,all(isnan(B.meanPsth(:,:,2,2)),'all'));
verifyEqual(t,B.status(1,2),"computed with empty bins");
for s=1:2
    M=B.trialMap{s,1}; [~,rank]=ismember(M.dayLabel,c.phaseOrder);
    verifyTrue(t,issorted(rank));
    covered=[];
    for j=1:10
        R=B.binRanges{s,1}; take=R.firstTrial(j):R.lastTrial(j);
        covered=[covered take]; %#ok<AGROW>
        verifyEqual(t,B.meanPsth(:,j,s,1),repmat(1.5*mean(M.sourceTrialRow(take)),2,1));
    end
    verifyEqual(t,covered,1:height(M));
end
% Nonfinite activity outside the time window is irrelevant, inside is audited.
A{1,1}(1,1,1)=NaN;
r2=fn_analyzeTrialProgression(A,T,c,p,info);
verifyEqual(t,r2.stimulusBins.meanPsth,B.meanPsth);
A{1,1}(1,2,1)=NaN;
r3=fn_analyzeTrialProgression(A,T,c,p,info);
verifyEqual(t,r3.stimulusBins.nNeurons(1,1),1);
verifyEqual(t,r3.stimulusBins.nDroppedNeurons(1,1),1);
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
[f,files]=fn_plotTrialProgression(r,p);
verifyEmpty(t,f.stimulusBins); verifyTrue(t,isfile(files.stimulusBins));
c.nStimulusBins=0; disabled=fn_analyzeTrialProgression(A,T,c,struct('makePlot',false),info);
verifyEmpty(t,disabled.stimulusBins);
end

function [A,T,info,c,p]=groupFixture()
[c,p]=fn_trialProgressionConfig(); c.groupBy='phaseOutcome'; c.time=0:3;
c.verbose=false; p.makePlot=false; p.showAnimals=false;
T=table(["S1L";"S2R";"incorrectChoice";"probe"],repmat("T1E",4,1), ...
    'VariableNames',{'conditionName','dayLabels'});
T.stimulus=[1;2;1;2];
A=cell(4,2); info=cell(size(A));
for k=1:4
    source=4*(60:-1:1)'+k; outcome=ones(60,1);
    if k==3, outcome(:)=-1; outcome(1:4:end)=2; end
    if k==4, outcome(:)=2; end
    A{k,1}=repmat(reshape(source,1,1,[]),2,4,1).*[1;2];
    info{k,1}=table(repmat("T1E",60,1),outcome,source, ...
        'VariableNames',{'dayLabel','responseType','sourceTrialRow'});
end
end

function testNormalizationPoolsPhasesTypesAndAllTrials(t)
[A,T,info,c,p]=groupFixture(); c.groupBy='outcome'; c.timeWindow=[1 2];
c.nProgressionTrials=5; c.startTrials=1:2; c.nEndTrials=2;
for k=1:4
    info{k,1}.dayLabel=[repmat("T1E",30,1);repmat("T1M",30,1)];
    if k<4
        A{k,2}=2*A{k,1}(:,:,1:(10+k))+100;
        info{k,2}=info{k,1}(1:(10+k),:);
    end
end
A{1,1}(1,1,1)=NaN; % Outside timeWindow; must not affect fit or exclusions.
for method={'zscore','rms'}
    c.normalization=method{1}; r=fn_analyzeTrialProgression(A,T,c,p,info);
    normalized=A;
    for a=1:2
        chunks=cell(1,4);
        for k=1:4
            if ~isempty(A{k,a}), chunks{k}=reshape(A{k,a}(:,2:3,:),2,[]); end
        end
        pooled=cat(2,chunks{:});
        if strcmp(method{1},'zscore'), offset=mean(pooled,2); scale=std(pooled,0,2);
        else, offset=zeros(2,1); scale=sqrt(mean(pooled.^2,2)); end
        verifyEqual(t,r.normalization.offset{a},offset,'AbsTol',1e-10);
        verifyEqual(t,r.normalization.scale{a},scale,'AbsTol',1e-10);
        verifyEqual(t,r.normalization.nSamples{a},repmat(size(pooled,2),2,1));
        for k=1:4
            if ~isempty(A{k,a}), normalized{k,a}=(A{k,a}-offset)./scale; end
        end
    end
    verifyEqual(t,r.normalization.inputTimeBins,[2 3]);
    manualCfg=c; manualCfg.normalization='none';
    expected=fn_analyzeTrialProgression(normalized,T,manualCfg,p,info);
    for k=1:3
        verifyEqual(t,r.byCondition(k).allPopulation,expected.byCondition(k).allPopulation,'AbsTol',1e-10);
        verifyEqual(t,r.byCondition(k).selectedPopulation,expected.byCondition(k).selectedPopulation,'AbsTol',1e-10);
        verifyEqual(t,r.byCondition(k).neurons.varianceScore,expected.byCondition(k).neurons.varianceScore,'AbsTol',1e-10);
    end
    verifyEqual(t,r.stimulusBins.meanPsth,expected.stimulusBins.meanPsth,'AbsTol',1e-10);
end
end

function testNormalizationConstantMissingAndEmptyNeurons(t)
[c,p]=fn_trialProgressionConfig(); c.time=0:1; c.nProgressionTrials=6;
c.startTrials=1:2; c.nEndTrials=2; c.verbose=false; p.makePlot=false;
A=cell(2,2); A{1,1}=repmat([7;0;NaN],1,2,6); A{2,1}=repmat([7;0;NaN],1,2,10);
T=table([1;2],'VariableNames',{'stimulus'});
c.normalization='zscore'; r=fn_analyzeTrialProgression(A,T,c,p);
verifyEqual(t,r.normalization.offset{1},[7;0;0]);
verifyEqual(t,r.normalization.scale{1},ones(3,1));
verifyEqual(t,r.normalization.degenerate{1},true(3,1));
verifyEqual(t,r.normalization.nSamples{1},[32;32;0]);
verifyEmpty(t,r.normalization.scale{2});
verifyEqual(t,r.byCondition(1).allPopulation.meanPsth,zeros(2,1));
verifyEqual(t,r.byCondition(1).animalAudit.nDroppedNeurons,[1;0]);
c.normalization='rms'; r=fn_analyzeTrialProgression(A,T,c,p);
verifyEqual(t,r.normalization.offset{1},zeros(3,1));
verifyEqual(t,r.normalization.scale{1},[7;1;1]);
verifyEqual(t,r.byCondition(1).allPopulation.meanPsth,[0.5;0.5]);
end

function testAnimalSummariesAndMainPlots(t)
[~,defaults]=fn_trialProgressionConfig(); verifyTrue(t,defaults.showAnimals);
[A,T,c,p]=fixture(); A=[A A cell(2,1)];
A{1,2}=A{1,2}+20; A{2,2}=A{2,2}*3;
A{1,2}(1,1,1)=NaN;
c.normalization='zscore'; c.animalLabels=["mouseA","mouseB","missingMouse"];
r=fn_analyzeTrialProgression(A,T,c,p);
for k=1:2
    C=r.byCondition(k); weighted=zeros(size(C.allPopulation.trialPsth)); nn=0; nSelected=0;
    for a=1:2
        S=C.byAnimal(a).allPopulation;
        rows=C.neurons.rowInAnimal(C.neurons.animalIndex==a);
        X=(A{k,a}-r.normalization.offset{a})./r.normalization.scale{a};
        expected=reshape(mean(X(rows,:,1:C.nProgressionTrials),1),4,[]);
        verifyEqual(t,S.trialPsth,expected,'AbsTol',1e-12);
        verifyEqual(t,C.byAnimal(a).animalLabel,c.animalLabels(a));
        nExpected=sum(C.neurons.animalIndex==a&C.neurons.selected);
        verifyEqual(t,C.byAnimal(a).selectedPopulation.nNeurons,nExpected);
        weighted=weighted+S.nNeurons*S.trialPsth; nn=nn+S.nNeurons;
        nSelected=nSelected+C.byAnimal(a).selectedPopulation.nNeurons;
    end
    verifyEqual(t,weighted/nn,C.allPopulation.trialPsth,'AbsTol',1e-12);
    verifyEqual(t,nSelected,C.selectedPopulation.nNeurons);
    verifyEmpty(t,C.byAnimal(3).allPopulation);
    verifyEqual(t,C.byAnimal(3).status,"no usable neurons");
end
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.showAnimals=true; p.visible=false; p.savePath=folder.Folder;
before=findall(groot,'Type','figure'); [f,files]=fn_plotTrialProgression(r,p);
verifyNumElements(t,fieldnames(f),4); % Pooled plus three animals, one main figure each.
verifyFalse(t,any(contains(string(fieldnames(f)),'selectedNeurons')));
verifyFalse(t,any(contains(string(fieldnames(files)),'selectedNeurons')));
for a=1:3
    name=sprintf('animal%d_allNeurons',a);
    verifyEmpty(t,f.(name)); verifyTrue(t,isfile(files.(name)));
end
verifyEqual(t,findall(groot,'Type','figure'),before);
end
