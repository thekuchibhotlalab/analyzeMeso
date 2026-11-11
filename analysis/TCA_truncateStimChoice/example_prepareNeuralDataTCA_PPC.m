%%
clear;
aniPath = 'B:\animal';

animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};

%% load AC animal
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
cfg = fn_TCA_TrialSelectionConfig();
allTrialsel = {};
for i = 1:length(animals)
    trialSel = allAni{i}.fn_prepareTrialData(cfg,'MakePlot', true);
    allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel, 'PlotSavePath', 'B:\analysis\trialSelection\TCA');
    %allTrialsel{i}= allAni{i}.fn_prepareNeuralData(trialSel,'DataPath', putYourDataPath);
end
%save('B:\analysis\trialSelection\interleavedAnalysis\allTrialsel.mat','allTrialsel','-v7.3')
%%
tempAct = cell(16, numel(allTrialsel));
for i = 1:16                      % Conditions
    for a = 1:numel(allTrialsel)   % Animals
        X = allTrialsel{a}.neuralSelection(i).neuralRaw;

        if ~isempty(X)
            mask = allTrialsel{a}.tracking.selectedNeuronMask;
            tempAct{i,a} = X(mask,:,:);
        end
    end
end
%% Per-neuron RMS pooled across all trial types, learning phases, times and trials.
for a = 1:size(tempAct,2)
    X = cat(3,tempAct{:,a});
    if isempty(X), continue; end
    neuronRMS = sqrt(mean(X.^2,[2 3],'omitnan'));
    neuronRMS(neuronRMS==0 | ~isfinite(neuronRMS)) = 1;
    for i = 1:size(tempAct,1)
        if ~isempty(tempAct{i,a}), tempAct{i,a} = tempAct{i,a} ./ neuronRMS; end
    end
end
clear X
%%
timeWindow = 21:50;
tempActAvg = cellfun(@(x)(nanmean(x(:,timeWindow,:),3)),tempAct,'UniformOutput',false);
outDffMat = []; nNeuron = []; 
for i = 1:6
    temp = fn_cell2mat(tempActAvg(:,i),3);
    nNeuron = cat(1,nNeuron,size(temp,1));
    outDffMat = cat(1,outDffMat,temp);
end

outDffMat = reshape(outDffMat,size(outDffMat,1),size(outDffMat,2),4,2,2);
%% run TCA
save('B:\analysis\TCA2026_concat\outDffMat_allAni_AC.mat',"outDffMat",'nNeuron','animals');
[M,VEpct,TzProj] = fn_runTCA_nonneg(outDffMat + 1e-6);

save('B:\analysis\TCA2026_concat\TCA-nonneg_allAni_AC.mat','M','TzProj','VEpct');



