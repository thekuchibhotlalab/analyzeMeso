function tests=testDffStimChoice
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(fileparts(mfilename('fullpath')),'helper')));
end
function testExactFrameMapping(t)
stim=repmat(single(1:100),2,1,3); choice=1000+stim;
[X,m]=fn_makeDffStimChoice(stim,choice);
verifySize(t,X,[2 100 3]); verifyEqual(t,X,cat(2,stim(:,2:33,:),choice(:,28:95,:)));
verifyEqual(t,X(:,30,:),stim(:,31,:)); verifyEqual(t,X(:,36,:),choice(:,31,:));
verifyEqual(t,X(:,33:35,:),choice(:,28:30,:));
verifyEqual(t,m.choicePreFrames,33:35); verifyEqual(t,m.segmentTime(33:35),(-3:-1)/15);
verifyEqual(t,X(:,100,:),choice(:,95,:));
end
function testMissingFramesAndIdentity(t)
[X,~]=fn_makeDffStimChoice(ones(2,31,3,'single'),ones(2,40,3,'single'));
verifyTrue(t,all(isnan(X(:,31:32,:)),'all'));
verifyTrue(t,all(isnan(X(:,46:100,:)),'all'));
verifyEmpty(t,fn_makeDffStimChoice([],ones(2,100,'single')));
verifyError(t,@()fn_makeDffStimChoice(ones(2,100,3),ones(2,100,2)),'trialCuration:CompositeShape');
end
