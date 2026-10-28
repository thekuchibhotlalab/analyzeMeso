%% Run after your example_prepareNeuralDataTaskStim.m has created intAct.
% intAct rows: Int_S1_L, Int_S2_R, Int_S3_L, Int_S4_R. Columns: animals.
% Input must be dffStim with identical tracked neuron rows within each animal.
addpath(fileparts(mfilename('fullpath')));
conditions=table(["Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
    ["S1";"S2";"S3";"S4"], ...
    ["S1";"S2";"";""], ...
    ["";"";"S3";"S4"], ...
    ["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','stimulus','stimT1','stimT2','task'});

[analysisCfg,plotCfg]=fn_taskStimGeometryConfig();
analysisCfg.period='stimulus';       % Change to 'reward' to use choice-relative responses.
analysisCfg.eventFrame=31;
analysisCfg.stimulusOffsets=1:3;
analysisCfg.rewardOffsets=3:4;
analysisCfg.animalLabels=string(animals);
analysisCfg.normalization='none';   % Or 'zscore' across reduced responses per neuron.
analysisCfg.covariance='withinAnimal'; % Or 'diagonal'.
analysisCfg.nPseudoTrials=[];        % Min trial count per condition; no replacement.
% analysisCfg.nPseudoTrials=500;     % Fixed number, with replacement; not independent extra data.
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\taskStimGeometry';

% Match metadata to intAct. Needed for reward timing; also preserves source IDs.
trialInfo=cell(size(intAct));
for a=1:size(intAct,2)
    names=string({allTrialsel{a}.neuralSelection.name});
    [found,rows]=ismember(conditions.conditionName,names);
    assert(all(found),'Condition names must match the loaded neuralSelection.');
    for c=1:height(conditions)
        trialInfo{c,a}=allTrialsel{a}.neuralSelection(rows(c)).trialInfoNeural;
    end
end
[taskStim,figures]=fn_analyzeTaskStimGeometry(intAct,conditions,analysisCfg,plotCfg,trialInfo);

weights=taskStim.weights;           % All pooled neurons x 3 unit-length axes.
thresholds=taskStim.thresholds;     % One boundary per axis; high scores = positiveClass.
% taskStim.projection.scores{condition}: trial/pseudo-trial x 3.
% taskStim.projection.sourceTrial{condition}: point x included animal, ORIGINAL input trial indices.
% taskStim.projection.sourceRowInReduced{condition}: rows in taskStim.trialMap{condition,animal}.metadata.
% taskStim.projection.animalIndices: input animal columns corresponding to these source columns.
% taskStim.neurons: original animal and neuron row for every weight.
% Save taskStim alone; figures are separate. No original full time traces are stored.
