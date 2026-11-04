function [cfg,plotCfg] = fn_neuralGeometryConfig()
%FN_NEURALGEOMETRYCONFIG Analysis and display options for pooled neurons.
cfg.method='lda';              % 'lda', 'meanSquared', or 'regression'
cfg.nAxes=3;                   % Per variable; stop if residual signal vanishes.
cfg.normalization='none';      % 'none', 'zscore', or 'rms'; pooled time/trials.
cfg.covariance='diagonal';     % LDA: 'diagonal' or 'withinAnimal' full blocks.
cfg.ridge=1e-3;                % Relative within-group covariance regularization.
cfg.tolerance=1e-9;            % Relative stopping threshold for residual signal.
cfg.variables=strings(0,1);    % []: all table columns except conditionName.
cfg.time=[];                   % Explicit seconds, one entry per time bin.
cfg.frameRate=15;
cfg.eventFrame=31;
cfg.timeWindow=[];             % []: all bins; otherwise [start end] seconds.
cfg.animalLabels=strings(0,1);
cfg.missingAnimal='exclude';   % 'exclude' or 'error' if any condition is empty.
cfg.dropNonfiniteNeurons=true; % Drop a neuron across ALL analyzed conditions.
cfg.verbose=true;
cfg.crossValidate=true;        % LDA only; false restores descriptive full-data fits.
cfg.cvFolds=5;                 % Whole trials, stratified by animal and condition.
cfg.cvRepeats=5;               % Independent partitions; SEM across repeat means.
cfg.cvSeed=1;
cfg.decode=true;               % Real-trial single-neuron binary LDA decoders.
cfg.decoderTopFractions=[0.10 0.25];
cfg.decoderFractions=[];       % Deprecated/ignored; retained for saved cfg compatibility.
cfg.decoderInnerFolds=3;       % Training-only ranking for top-group time courses.
cfg.decoderChoiceVariable='action';
cfg.decoderWindowFrames=3;     % Fixed -3:-1, excluding choice frame; requires 15 Hz dffChoice.
cfg.decoderPseudoTrials=[];    % Deprecated/ignored; no pseudo-population decoding.


plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';           % PNG + editable FIG folder; visible=false saves without display.
plotCfg.prefix='neuralGeometry';
plotCfg.trialTypes=strings(0,1); % Condition names for extra traces; []: skip.
plotCfg.projectionError='sem'; % CV: SEM/SD across repeat means; legacy: trial errors.
plotCfg.trajectory='none';     % Separate figure: '3d', '2d', 'both', or 'none'; ALL conditions.
plotCfg.trajectoryAxes=[];     % []: first 3 per factor + same-rank cross-factor pairs; or custom triplet.
plotCfg.similarity='cosine';    % Also 'correlation' (Pearson) or unsigned 'angle'.
plotCfg.showConditionContribution=false; % Include condition-contribution heatmap and time courses.
plotCfg.columns=6;             % Maximum subplot columns (at least 3).
plotCfg.figureWidth=1800;      % Pixels; height grows with the number of rows.
plotCfg.rowHeight=280;         % Pixels per subplot row.
end
