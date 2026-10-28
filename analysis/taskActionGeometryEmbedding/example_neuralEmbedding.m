%% Input: intAct is condition x animal; each cell is neuron x time x trial.
% Keep the same tracked neurons in the same order across all conditions.
% These labels assume Int-only rows S1L, S2R, S3L, S4R; edit to match your data.

%conditions=table(["T1_S1_L";"T1_S2_R";"T2_S3_L";"T2_S4_R"], ...
%    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
%    'VariableNames',{'conditionName','action','task'});

%conditions=table(["Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
%    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
%    'VariableNames',{'conditionName','action','task'});

conditions=table(["T1_S1_L";"T1_S2_R";"T2_S3_L";"T2_S4_R";"Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
    ["L";"R";"L";"R";"L";"R";"L";"R"],["T1";"T1";"T2";"T2";"T1";"T1";"T2";"T2"], ...
    ["E";"E";"E";"E";"Int";"Int";"Int";"Int"], ...
    'VariableNames',{'conditionName','action','task','learning'});

% Add the external MATLAB UMAP package once (adjust to your installation):
% add%path(genpath('C:\Users\zzhu34\Documents\GitHub\umap'));
% javaaddpath('C:\Users\zzhu34\Documents\GitHub\umap\util\suh.jar');

[cfg,plotCfg]=fn_neuralEmbeddingConfig();
cfg.timeWindow=[-1.0 4.0];           % Whole trial, or e.g. [-0.5 1].
cfg.frameRate=15; cfg.eventFrame=31;
cfg.normalization='zscore';    % Already normalized input.
cfg.nNeighbors=150; cfg.minDist=0.1; cfg.metric='correlation';
plotCfg.colorBy=["conditionName","action","task"];
plotCfg.connectTime=false;   % Set true to join time bins within each condition.
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\neuralEmbedding';
[embedding,figures]=fn_analyzeNeuralEmbedding(intAct,conditions,cfg,plotCfg);

% All panels reuse these coordinates; labels never influence the fit.
xy=embedding.embedding;      % (nCondition*nSelectedTime) x 2
pointInfo=embedding.pointInfo;
pointLabels=embedding.pointLabels;
% [figures,files]=fn_plotNeuralEmbedding(embedding,plotCfg); % Replot without fitting.
% save('neuralEmbedding.mat','embedding'); % No graphics or trial arrays inside.
