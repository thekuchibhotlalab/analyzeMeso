function tests=testTaskActionGeometry
tests=functiontests(localfunctions);
end
function setupOnce(tc)
tc.TestData.oldPath=path; addpath(fileparts(fileparts(mfilename('fullpath'))));
end
function teardownOnce(tc)
path(tc.TestData.oldPath);
end
function testKnownAxesAndVariance(tc)
[c,o]=fixture(0); r=fn_analyzeTaskActionSubspaces(c,o);
verifyEqual(tc,r.task.rank,2); verifyEqual(tc,r.action.rank,1);
verifyEqual(tc,r.taskActionOverlap.principalAnglesDeg,90,'AbsTol',1e-10);
verifyEqual(tc,sum(r.variance.fractionOfConditionMeanVariance),1,'AbsTol',1e-12);
C=r.conditionMeans; centered=C-mean(reshape(C,size(C,1),[]),2);
verifyEqual(tc,sum(r.variance.energy),sum(centered.^2,'all'),'RelTol',1e-12);
verifyEqual(tc,r.cv.meanPredictiveVariance(2,1),1,'AbsTol',1e-12);
verifyLessThan(tc,r.cv.meanPredictiveVariance(1,1),1);
verifyEqual(tc,r.cv.meanPredictiveVariance(1,2),1,'AbsTol',1e-12);
for k=1:numel(r.cv.splits)
    s=r.cv.splits{k}; verifyEmpty(tc,intersect(s.trainSessionRec,s.testSessionRec));
end
end
function testStaticRank(tc)
[c,o]=fixture(0); o.averageTime=true;
r=fn_analyzeTaskActionSubspaces(c,o);
verifyLessThanOrEqual(tc,r.task.rank,1); verifyLessThanOrEqual(tc,r.action.rank,1);
verifyError(tc,@()fn_analyzeTaskActionManifold(c,o),'taskGeometry:Time');
end
function testParallelAndOverlappingCodes(tc)
[c,o]=fixture(0); r=fn_analyzeTaskActionManifold(c,o);
verifyEqual(tc,r.timeGeometry.actionAcrossTasksAngleDeg,zeros(12,1),'AbsTol',1e-5);
verifyEqual(tc,r.interactionFraction,0,'AbsTol',1e-12);
verifyGreaterThan(tc,min(r.cv.actionGeneralization),0);
% Move action coding onto the task's first neuron: additive but overlapping.
for k=1:4
    x=c.neuralSelection(k).neuralRaw;
    x(1,:,:)=x(1,:,:)+x(2,:,:); x(2,:,:)=0; c.neuralSelection(k).neuralRaw=x;
