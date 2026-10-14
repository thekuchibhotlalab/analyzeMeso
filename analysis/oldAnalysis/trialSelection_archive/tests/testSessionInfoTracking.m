function tests = testSessionInfoTracking
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.oldPath = path;
addpath(fileparts(fileparts(mfilename('fullpath'))));
t.TestData.oldWarning = warning('off','evaluateTrialTracking:ExcludedSessions');
end

function teardownOnce(t)
path(t.TestData.oldPath);
warning(t.TestData.oldWarning);
end

function testSavedSessionMapsAndFlagsWithoutOps(t)
[trials,file,cleanup,s] = fixture(); %#ok<ASGLU>
trials.ishere = repmat({[0 0 0 0]},height(trials),1); % Saved flags take precedence.
r = fn_evaluateTrialTracking(trials,'nonexistent-ops.mat','SessionInfoFile',file,'Plot',false);
verifyEqual(t,r.opsFile,"");
verifyEqual(t,r.sessionInfoFile,string(file));
verifyEqual(t,r.presenceFile,string(file));
verifyTrue(t,all(isnan(r.sessions.opsSessionIndex)));
verifyEqual(t,height(r.sessions),4);
verifyEqual(t,r.excludedSessions.sessionInfoRow,4);
verifyTrue(t,isnan(r.trialSessionRank(5)));
for j = 1:height(r.sessions)
    row = r.sessions.sessionInfoRow(j);
    verifyEqual(t,r.sessions.offsetMap{j},s.offsetMap{row});
    verifyEqual(t,r.sessions.ishere{j},s.ishere{row});
    verifyEqual(t,r.sessions.sessionRec(j),s.sessionRec(row));
end
end

function testSessionRecIsIdentifierNotRow(t)
[trials,file,cleanup,s] = fixture(); %#ok<ASGLU>
trials = trials(trials.sessionRec>0,:);
trials(:,{'date','sessionName'}) = [];
sessionInfoBeh = s([5 3 1 4 2],:); save(file,'sessionInfoBeh');
r = fn_evaluateTrialTracking(trials,[],'SessionInfoFile',file,'Plot',false);
for row = 1:height(trials)
    matched = r.sessions.sessionInfoRow(r.trialSessionRank(row));
    verifyEqual(t,sessionInfoBeh.sessionRec(matched),trials.sessionRec(row));
end
end

function testUnknownSessionDoesNotBorrowSameDayMap(t)
[trials,file,cleanup] = fixture(); %#ok<ASGLU>
extra = trials(1,:); extra.sessionName = {'unknown'};
r = fn_evaluateTrialTracking([trials;extra],[],'SessionInfoFile',file,'Plot',false);
verifyEqual(t,height(r.excludedSessions),2);
verifyTrue(t,isnan(r.trialSessionRank(end)));
verifyTrue(t,any(r.excludedSessions.reason=="No matching sessionInfoBeh row"));
end

function testSameDaySessionsRetainTheirSavedFlags(t)
[trials,file,cleanup,s] = fixture(); %#ok<ASGLU>
s.ishere{3} = [1 0 0 0]; sessionInfoBeh = s; save(file,'sessionInfoBeh');
r = fn_evaluateTrialTracking(trials,[],'SessionInfoFile',file,'Plot',false);
verifyEqual(t,r.sessions.ishere{r.trialSessionRank(1)},[1 1 0 1]);
verifyEqual(t,r.sessions.ishere{r.trialSessionRank(3)},[1 0 0 0]);
end

function testBalancedMethodsAndOriginalTrialMapping(t)
[trials,file,cleanup,s] = fixture(); %#ok<ASGLU>
trials = [trials;trials(1,:)];
for method = ["error","greedy","lookahead"]
    r = fn_evaluateTrialTrackingBalanced(trials,[],'SessionInfoFile',file, ...
        'PhaseOrder',["T1E","T1M"],'MinSessionsPerStage',1, ...
        'MatchRemaining',false,'Method',method,'Plot',false);
    verifyEqual(t,r.referenceOffsetMap,2*ones(2)); % median of [0,0,4,10].
    verifyEqual(t,r.curve.nSessionsByPhase(2,:),[1 1]);
    verifyFalse(t,r.uniqueTrialMask(end));
    verifyEqual(t,r.curve.nTrials(end),5);
    for k = 1:height(r.sessions)
        rows = r.sessions.sessionInfoRow(1:k);
        verifyEqual(t,r.trackedNeurons(:,k),all(vertcat(s.ishere{rows})==1,1)');
    end
end
end

function testAmbiguousSessionRowsRejected(t)
[trials,file,cleanup,s] = fixture(); %#ok<ASGLU>
sessionInfoBeh = [s;s(1,:)]; save(file,'sessionInfoBeh');
verifyError(t,@()fn_evaluateTrialTracking(trials,[],'SessionInfoFile',file,'Plot',false), ...
    'evaluateTrialTracking:Mapping');
end

function [trials,file,cleanup,s] = fixture()
file = [tempname '.mat']; cleanup = onCleanup(@()delete(file));
date = [20260102;20260101;20260101;20260103;20260104];
sessionName = {'2AFC1';'2AFC1';'2AFC2';'2AFC1';'2AFC1'};
sessionRec = [90;11;300;0;400];
dayLabel = ["T1M";"T1E";"T1E";"T1M";"T1M"];
offsetMap = {10*ones(2);zeros(2);zeros(2);[];4*ones(2)};
ishere = {[1 1 1 0];[1 1 0 1];[1 1 0 1];[];[1 0 1 1]};
s = table(date,sessionName,sessionRec,dayLabel,offsetMap,ishere);
sessionInfoBeh = s; save(file,'sessionInfoBeh');
trials = s([2 2 3 1 4 5],{'date','sessionName','sessionRec','dayLabel'});
trials.trialInSession = [1;2;1;1;1;1];
end
