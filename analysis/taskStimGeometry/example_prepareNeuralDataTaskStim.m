%%
clear;
aniPath = 'B:\animal';

animals={'zz151_AC1','zz153_AC','zz159_AC','zz170_AC1','zz170_AC2','zz180_AC'};
%% Load animal Data
allAni = {};
for i = 1:length(animals)
    load([aniPath filesep animals{i} '_animal.mat'],'ani');
    allAni{i} = ani;
end

%% load data accoridng to cfg
cfg = fn_T2E_Int_TrialSelectionConfig();
cfg.neuralField = 'dffStim';
allTrialsel = {};
for i = 1:length(animals)
    trialSel = allAni{i}.fn_prepareTrialData(cfg,'MakePlot', true);
    allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel, 'PlotSavePath', 'B:\analysis\trialSelection');
end
%save('B:\analysis\trialSelection\interleavedAnalysis\allTrialsel.mat','allTrialsel','-v7.3')

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


%% Select the four conditions for task/stimulus geometry.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','taskActionGeometry'));

% Four rows: T1-left, T1-right, T2-left, T2-right. Columns remain animals.
%intNames = ["Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"];
intNames = ["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R"];


%intNames = ["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R","Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"];
intAct = cell(numel(intNames),numel(allTrialsel));
trialInfo = cell(size(intAct));
for a = 1:numel(allTrialsel)
    names = string({allTrialsel{a}.neuralSelection.name});
    [found,rows] = ismember(intNames,names);
    assert(all(found),'The loaded selection must include every condition in intNames.');
    for k = 1:length(rows)
        intAct{k,a} = tempAct{rows(k),a};
        trialInfo{k,a} = allTrialsel{a}.neuralSelection(rows(k)).trialInfoNeural;
    end
end
