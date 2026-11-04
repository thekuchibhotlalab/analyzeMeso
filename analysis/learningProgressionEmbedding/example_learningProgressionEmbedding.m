%% Use already loaded intAct, intNames, allTrialsel, and animals.
% Default example: four rows ordered S1, S2, S3, S4; columns are animals.
% Keep ALL animal columns. Missing phase cells are allowed; missing required
% progression groups/insufficient bins cause automatic exclusion of that animal.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','learningProgressionEmbedding'));
addpath(fullfile(repo,'analysis','taskActionGeometryEmbedding'));
assert(numel(intNames)==4&&size(intAct,1)==4,'Edit the conditions table to match every intAct row.');
conditions=table(string(intNames(:)),["S1";"S2";"S3";"S4"], ...
    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','stimulus','action','task'});
% For more condition rows (e.g. separate phases), add one matching label row
% for each activity row. Repeated stimulus/action/task labels merge into a
% single progression, ordered using trialInfo.dayLabel and sourceTrialRow.
trialInfo=cell(size(intAct));
for a=1:size(intAct,2)
    names=string({allTrialsel{a}.neuralSelection.name});
    [found,rows]=ismember(conditions.conditionName,names);
    assert(all(found),'Condition names must match the activity selection.');
    for c=1:height(conditions)
        trialInfo{c,a}=allTrialsel{a}.neuralSelection(rows(c)).trialInfoNeural;
    end
end

%% Select the learning interval and trial types to follow.
[cfg,plotCfg]=fn_learningProgressionEmbeddingConfig();
cfg.animalLabels=string(animals);
cfg.learningPeriods=["T1L","T2E"]; % Or "Int", or any subset of phaseOrder.
%cfg.select=struct('task',"T2");           % Only T2 stimulus-set labels from the table.
cfg.select=struct('task',["T1","T2"]);  % Follow both tasks.
% cfg.select=struct('stimulus',["S1","S3"]); % Any table label can filter conditions.
cfg.trialTypes=[];                       % Or explicit conditions.conditionName entries.
cfg.responseTypes=[];                    % Optional actual outcome filter: 1 rewarded, 2 probe.
cfg.groupBy=["stimulus","action","task"];
cfg.responsePeriods=["stimulus","reward"]; % Or "stimulus" / "reward" alone.
cfg.eventFrame=31; cfg.stimulusOffsets=1:3; cfg.rewardOffsets=3:4;
cfg.nBins=30; cfg.overlap=1/3; cfg.minTrialsPerBin=2;
cfg.normalization='none';                % Or zscore across selected reduced responses.
cfg.umap.nNeighbors=15; cfg.umap.minDist=0.1; cfg.umap.metric='correlation';
% cfg.runUMAP=false;                     % PCA only (no run_umap dependency).
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\learningProgressionEmbedding';
[learningEmbedding,figures]=fn_analyzeLearningProgressionEmbedding( ...
    intAct,conditions,cfg,plotCfg,trialInfo);
disp(learningEmbedding.animalAudit);
% windows{group,animal} gives exact trial bins and phase counts.
% trialMap{group,animal} gives sourceCondition/sourceTrial and sourceTrialRow.
% pointInfo labels each pooled group/period/bin point; neurons maps features.
% [figures,files]=fn_plotLearningProgressionEmbedding(learningEmbedding,plotCfg);
% save('learningProgressionEmbedding.mat','learningEmbedding'); % Figures stay separate.
