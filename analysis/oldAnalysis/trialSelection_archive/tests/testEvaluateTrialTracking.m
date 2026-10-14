function tests = testEvaluateTrialTracking
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.oldPath = path; addpath(fileparts(fileparts(mfilename('fullpath'))));
end

function teardownOnce(t)
path(t.TestData.oldPath);
end

function testWeightedReferenceRankingAndActualIntersection(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.referenceOffsetMap,repmat(8/3,2),'AbsTol',1e-12);
verifyEqual(t,r.sessions.opsSessionIndex,[2;1;3]);
verifyEqual(t,r.sessions.trialWeight,[1/2;1/3;1/6],'AbsTol',1e-12);
verifyEqual(t,r.sessions.meanAbsoluteOffset,[2/3;8/3;22/3],'AbsTol',1e-12);
verifyEqual(t,r.sessions.offsetScore,[2/3;8/3;22/3]./log(1+[50;100/3;100/6]),'AbsTol',1e-12);
verifyEqual(t,r.curve.nTrials,[3;5;6]);
verifyEqual(t,r.curve.nTrackedNeurons,[3;2;1]);
verifyEqual(t,r.trackedNeurons(:,2),[true;true;false;false]);
verifyEqual(t,r.trialSessionRank,[2;2;1;1;1;3]);
verifyFalse(t,isfile(b.sourceFile(1))); % The parsedTrial file is never read.
end

function testEqualOffsetErrorsDoNotFavorSmallSessions(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
d = load(file); ops = d.ops;
% Counts are [2 3 1], giving reference=2 and equal offset errors of 2.
ops.offsetMap = {zeros(2);4*ones(2);zeros(2)}; save(file,'ops');
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.referenceOffsetMap,2*ones(2));
verifyEqual(t,r.sessions.offsetScore,2./log(1+[50;100/3;100/6]),'AbsTol',1e-12);
verifyEqual(t,r.sessions.opsSessionIndex,[2;1;3]);
verifyEqual(t,r.sessions.nTrials,[3;2;1]);
verifyEqual(t,r.curve.nTrials,[3;5;6]);
end

