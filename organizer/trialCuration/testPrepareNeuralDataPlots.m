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
verifyFalse(t,isfield(r,'figures'));
verifyFalse(t,isfield(r.tracking,'figure'));
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
[r,figures]=ani.fn_prepareNeuralData(c,'PlotSavePath',out);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyEqual(t,numel(fieldnames(r.plotFiles)),4);
verifyTrue(t,isfield(r.plotFiles,'trackingCurve'));
for name=fieldnames(r.plotFiles)'
    file=r.plotFiles.(name{1}); verifyTrue(t,isfile(file));
    info=imfinfo(file); verifyEqual(t,info.Format,'png');
    figFile=[file(1:end-4) '.fig']; verifyTrue(t,isfile(figFile));
    reopened=openfig(figFile,'new','invisible');
    cleanup=onCleanup(@()close(reopened));
    verifyNotEmpty(t,findall(reopened,'Type','axes'));
    clear cleanup
    verifyEmpty(t,figures.(name{1}));
end
end
function testDisplayOnly(t)
[c,S]=fixture(); [r,figures]=fn_prepareNeuralData(c,S,'ShowPlots',true);
cleanup=onCleanup(@()closeFigures(figures)); %#ok<NASGU>
verifyEmpty(t,fieldnames(r.plotFiles));
for name={'trialCounts','meanTC','sessionAmplitude'}
    verifyEqual(t,char(figures.(name{1}).Visible),'on');
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
[r,figures]=fn_prepareNeuralData(c,S,'ShowPlots',true,'PlotSavePath',folder.Folder);
cleanup=onCleanup(@()closeFigures(figures)); %#ok<NASGU>
for name=fieldnames(r.plotFiles)'
    verifyTrue(t,isfile(r.plotFiles.(name{1})));
    file=r.plotFiles.(name{1}); verifyTrue(t,isfile([file(1:end-4) '.fig']));
    verifyEqual(t,char(figures.(name{1}).Visible),'on');
end
end
function testTrialPlotsIndependentOfNeuralPlots(t)
[c,S,T]=fixture();
cfg=c.cfg; cfg.selectSessionsByTracking=true; cfg.minSessionsPerStage=1;
S.offsetMap={zeros(2)}; S.ishere={true(3,1)};
ani=Animal(); ani.ID='fixture_AC'; ani.trialInfo=T; ani.sessionInfoBeh=S;
ani.ops=struct('sessionInfoName','unused-neural-file.mat');
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
cfg.saveFile=fullfile(folder.Folder,'selected.mat');
[selected,trialFigures]=ani.fn_prepareTrialData(cfg,'MakePlot',true);
cleanup=onCleanup(@()closeTrialFigures(trialFigures)); %#ok<NASGU>
verifyFalse(t,selected.neuralLoaded);
verifyFalse(t,isfield(selected,'figures'));
verifyFalse(t,isfield(selected.tracking,'figure'));
saved=load(cfg.saveFile,'curated');
verifyFalse(t,isfield(saved.curated,'figures'));
verifyFalse(t,isfield(saved.curated.tracking,'figure'));
reselected=fn_chooseTrackedSessions(selected,1);
verifyEqual(t,reselected.tracking.numSessionsSelected,1);
verifyEqual(t,char(trialFigures.tracking.Visible),'on');
verifyEqual(t,char(trialFigures.rt.Visible),'on');
verifyEqual(t,numel(findall(trialFigures.tracking,'Tag','TrialSelectionPrefix')),2);
before=findall(groot,'Type','figure');
[r,figures]=fn_prepareNeuralData(selected,S,'PlotSavePath',folder.Folder);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyTrue(t,isfile(r.plotFiles.trackingCurve));
verifyEqual(t,char(trialFigures.tracking.Visible),'on');
verifyFalse(t,isfield(figures,'tracking'));
verifyFalse(t,isfield(figures,'rt'));
verifyFalse(t,isfield(r,'figures'));
verifyFalse(t,isfield(r.tracking,'figure'));
% A stale config must not override the function's default or explicit false.
cfg.makePlots=true;
[quiet,quietFigures]=fn_prepareTrialData(T,S,cfg);
verifyFalse(t,isfield(quiet.tracking,'figure'));
verifyEmpty(t,quietFigures.tracking); verifyEmpty(t,quietFigures.rt);
[quiet,quietFigures]=ani.fn_prepareTrialData(cfg,'MakePlot',false);
verifyFalse(t,isfield(quiet.tracking,'figure'));
verifyEmpty(t,quietFigures.tracking); verifyEmpty(t,quietFigures.rt);
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function testTrialSelectionWithNeuralLoad(t)
[c,S,T]=fixture();
cfg=c.cfg; cfg.loadNeural=true; cfg.sessionInfoFile='';
[r,figures]=fn_prepareTrialData(T,S,cfg,'MakePlot',true);
cleanup=onCleanup(@()closeTrialFigures(figures)); %#ok<NASGU>
verifyTrue(t,r.neuralLoaded);
verifyFalse(t,isfield(r,'figures'));
verifyFalse(t,isfield(r.tracking,'figure'));
verifyEqual(t,char(figures.rt.Visible),'on');
verifyEmpty(t,figures.tracking);
end
function closeTrialFigures(figures)
for name={'tracking','rt'}
    fig=figures.(name{1}); if isgraphics(fig), close(fig); end
end
end
function closeFigures(figures)
for name={'trialCounts','meanTC','sessionAmplitude'}
    fig=figures.(name{1}); if isgraphics(fig), close(fig); end
end
end
function [c,S,T]=fixture()
cfg=fn_trialSelectionSettings(); cfg.verbose=false;
cfg.useRTFilter=false;
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
