%% load animal
clear;
aniPath = 'B:\animal';
animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};
allAni = {};
for i = 1:length(animals)
    load([aniPath filesep animals{i} '_animal.mat'],'ani');
    allAni{i} = ani;
end

%% load neural data
cfg = fn_T2E_Int_TrialSelectionConfig();
allTrialsel = {};
for i = 1:length(animals)
    trialSel = allAni{i}.fn_prepareTrialData(cfg,'MakePlot', true);
    allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel, 'PlotSavePath', 'B:\analysis\trialSelection');
end

%% select trials
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

repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','taskActionGeometry'));

intNames = ["Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"];
%intNames = ["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R"];

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

%% Custom code for decoding

% task 1 comparison
tempAni = 1; tempTime = 31:37;
tempAct = cellfun(@(x)(squeeze(nanmean(x(:,tempTime,:),2))'), intAct([2 4],tempAni),'UniformOutput',false);

decoder = fn_runDecoder(tempAct{1},tempAct{2}, 0.8);
disp(max(decoder.cellAcc(:,2)))
%decoder2 = fn_runLDA(tempAct{1},tempAct{2},'xvalidT',0.8,'xvalidF',0.8); 

[~,tempIdx] = (max(decoder.cellAcc(:,2)));
figure; fn_plotMeanErrorbar(1:100,   squeeze(intAct{2,tempAni}(tempIdx,:,:))',matlabColors(1),matlabColors(1)...
,{},{'faceAlpha',0.1,'LineStyle','none'});
hold on;
fn_plotMeanErrorbar(1:100,   squeeze(intAct{4,tempAni}(tempIdx,:,:))',matlabColors(2),matlabColors(2)...
,{},{'faceAlpha',0.1,'LineStyle','none'});
