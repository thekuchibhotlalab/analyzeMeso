%%
clear;
aniPath = 'B:\animal';

animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};
%% Load animal Data
allAni = {};
for i = 1:length(animals)
    load([aniPath filesep animals{i} '_animal.mat'],'ani');
    allAni{i} = ani;
end


%% Run after defining allAni (cell array of Animal objects) and animals.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','learningChoiceAxes'));
addpath(genpath(fullfile(repo,'organizer','trialCuration')));
addpath(fullfile(repo,'helper_function'));
[cfg,plotCfg,selectionCfg]=fn_learningChoiceAxesConfig();
cfg.nT2Bins=4; cfg.windowWidthChunks=1;
cfg.decoder='svm'; % Or 'svm': linear support-vector classifier.
% Existing session/tracking controls remain available:
% selectionCfg.trackingMethod='lookahead';
% selectionCfg.sessionCountMethod='fixed'; selectionCfg.numSessions=Inf;
selectionCfg.neuralField='dffStimChoice'; % Composite; choice pre-frames 33:35.
plotCfg.savePath='B:/analysis/learningChoiceAxes'; plotCfg.visible=false;
learningResults=cell(size(allAni)); learningPlans=cell(size(allAni)); learningAudits=cell(size(allAni));
quietPlots=plotCfg; quietPlots.makePlot=false;
for a=1:numel(allAni)
    s=selectionCfg; s.animalID=string(allAni{a}.ID);
    [selected,learningPlans{a}]=fn_prepareLearningChoiceData( ...
        allAni{a}.trialInfo,allAni{a}.sessionInfoBeh,allAni{a}.ops.sessionInfoName,s,cfg);
    learningAudits{a}=struct('cfg',selected.cfg,'tracking',selected.tracking, ...
        'selectionQC',selected.selectionQC,'droppedTrialReport',selected.droppedTrialReport);
    animalCfg=cfg; animalCfg.seed=cfg.seed+a-1;
    one=fn_analyzeLearningChoiceAxes(selected,animalCfg,quietPlots);
    learningResults{a}=one.animals{1};
    clear selected % Release this animal's trial-by-trial fluorescence before loading the next.
end
learningAxes=one; learningAxes.cfg=cfg; learningAxes.animals=learningResults;
[learningFigures,learningAxes.plotFiles]=fn_plotLearningChoiceAxes(learningAxes,plotCfg);
if ~isfolder(plotCfg.savePath), mkdir(plotCfg.savePath); end
save(fullfile(plotCfg.savePath,'learningChoiceAxes_svm_chunk4_bin1.mat'),'learningAxes','learningPlans','learningAudits','-v7.3');
%%

a = cellfun(@(x)(x.angleDegrees),learningAxes.animals,'UniformOutput',false);
b = fn_cell2matFillNan(a);
figure; plot(b)