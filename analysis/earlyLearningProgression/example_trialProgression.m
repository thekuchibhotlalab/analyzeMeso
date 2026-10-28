%%
clear;
aniPath = 'B:\animal';

animals = {'zz151_AC1','zz153_AC','zz159_AC',...
           'zz170_AC1','zz170_AC2','zz180_AC'};
%% Load animal Data
allAni = {};
for i = 1:length(animals)
    load([aniPath filesep animals{i} '_animal.mat'],'ani');
    allAni{i} = ani;
end

%% load data accoridng to cfg
selectionCfg = fn_earlyT1TrialSelectionConfig();
selectionCfg.neuralField = 'dffChoice';
selectionCfg.alignedEventName = 'Choice';
% Also query T1L using the same six stimulus/action/outcome definitions as T1E.
lateDefinitions = selectionCfg.conditionDef(1:6);
for k = 1:numel(lateDefinitions)
    lateDefinitions(k).name = replace(lateDefinitions(k).name,"T1E","T1L");
    lateDefinitions(k).dayLabels = "T1L";
end
selectionCfg.conditionDef = [selectionCfg.conditionDef; lateDefinitions];
allTrialsel = {};
for i = 1:length(animals)
    trialSel = allAni{i}.fn_prepareTrialData(selectionCfg,'MakePlot', true);
    allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel, 'PlotSavePath', 'B:\analysis\trialSelection');
    %allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel,'DataPath', putYourDataPath);
end

%%
nConditions = numel(selectionCfg.conditionDef);
tempAct = cell(nConditions, numel(allTrialsel));
trialInfo = cell(size(tempAct)); % Metadata aligned to neuralRaw, including any dropped trials.
for a = 1:numel(allTrialsel)
    assert(isequal(string({allTrialsel{a}.neuralSelection.name}), ...
        string({selectionCfg.conditionDef.name})), ...
        'Activity rows must match selectionCfg.conditionDef in order.');
end
for i = 1:nConditions             % Conditions, in selection-config order
    for a = 1:numel(allTrialsel)   % Animals
        X = allTrialsel{a}.neuralSelection(i).neuralRaw;

        if ~isempty(X)
            mask = allTrialsel{a}.tracking.selectedNeuronMask;
            tempAct{i,a} = X(mask,:,:);
            trialInfo{i,a} = allTrialsel{a}.neuralSelection(i).trialInfoNeural;
        end
    end
end

%% Analyze tempAct: condition x animal; neuron x time x chronological trial.
% Keep the T1E/T1M/T1L, action, and probe definitions for every activity row.
% Empty cells are skipped only for that condition; other animals still contribute.
conditions=selectionCfg.conditionDef;
[cfg,plotCfg]=fn_trialProgressionConfig();
cfg.animalLabels=string(animals);
cfg.groupBy='outcome';            % Three groups: rewarded / incorrect / probe, across phases.
cfg.phaseOrder=["T1E","T1M","T1L"];
cfg.nProgressionTrials=Inf;         % First 50 AFTER merging. Set Inf for the full common sequence.
cfg.nStimulusBins=10;              % Additional plot: all trials split per animal and stimulus.
cfg.psthTrials=1:3;
cfg.startTrials=1:10;
cfg.endTrials=[]; cfg.nEndTrials=10;
cfg.timeWindow = [-0.5 0.5];
cfg.scoreTimeWindow = [0.15 0.35]; % Seconds relative to eventFrame
cfg.comparisonReference='progression'; % Last 10 of first 50 (41:50 when available).
% cfg.comparisonReference='all';   % Instead compare with last 10 of all available trials.
cfg.selectionMethod='variance';   % Or 'progression' for trial-order trend.
cfg.progressionDirection='positive'; % Only affects progression selection.
cfg.selectedFraction=0.2;         % Top 20% per condition; or cfg.nSelectedNeurons=50.
cfg.normalization='rms';        % 'zscore' or 'rms'; one normalization across all phases/types.
cfg.time=[]; cfg.frameRate=15; cfg.eventFrame=31;
plotCfg.heatmapMethod='bin';      % 'smooth' for moving average; 'none' for raw trials.
plotCfg.heatmapWindow=5;          % Five trials per bin (or smoothing window).
plotCfg.showAnimals=true;        % Also show main progression plots separately for each animal.
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\earlyLearningProgression';
[progression,figures]=fn_analyzeTrialProgression(tempAct,conditions,cfg,plotCfg,trialInfo);

selectedRewarded=progression.byCondition(1).neurons;
if ~isempty(selectedRewarded)
    selectedRewarded=selectedRewarded(selectedRewarded.selected,:); % Original animal + neuron row IDs.
end
% [figures,files]=fn_plotTrialProgression(progression,plotCfg); % No raw arrays needed.
% save('trialProgression.mat','progression'); % Figure handles stay separate.
