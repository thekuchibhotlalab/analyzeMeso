function [cfg,plotCfg]=fn_taskStimGeometryConfig()
%FN_TASKSTIMGEOMETRYCONFIG Three binary LDA comparisons of reduced AC responses.
cfg.period='stimulus';              % 'stimulus' or 'reward'; input is dffStim in both cases.
cfg.neuralField='dffStim';
cfg.eventFrame=31;
cfg.stimulusOffsets=1:3;
cfg.rewardOffsets=3:4;               % After choice threshold, not measured reward delivery.
cfg.stimulusFrameField='stimulusFrame';
cfg.choiceFrameField='responseFrame';
cfg.comparisons=["stimT1","stimT2","task"]; % Binary columns; empty labels exclude a row.
cfg.normalization='none';           % 'zscore': pool reduced trials across input conditions.
cfg.covariance='withinAnimal';      % Full within-animal noise, or 'diagonal'.
cfg.ridge=1e-3;                     % Relative to mean within-class variance.
cfg.minTrials=2;
cfg.missingAnimal='exclude';        % Or 'error'; require all conditions in each retained animal.
cfg.animalLabels=strings(0,1);
cfg.nPseudoTrials=[];               % []: smallest available count per condition, without replacement.
                                   % Integer: this many per condition, sampled WITH replacement.
cfg.seed=1;
plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';
plotCfg.prefix='taskStimGeometry';
plotCfg.pointSize=16;
end
