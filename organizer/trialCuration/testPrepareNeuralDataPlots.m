function tests=testPrepareNeuralDataPlots
tests=functiontests(localfunctions);
end
function setupOnce(t)
root=fileparts(mfilename('fullpath'));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root,'IncludingSubfolders',true));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(fileparts(root),'object_organzier')));
end
function testDefaultDoesNotPlotEvenWithCfgEnabled(t)
[c,S]=fixture(); c.cfg.makePlots=true;
before=findall(groot,'Type','figure');
r=fn_prepareNeuralData(c,S);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyEmpty(t,fieldnames(r.plotFiles)); verifyTrue(t,r.neuralLoaded);
end
function testSaveHiddenAndObjectForwarding(t)
[c,sessionInfo]=fixture();
% Saving must reconstruct the curve even when trial selection made no figure.
c.tracking.curve=table((1:3)',[2;5;8],[3;2;1], ...
    'VariableNames',{'nSessions','nTrials','nTrackedNeurons'});
c.tracking.numSessionsSelected=2;
c.tracking.method='lookahead';
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(folder.Folder,'neural.mat'); save(file,'sessionInfo');
ani=Animal(); ani.ID='fixture_AC'; ani.ops=struct('sessionInfoName',file);
out=fullfile(folder.Folder,'plots'); before=findall(groot,'Type','figure');
r=ani.fn_prepareNeuralData(c,'PlotSavePath',out);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyEqual(t,numel(fieldnames(r.plotFiles)),4);
verifyTrue(t,isfield(r.plotFiles,'trackingCurve'));
for name=fieldnames(r.plotFiles)'
    file=r.plotFiles.(name{1}); verifyTrue(t,isfile(file));
    info=imfinfo(file); verifyEqual(t,info.Format,'png');
    verifyEmpty(t,r.figures.(name{1}));
end
end
function testDisplayOnly(t)
[c,S]=fixture(); r=fn_prepareNeuralData(c,S,'ShowPlots',true);
cleanup=onCleanup(@()closeFigures(r)); %#ok<NASGU>
verifyEmpty(t,fieldnames(r.plotFiles));
for name={'trialCounts','meanTC','sessionAmplitude'}
    verifyEqual(t,char(r.figures.(name{1}).Visible),'on');
end
end
function testDataPathFileOverridesAnimalSource(t)
[c,sessionInfo]=fixture();
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(folder.Folder,'copied_neural.mat'); save(file,'sessionInfo');
ani=Animal(); ani.ID='fixture_AC';
ani.ops=struct('sessionInfoName',fullfile(folder.Folder,'missing.mat'));
originalOps=ani.ops;
r=ani.fn_prepareNeuralData(c,'DataPath',file);
verifyEqual(t,r.neuralSelection(1).neuralRaw,sessionInfo.dffChoice{1}(:,:,1));
verifyEqual(t,r.neuralSourceFile,char(java.io.File(file).getCanonicalPath()));
verifyEqual(t,ani.ops,originalOps);
% The standalone function accepts the same override, including a missing source.
r=fn_prepareNeuralData(c,[],'DataPath',file);
verifyEqual(t,r.neuralSelection(2).neuralRaw,sessionInfo.dffChoice{1}(:,:,2));
end
function testDataPathFolderAndMissingOps(t)
[c,sessionInfo]=fixture();
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=fullfile(folder.Folder,'fixture_AC_parsedTrial.mat'); save(file,'sessionInfo');
ani=Animal(); ani.ID='fixture_AC';
ani.ops=struct('sessionInfoName','Z:\unavailable\fixture_AC_parsedTrial.mat');
r=ani.fn_prepareNeuralData(c,'DataPath',folder.Folder);
verifyEqual(t,r.neuralSourceFile,char(java.io.File(file).getCanonicalPath()));
ani.ops=struct();
r=ani.fn_prepareNeuralData(c,'DataPath',folder.Folder);
verifyEqual(t,r.neuralSourceFile,char(java.io.File(file).getCanonicalPath()));
end
function testInvalidDataPathDoesNotFallBack(t)
[c,S]=fixture();
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
verifyError(t,@()fn_prepareNeuralData(c,S,'DataPath', ...
    fullfile(folder.Folder,'missing.mat')),'trialCuration:DataPath');
