%% Compare phase-balanced session selection using the same trials.
% Run fn_selectNeuralTrials first to create trialTypeInfo.
trials = cat(1,trialTypeInfo{:,1,1}); % All periods, first type, first animal.
opsFile = 'B:\zz172_PPC2\ops.mat';
phases = ["T1E","T1M","T1L"];
minSessionsPerStage = 3; % Scalar, or one minimum for each entry in phases.
matchRemaining = false; % After minimums: false = any phase; true = keep cycling.

trackingError = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',phases,'Method','error','MinSessionsPerStage',minSessionsPerStage, ...
    'MatchRemaining',matchRemaining,'Plot',false);
trackingGreedy = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',phases,'Method','greedy','MinSessionsPerStage',minSessionsPerStage, ...
    'MatchRemaining',matchRemaining,'Plot',false);

figure('Color','w');
tiledlayout(2,1);
nexttile;
plot(trackingError.curve.nSessions,trackingError.curve.nTrackedNeurons,'-o');
hold on;
plot(trackingGreedy.curve.nSessions,trackingGreedy.curve.nTrackedNeurons,'-o');
xlabel('Sessions taken (selection order)');
ylabel('Common tracked neurons'); grid on;
legend('Median map / squared error','Greedy neuron intersection','Location','best');
nexttile;
plot(trackingError.curve.nTrials,trackingError.curve.nTrackedNeurons,'-o');
hold on;
plot(trackingGreedy.curve.nTrials,trackingGreedy.curve.nTrackedNeurons,'-o');
xlabel('Unique selected trials'); ylabel('Common tracked neurons'); grid on;
legend('Median map / squared error','Greedy neuron intersection','Location','best');

%% Inspect session identities and choose a prefix from either result.
tracking = trackingGreedy;
disp(tracking.sessions(:,{'rank','phase','opsSessionIndex','nTrials', ...
    'meanSquaredOffset','nTrackedAfterSelection'}));
% Automatically take the prefix meeting the achievable minimums. Inspect
% minimumMet/minimumStatus for shortfalls; increase k to include more sessions.
k = tracking.minimumPrefixLength;
selectedSessions = tracking.sessions(1:k,:);
chosenTrials = trials(tracking.uniqueTrialMask & tracking.trialSessionRank<=k,:);
if k>0
    neuronIDs = find(tracking.trackedNeurons(:,k));
else
    neuronIDs = []; % A zero minimum selects no sessions in this example.
end
