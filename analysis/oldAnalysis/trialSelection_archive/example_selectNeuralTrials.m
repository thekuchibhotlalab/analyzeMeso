%% 1. Trial selection: load ONLY the saved trialInfo tables.
files = ["B:\analysis\animal\zz172_PPC2_parsedTrial_trialInfo.mat"; ...
         "B:\analysis\animal\zz159_PPC_parsedTrial_trialInfo.mat"];
animalLabels = ["zz172";"zz159"];
learningPeriods = ["T1E","T1M","T1L", 'Int'];
% Each row defines one trial type. Identical definitions produce identical
% subsets in se2parate cells; edit stimulus/action values to distinguish them.
types = table(["T1L,reward";"T1R,reward"],[1;2],[1;2], ...
    'VariableNames',{'label','stimulus','action'});
trialTypeInfo = fn_selectNeuralTrials(files, ...
    'AnimalLabels',animalLabels,'RT',[.2 0.32], ...
    'TrialTypes',types,'LearningPeriods',learningPeriods);
% trialTypeInfo is nLearningPeriod x nTrialType x nAnimal (here 4 x 2 x 2).
% Each entry is its own trialInfo table, preserving original saved columns.
trialCounts = cellfun(@height,trialTypeInfo);
disp(trialCounts);
% Example: Int, first trial type, zz172:
trials = trialTypeInfo{4,1,1};

%% 2. Optional, slower: load neural activity only when needed.
[activity, ishere] = fn_loadSelectedNeuralActivity(trialTypeInfo,files, ...
    'ActivityField','dffStim','FrameIndices',1:60);
% Both outputs have exactly the same learning period x trial type x animal layout.
% Activity within each cell is NEURONS x FRAMES x TRIALS.
% 846 or 1031 in dimension 1 is a neuron count, not a trial count.
a = 1; s = 1; t = 1;
trials = trialTypeInfo{s,t,a};
traces = activity{s,t,a};
assert(size(traces,3)==height(trials));
% traces(:,:,k) corresponds to trials(k,:).
% ishere{s,t,a}{k} is the original session's raw ishere value.
% Behavior-only trials retain their table rows and have NaN traces.
% Use 'MissingActivity','error' to stop instead of filling missing signals.

%% 3. Inspect tracking for one animal, across any selected stages/types.
% Concatenate any tables from the SAME animal/file. Repeated original trials
% are counted once, including overlaps between trial types.
trials = cat(1,trialTypeInfo{:,1,1});
tracking = fn_evaluateTrialTracking(trials,'B:\zz172_PPC2\ops.mat');
% offsetScore = meanAbsoluteOffset / log(1 + trialPercent); lowest first.
disp(tracking.sessions(:,{'rank','opsSessionIndex','nTrials','trialPercent', ...
    'meanAbsoluteOffset','scoreDivisor','offsetScore'}));
disp(tracking.curve);
%%
trials = cat(1,trialTypeInfo{:,1,1});
opsFile = 'B:\zz172_PPC2\ops.mat';
phases = ["T1E","T1M","T1L","Int"];

trackingError = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',phases,'Method','error');

trackingGreedy = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',phases,'Method','greedy');

tracking = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',["Int","T1E","T1M","T1L"], ...
    'MinSessionsPerStage',3, ...
    'MatchRemaining',false, ...
    'Method','greedy');

%% 4. Choose a session count after inspecting the tracking curve.
k = min(5,height(tracking.sessions)); % Edit this choice after inspecting.
keep = tracking.uniqueTrialMask & tracking.trialSessionRank<=k;
chosenTrials = trials(keep,:);
neuronIDs = find(tracking.trackedNeurons(:,k)); % Original neuron rows.
% All selected trials from the first k ranked sessions are retained.
