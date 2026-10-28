function [cfg,plotCfg] = fn_trialProgressionConfig()
%FN_TRIALPROGRESSIONCONFIG Preliminary, chronological trial progression.
cfg.groupBy='condition';      % 'outcome': concatenate phases; 'phaseOutcome': separate phases.
cfg.phaseOrder=["T1E","T1M","T1L"]; % Order for groupBy='outcome'; [] uses definition order.
cfg.nProgressionTrials=50;     % First N occurrences per group/animal; Inf = full common sequence.
cfg.nStimulusBins=10;          % Equal-count bins of ALL trials per stimulus/animal; 0 disables.
cfg.psthTrials=1:3;            % Individual trial ordinals to overlay as PSTHs.
cfg.startTrials=1:10;          % Absolute within-condition ordinals.
cfg.endTrials=[];              % []: last nEndTrials in comparisonReference.
cfg.nEndTrials=10;
cfg.comparisonReference='progression'; % Last ten of first common N; 'all' uses all input trials.
cfg.selectionMethod='variance'; % 'variance' or 'progression' (linear trend energy).
cfg.progressionDirection='positive'; % For progression: 'positive', 'negative', 'both'.
cfg.selectedFraction=0.2;      % Top fraction of eligible pooled neurons, per condition.
cfg.nSelectedNeurons=[];       % Set an integer to override selectedFraction.
cfg.normalization='none';     % 'none', 'zscore', 'rms'; per neuron pooled across phases/types/trials.
cfg.time=[];                  % Explicit seconds, one entry per time bin.
cfg.frameRate=15; cfg.eventFrame=31;
cfg.timeWindow=[];             % [start end] seconds: restrict BOTH analysis and plots.
cfg.scoreTimeWindow=[];        % Optional narrower scoring window within timeWindow.
cfg.animalLabels=strings(0,1);
cfg.dropNonfiniteNeurons=true;
cfg.verbose=true;

plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';
plotCfg.prefix='trialProgression';
plotCfg.showSEM=true;          % Descriptive SEM across neurons, not animal-level CI.
plotCfg.heatmapMethod='bin';    % 'bin', 'smooth', or 'none'; display only.
plotCfg.heatmapWindow=5;        % Trial-bin size or moving-average window.
plotCfg.showStimulusBins=true; % Additional per-animal stimulus heatmaps.
plotCfg.showAnimals=true;      % Main progression and outcome comparisons for each animal too.
end
