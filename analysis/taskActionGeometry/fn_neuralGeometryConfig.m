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

plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';           % PNG folder; visible=false saves without display.
plotCfg.prefix='neuralGeometry';
plotCfg.trialTypes=strings(0,1); % Condition names for extra traces; []: skip.
plotCfg.trajectory='none';     % Separate figure: '3d', '2d', 'both', or 'none'; ALL conditions.
plotCfg.trajectoryAxes=[];     % []: first 3 per factor + same-rank cross-factor pairs; or custom triplet.
plotCfg.similarity='correlation'; % Pearson neuron-weight correlation; also 'angle' or 'cosine'.
plotCfg.showConditionContribution=false; % Include condition-contribution heatmap and time courses.
plotCfg.columns=6;             % Maximum subplot columns (at least 3).
plotCfg.figureWidth=1800;      % Pixels; height grows with the number of rows.
plotCfg.rowHeight=280;         % Pixels per subplot row.
end
