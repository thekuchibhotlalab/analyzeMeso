function tests = testLoadTrackedNeuralActivity
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.oldPath = path;
addpath(fileparts(fileparts(mfilename('fullpath'))));
end

function teardownOnce(t)
path(t.TestData.oldPath);
end

function testExactSignalsAndPrefixCommonNeurons(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
[a,info,n] = fn_loadTrackedNeuralActivity(file,tracking,b, ...
    ["T1M","T1E","absent"],types,'NumSessions',2,'FrameIndices',[3 1]);
verifySize(t,a,[3 2]); verifySize(t,info,[3 2]);
verifyEqual(t,n.neuronIDs,[1;4]);
verifyEqual(t,n.sessionRec,[11;90]);
verifyEqual(t,n.sessionInfoRows,[2;1]);
verifyEqual(t,a{1,1},si.dffStim{1}([1 4],[3 1],1));
verifyEqual(t,a{2,2},si.dffStim{2}([1 4],[3 1],4));
verifyEqual(t,info{1,1}.sessionRec,90);
verifyEqual(t,info{2,2}.inputTrialRow,4);
verifyEqual(t,size(a{3,1},3),0);
verifyEqual(t,size(a{3,1},1),2);
verifyEqual(t,info{1,1}.sourceFile,b.sourceFile(1));
end

function testArbitrarySessionsAndAllNeurons(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
sessions = tracking.sessions([3 1],:);
[a,info,n] = fn_loadTrackedNeuralActivity(file,sessions,b,'T1E',types,'NeuronSelection','all');
verifyEqual(t,n.sessionRec,[300;11]);
verifyEqual(t,n.neuronIDs,(1:4)');
verifyEqual(t,n.commonNeuronMask,logical([1;1;0;0]));
verifyEqual(t,a{1,1},cat(3,si.dffStim{2}(:,:,1),si.dffStim{3}(:,:,1)));
verifyEqual(t,info{1,1}.sessionRec,[11;300]); % Input trial order is preserved.
end

function testNumericIdsAndDuplicateTrials(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
b = [b;b(1,:)];
[a,info,n] = fn_loadTrackedNeuralActivity(file,[11;90],b,["T1E","T1M"],types);
verifyEqual(t,height(info{1,1}),1);
verifyEqual(t,a{1,1},si.dffStim{2}(n.neuronIDs,:,1));
end

function testPredicatesAndOverlappingTypes(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
types = table(["all";"action1"],{@(x)true(height(x),1);@(x)x.action==1}, ...
    'VariableNames',{'label','predicate'});
b = b(b.RT<=.5,:);
[a,info] = fn_loadTrackedNeuralActivity(file,11,b,'T1E',types);
verifyEqual(t,info{1,1}.trialInSession,[1;2]);
verifyEqual(t,info{1,2}.trialInSession,1);
verifyEqual(t,a{1,1}(:,:,1),a{1,2});
end

function testShortTracesArePaddedAndAlternateField(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
si.dffChoice = si.dffStim;
si.dffChoice{1} = si.dffChoice{1}(:,1:2,:);
sessionInfo = si; save(file,'sessionInfo');
[a,~,n] = fn_loadTrackedNeuralActivity(file,[11;90],b,["T1M","T1E"],types, ...
    'ActivityField','dffChoice');
verifyEqual(t,size(a{1,1},2),3);
verifyTrue(t,all(isnan(a{1,1}(:,3,:)),'all'));
verifyEqual(t,a{1,1}(:,1:2,:),si.dffChoice{1}(n.neuronIDs,:,1));
end

function testNoCommonNeuronsAndEmptyTrialGroups(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
si.ishere{1} = [0 0 0 0]; sessionInfo = si; save(file,'sessionInfo');
[a,info,n] = fn_loadTrackedNeuralActivity(file,[11;90],b,'T1E',types);
verifyEmpty(t,n.neuronIDs);
verifyEqual(t,size(a{1,1},1),0);
verifyEqual(t,size(a{1,1},3),height(info{1,1}));
[a,info] = fn_loadTrackedNeuralActivity(file,11,b,'absent',types,'FrameIndices',1:2);
verifyEqual(t,size(a{1,1},2),2);
verifyEqual(t,size(a{1,1},3),0);
verifyEmpty(t,info{1,1});
end

function testWrongIdentityAndTrialMappingRejected(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
wrong = tracking.sessions; wrong.date(1) = 20251231;
verifyError(t,@()fn_loadTrackedNeuralActivity(file,wrong,b,'T1E',types), ...
    'loadTrackedNeuralActivity:Identity');
stale = b; stale.RT(1) = 99;
verifyError(t,@()fn_loadTrackedNeuralActivity(file,11,stale,'T1E',types), ...
    'loadTrackedNeuralActivity:StaleTrials');
stale = b; stale.trialInSession(1) = 99;
verifyError(t,@()fn_loadTrackedNeuralActivity(file,11,stale,'T1E',types), ...
    'loadTrackedNeuralActivity:TrialIndex');
verifyError(t,@()fn_loadTrackedNeuralActivity(file,999,b,'T1E',types), ...
    'loadTrackedNeuralActivity:Mapping');
end

function testMissingActivityAndSelectionErrors(t)
[file,tracking,b,types,si,cleanup] = fixture(); %#ok<ASGLU>
si.dffStim{2} = []; sessionInfo = si; save(file,'sessionInfo');
verifyError(t,@()fn_loadTrackedNeuralActivity(file,11,b,'T1E',types), ...
    'loadTrackedNeuralActivity:MissingActivity');
verifyError(t,@()fn_loadTrackedNeuralActivity(file,tracking,b,'T1E',types,'NumSessions',4), ...
    'loadTrackedNeuralActivity:NumSessions');
end

function [file,tracking,b,types,si,cleanup] = fixture()
file = [tempname '.mat']; cleanup = onCleanup(@()delete(file));
si = table([20260102;20260101;20260103],{'2AFC1';'2AFC1';'2AFC2'}, ...
    [90;11;300],["T1M";"T1E";"T1E"],cell(3,1),cell(3,1), ...
    {[1 0 1 1];[1 1 0 1];[1 1 1 0]}, ...
    'VariableNames',{'date','sessionName','sessionRec','dayLabel','behSel','dffStim','ishere'});
b = table();
for row = [2 1 3]
    beh = table([1;1;2;2],[1;2;1;2],[.4;.5;.6;.7], ...
        'VariableNames',{'stimuli','action','RT'});
    si.behSel{row} = beh;
    si.dffStim{row} = single(reshape(1:48,4,3,4)+row*1000);
    part = [si(repmat(row,4,1),{'date','sessionName','sessionRec','dayLabel'}),beh];
    part.trialInSession = (1:4)';
    part.sourceFile = repmat("metadata_trialInfo.mat",4,1);
    b = [b;part]; %#ok<AGROW>
end
sessionInfo = si; save(file,'sessionInfo');
tracking.sessions = si([2 1 3],{'date','sessionName','sessionRec','dayLabel'});
tracking.trackedNeurons = false(4,3); % Deliberately stale; loader must recompute.
types = table(["one";"two"],[1;2],[1;2],'VariableNames',{'label','stimulus','action'});
end