function testLogPercentWeightingExample(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
d = load(file); ops = d.ops;
ops.offsetMap = {zeros(2);zeros(2);(100/89)*ones(2)}; save(file,'ops');
sessions = b([1 3 6],:);
trials = sessions([1;repmat(2,10,1);repmat(3,89,1)],:);
trials.trialInSession = [1;(1:10)';(1:89)'];
r = fn_evaluateTrialTracking(trials,file,'Plot',false);
s = sortrows(r.sessions,'opsSessionIndex');
verifyEqual(t,s.trialPercent,[1;10;89],'AbsTol',1e-12);
verifyEqual(t,s.scoreDivisor,log([2;11;90]),'AbsTol',1e-12);
verifyEqual(t,s.offsetScore(1:2),1./log([2;11]),'AbsTol',1e-12);
verifyEqual(t,r.sessions.opsSessionIndex,[3;2;1]);
% Doubling every trial count preserves percentages and ranking scores.
trials = sessions([ones(2,1);repmat(2,20,1);repmat(3,178,1)],:);
trials.trialInSession = [(1:2)';(1:20)';(1:178)'];
doubled = fn_evaluateTrialTracking(trials,file,'Plot',false);
verifyEqual(t,doubled.sessions.offsetScore,r.sessions.offsetScore,'AbsTol',1e-12);
end

function testMouseAreaMetadataNotRequiredOrUsed(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
baseline = fn_evaluateTrialTracking(b,file,'Plot',false); % No mouseArea field.
d = load(file); ops = d.ops;
ops.mouseArea = 'unrelated_dataset_label'; save(file,'ops');
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.sessions.opsSessionIndex,baseline.sessions.opsSessionIndex);
verifyEqual(t,r.referenceOffsetMap,baseline.referenceOffsetMap);
verifyEqual(t,r.curve,baseline.curve);
end

function testConcatenationDeduplicatesTrials(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
baseline = fn_evaluateTrialTracking(b,file,'Plot',false);
b = [b;b([1 3 6],:)];
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.referenceOffsetMap,baseline.referenceOffsetMap);
verifyEqual(t,r.curve,baseline.curve);
verifyEqual(t,r.uniqueTrialMask,[true(6,1);false(3,1)]);
verifyEqual(t,sum(r.sessions.nInputRows),9);
verifyEqual(t,nnz(r.uniqueTrialMask & r.trialSessionRank<=2),5);
end

function testPixelwiseNaNWeights(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
d = load(file); ops = d.ops;
ops.offsetMap{1}(1,2) = NaN; ops.offsetMap{3}(1,2) = Inf;
for k = 1:3, ops.offsetMap{k}(2,2) = NaN; end
save(file,'ops');
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.referenceOffsetMap(1,2),2);
verifyEqual(t,r.referenceTrialCounts(1,2),3);
verifyTrue(t,isnan(r.referenceOffsetMap(2,2)));
verifyEqual(t,sort(r.sessions.nValidPixels),[2;2;3]);
end

function testMissingRecordingAndMetadataReported(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
d = load(file); ops = d.ops; ops.offsetMap{2} = []; save(file,'ops');
extra = b(1,:); extra.date = 20260201; extra.sessionRec = 0; b = [b;extra];
previous = warning('off','evaluateTrialTracking:ExcludedSessions');
reset = onCleanup(@()warning(previous)); %#ok<NASGU>
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,height(r.excludedSessions),2);
verifyEqual(t,r.excludedSessions.nTrials,[3;1]);
verifyTrue(t,all(isnan(r.trialSessionRank([3:5 7]))));
verifyEqual(t,r.referenceOffsetMap,repmat(10/3,2),'AbsTol',1e-12);
end

function testDateMappingWithReorderedOps(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
d = load(file); ops = d.ops; order = [3 1 2];
ops.offsetMap = cat(3,ops.offsetMap{order}); % Numeric stack as in real ops.mat.
ops.imagingFilename = ops.imagingFilename(order); save(file,'ops');
trackFile = fullfile(fileparts(file),'stackROI_final_tracked.mat');
d = load(trackFile); ishereFinal = d.ishereFinal(order,:); save(trackFile,'ishereFinal');
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.sessions.opsSessionIndex,[3;2;1]);
verifyEqual(t,r.curve.nTrackedNeurons,[3;2;1]);
end

function testTablePresenceAndSessionRecFallback(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
b.ishere = repmat({[1 0 1 0]},height(b),1);
delete(fullfile(fileparts(file),'stackROI_final_tracked.mat'));
b(:,{'date','sessionName'}) = [];
r = fn_evaluateTrialTracking(b,file,'Plot',false);
verifyEqual(t,r.curve.nTrackedNeurons,[2;2;2]);
verifyEqual(t,r.presenceFile,"");
b.ishere{1} = [0 0 0 0];
verifyError(t,@()fn_evaluateTrialTracking(b,file,'Plot',false),'evaluateTrialTracking:Presence');
end

function testRejectMixedAnimalsAndIncompatibleData(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
mixed = b; mixed.sourceFile(2) = "another-file.mat";
verifyError(t,@()fn_evaluateTrialTracking(mixed,file,'Plot',false),'evaluateTrialTracking:MixedAnimals');
d = load(file); ops = d.ops; ops.offsetMap{2} = zeros(3); save(file,'ops');
verifyError(t,@()fn_evaluateTrialTracking(b,file,'Plot',false),'evaluateTrialTracking:MapShape');
ops.offsetMap{2} = zeros(2); save(file,'ops');
b.ishere = repmat({[1 1 1]},height(b),1);
b.ishere(3:5) = {[1 1]};
verifyError(t,@()fn_evaluateTrialTracking(b,file,'Plot',false),'evaluateTrialTracking:NeuronCount');
end

function testSingleSessionPlotAndEmptyInput(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
old = get(groot,'DefaultFigureVisible');
reset = onCleanup(@()set(groot,'DefaultFigureVisible',old)); %#ok<NASGU>
set(groot,'DefaultFigureVisible','off');
r = fn_evaluateTrialTracking(b(1:2,:),file);
closeFigure = onCleanup(@()close(r.figure)); %#ok<NASGU>
verifyTrue(t,isgraphics(r.figure)); verifyEqual(t,r.curve.nTrials,2);
verifyEqual(t,r.curve.nTrackedNeurons,3); verifyEqual(t,r.sessions.offsetScore,0);
verifyError(t,@()fn_evaluateTrialTracking(b([],:),file,'Plot',false),'evaluateTrialTracking:Input');
end

function [b,file,cleanup] = fixture()
folder = tempname; mkdir(folder); file = fullfile(folder,'ops.mat');
cleanup = onCleanup(@()cleanupFiles(folder));
ops.offsetMap = {zeros(2);2*ones(2);10*ones(2)};
ops.imagingFilename = {'B:\sample_20260101_2AFC1_parsed'; ...
    'B:\sample_20260102_2AFC2_parsed';'B:\sample_20260103_2AFC3_parsed'};
save(file,'ops');
ishereFinal = [1 1 0 1;1 1 1 NaN;1 0 1 1];
save(fullfile(folder,'stackROI_final_tracked.mat'),'ishereFinal');
sessions = table([20260101;20260102;20260103],{'2AFC1';'2AFC2';'2AFC3'},[1;2;3], ...
    'VariableNames',{'date','sessionName','sessionRec'});
b = sessions([1;1;2;2;2;3],:);
b.sourceFile = repmat(string(fullfile(folder,'never_read_parsedTrial.mat')),6,1);
b.trialInSession = [1;2;1;2;3;1];
end

function cleanupFiles(folder)
for name = {'ops.mat','stackROI_final_tracked.mat'}
    file = fullfile(folder,name{1});
    if isfile(file), delete(file); end
end
rmdir(folder);
end

