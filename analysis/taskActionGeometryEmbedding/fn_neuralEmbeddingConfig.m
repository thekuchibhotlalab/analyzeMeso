function [cfg,plotCfg] = fn_neuralEmbeddingConfig()
%FN_NEURALEMBEDDINGCONFIG Trial-averaged, pooled-neuron UMAP options.
cfg.nNeighbors=100;           % Paper setting; capped at nPoints-1.
cfg.minDist=0.1;
cfg.spread=1;
cfg.metric='correlation';     % 'correlation', 'euclidean', or 'cosine'.
cfg.nEpochs=500;
cfg.randomize=false;          % run_umap resets to its default RNG seed.
cfg.backendMethod='MEX';      % run_umap optimizer; 'MATLAB' is a slower option.
cfg.normalization='none';     % 'none', 'zscore', 'rms'; raw pooled samples before averaging.
cfg.time=[];
cfg.frameRate=15;
cfg.eventFrame=31;
cfg.timeWindow=[];
cfg.variables=strings(0,1);   % []: all columns except conditionName; labels only.
cfg.animalLabels=strings(0,1);
cfg.missingAnimal='exclude';  % Exclude whole animal if any condition is empty.
cfg.dropNonfiniteNeurons=true;
cfg.diagnosticNeighbors=10;  % Local fidelity; capped below nPoints/2.
cfg.maxDiagnosticPoints=2000; % Exact diagnostics use quadratic memory; [] disables limit.
cfg.verbose=true;

plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';
plotCfg.prefix='neuralEmbedding';
plotCfg.colorBy=strings(0,1); % []: conditionName, then all cfg.variables.
plotCfg.showTime=true;        % Append a continuous time-colored panel across all conditions.
plotCfg.connectTime=false;    % Optional lines within each condition, in time order.
plotCfg.pointSize=24;
end
