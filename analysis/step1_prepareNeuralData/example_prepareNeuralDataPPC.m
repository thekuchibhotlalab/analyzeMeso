clear;
aniPath = 'B:\animal';

animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};
%%
clear;
aniPath = 'B:\animal';

animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};
%% Load animal Data
allAni = {};
for i = 1:length(animals)
    load([aniPath filesep animals{i} '_animal.mat'],'ani');
    allAni{i} = ani;
end

%% find only the first day of t2
cfg = fn_T2E_Int_TrialSelectionConfig();

% Four stimulus/action combinations, accepting all task labels.
cfg.conditionDef = [
    fn_trialCondition("T2E_S1_L","T2E",[],1,1);
    fn_trialCondition("T2E_S2_R","T2E",[],2,2);
    fn_trialCondition("T2E_S3_L","T2E",[],3,1);
    fn_trialCondition("T2E_S4_R","T2E",[],4,2)
];

% A single day may contain fewer sessions than the preset's minimum of four.
cfg.minSessionsPerStage = 1;

allTrialsel = {};
for i = 1:length(animals)
    T = allAni{i}.trialInfo;
    firstDate = min(T.date(strcmpi(string(T.dayLabel),'T2E')));

    trialNumbers = find(T.date == firstDate); % All task/day labels on that date

    trialSel = allAni{i}.fn_prepareTrialData(cfg, ...
        'TrialNumbers',trialNumbers, ...
        'GroupManualTrialsByCondition',true, ...
        'MakePlot',true);
    allTrialsel{i} = allAni{i}.fn_prepareNeuralData(trialSel);
    %allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel,'DataPath', putYourDataPath);
end


%% load data accoridng to cfg
cfg = fn_interleaveTrialSelectionConfig();
allTrialsel = {};
for i = 1:length(animals)
    trialSel = allAni{i}.fn_prepareTrialData(cfg,'MakePlot', true);
    allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel, 'PlotSavePath', 'B:\analysis\trialSelection');
    %allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel,'DataPath', putYourDataPath);
end
%save('B:\analysis\trialSelection\interleavedAnalysis\allTrialsel.mat','allTrialsel','-v7.3')

%% load data accoridng to cfg
cfg = fn_T2E_Int_TrialSelectionConfig();
allTrialsel = {};
for i = 1:length(animals)
    trialSel = allAni{i}.fn_prepareTrialData(cfg,'MakePlot', true);
    allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel, 'PlotSavePath', 'B:\analysis\trialSelection');
    %allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel,'DataPath', putYourDataPath);
end
%save('allTrialsel.mat','allTrialsel')
%%
tempAct = cell(8, numel(allTrialsel));
for i = 1:8                      % Conditions
    for a = 1:numel(allTrialsel)   % Animals
        X = allTrialsel{a}.neuralSelection(i).neuralRaw;

        if ~isempty(X)
            mask = allTrialsel{a}.tracking.selectedNeuronMask;
            tempAct{i,a} = X(mask,:,:);
        end
    end
end

%% Subspace and geometry: fully interleaved (Int) trials only.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','taskActionGeometry'));

% Four rows: T1-left, T1-right, T2-left, T2-right. Columns remain animals.
%intNames = ["Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"];
intNames = ["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R"];
%intNames = ["T2E_S1_L","T2E_S2_R","T2E_S3_L","T2E_S4_R"];


%intNames = ["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R","Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"];
intAct = cell(4,numel(allTrialsel));
for a = 1:numel(allTrialsel)
    names = string({allTrialsel{a}.neuralSelection.name});
    [found,rows] = ismember(intNames,names);
    assert(all(found),'The selection must include all four Int condition definitions.');
    for k = 1:length(rows)
        %trials = allTrialsel{a}.neuralSelection(rows(k)).trialInfoNeural;
        intAct{k,a} = tempAct{rows(k),a};
    end
end
%%
opts = fn_taskActionGeometryConfig();
opts.animalLabels = string(animals);
opts.eventFrame = allTrialsel{1}.cfg.alignedEventFrame;
opts.frameRate = allAni{1}.ops.frameRate;
for a = 1:numel(allAni)
    assert(allAni{a}.ops.frameRate==opts.frameRate && ...
        allTrialsel{a}.cfg.alignedEventFrame==opts.eventFrame, ...
        'Animals must have matching time bins and alignment.');
end
opts.timeWindow = [-0.5 0.2];         % Whole trial; or e.g. [-0.5 1] seconds.
opts.nComponents = 3;
opts.normalization = 'zscore';
opts.splitUnit = 'trial';     % Raw arrays do not contain session identities.
% Unequal trial counts are OK: the functions average/split WITHIN each animal,
% then concatenate neuron responses across animals (a pseudo-population).
linear = fn_analyzeTaskActionSubspaces(intAct,opts);
geometry = fn_analyzeTaskActionManifold(intAct,opts);

pooledMean = linear.conditionMeans; % Concatenated neurons x time x 4 conditions.
neuronMap = linear.data.neurons;    % Animal and row in tempAct for each neuron.
% linear.data.excludedAnimals lists animals without four usable Int conditions.
