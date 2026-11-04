function [cfg,plotCfg]=fn_taskStimGeometryConfig()
%FN_TASKSTIMGEOMETRYCONFIG Six binary LDA comparisons of reduced AC responses.
cfg.period='stimulus';              % 'stimulus' or 'reward'; input is dffStim in both cases.
cfg.neuralField='dffStim';
cfg.eventFrame=31;
cfg.stimulusOffsets=1:3;
cfg.rewardOffsets=3:4;               % After choice threshold, not measured reward delivery.
cfg.stimulusFrameField='stimulusFrame';
cfg.choiceFrameField='responseFrame';
cfg.comparisons=["stimT1","stimT2","task","stimS1S3","stimS2S4","action"];
% Binary table columns; empty labels exclude a row. Each triplet gets one plot row.
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
plotCfg.savePath='';            % Save PNG + editable FIG files when nonempty.
plotCfg.prefix='taskStimGeometry';
plotCfg.pointSize=16;
plotCfg.axisColors=[0 0.447 0.741; 0.85 0.325 0.098; 0.494 0.184 0.556; ...
    0 0.55 0.3; 0.75 0.4 0.65; 0.55 0.35 0.15]; % Comparison order.
end