end
function testDisplayAndSave(t)
[c,S]=fixture(); folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
r=fn_prepareNeuralData(c,S,'ShowPlots',true,'PlotSavePath',folder.Folder);
cleanup=onCleanup(@()closeFigures(r)); %#ok<NASGU>
for name=fieldnames(r.plotFiles)'
    verifyTrue(t,isfile(r.plotFiles.(name{1})));
    verifyEqual(t,char(r.figures.(name{1}).Visible),'on');
end
end
function testTrialPlotsIndependentOfNeuralPlots(t)
[c,S,T]=fixture();
cfg=c.cfg; cfg.selectSessionsByTracking=true; cfg.minSessionsPerStage=1;
S.offsetMap={zeros(2)}; S.ishere={true(3,1)};
ani=Animal(); ani.ID='fixture_AC'; ani.trialInfo=T; ani.sessionInfoBeh=S;
ani.ops=struct('sessionInfoName','unused-neural-file.mat');
selected=ani.fn_prepareTrialData(cfg,'MakePlot',true);
cleanup=onCleanup(@()closeTrialFigures(selected)); %#ok<NASGU>
verifyFalse(t,selected.neuralLoaded);
verifyEqual(t,char(selected.figures.tracking.Visible),'on');
verifyEqual(t,char(selected.figures.rt.Visible),'on');
verifyEqual(t,numel(findall(selected.figures.tracking,'Tag','TrialSelectionPrefix')),2);
before=findall(groot,'Type','figure');
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
r=fn_prepareNeuralData(selected,S,'PlotSavePath',folder.Folder);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyTrue(t,isfile(r.plotFiles.trackingCurve));
verifyEqual(t,char(selected.figures.tracking.Visible),'on');
% A stale config must not override the function's default or explicit false.
cfg.makePlots=true;
quiet=fn_prepareTrialData(T,S,cfg);
verifyEmpty(t,quiet.tracking.figure);
quiet=ani.fn_prepareTrialData(cfg,'MakePlot',false);
verifyEmpty(t,quiet.tracking.figure);
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function closeTrialFigures(r)
for name={'tracking','rt'}
    fig=r.figures.(name{1}); if isgraphics(fig), close(fig); end
end
end
function closeFigures(r)
for name={'trialCounts','meanTC','sessionAmplitude'}
    fig=r.figures.(name{1}); if isgraphics(fig), close(fig); end
end
end
function [c,S,T]=fixture()
cfg=fn_trialSelectionSettings(); cfg.verbose=false;
cfg.selectSessionsByTracking=false; cfg.runTrackedNeuronQC=false;
cfg.sessionCountMethod='fixed'; cfg.numSessions=Inf; cfg.minTrials=1;
cfg.animalID='fixture_AC'; cfg.alignedEventFrame=2;
cfg.conditionDef=[fn_trialCondition("left","T1L",[],1,1); ...
    fn_trialCondition("right","T1L",[],2,2)];
sessionRec=[1;1]; trialInSession=[1;2]; dayLabel=["T1L";"T1L"];
taskLabel=["T1";"T1"]; stimuli=[1;2]; action=[1;2]; RT=[0.5;0.5];
T=table(sessionRec,trialInSession,dayLabel,taskLabel,stimuli,action,RT);
S=table(1,"T1L",true,'VariableNames',{'sessionRec','dayLabel','goodTracking'});
c=fn_prepareTrialData(T,S,cfg);
S.dffChoice={reshape(single(1:24),3,4,2)};
end