end
r=fn_analyzeTaskActionManifold(c,o);
verifyEqual(tc,r.taskActionOverlap.principalAnglesDeg,0,'AbsTol',1e-5);
verifyEqual(tc,r.interactionFraction,0,'AbsTol',1e-12);
end
function testCrossvalidatedDistances(tc)
[c,o]=fixture(0.3); o.noiseMetric='diagonal';
r=fn_analyzeTaskActionManifold(c,o);
verifyEqual(tc,r.cv.rdm,r.cv.rdm','AbsTol',1e-12);
verifyEqual(tc,diag(r.cv.rdm),zeros(48,1));
verifyTrue(tc,all(isfinite(r.cv.rdm),'all'));
verifySize(tc,r.cv.distanceByTime,[4 4 12]);
verifyGreaterThan(tc,mean(r.cv.factorEnergy(:,1)),0);
end
function testNegativeDistancesRetained(tc)
[c,o]=fixture(0); stream=RandStream('mt19937ar','Seed',91);
for k=1:4, c.neuralSelection(k).neuralRaw=randn(stream,8,12,48); end
r=fn_analyzeTaskActionManifold(c,o);
verifyLessThan(tc,min(r.cv.rdm,[],'all'),0);
end
function testInteraction(tc)
[c,o]=fixture(0);
for k=1:4
    signInteraction=[1 -1 -1 1];
    c.neuralSelection(k).neuralRaw(4,:,:)=2*signInteraction(k);
end
r=fn_analyzeTaskActionManifold(c,o);
verifyGreaterThan(tc,r.interactionFraction,0.1);
verifyGreaterThan(tc,min(r.cv.factorEnergy(:,3)),1);
end
function testFilteringAndDedup(tc)
[c,o]=fixture(0.1); c.neuralSelection(5)=c.neuralSelection(1);
c.neuralSelection(5).name='duplicate';
c.neuralSelection(1).neuralRaw(8,1,1)=NaN;
[d,~]=fn_prepareTaskActionData(c,o);
verifyEqual(tc,d.duplicateTrialCount,48); verifyEqual(tc,d.droppedNeuronIDs,8);
verifyEqual(tc,size(d.X,3),192); verifyEqual(tc,numel(d.neuronIDs),7);
o.timeWindow=[0 0.2]; [d,~]=fn_prepareTaskActionData(c,o);
verifyEqual(tc,d.neuronIDs,(1:8)'); verifyEqual(tc,numel(d.time),4);
end
function testTrainingNormalization(tc)
[c,o]=fixture(0.1); [d,~]=fn_prepareTaskActionData(c,o);
[~,tr,Y]=fn_taskActionMeans(d.X,d.group,'zscore');
verifyEqual(tc,mean(reshape(Y,8,[]),2),zeros(8,1),'AbsTol',1e-12);
verifyEqual(tc,std(reshape(Y,8,[]),0,2),ones(8,1),'AbsTol',1e-12);
[~,trTest]=fn_taskActionMeans(100+d.X,d.group,'zscore',tr);
verifyEqual(tc,trTest,tr);
end
function testContextAndMissingCells(tc)
[c,o]=fixture(0.1); o.taskDefinition='context';
% Deliberately reverse context labels, leaving stimuli unchanged.
for k=1:4
    if k<=2, label="T2"; else, label="T1"; end
    c.neuralSelection(k).trialInfoNeural.taskLabel(:)=label;
end
[d,~]=fn_prepareTaskActionData(c,o);
verifyEqual(tc,d.group(1),3);
o.conditionNames="C1";
verifyError(tc,@()fn_prepareTaskActionData(c,o),'taskGeometry:Cells');
end
function testNoiseMetricOptions(tc)
[c,o]=fixture(0.3); o.noiseMetric='shrinkage';
r=fn_analyzeTaskActionManifold(c,o);
verifyTrue(tc,all(isfinite(r.cv.rdm),'all'));
verifyGreaterThan(tc,mean(r.cv.factorEnergy(:,2)),0);
end
function testSessionSplitRequiresIndependentSessions(tc)
[c,o]=fixture(0.1);
for k=1:4
    T=c.neuralSelection(k).trialInfoNeural;
    T.sessionRec(:)=1; T.trialInSession=(1:48)'+(k-1)*48;
    c.neuralSelection(k).trialInfoNeural=T;
end
verifyError(tc,@()fn_analyzeTaskActionSubspaces(c,o),'taskGeometry:Split');
o.splitUnit='trial'; r=fn_analyzeTaskActionSubspaces(c,o);
verifyTrue(tc,all(isfinite(r.cv.meanPredictiveVariance),'all'));
end
function testPlotSmoke(tc)
[c,o]=fixture(0.1); o.makePlots=true;
old=get(groot,'DefaultFigureVisible'); set(groot,'DefaultFigureVisible','off');
cleanup=onCleanup(@()set(groot,'DefaultFigureVisible',old)); %#ok<NASGU>
r=fn_analyzeTaskActionSubspaces(c,o); m=fn_analyzeTaskActionManifold(c,o);
verifyTrue(tc,isgraphics(r.figures)); verifyTrue(tc,isgraphics(m.figures));
exportgraphics(r.figures,fullfile(tempdir,'taskActionLinearTest.png'));
exportgraphics(m.figures,fullfile(tempdir,'taskActionManifoldTest.png'));
close(r.figures); close(m.figures);
end
function testRawCellsUnequalTrialsAndNeuronMapping(tc)
[c,o]=fixture(0); o.eventFrame=4;
X=cell(4,2);
for g=1:4
    X{g,1}=c.neuralSelection(g).neuralRaw;
    X{g,2}=c.neuralSelection(g).neuralRaw(1:5,:,1:8+g);
end
o.animalLabels=["first","second"];
r=fn_analyzeTaskActionSubspaces(X,o);
expected=cat(1,cat(3,mean(X{1,1},3),mean(X{2,1},3),mean(X{3,1},3),mean(X{4,1},3)), ...
    cat(3,mean(X{1,2},3),mean(X{2,2},3),mean(X{3,2},3),mean(X{4,2},3)));
verifyEqual(tc,r.conditionMeans,expected,'AbsTol',1e-12);
verifyEqual(tc,r.data.neurons.animalIndex,[ones(8,1);2*ones(5,1)]);
verifyEqual(tc,r.data.neurons.rowInAnimal,[(1:8)';(1:5)']);
verifyEqual(tc,r.data.trialsPerAnimal{2,:},9:12);
verifyEqual(tc,r.options.splitUnit,'trial');
verifyEqual(tc,r.cv.meanPredictiveVariance(2,1),1,'AbsTol',1e-12);
verifyFalse(tc,isfield(r.data,'animalData'));
for a=1:2
    s=r.cv.splits{1}.animals{a}; verifyEmpty(tc,intersect(s.trainRows,s.testRows));
    verifyEqual(tc,numel(s.trainRows)+numel(s.testRows),sum(cellfun(@(x)size(x,3),X(:,a))));
end
end
function testRawCellsManifoldAndNoiseBlocks(tc)
[c,o]=fixture(0.3); o.eventFrame=4; o.noiseMetric='shrinkage';
X=cell(4,2);
for g=1:4
    X{g,1}=c.neuralSelection(g).neuralRaw;
    X{g,2}=c.neuralSelection(g).neuralRaw(1:5,:,1:8+g);
end
r=fn_analyzeTaskActionManifold(X,o);
verifySize(tc,r.conditionMeans,[13 12 4]);
verifyEqual(tc,r.metricTransform(1:8,9:13),zeros(8,5));
verifyTrue(tc,all(isfinite(r.cv.rdm),'all'));
verifyEqual(tc,r.cv.rdm,r.cv.rdm','AbsTol',1e-12);
verifyGreaterThan(tc,mean(r.cv.factorEnergy(:,1)),0);
end
function testRawCellsExclusionsAndFilters(tc)
[c,o]=fixture(0.1); X=cell(4,2);
for g=1:4, X{g,1}=c.neuralSelection(g).neuralRaw; X{g,2}=X{g,1}; end
X{4,2}=[]; X{1,1}(8,1,1)=NaN;
[d,~]=fn_prepareTaskActionData(X,o);
verifyEqual(tc,height(d.neurons),7); verifyEqual(tc,d.excludedAnimals.animalIndex,2);
verifyEqual(tc,d.droppedNeurons.rowInAnimal,8);
o.splitUnit='session';
verifyError(tc,@()fn_prepareTaskActionData(X,o),'taskGeometry:CellSplit');
o.splitUnit='trial'; o.dayLabels="Int";
verifyError(tc,@()fn_prepareTaskActionData(X,o),'taskGeometry:CellFilters');
end
function testRawCellsSingleAnimalMatchesCurated(tc)
[c,o]=fixture(0.1); o.splitUnit='trial'; o.eventFrame=c.cfg.alignedEventFrame;
X={c.neuralSelection.neuralRaw};
r=fn_analyzeTaskActionSubspaces(X,o); old=fn_analyzeTaskActionSubspaces(c,o);
verifyEqual(tc,r.conditionMeans,old.conditionMeans,'AbsTol',1e-12);
verifyEqual(tc,r.cv.predictiveVariance,old.cv.predictiveVariance,'AbsTol',1e-12);
end
function [c,o]=fixture(noise)
o=fn_taskActionGeometryConfig(); o.makePlots=false; o.verbose=false;
o.nSplits=3; o.nComponents=3; o.normalization='none'; o.noiseMetric='identity';
c.neuralLoaded=true; c.tracking.selectedNeuronIDs=(1:8)'; c.cfg.alignedEventFrame=4;
stream=RandStream('mt19937ar','Seed',42); nt=12; t=linspace(0,2*pi,nt);
for g=1:4
    task=2*(g>2)-1; action=2*(mod(g,2)==0)-1;
    base=zeros(8,nt); base(1,:)=task*(2+sin(t));
    base(3,:)=task*cos(t); base(2,:)=action*(1+0.3*cos(t));
    sessionRec=repelem((1:6)',8); trialInSession=repmat((1:8)',6,1)+(g-1)*8;
    stimuli=repmat(g,48,1); act=repmat(1+(action>0),48,1);
    dayLabel=repmat("Int",48,1); taskLabel=repmat("T"+string(1+(task>0)),48,1);
    T=table(sessionRec,trialInSession,stimuli,act,dayLabel,taskLabel, ...
        'VariableNames',{'sessionRec','trialInSession','stimuli','action','dayLabel','taskLabel'});
    c.neuralSelection(g)=struct('name',sprintf('C%d',g), ...
        'neuralRaw',repmat(base,1,1,48)+noise*randn(stream,8,nt,48),'trialInfoNeural',T);
end
end
