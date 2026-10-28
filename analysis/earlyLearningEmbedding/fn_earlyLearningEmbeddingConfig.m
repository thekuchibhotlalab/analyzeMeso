function [cfg,plotCfg]=fn_earlyLearningEmbeddingConfig()
%FN_EARLYLEARNINGEMBEDDINGCONFIG AC stimulus/reward learning trajectories.
% Requires earlyLearningProgression and taskActionGeometryEmbedding on the path.
cfg.response=fn_stimRewardAlignmentConfig();
cfg.response.normalization='zscore'; % Shared per-neuron scale across all supplied data.
cfg.nBins=30;
cfg.overlap=1/3;                     % Fraction of a window shared with its neighbor.
cfg.minTrialsPerBin=2;               % Minimum paired finite responses per neuron/window.
cfg.missingAnimal='exclude';         % 'error': stop if an animal cannot supply all points.
[cfg.umap,~]=fn_neuralEmbeddingConfig();
cfg.umap.nNeighbors=15;
cfg.umap.minDist=0.1;
cfg.umap.metric='correlation';
cfg.umap.init='random';             % Reproducible with randomize=false; avoids spectral degeneracy.
cfg.umap.normalization='none';       % Already normalized by cfg.response, never normalize again.

plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';
plotCfg.prefix='earlyLearningEmbedding';
plotCfg.pointSize=30;
plotCfg.connectBins=true;            % Lines within each stimulus x response-period trajectory.
plotCfg.showPCA=true;                % PC1-PC2, PC1-PC3, and PC2-PC3 in a separate figure.
end
