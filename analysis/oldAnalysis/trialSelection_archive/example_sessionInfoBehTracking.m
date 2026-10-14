%% zz159_PPC: select trials, then track using the saved session-level table.
animalArea = 'zz159_PPC';
trialFile = fullfile('B:\analysis\animal', ...
    string(animalArea)+"_parsedTrial_trialInfo.mat");
sessionFile = fullfile('B:\analysis\animal', ...
    string(animalArea)+"_parsedTrial_sessionInfoBeh.mat");
phases = ["T1E","T1M","T1L","Int","T2E","T2M","T2L"];
types = table(["T1L,reward";"T1R,reward";"T2L,reward";"T2R,reward"], ...
    [1;2;3;4],[1;2;1;2],'VariableNames',{'label','stimulus','action'});
trialTypeInfo = fn_selectNeuralTrials(trialFile,'AnimalLabels','zz159', ...
    'RT',[.34 .66],'LearningPeriods',phases,'TrialTypes',types);
trials = cat(1,trialTypeInfo{:}); % One animal; concatenate all selected groups.

% sessionInfoBeh already contains offsetMap/ishere for each behavioral session.
% No ops.mat, tracking sidecar, or large parsedTrial.mat is loaded here.
tracking = fn_evaluateTrialTrackingBalanced(trials,[], ...
    'SessionInfoFile',sessionFile, ...
    'PhaseOrder',phases,'MinSessionsPerStage',3, ...
    'MatchRemaining',false,'Method','greedy');
% Use Method='error' to compare median-map squared-error selection.

disp(tracking.sessions(:,{'rank','sessionInfoRow','date','sessionName', ...
    'sessionRec','phase','nTrials','nTrackedAfterSelection'}));
disp(tracking.excludedSessions(:,{'sessionInfoRow','date','sessionName','reason'}));

%% Choose the prefix meeting the achievable stage minimums.
k = tracking.minimumPrefixLength;
selectedSessions = tracking.sessions(1:k,:);
chosenTrials = trials(tracking.uniqueTrialMask & tracking.trialSessionRank<=k,:);
neuronIDs = find(tracking.trackedNeurons(:,k));
