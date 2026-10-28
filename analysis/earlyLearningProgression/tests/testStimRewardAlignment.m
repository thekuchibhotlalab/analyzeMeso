function tests=testStimRewardAlignment
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
end
function testOffsetsOrderAndCrossBinCorrelation(t)
[A,D,T,c,p]=fixture();
r=fn_analyzeStimRewardAlignment(A,D,c,p,T); B=r.byStimulus(1,1);
verifyEqual(t,B.trials.sourceTrialRow,(1:105)');
verifyEqual(t,B.stimulusActivity,(1:4)'+(1:105)*0.001+10,'AbsTol',1e-12);
verifyEqual(t,B.rewardActivity,(1:4)'.*[-ones(1,50) ones(1,55)]+(1:105)*0.003+10,'AbsTol',1e-12);
verifyEqual(t,B.bins.nTrials,[50;50;5]);
verifyEqual(t,B.withinBinCorrelation,[-1;1;1],'AbsTol',1e-12);
verifyEqual(t,B.crossBinCorrelation,repmat([-1 1 1],3,1),'AbsTol',1e-12);
verifyEqual(t,B.neuronRows,(1:4)');
verifyEqual(t,r.byStimulus(2,1).status,"no rewarded trials");
verifyEmpty(t,fieldnames(r.plotFiles));
c.baselineOffsets=-5:-1;
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyEqual(t,r.byStimulus(1,1).stimulusActivity,B.stimulusActivity-10,'AbsTol',1e-12);
verifyEqual(t,r.byStimulus(1,1).rewardActivity,B.rewardActivity-10,'AbsTol',1e-12);
end
function testRewardFilterInvalidWindowsAndFiniteCohort(t)
[A,D,T,c,p]=fixture();
T{2}.responseType(end)=2; % Source trial 1 is a probe; exclude despite the condition label.
T{2}.responseFrame(end-1)=NaN; % Source trial 2 stays in trial chronology, invalid window.
A{1}(4,32,1)=NaN; % Fourth neuron excluded consistently across bins.
r=fn_analyzeStimRewardAlignment(A,D,c,p,T); B=r.byStimulus(1,1);
verifyEqual(t,B.trials.sourceTrialRow,(2:105)');
verifyFalse(t,B.trials.validWindow(1));
verifyTrue(t,all(isnan(B.stimulusActivity(:,1))));
verifyEqual(t,B.bins.nTrials,[50;50;4]);
verifyEqual(t,B.bins.nValidTrials,[49;50;4]);
verifyEqual(t,B.neuronRows,(1:3)');
c.includePartialBin=false;
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyEqual(t,r.byStimulus(1,1).bins.nTrials,[50;50]);
verifySize(t,r.byStimulus(1,1).crossBinCorrelation,[2 2]);
end
function testInputSafetyAndEmptyAnimals(t)
[A,D,T,c,p]=fixture();
c.neuralField='dffChoice';
verifyError(t,@()fn_analyzeStimRewardAlignment(A,D,c,p,T),'stimReward:Alignment');
c.neuralField='dffStim';
bad=T; bad{1}.sourceTrialRow(1)=1;
verifyError(t,@()fn_analyzeStimRewardAlignment(A,D,c,p,bad),'stimReward:DuplicateTrial');
bad=T; bad{1}=removevars(bad{1},'responseFrame');
verifyError(t,@()fn_analyzeStimRewardAlignment(A,D,c,p,bad),'stimReward:TrialInfo');
A=[A cell(2,1)]; T=[T cell(2,1)]; c.animalLabels=["AC1","missing"];
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyEqual(t,size(r.byStimulus),[2 2]);
verifyEqual(t,r.byStimulus(1,2).status,"no rewarded trials");
end
function testConstantResponsesAndPlotExport(t)
[A,D,T,c,p]=fixture();
for k=1:numel(A), A{k}=ones(size(A{k})); end
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyTrue(t,all(isnan(r.byStimulus(1).crossBinCorrelation),'all'));
[A,D,T,c,p]=fixture();
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder; p.maxScatterPanels=2;
before=findall(groot,'Type','figure');
[figures,files]=fn_plotStimRewardAlignment(r,p);
verifyNumElements(t,fieldnames(figures),5); % Two scatter pages, correlation, two pooled stimulus figures.
verifyTrue(t,isfield(figures,'pooledEarlyTrials_S1'));
verifyTrue(t,isfield(figures,'pooledEarlyTrials_S2'));
verifyTrue(t,all(structfun(@(file)isfile(file),files)));
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function testSeparateStimuliAndAnimals(t)
[A,D,T,c,p]=fixture();
D2=D; D2.stimulus(:)=2; D=[D;D2];
T2=T;
for k=1:2, T2{k}.sourceTrialRow=T2{k}.sourceTrialRow+200; end
A=[A;A]; T=[T;T2];
A=[A cellfun(@(x)2*x,A,'UniformOutput',false)]; T=[T T];
c.animalLabels=["AC1","AC2"];
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
for s=1:2
    verifyEqual(t,r.byStimulus(s,1).bins.nTrials,[50;50;5]);
    verifyEqual(t,r.byStimulus(s,2).stimulusActivity,2*r.byStimulus(s,1).stimulusActivity);
    verifyEqual(t,r.byStimulus(s,2).withinBinCorrelation,[-1;1;1],'AbsTol',1e-12);
end
verifyEqual(t,r.byStimulus(2,1).trials.sourceTrialRow,(201:305)');
end
function testZscorePoolsAllInputSamples(t)
[A,D,T,c,p]=fixture();
A{1}(1,1,1)=NaN; % Outside the response windows, excluded only from normalization fit.
raw=fn_analyzeStimRewardAlignment(A,D,c,p,T);
c.normalization='zscore'; r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
X=[reshape(A{1},4,[]) reshape(A{2},4,[])];
mu=mean(X,2,'omitnan'); sd=std(X,0,2,'omitnan');
verifyEqual(t,r.normalization.offset{1},mu,'AbsTol',1e-12);
verifyEqual(t,r.normalization.scale{1},sd,'AbsTol',1e-12);
verifyEqual(t,r.normalization.nSamples{1},sum(isfinite(X),2));
verifyEqual(t,r.byStimulus(1).stimulusActivity, ...
    (raw.byStimulus(1).stimulusActivity-mu)./sd,'AbsTol',1e-12);
verifyEqual(t,r.byStimulus(1).rewardActivity, ...
    (raw.byStimulus(1).rewardActivity-mu)./sd,'AbsTol',1e-12);
c.baselineOffsets=-5:-1;
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyEqual(t,r.byStimulus(1).stimulusActivity, ...
    (raw.byStimulus(1).stimulusActivity-10)./sd,'AbsTol',1e-12);
% Constant neurons safely become zero; no independent event normalization.
for k=1:2, A{k}=ones(size(A{k})); end
c.baselineOffsets=[]; r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyTrue(t,all(r.normalization.degenerate{1}));
verifyEqual(t,r.byStimulus(1).stimulusActivity,zeros(4,105));
end
function testPooledEarlyTrialOrdinalsAndMissingData(t)
[A,D,T,c,p]=fixture();
c.nEarlyTrials=15; c.pooledBinSize=1; % Individual-trial mode remains available.
D2=D; D2.stimulus(:)=2; D=[D;D2]; T2=T;
for k=1:2, T2{k}.sourceTrialRow=T2{k}.sourceTrialRow+200; end
A=[A;A]; T=[T;T2]; A=[A A]; T=[T T]; c.animalLabels=["AC1","AC2"];
A{3,2}=[]; T{3,2}=[]; % Second animal has only two rewarded S2 trials.
A{4,2}=A{4,2}(:,:,end-1:end); T{4,2}=T{4,2}(end-1:end,:);
A{2,1}(1,32,end)=NaN; % Exclude one pair only at ordinal 1.
r=fn_analyzeStimRewardAlignment(A,D,c,p,T); P=r.pooledEarlyTrials;
verifySize(t,P.stimulusActivity,[16 15]);
verifyEqual(t,P.nPoints,[15 16 repmat(12,1,13)]);
verifyEqual(t,P.nAnimals,2*ones(1,15)); verifyEqual(t,P.nStimuli,2*ones(1,15));
for a=1:2
    for s=1:2
        rows=P.points.animalIndex==a&P.points.stimulus==s; B=r.byStimulus(s,a);
        n=min(15,height(B.trials));
        expected=B.rewardActivity(:,1:n);
        expected(~isfinite(B.stimulusActivity(:,1:n))|~isfinite(expected))=NaN;
        verifyEqual(t,P.rewardActivity(rows,1:n),expected);
        verifyTrue(t,all(isnan(P.rewardActivity(rows,n+1:end)),'all'));
    end
end
good=isfinite(P.stimulusActivity(:,1))&isfinite(P.rewardActivity(:,1));
x=P.stimulusActivity(good,1); y=P.rewardActivity(good,1);
x=x-mean(x); y=y-mean(y);
verifyEqual(t,P.correlation(1),dot(x,y)/(norm(x)*norm(y)),'AbsTol',1e-12);
% All-empty inputs still return 15 undefined correlations without fabricated data.
r=fn_analyzeStimRewardAlignment(cell(size(A)),D,c,p,cell(size(T)));
verifyEqual(t,r.pooledEarlyTrials.nPoints,zeros(1,15));
verifyTrue(t,all(isnan(r.pooledEarlyTrials.correlation)));
end
function testPooledTenTrialBins(t)
[A,D,T,c,p]=fixture();
c.nEarlyTrials=150; c.pooledBinSize=10;
A{2}(1,32,end)=NaN; % Trial 1: both event averages must omit this pair.
r=fn_analyzeStimRewardAlignment(A,D,c,p,T); P=r.pooledEarlyTrials;
verifyEqual(t,P.bins.firstTrial,(1:10:150)');
verifyEqual(t,P.bins.lastTrial,(10:10:150)');
verifySize(t,P.stimulusActivity,[4 15]);
verifyEqual(t,P.nPoints,[4*ones(1,11) zeros(1,4)]);
verifyEqual(t,P.trialCounts(:,1),[9;10;10;10]);
verifyEqual(t,P.trialCounts(:,11),5*ones(4,1));
verifyEqual(t,P.trialCounts(:,12:15),zeros(4,4));
B=r.byStimulus(1);
verifyEqual(t,P.stimulusActivity(1,1),mean(B.stimulusActivity(1,2:10)),'AbsTol',1e-12);
verifyEqual(t,P.rewardActivity(1,1),mean(B.rewardActivity(1,2:10)),'AbsTol',1e-12);
verifyEqual(t,P.stimulusActivity(:,2),mean(B.stimulusActivity(:,11:20),2),'AbsTol',1e-12);
verifyEqual(t,P.rewardActivity(:,11),mean(B.rewardActivity(:,101:105),2),'AbsTol',1e-12);
verifyTrue(t,all(isnan(P.correlation(12:15))));
end
function testSeparatePooledCorrelationsAndRemainingAnimals(t)
[A,D,T,c,p]=fixture();
D2=D; D2.stimulus(:)=2; D=[D;D2]; T2=T; A2=A;
for k=1:2
    T2{k}.sourceTrialRow=T2{k}.sourceTrialRow+200;
    A2{k}(:,39:41,:)=-A2{k}(:,39:41,:); % Reverse reward response, leaving stimulus intact.
end
A=[A;A2]; T=[T;T2]; A=[A A]; T=[T T]; c.animalLabels=["AC1","AC2"];
A{1,2}=[]; T{1,2}=[];
A{2,2}=A{2,2}(:,:,end-44:end); T{2,2}=T{2,2}(end-44:end,:); % 45 S1 trials in AC2.
r=fn_analyzeStimRewardAlignment(A,D,c,p,T); G=r.pooledEarlyTrials.byStimulus;
verifyEqual(t,G(1).bins.firstTrial,[1;51;101]);
verifyEqual(t,G(1).bins.lastTrial,[50;100;150]);
verifyEqual(t,G(1).nAnimals,[2 1 1]); verifyEqual(t,G(1).nPoints,[8 4 4]);
verifyEqual(t,G(2).nAnimals,[2 2 2]);
verifyLessThan(t,G(1).correlation(1),-0.99);
verifyGreaterThan(t,G(2).correlation(1),0.99);
verifyEmpty(t,intersect(G(1).pointRows,G(2).pointRows));
% No stimulus data: no fabricated bins or animals.
r=fn_analyzeStimRewardAlignment(cell(size(A)),D,c,p,cell(size(T)));
verifyEmpty(t,r.pooledEarlyTrials.byStimulus(1).binIndices);
% Even when more than 500 trials are requested, pooled figures stop at 10 bins.
[A,D,T,c,p]=fixture();
A={repmat(A{2}(:,:,1),1,1,601)}; T={repmat(T{2}(1,:),601,1)};
T{1}.sourceTrialRow=(1:601)'; D=D(2,:); c.nEarlyTrials=1000;
r=fn_analyzeStimRewardAlignment(A,D,c,p,T);
verifyEqual(t,r.pooledEarlyTrials.byStimulus(1).binIndices,1:10);
verifyEqual(t,r.pooledEarlyTrials.byStimulus(1).bins.lastTrial(end),500);
end
function [A,D,T,c,p]=fixture()
[c,p]=fn_stimRewardAlignmentConfig(); p.makePlot=false;
c.animalLabels="AC1";
D=table(["T1M_S1_L";"T1E_S1_L"],[1;1], 'VariableNames',{'conditionName','stimulus'});
A=cell(2,1); T=cell(2,1);
orders={105:-1:56,55:-1:1}; phases=["T1M","T1E"];
for k=1:2
    order=orders{k}; n=numel(order); X=10*ones(4,45,n);
    sourceTrialRow=order'; dayLabel=repmat(phases(k),n,1); responseType=ones(n,1);
    stimulusFrame=1000+order'*60; responseFrame=stimulusFrame+5+mod(order',2);
    for j=1:n
        q=order(j); rewardSign=1; if q<=50, rewardSign=-1; end
        X(:,32:34,j)=repmat(10+(1:4)'+q*0.001,1,3);
        idx=31+responseFrame(j)-stimulusFrame(j)+(3:4);
        X(:,idx,j)=repmat(10+rewardSign*(1:4)'+q*0.003,1,2);
    end
    A{k}=X; T{k}=table(sourceTrialRow,dayLabel,responseType,stimulusFrame,responseFrame);
end
end
