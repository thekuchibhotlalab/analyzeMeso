function [cfg,plotCfg] = fn_stimRewardAlignmentConfig()
%FN_STIMREWARDALIGNMENTCONFIG Stimulus/reward population alignment in AC.
cfg.neuralField='dffStim';           % Input MUST be stimulus aligned.
cfg.eventFrame=31;                  % Stimulus onset, MATLAB 1-based index.
cfg.stimulusOffsets=1:3;             % Frames strictly AFTER stimulus onset.
cfg.rewardOffsets=3:4;              % Frames after CHOICE THRESHOLD, not rewardFrame.
cfg.stimulusFrameField='stimulusFrame';
cfg.choiceFrameField='responseFrame';
cfg.baselineOffsets=[];             % Optional, e.g. -5:-1; same baseline for both responses.
cfg.normalization='none';           % 'zscore': per neuron across ALL supplied time/trials/conditions.
cfg.phaseOrder=["T1E","T1M","T1L"];
cfg.stimuli=[1 2];
cfg.binSize=50;                     % Separate rewarded-trial sequences for S1 and S2.
cfg.includePartialBin=true;         % Keep final <50-trial bin; actual counts reported.
cfg.animalLabels=strings(0,1);
cfg.nEarlyTrials=500;               % Pooled scatter: up to first 500 trials per stimulus/animal.
cfg.pooledBinSize=50;               % Up to 10 panels: 1:50, 51:100, ...; stop when data ends.

plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';                % With visible=false: save PNGs, close figures.
plotCfg.prefix='stimRewardAlignment';
plotCfg.maxScatterPanels=12;        % Paginate long learning sequences.
plotCfg.showPooledEarlyTrials=true;  % Pool animals in separate S1/S2 figures and correlations.
end
