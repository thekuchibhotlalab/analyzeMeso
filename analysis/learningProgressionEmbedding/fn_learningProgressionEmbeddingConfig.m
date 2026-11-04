function [cfg,p]=fn_learningProgressionEmbeddingConfig()
%FN_LEARNINGPROGRESSIONEMBEDDINGCONFIG Selection, reduction, bins and embedding.
cfg.phaseOrder=["T1E","T1M","T1L","T2E","T2M","T2L","Int"];
cfg.learningPeriods=cfg.phaseOrder; % Select any subset; phaseOrder determines chronology.
cfg.trialTypes=strings(0,1);       % []: all conditionName rows; otherwise select names.
cfg.select=struct();              % E.g. struct('task',"T2") or struct('stimulus',["S3","S4"]).
cfg.responseTypes=[];             % []: honor supplied trials; 1: rewarded, 2: probe, -1: incorrect.
cfg.groupBy=["stimulus","action","task"]; % One progression per unique label combination.
cfg.responsePeriods=["stimulus","reward"]; % Either one or both; future response layers go here.
cfg.eventFrame=31;                % Input must be stimulus-aligned dffStim.
cfg.stimulusOffsets=1:3;
cfg.rewardOffsets=3:4;            % After CHOICE THRESHOLD, not measured reward delivery.
cfg.stimulusFrameField='stimulusFrame';
cfg.choiceFrameField='responseFrame';
cfg.nBins=30;                     % Equal-progress windows per group per animal.
cfg.overlap=1/3;                  % 0: disjoint bins; 1/3: overlapping windows.
cfg.minTrialsPerBin=2;
cfg.normalization='none';         % 'zscore': pool selected reduced responses, all groups/events.
cfg.missingAnimal='exclude';      % Exclude if a required GROUP cannot supply all bins.
cfg.animalLabels=strings(0,1);
cfg.runUMAP=true;                 % false: prepare and run PCA only.
[cfg.umap,~]=fn_neuralEmbeddingConfig();
cfg.umap.nNeighbors=15; cfg.umap.minDist=0.1;
cfg.umap.metric='correlation'; cfg.umap.init='random'; cfg.umap.normalization='none';
p.makePlot=true; p.visible=true; p.savePath=''; p.prefix='learningProgressionEmbedding'; % PNG + FIG exports.
p.colorBy=["stimulus","action","task","responsePeriod","learningBin"];
p.connectBins=true; p.pointSize=30; p.showPCA=true;
end
