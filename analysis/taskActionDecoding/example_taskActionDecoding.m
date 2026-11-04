%% Start with intAct and intNames from your existing custom_code_LDA loader.
% intAct: condition x animal, each cell = neuron x time x real trials.
% Load cfg.neuralField='dffChoice'; frame 31 is choice threshold at 15 Hz.
% This file does not reload or overwrite your activity/configuration scripts.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','taskActionDecoding'));
addpath(fullfile(fileparts(repo),'ziyiFunction','analysis'));
assert(size(intAct,1)==4 && numel(intNames)==4,'Edit the table to match each input row.');
conditions=table(string(intNames(:)),["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','action','task'});
[decodeCfg,plotCfg]=fn_taskActionDecodingConfig();
decodeCfg.balanceTaskActions=true; % Equal S1/S2 within T1 and S3/S4 within T2.
decodeCfg.animalLabels=string(animals);
decodeCfg.choiceFrames=28:30; % Average within each trial BEFORE decoding.
decodeCfg.taskWindows={16:20,28:30,31:37,16:37};
decodeCfg.removeTopFractions=0:.05:.95; % All neurons, remove best 5%, 10%, ...
decodeCfg.repeats=5;         % 5 repetitions x 5 outer folds.
% decodePlots.populationXAxis='count'; % Actual # neurons instead of percent.
% decodePlots.visible=false; decodePlots.savePath='B:\analysis\taskActionDecoding';

plotCfg.savePath = 'B:\analysis\T2E\decoding';
plotCfg.visible = false; % Save without displaying; true to also display
plotCfg.prefix = 'decoding'; % Optional filename prefix

[decoding,decoderFigures]=fn_analyzeTaskActionDecoding(intAct,conditions,decodeCfg,plotCfg);

save([plotCfg.savePath filesep 'decoding.mat'],'decoding');

%% Outputs (no graphics handles or original activity arrays in decoding).
decoding.neurons       % Single-cell accuracies, LDA weights, all-neuron SVM weights.
decoding.choicePairs   % Same-neuron choice accuracy in T1 versus T2.
decoding.population    % SVM accuracy, removedFraction, nRemoved, nNeurons remaining.
% d=decoding.fits{1,1}.decoder; % Choice in T1, animal 1.
% d.cellAcc(:,2)              % Each neuron's held-out balanced LDA accuracy.
% d.popAcc(2)                % All-neuron SVM held-out balanced accuracy.
% d.cv.foldAssignments       % Original class trial -> outer fold per repetition.
% decoding.audit             % Missing/insufficient comparisons are skipped independently.
