function tests=testTrialProjectionSEM
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
end
function testFoldCombinationAndRepeatedTrials(t)
r.time=1:3; r.crossValidation.enabled=true;
r.projection.conditionMean=zeros(1,3,2);
r.crossValidation.nFolds=2; r.crossValidation.nRepeats=2;
for s=1:4
    r.crossValidation.splits{s}.projection.conditionSEM=cat(3,2*ones(1,3),4*ones(1,3));
end
verifyEqual(t,fn_neuralGeometryTrialSEM(r,1,[1 2]),sqrt(5/2)*ones(1,3),'AbsTol',1e-12);
saved=fn_addNeuralGeometryTrialSEM(r);
verifyEqual(t,saved.projection.conditionTrialSEM,cat(3,sqrt(2)*ones(1,3),sqrt(8)*ones(1,3)),'AbsTol',1e-12);
verifyEqual(t,fn_neuralGeometryTrialSEM(saved,1,[1 2]),fn_neuralGeometryTrialSEM(r,1,[1 2]),'AbsTol',1e-12);
r.crossValidation.nRepeats=4;
r.crossValidation.splits=[r.crossValidation.splits r.crossValidation.splits];
verifyEqual(t,fn_neuralGeometryTrialSEM(r,1,[1 2]),sqrt(5/2)*ones(1,3),'AbsTol',1e-12);
end
function testDescriptiveTrialSEM(t)
r.projection.conditionSEM=cat(3,2*ones(1,3),4*ones(1,3));
verifyEqual(t,fn_neuralGeometryTrialSEM(r,1,[1 2]),sqrt(5)*ones(1,3),'AbsTol',1e-12);
end
