%% AC learning trajectories: load the same dffStim data as stimulus/reward alignment.
% Add analyzeMeso subfolders and your MATLAB run_umap installation to the path.
aniPath='B:\animal';
animals={'zz151_AC1','zz153_AC','zz159_AC','zz170_AC1','zz170_AC2','zz180_AC'};
phases=["T1E","T1M","T1L"];
selectionCfg=fn_earlyT1TrialSelectionConfig();
selectionCfg.neuralField='dffStim';
selectionCfg.alignedEventName='Stimulus';
selectionCfg.conditionDef=[];
for phase=phases
    selectionCfg.conditionDef=[selectionCfg.conditionDef; ...
        fn_trialCondition(phase+"_S1_L",phase,[],1,1,1); ...
        fn_trialCondition(phase+"_S2_R",phase,[],2,2,1)];
end
% Keep the preset's RT/session filters, or edit here, e.g.:
% selectionCfg.useRTFilter=false;
activity=cell(numel(selectionCfg.conditionDef),numel(animals));
trialInfo=cell(size(activity));
for a=1:numel(animals)
    loaded=load(fullfile(aniPath,[animals{a} '_animal.mat']),'ani');
    trialSel=loaded.ani.fn_prepareTrialData(selectionCfg,'MakePlot',false);
    neural=loaded.ani.fn_prepareNeuralData(trialSel);
    % For relocated files: add 'DataPath',yourLocalPath above.
    assert(isequal(string({neural.neuralSelection.name}),string({selectionCfg.conditionDef.name})), ...
        'Activity rows must match the condition definitions.');
    for c=1:numel(selectionCfg.conditionDef)
        X=neural.neuralSelection(c).neuralRaw;
        if isempty(X), continue; end
        activity{c,a}=X(neural.tracking.selectedNeuronMask,:,:);
        trialInfo{c,a}=neural.neuralSelection(c).trialInfoNeural;
    end
end

%% Run this section directly if activity, selectionCfg, trialInfo already exist.
[cfg,plotCfg]=fn_earlyLearningEmbeddingConfig();
cfg.response.animalLabels=string(animals);
cfg.response.phaseOrder=phases;
cfg.response.eventFrame=31;
cfg.response.stimulusOffsets=1:3;
cfg.response.rewardOffsets=3:4; % Frames after choice threshold, not after measured rewardFrame.
cfg.response.normalization='zscore';
cfg.response.baselineOffsets=[];
cfg.nBins=0;
cfg.overlap=1/3;
cfg.minTrialsPerBin=2;
cfg.missingAnimal='exclude';
cfg.umap.nNeighbors=150;
cfg.umap.minDist=0.4;
cfg.umap.metric='correlation';
cfg.umap.init='random'; % Fixed RNG by default; stable initialization for small/disconnected graphs.
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\earlyLearningEmbedding';
[learningEmbedding,figures]=fn_analyzeEarlyLearningEmbedding( ...
    activity,selectionCfg,cfg,plotCfg,trialInfo);

% 120 points x all retained neurons: 30 chunks x 2 stimuli x 2 response periods.
populationVectors=learningEmbedding.populationVectors;
pointInfo=learningEmbedding.pointInfo;
animalAudit=learningEmbedding.animalAudit;
% PCA is computed on the same points, with pooled neurons as features.
pcaScores=learningEmbedding.pca.scores; % Point x 3; row labels are in pointInfo.
% figures.pca shows PC1-PC2, PC1-PC3, PC2-PC3; plotCfg.showPCA=false hides it.
% learningEmbedding.windows{stimulusIndex,animalIndex}: exact overlapping trial ranges.
% learningEmbedding.neurons: animal and original input neuron row for every feature.
% [figures,files]=fn_plotEarlyLearningEmbedding(learningEmbedding,plotCfg);
% save('earlyLearningEmbedding.mat','learningEmbedding'); % No figure handles in data.
