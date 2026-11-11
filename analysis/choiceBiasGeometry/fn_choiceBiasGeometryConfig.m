function [cfg,p]=fn_choiceBiasGeometryConfig()
%FN_CHOICEBIASGEOMETRYCONFIG Choice LDA, behavior bins and display defaults.
cfg.choiceFrame=31; cfg.frameRate=15; % dffChoice event alignment.
cfg.itiFrames=1:15; cfg.choiceFrames=3;
cfg.biasedThreshold=.4; cfg.unbiasedThreshold=.2;
cfg.minTrialsPerAction=10; cfg.minBinTrialsPerAction=5;
cfg.folds=5; cfg.ridge=.01; cfg.seed=1;
cfg.biasWindow=40; cfg.biasMagnitude=true;
p.makePlot=true; p.visible=true; p.showTrials=true;
p.savePath=''; p.prefix='choiceBiasGeometry'; p.trialLineWidth=.25;
end
