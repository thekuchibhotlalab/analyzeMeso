function [cfg,plotCfg]=fn_taskActionDecodingConfig()
%FN_TASKACTIONDECODINGCONFIG Accuracy-only analysis; input must be dffChoice.
cfg.animalLabels=strings(0,1);
cfg.taskLabels=["T1","T2"];
cfg.actionLabels=["L","R"];
cfg.balanceTaskActions=true;    % Equal L/R counts within each task for task decoding.
cfg.choiceFrames=28:30;
cfg.taskWindows={16:20,28:30,31:37,16:37};
cfg.taskWindowNames=["preTrial","choice","postChoice","fullWindow"];
cfg.trainFraction=.8;           % Stratified 5-fold CV; uses every trial/class.
cfg.repeats=5;
cfg.innerFolds=3;               % Training-only ranking of individual neurons.
cfg.topFractions=.05:.05:1;
cfg.removeTopFractions=0:.05:.95; % All neurons, then remove best 5%, 10%, ... 95%.
% Set removeTopFractions=[] to restore the original topFractions curve.
cfg.svmBoxConstraint=1;         % Fixed regularization; not tuned on test data.
cfg.ldaRidge=1e-6;
cfg.seed=1;
cfg.shuffle=false;              % Optional label-shuffle control; adds runtime.
cfg.verbose=true;
plotCfg.makePlot=true;
plotCfg.visible=true;
plotCfg.savePath='';            % Save PNG + editable FIG files when nonempty.
plotCfg.prefix='taskActionDecoding';
plotCfg.histogramEdges=0:.05:1;
plotCfg.populationXAxis='percent'; % 'count' for actual number of neurons.
end
