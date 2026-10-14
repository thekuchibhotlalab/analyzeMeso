function tests=testBatchPrepareNeuralData
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath')));
repo=fileparts(fileparts(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'organizer','object_organzier')));
fn_neuralDataQueries();
end
function testAcrossAnimalsAndQueries(t)
[root,out,q]=fixture(t,2);
s=fn_batchPrepareNeuralData(root,out,q);
verifyEqual(t,s.status,repmat("saved",4,1));
verifyEqual(t,s.nNeuralTrials,ones(4,1));
for a=1:2
    id=sprintf('test%d_AC',a);
    d=load(fullfile(out,'early',id+"_neural.mat"),'neural');
    verifyEqual(t,d.neural.animalID,string(id));
    verifyEqual(t,d.neural.byCondition.left.neuralRaw,single(a*ones(2,3)));
    verifyEqual(t,d.neural.byCondition.left.trialInfo.trialInSession,1);
    verifyFalse(t,d.neural.cfg.makePlots);
    d=load(fullfile(out,'late',id+"_neural.mat"),'neural');
    verifyEqual(t,d.neural.byCondition.right.trialInfo.trialInSession,2);
end
end
function testSkipAndAnimalSubset(t)
[root,out,q]=fixture(t,2);
s=fn_batchPrepareNeuralData(root,out,q,'AnimalIDs',"test2_AC");
verifyEqual(t,height(s),2); verifyEqual(t,s.animalID,repmat("test2_AC",2,1));
delete(fullfile(root,'parsedTrial','test2_AC_parsedTrial.mat'));
s=fn_batchPrepareNeuralData(root,out,q,'AnimalIDs',"test2_AC");
verifyEqual(t,s.status,repmat("skipped",2,1));
verifyError(t,@()fn_batchPrepareNeuralData(root,out,q,'AnimalIDs',"absent"),'neuralBatch:Animals');
end
function testEmptyOverwriteAndFailures(t)
[root,out,q]=fixture(t,2);
delete(fullfile(root,'parsedTrial','test1_AC_parsedTrial.mat'));
s=fn_batchPrepareNeuralData(root,out,q);
verifyEqual(t,s.status,["failed";"failed";"saved";"saved"]);
q.early.RTRange=[2 3]; q.late.RTRange=[2 3];
s=fn_batchPrepareNeuralData(root,out,q,'Overwrite',true);
verifyEqual(t,s.status,repmat("empty",4,1));
d=load(s.outputFile(1),'neural'); verifyFalse(t,d.neural.neuralLoaded);
end
function testNeuralTableReusedAcrossQueries(t)
[root,out,q]=fixture(t,1);
% Remove this TEMP fixture's source during query one. Query two must reuse
% the in-memory sessionInfo rather than try to load the file again.
q.early.normalizationFcn=@removeFixtureFile;
s=fn_batchPrepareNeuralData(root,out,q);
verifyEqual(t,s.status,["saved";"saved"]);
verifyFalse(t,isfile(fullfile(root,'parsedTrial','test1_AC_parsedTrial.mat')));
end
function X=removeFixtureFile(X,~,~,cfg)
delete(cfg.sessionInfoFile);
end
function [root,out,q]=fixture(t,n)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
root=fullfile(f.Folder,'animals'); out=fullfile(f.Folder,'output');
mkdir(root); mkdir(fullfile(root,'parsedTrial'));
q=fn_neuralDataQueries(); cfg=q.earlyT1;
cfg.selectSessionsByTracking=false; cfg.sessionCountMethod='fixed'; cfg.numSessions=Inf;
cfg.runTrackedNeuronQC=false; cfg.minTrials=1;
cfg.conditionDef=fn_trialCondition("left","T1E",[],1,1);
q=struct('early',cfg,'late',cfg);
q.late.conditionDef=fn_trialCondition("right","T1L",[],2,2);
for a=1:n
    ani=Animal(); ani.ID=sprintf('test%d_AC',a);
    file=fullfile(root,'parsedTrial',[ani.ID '_parsedTrial.mat']);
    ani.ops=struct('sessionInfoName',file);
    sessionRec=[1;2]; dayLabel=["T1E";"T1L"]; goodTracking=[true;true];
    ishere=ones(2,2); offsetMap={zeros(2);zeros(2)};
    ani.sessionInfoBeh=table(sessionRec,dayLabel,goodTracking,ishere,offsetMap);
    taskLabel=["T1";"T1"]; stimuli=[1;2]; action=[1;2]; RT=[0.5;0.5]; trialInSession=[1;2];
    ani.trialInfo=table(sessionRec,dayLabel,taskLabel,stimuli,action,RT,trialInSession);
    sessionInfo=ani.sessionInfoBeh;
    sessionInfo.dffChoice={single(a*ones(2,3,2));single(a*ones(2,3,2))};
    save(file,'sessionInfo'); save(fullfile(root,[ani.ID '_animal.mat']),'ani');
end
end
