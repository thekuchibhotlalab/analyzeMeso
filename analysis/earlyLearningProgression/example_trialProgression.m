%% Input: earlyAct is condition x animal, each neuron x time x chronological trial.
% Build earlyAct from EARLY learning, preserving trial order within condition.
% This table has only stimulus labels; conditionName will be generated.
conditions=table([1;2],'VariableNames',{'stimulus'});
[cfg,plotCfg]=fn_trialProgressionConfig();
cfg.nProgressionTrials=30;
cfg.psthTrials=1:3;
cfg.startTrials=1:5;
cfg.endTrials=[]; cfg.nEndTrials=5; % Last five of the reference below.
cfg.comparisonReference='all';     % Or 'progression': last five of first 30.
% cfg.endTrials=26:30;             % Explicit trial indices override last-five rule.
cfg.selectionMethod='variance';   % Or 'progression' for trial-order trend.
cfg.progressionDirection='positive'; % Only affects progression selection.
cfg.selectedFraction=0.2;         % Top 20% per condition; or cfg.nSelectedNeurons=50.
cfg.time=[]; cfg.frameRate=15; cfg.eventFrame=31;
cfg.scoreTimeWindow=[];          % Or e.g. [0 1] for a relevant response window.
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\earlyLearningProgression';
[progression,figures]=fn_analyzeTrialProgression(earlyAct,conditions,cfg,plotCfg);

selectedS1=progression.byCondition(1).neurons;
selectedS1=selectedS1(selectedS1.selected,:); % Original animal + neuron row IDs.
% [figures,files]=fn_plotTrialProgression(progression,plotCfg); % No raw arrays needed.
% save('trialProgression.mat','progression'); % Figure handles stay separate.
