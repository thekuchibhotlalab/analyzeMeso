function [cfg,plotCfg] = fn_trialProgressionConfig()
%FN_TRIALPROGRESSIONCONFIG Preliminary, chronological trial progression.
cfg.nProgressionTrials=30;     % First N occurrences of EACH condition/animal.
cfg.psthTrials=1:3;            % Individual trial ordinals to overlay as PSTHs.
cfg.startTrials=1:5;           % Absolute within-condition ordinals.
cfg.endTrials=[];              % []: last nEndTrials in comparisonReference.
cfg.nEndTrials=5;
cfg.comparisonReference='all'; % 'all' input trials, or 'progression' (first common N).
cfg.selectionMethod='variance'; % 'variance' or 'progression' (linear trend energy).
cfg.progressionDirection='positive'; % For progression: 'positive', 'negative', 'both'.
cfg.selectedFraction=0.2;      % Top fraction of eligible pooled neurons, per condition.
cfg.nSelectedNeurons=[];       % Set an integer to override selectedFraction.
cfg.time=[];                  % Explicit seconds, one entry per time bin.
cfg.frameRate=15; cfg.eventFrame=31;
cfg.scoreTimeWindow=[];        % []: all bins; or e.g. [0 1] for reward-related activity.
cfg.animalLabels=strings(0,1);
cfg.dropNonfiniteNeurons=true;
cfg.verbose=true;

plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';
plotCfg.prefix='trialProgression';
plotCfg.showSEM=true;          % Descriptive SEM across neurons, not animal-level CI.
end
