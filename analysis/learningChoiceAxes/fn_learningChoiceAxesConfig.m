function [cfg,plotCfg,selectionCfg]=fn_learningChoiceAxesConfig()
%FN_LEARNINGCHOICEAXESCONFIG Trial-order learning bins; per-animal fixed cells.
cfg.nT2Bins=10;
cfg.windowWidthChunks=2;       % Centers one chunk apart; width 2 -> 50% overlap.
cfg.t2AnchorLabel='T2E'; cfg.intAnchorLabel='Int';
cfg.preTrainingLabel='T1L';
cfg.dayLabels=["T1L","T2E","T2M","T2L","T1R","Int"];
cfg.decoder='lda';            % 'lda' (regularized diagonal LDA) or linear 'svm'.
cfg.choiceOffsets=-3:-1;      % Same 200 ms strictly pre-choice window at 15 Hz.
cfg.frameRate=15;
cfg.folds=5; cfg.repeats=5; cfg.minTrialsPerClass=10;
cfg.ldaRidge=1e-3; cfg.svmBoxConstraint=1;
cfg.seed=1; cfg.verbose=true;
plotCfg.makePlot=true; plotCfg.visible=true; plotCfg.savePath='';
plotCfg.prefix='learningChoiceAxes';
selectionCfg=fn_T2E_Int_TrialSelectionConfig();
selectionCfg.conditionDef=[]; % Prepared from all stimulus x action combinations.
selectionCfg.minSessionsPerStage=1;
selectionCfg.neuralField='dffChoice';
selectionCfg.loadNeural=false; selectionCfg.saveFile='';
end
