%% Input: intAct is condition x animal; each entry is neuron x time x trials.
% Rows of this table MUST match rows of intAct. Labels are supplied explicitly;
% the analysis never guesses task/action from condition names.

%conditions=table(["Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
%    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
%    'VariableNames',{'conditionName','action','task'});

conditions=table(["T1_S1_L";"T1_S2_R";"T2_S3_L";"T2_S4_R"], ...
    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','action','task'});

[cfg,plotCfg]=fn_neuralGeometryConfig();
cfg.method='lda';              % 'meanSquared' or 'regression' to compare.
cfg.nAxes=3;                   % Independently fit up to 3 axes per variable.
cfg.timeWindow = [-1.0 0.2];         % Whole trial; or e.g. [-0.5 1] seconds.
cfg.normalization='zscore';      % Input has already been normalized.
cfg.frameRate=15; cfg.eventFrame=31;
% cfg.animalLabels=string(animals);
plotCfg.trialTypes=conditions.conditionName;

%plotCfg.savePath = 'B:\analysis\T2_firstDayComparison\neuralGeometry';
%plotCfg.visible = false; % Save without displaying; true to also display
%plotCfg.prefix = 'firstDayT2'; % Optional filename prefix

plotCfg.trajectory='both';     % 3D plus three 2D projections of the same axes.
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\neuralGeometry';
[geometry,figures]=fn_analyzeNeuralGeometry(intAct,conditions,cfg,plotCfg);

weights=geometry.weights;      % ALL pooled neurons x ALL fitted axes.
axisLabels=geometry.axisInfo;  % Which variable and rank each weight column fits.
neuronMap=geometry.neurons;    % Animal and original input row for every neuron.
% geometry.factors(1).weights contains only axes for the first variable.
% geometry.projection.conditionMean is axis x time x condition.
% Save geometry alone: figures and original trial arrays are separate.

%save([plotCfg.savePath filesep 'geometry.mat'],'geometry');
%% More conditions/variables: use tempAct and a matching table instead.
% Example for rows T1_S1_L,T1_S2_R,T2_S3_L,T2_S4_R,Int_S1_L,...,Int_S4_R:
% conditions=table(["T1_S1_L";"T1_S2_R";"T2_S3_L";"T2_S4_R"; ...
%     "Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
%     repmat(["L";"R"],4,1),repmat(["T1";"T1";"T2";"T2"],2,1), ...
%     [repmat("blocked",4,1);repmat("Int",4,1)], ...
%     'VariableNames',{'conditionName','action','task','period'});
% plotCfg.trialTypes=conditions.conditionName;
% [geometry,figures]=fn_analyzeNeuralGeometry(tempAct,conditions,cfg,plotCfg);
