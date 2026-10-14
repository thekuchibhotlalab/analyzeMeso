function tests = testEvaluateTrialTrackingBalanced
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.oldPath = path;
t.TestData.oldWarning = warning('off','balancedTrialTracking:InsufficientSessions');
addpath(fileparts(fileparts(mfilename('fullpath'))));
end

function teardownOnce(t)
path(t.TestData.oldPath);
warning(t.TestData.oldWarning);
end

function testMedianSquaredErrorAndPhaseRounds(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
r = fn_evaluateTrialTrackingBalanced(b,file,'Plot',false);
verifyEqual(t,r.referenceOffsetMap,5*ones(2));
verifyEqual(t,r.referenceSessionCounts,6*ones(2));
verifyEqual(t,r.sessions.opsSessionIndex,[2;4;5;1;3;6]);
verifyEqual(t,r.sessions.meanSquaredOffset,[9;1;1;25;25;9025]);
verifyEqual(t,r.sessions.phase,["T1E";"T1M";"T1L";"T1E";"T1M";"T1E"]);
verifyEqual(t,r.curve.nSessionsByPhase,[1 0 0;1 1 0;1 1 1;2 1 1;2 2 1;3 2 1]);
verifyEqual(t,r.curve.nTrackedNeurons,[2;0;0;0;0;0]);
verifyEqual(t,r.trialSessionRank,[4;1;5;2;3;6]);
verifyFalse(t,isfield(r,'referenceTrialCounts'));
verifyFalse(t,ismember('scoreDivisor',r.sessions.Properties.VariableNames));
end

function testGreedyRetainsIntersectionAcrossAllPreviousSessions(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
r = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy','Plot',false);
verifyEqual(t,r.sessions.opsSessionIndex,[1;3;5;2;4;6]);
verifyEqual(t,r.curve.nTrackedNeurons,[4;3;2;2;0;0]);
verifyEqual(t,r.trackedNeurons(:,3),logical([1;1;0;0;0;0]));
verifyEqual(t,r.sessions.nTrackedAfterSelection,r.curve.nTrackedNeurons);
for k = 1:height(r.sessions)
    rows = find(r.trialSessionRank<=k);
    flags = vertcat(b.ishere{rows});
    verifyEqual(t,r.trackedNeurons(:,k),all(flags==1,1)');
end
end

function testTrialCountsAndDuplicatesDoNotChangeRanking(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
extra = b(repmat(1,10,1),:); extra.trialInSession = (2:11)';
augmented = [b;extra;b(1,:)];
for method = ["error","greedy","lookahead"]
    baseline = fn_evaluateTrialTrackingBalanced(b,file,'Method',method,'Plot',false);
    r = fn_evaluateTrialTrackingBalanced(augmented,file,'Method',method,'Plot',false);
    verifyEqual(t,r.referenceOffsetMap,baseline.referenceOffsetMap);
    verifyEqual(t,r.sessions.opsSessionIndex,baseline.sessions.opsSessionIndex);
    verifyEqual(t,r.sessions.offsetScore,baseline.sessions.offsetScore);
    verifyEqual(t,r.curve.nTrials(end),16);
    verifyFalse(t,r.uniqueTrialMask(end));
end
end

function testPhaseOrderAndExhaustion(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
r = fn_evaluateTrialTrackingBalanced(b,file,'PhaseOrder', ...
    ["T1L","T1M","T1E","absent"],'Plot',false);
verifyEqual(t,r.sessions.opsSessionIndex,[5;4;2;3;1;6]);
verifyEqual(t,r.curve.nSessionsByPhase(end,:),[1 2 3 0]);
verifyEqual(t,r.phaseOrder,["T1L";"T1M";"T1E";"absent"]);
end

function testGreedyTiesUseErrorThenIndex(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
b.ishere(:) = {[1 1 0 0 0 0]};
d = load(file); ops = d.ops; ops.offsetMap(:,:,1) = 2; save(file,'ops');
r = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy','Plot',false);
% Sessions 1 and 2 now have identical maps/flags. Index decides the tie.
verifyEqual(t,r.sessions.opsSessionIndex,[1;4;5;2;3;6]);
end

function testNonfinitePixelsAndExcludedSession(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
d = load(file); ops = d.ops;
ops.offsetMap(2,2,:) = NaN;
ops.offsetMap(1,2,1:3) = Inf;
save(file,'ops');
r = fn_evaluateTrialTrackingBalanced(b,file,'Plot',false);
verifyEqual(t,r.referenceOffsetMap(1,2),6);
verifyEqual(t,r.referenceSessionCounts(1,2),3);
verifyTrue(t,isnan(r.referenceOffsetMap(2,2)));
ops.offsetMap(:,:,6) = NaN; save(file,'ops');
previous = warning('off','evaluateTrialTracking:ExcludedSessions');
reset = onCleanup(@()warning(previous)); %#ok<NASGU>
r = fn_evaluateTrialTrackingBalanced(b,file,'Plot',false);
verifyEqual(t,r.excludedSessions.opsSessionIndex,6);
verifyTrue(t,isnan(r.trialSessionRank(6)));
verifyEqual(t,height(r.sessions),5);
end

function testInvalidPhaseLabels(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
verifyError(t,@()fn_evaluateTrialTrackingBalanced(b,file,'PhaseOrder',"T1E",'Plot',false), ...
    'balancedTrialTracking:PhaseOrder');
extra = b(1,:); extra.dayLabel = "T1M";
verifyError(t,@()fn_evaluateTrialTrackingBalanced([b;extra],file,'Plot',false), ...
    'balancedTrialTracking:SessionPhase');
b.dayLabel(1) = missing;
verifyError(t,@()fn_evaluateTrialTrackingBalanced(b,file,'Plot',false), ...
    'balancedTrialTracking:Phases');
end

function testMinimumThenGlobalGreedy(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
r = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy', ...
    'MinSessionsPerStage',1,'MatchRemaining',false,'Plot',false);
verifyEqual(t,r.sessions.opsSessionIndex,[1;3;5;2;6;4]);
verifyEqual(t,r.curve.nTrackedNeurons,[4;3;2;2;2;0]);
verifyEqual(t,r.minimumPrefixLength,3);
verifyTrue(t,r.minimumMet);
verifyEqual(t,r.curve.nSessionsByPhase(3,:),[1 1 1]);
matched = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy', ...
    'MinSessionsPerStage',1,'MatchRemaining',true,'Plot',false);
verifyEqual(t,matched.sessions.opsSessionIndex,[1;3;5;2;4;6]);
end

function testDefaultThreeBeforeReleasingPhaseConstraint(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
b = b(ones(15,1),:); b.sessionRec = (1:15)';
b.dayLabel = repelem(["T1E";"T1M";"T1L"],5);
ops.offsetMap = zeros(2,2,15); save(file,'ops');
r = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy', ...
    'MatchRemaining',false,'Plot',false);
verifyEqual(t,r.minSessionsPerStage,[3;3;3]);
verifyEqual(t,r.minimumPrefixLength,9);
verifyTrue(t,r.minimumMet);
verifyEqual(t,r.curve.nSessionsByPhase(9,:),[3 3 3]);
verifyEqual(t,r.sessions.opsSessionIndex,[1;6;11;2;7;12;3;8;13;4;5;9;10;14;15]);
matched = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy','Plot',false);
verifyEqual(t,matched.sessions.opsSessionIndex(10:end),[4;9;14;5;10;15]);
end

function testZeroMinimumAndStageSpecificShortfall(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
r = fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy', ...
    'MinSessionsPerStage',0,'MatchRemaining',false,'Plot',false);
verifyEqual(t,r.minimumPrefixLength,0);
verifyTrue(t,r.minimumMet);
verifyEqual(t,r.sessions.opsSessionIndex,[1;3;5;2;6;4]);
r = fn_evaluateTrialTrackingBalanced(b,file,'MinSessionsPerStage',[0 1 2], ...
    'MatchRemaining',false,'Plot',false);
verifyEqual(t,r.minimumPrefixLength,2);
verifyFalse(t,r.minimumMet);
verifyEqual(t,r.minimumStatus.shortfall,[0;0;1]);
verifyEqual(t,r.curve.nSessionsByPhase(2,:),[0 1 1]);
verifyError(t,@()fn_evaluateTrialTrackingBalanced(b,file,'MinSessionsPerStage',[1 2]), ...
    'balancedTrialTracking:Minimum');
end

function testSingleSessionFigure(t)
[b,file,cleanup] = fixture(); %#ok<ASGLU>
old = get(groot,'DefaultFigureVisible');
reset = onCleanup(@()set(groot,'DefaultFigureVisible',old)); %#ok<NASGU>
set(groot,'DefaultFigureVisible','off');
r = fn_evaluateTrialTrackingBalanced(b(1,:),file,'Method','greedy');
closeFigure = onCleanup(@()close(r.figure)); %#ok<NASGU>
verifyTrue(t,isgraphics(r.figure));
verifyEqual(t,r.sessions.offsetScore,0);
verifyEqual(t,r.curve.nTrackedNeurons,4);
end

function [b,file,cleanup] = fixture()
folder = tempname; mkdir(folder); file = fullfile(folder,'ops.mat');
cleanup = onCleanup(@()cleanupFiles(folder));
ops.offsetMap = repmat(reshape([0 2 10 4 6 100],1,1,6),2,2,1);
save(file,'ops');
sessionRec = (1:6)'; trialInSession = ones(6,1);
dayLabel = ["T1E";"T1E";"T1M";"T1M";"T1L";"T1E"];
ishere = {[1 1 1 1 0 0];[1 1 0 0 0 0];[1 1 1 0 1 0]; ...
    [0 0 0 1 1 1];[1 1 0 0 1 0];[1 1 0 0 0 1]};
b = table(sessionRec,trialInSession,dayLabel,ishere);
end

function testLookaheadFavorsFutureCohortAndKeepsMinimums(t)
% One isolated session has six neurons; six others share the same five.
% Greedy starts at the isolated session. Lookahead prefers the cohort.
sessionRec=(1:7)';
dayLabel=["T1E";"T1E";repmat("T1M",5,1)];
flags=false(7,11); flags(1,1:6)=true; flags(2:7,7:11)=true;
ishere=mat2cell(double(flags),ones(7,1),11);
offsetMap=repmat({zeros(2)},7,1);
S=table(sessionRec,dayLabel,ishere,offsetMap);
b=table(sessionRec,ones(7,1),dayLabel, ...
    'VariableNames',{'sessionRec','trialInSession','dayLabel'});
r=fn_evaluateTrialTrackingBalanced(b,[],'SessionInfo',S,'Method','lookahead', ...
    'MinSessionsPerStage',1,'Plot',false);
verifyEqual(t,r.sessions.sessionRec,[2;3;4;5;6;7;1]);
verifyEqual(t,r.minimumPrefixLength,2);
verifyEqual(t,r.curve.nSessionsByPhase(2,:),[1 1]);
% After quotas, choose from ALL stages even though MatchRemaining defaults true.
verifyFalse(t,r.matchRemaining);
verifyEqual(t,r.sessions.lookaheadMeanShared(1:3),[5;4;3.75]);
verifyEqual(t,r.sessions.selectionScore(1:3),[8.75;8;7.8125]);
verifyEqual(t,r.sessions.lookaheadSessionRec{1},(3:7)');
verifyEqual(t,r.sessions.lookaheadMeanShared(end),0);
verifyEmpty(t,r.sessions.lookaheadSessionRec{end});
verifyEqual(t,r.curve.nTrackedNeurons,[5;5;5;5;5;5;0]);
for k=1:7
    % No self or already-selected session enters the future average.
    verifyEmpty(t,intersect(r.sessions.lookaheadSessionRec{k},r.sessions.sessionRec(1:k)));
end
g=fn_evaluateTrialTrackingBalanced(b,[],'SessionInfo',S,'Method','greedy', ...
    'MinSessionsPerStage',1,'MatchRemaining',false,'Plot',false);
verifyEqual(t,g.sessions.sessionRec(1),1);
end

function testLookaheadZeroWeightMatchesGlobalGreedy(t)
[b,file,cleanup]=fixture(); %#ok<ASGLU>
g=fn_evaluateTrialTrackingBalanced(b,file,'Method','greedy', ...
    'MinSessionsPerStage',1,'MatchRemaining',false,'Plot',false);
r=fn_evaluateTrialTrackingBalanced(b,file,'Method','lookahead', ...
    'LookaheadWeight',0,'MinSessionsPerStage',1,'Plot',false);
verifyEqual(t,r.sessions.sessionRec,g.sessions.sessionRec);
verifyEqual(t,r.trackedNeurons,g.trackedNeurons);
verifyEqual(t,r.sessions.selectionScore,r.sessions.nTrackedAfterSelection);
end

function testLookaheadOneSessionAndConfigurableNeighborCount(t)
[b,file,cleanup]=fixture(); %#ok<ASGLU>
r=fn_evaluateTrialTrackingBalanced(b(1,:),file,'Method','lookahead','Plot',false);
verifyEqual(t,r.sessions.selectionScore,4);
verifyEqual(t,r.sessions.lookaheadMeanShared,0);
r=fn_evaluateTrialTrackingBalanced(b,file,'Method','lookahead', ...
    'LookaheadSessions',1,'LookaheadWeight',0.5,'Plot',false);
verifyEqual(t,r.lookaheadSessions,1);
verifyEqual(t,r.lookaheadWeight,0.5);
verifyEqual(t,cellfun(@numel,r.sessions.lookaheadSessionRec),[ones(5,1);0]);
end

function cleanupFiles(folder)
delete(fullfile(folder,'ops.mat'));
rmdir(folder);
end
