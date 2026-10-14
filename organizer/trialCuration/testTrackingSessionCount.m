function tests=testTrackingSessionCount
tests=functiontests(localfunctions);
end

function setupOnce(t)
root=fileparts(mfilename('fullpath'));
for folder={'','config','helper','tracking'}
    t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,folder{1})));
end
end

function testMovingAveragePrefersSustainedDropOverSpike(t)
% An isolated loss of 12 should lose to three consecutive losses of 8.
drops=[1 1 1 1 1 12 1 1 8 8 8 1 1 1 1];
[r,cfg]=fn_fixture([100,100-cumsum(drops)],2);
cfg.autoSessionSmoothWindow=3;
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,9); % Peak at ten, moved earlier by floor(3/2).
verifyEqual(t,d.peakDropCutoff,10);
verifyEqual(t,d.appliedCutoffShift,1);
verifyEqual(t,d.dropSessionRank,11);
verifyEqual(t,d.curve.smoothedDropToNext(10),8);
verifyEqual(t,d.searchRange,[5 16]);
cfg.autoSessionSmoothWindow=1;
verifyEqual(t,fn_selectTrackingSessionCount(r,cfg),6);
end

function testRangeExcludesEarlyCliffAndMinimumTakesPriority(t)
[r,cfg]=fn_fixture([200 100 90 89 88 60 59 58 57 56],2);
cfg.autoSessionSmoothWindow=1;
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,5);
verifyEqual(t,d.searchRange,[3 10]);
r.minimumPrefixLength=8;
cfg.autoSessionRange=[0.3 0.5];
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,8);
verifyEqual(t,d.searchRange,[8 8]);
end

function testSmoothedPlateauStopsBeforeActualCliff(t)
[r,cfg]=fn_fixture([100 100 100 100 100 50 50 50 50 50],2);
cfg.autoSessionSmoothWindow=3;
verifyEqual(t,fn_selectTrackingSessionCount(r,cfg),4);
end

function testHalfWindowShiftAndLowerBounds(t)
[r,cfg]=fn_fixture([100*ones(1,10),50*ones(1,10)],2);
cfg.autoSessionSmoothWindow=5;
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,d.peakDropCutoff,10);
verifyEqual(t,n,8);
verifyEqual(t,d.cutoffShift,2);
verifyEqual(t,d.curve.nSessions(d.curve.selected),8);
cfg.autoSessionSmoothWindow=4;
verifyEqual(t,fn_selectTrackingSessionCount(r,cfg),8);
r.minimumPrefixLength=9;
[n,d]=fn_selectTrackingSessionCount(r,cfg);
% Truncated endpoint smoothing peaks at the lower bound; do not cross it.
verifyEqual(t,n,9); verifyEqual(t,d.appliedCutoffShift,0);
r.minimumPrefixLength=2;
cfg.autoSessionRange=[0.45 1];
verifyEqual(t,fn_selectTrackingSessionCount(r,cfg),9);
end

function testFlatSingleEmptyAndFullMinimum(t)
[r,cfg]=fn_fixture(50*ones(1,10),2);
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,10); verifyEqual(t,d.reason,"noPositiveDrop");
[r,cfg]=fn_fixture(50,1);
verifyEqual(t,fn_selectTrackingSessionCount(r,cfg),1);
[r,cfg]=fn_fixture([50 30 10],3);
verifyEqual(t,fn_selectTrackingSessionCount(r,cfg),3);
[n,d]=fn_selectTrackingSessionCount(struct(),cfg);
verifyEqual(t,n,0); verifyEqual(t,d.reason,"noEligibleSessions");
end

function testManualCountsByAnimalAndClamping(t)
[r,cfg]=fn_fixture(100:-1:91,4);
cfg.sessionCountMethod='manual';
cfg.manualSessionCounts=struct('zz153_AC',7,'zz153_PPC',2,'zz159_PPC',30);
cfg.animalID='zz153_AC';
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,7); verifyEqual(t,d.requestedCount,7);
cfg.animalID='zz153_PPC';
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,4); verifyEqual(t,d.reason,"raisedToMinimum");
cfg.animalID='zz159_PPC';
[n,d]=fn_selectTrackingSessionCount(r,cfg);
verifyEqual(t,n,10); verifyEqual(t,d.reason,"limitedToAvailable");
cfg.animalID='unknown';
verifyError(t,@()fn_selectTrackingSessionCount(r,cfg),'trialCuration:ManualSessionCount');
cfg.animalID='';
verifyError(t,@()fn_selectTrackingSessionCount(r,cfg),'trialCuration:AnimalID');
end

function testDirectFileManualIdentityAndExplicitOverride(t)
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
sessionRec=(1:6)'; dayLabel=repmat("T1L",6,1);
trialInfo=table(sessionRec,ones(6,1),dayLabel,repmat("T1",6,1),ones(6,1), ...
    ones(6,1),0.5*ones(6,1),'VariableNames', ...
    {'sessionRec','trialInSession','dayLabel','taskLabel','stimuli','action','RT'});
sessionInfoBeh=table(sessionRec,dayLabel,true(6,1),repmat({ones(1,4)},6,1), ...
    repmat({zeros(2)},6,1),'VariableNames',{'sessionRec','dayLabel','goodTracking','ishere','offsetMap'});
file=fullfile(folder.Folder,'zzTest_AC_parsedTrial_trialInfo.mat');
save(file,'trialInfo');
cfg=fn_expertTrialSelectionConfig(); cfg.makePlots=false; cfg.verbose=false;
cfg.sessionCountMethod='manual'; cfg.manualSessionCounts.zzTest_AC=4;
c=fn_prepareTrialData(file,sessionInfoBeh,cfg);
verifyEqual(t,c.animalID,"zzTest_AC");
verifyEqual(t,c.tracking.numSessionsSelected,4);
verifyEqual(t,sum(c.selectionQC.NSelected),4);
verifyEqual(t,c.tracking.sessionCountSelection.method,"manual");
c.cfg.sessionCountMethod='auto';
c=fn_chooseTrackedSessions(c); % Reuse the complete curve, no file reload.
verifyEqual(t,c.tracking.numSessionsSelected,6); % Flat neuron curve.
c=fn_chooseTrackedSessions(c,5);
verifyEqual(t,c.tracking.numSessionsSelected,5);
verifyEqual(t,c.tracking.sessionCountSelection.method,"fixed");
verifyEmpty(t,c.tracking.sessionCountSelection.curve);
end

function testRejectCountSelectionWithTrackingDisabled(t)
[r,cfg]=fn_fixture([5 4 3],1);
cfg.selectSessionsByTracking=false;
verifyError(t,@()fn_selectTrackingSessionCount(r,cfg),'trialCuration:TrackingDisabled');
end

function [r,cfg]=fn_fixture(counts,minimum)
counts=counts(:); N=numel(counts);
r=struct('sessions',table((1:N)','VariableNames',{'rank'}), ...
    'minimumPrefixLength',minimum, ...
    'curve',table((1:N)',counts,'VariableNames',{'nSessions','nTrackedNeurons'}));
cfg=fn_defaultTrialSelectionConfig(); cfg.sessionCountMethod='auto';
end
