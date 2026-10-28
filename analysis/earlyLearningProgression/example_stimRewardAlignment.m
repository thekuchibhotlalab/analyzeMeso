%% AC: stimulus/reward alignment during T1 learning.
% Add analyzeMeso (including subfolders) to your MATLAB path first.
aniPath='B:\animal';
animals={'zz151_AC1','zz153_AC','zz159_AC','zz170_AC1','zz170_AC2','zz180_AC'};
phases=["T1E","T1M","T1L"];

%% Query rewarded S1/L and S2/R trials in each phase, using stimulus alignment.
selectionCfg=fn_earlyT1TrialSelectionConfig();
selectionCfg.neuralField='dffStim';
selectionCfg.alignedEventName='Stimulus';
selectionCfg.conditionDef=[];
for phase=phases
    selectionCfg.conditionDef=[selectionCfg.conditionDef; ...
        fn_trialCondition(phase+"_S1_L",phase,[],1,1,1); ...
        fn_trialCondition(phase+"_S2_R",phase,[],2,2,1)];
end
% Inherits RT and session-tracking filters from the selection preset.
% To include all RTs: selectionCfg.useRTFilter=false;
nConditions=numel(selectionCfg.conditionDef);
activity=cell(nConditions,numel(animals)); trialInfo=cell(size(activity));
for a=1:numel(animals)
    loaded=load(fullfile(aniPath,[animals{a} '_animal.mat']),'ani');
    trialSel=loaded.ani.fn_prepareTrialData(selectionCfg,'MakePlot',false);
    neural=loaded.ani.fn_prepareNeuralData(trialSel);
    % For relocated neural files, add 'DataPath',yourLocalPath above.
    assert(isequal(string({neural.neuralSelection.name}),string({selectionCfg.conditionDef.name})), ...
        'Neural condition order must match the query.');
    for c=1:nConditions
        X=neural.neuralSelection(c).neuralRaw;
        if isempty(X), continue; end
        activity{c,a}=X(neural.tracking.selectedNeuronMask,:,:);
        trialInfo{c,a}=neural.neuralSelection(c).trialInfoNeural;
    end
end

%% Reduce every rewarded trial to two responses per neuron, then bin learning.
[cfg,plotCfg]=fn_stimRewardAlignmentConfig();
cfg.animalLabels=string(animals);
cfg.phaseOrder=phases;
cfg.eventFrame=selectionCfg.alignedEventFrame;
cfg.stimulusOffsets=1:3;
cfg.rewardOffsets=3:4;       % Relative to responseFrame (choice threshold).
cfg.binSize=50;
cfg.includePartialBin=true;
cfg.baselineOffsets=[];     % Optional -5:-1, shared prestimulus baseline.
cfg.normalization='zscore'; % One scale per neuron across all input phases/types/trials/time.
cfg.nEarlyTrials=500;       % Up to 10 pooled subplots per stimulus, stopping when data ends.
cfg.pooledBinSize=50;       % Panels: 1:50, 51:100, ..., 451:500. Separate S1 and S2 figures.
plotCfg.showPooledEarlyTrials=true;
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\stimRewardAlignment';
[alignment,figures]=fn_analyzeStimRewardAlignment( ...
    activity,selectionCfg,cfg,plotCfg,trialInfo);

% Reduced neuron x trial arrays, with exact original trial identities:
S1animal1=alignment.byStimulus(1,1);
stimulusResponse=S1animal1.stimulusActivity;
rewardResponse=S1animal1.rewardActivity;
trialMap=S1animal1.trials;
% S1animal1.crossBinCorrelation(i,j): stimulus bin i vs reward bin j.
% S1animal1.withinBinCorrelation: diagonal, alignment within each bin.
% alignment.pooledEarlyTrials.byStimulus(s): separate correlations/counts for each stimulus.
% [figures,files]=fn_plotStimRewardAlignment(alignment,plotCfg); % No reload needed.
% save('stimRewardAlignment.mat','alignment'); % Figure handles are separate.
