function [TCmeanNorm,TCnorm,trials,trialTypeInfoT1,trialTypeInfoT2] = fn_selectTrialTCA_perAni(animalArea)

%% 1. Trial selection: load ONLY the saved trialInfo tables.
animalArea=  'zz170_AC1';
RTwindow = [.335 0.655];

files = fullfile('B:\analysis\animal',string(animalArea)+"_parsedTrial_trialInfo.mat");
animalLabels = strsplit(animalArea,"_");
animalLabels = animalLabels{1};
% Each row defines one trial type. Identical definitions produce identical
% subsets in se2parate cells; edit stimulus/action values to distinguish them.
learningPeriods = ["T1E","T1M","T1L", 'Int'];
types = table(["T1L,reward";"T1R,reward"],[1;2],[1;2], ...
    'VariableNames',{'label','stimulus','action'});
trialTypeInfoT1 = fn_selectNeuralTrials(files, ...
    'AnimalLabels',animalLabels,'RT',RTwindow, ...
    'TrialTypes',types,'LearningPeriods',learningPeriods);

learningPeriods = ["T2E","T2M","T2L", 'Int'];
types = table(["T2L,reward";"T2R,reward"],[3;4],[1;2], ...
    'VariableNames',{'label','stimulus','action'});
trialTypeInfoT2 = fn_selectNeuralTrials(files, ...
    'AnimalLabels',animalLabels,'RT',RTwindow, ...
    'TrialTypes',types,'LearningPeriods',learningPeriods);



%%
trials = cat(1,trialTypeInfoT1{:,1},trialTypeInfoT1{:,2},...
    trialTypeInfoT2{:,1},trialTypeInfoT2{:,2});
phases = ["T1E","T1M","T1L","Int","T2E","T2M","T2L"];
sessionFile = fullfile('B:\analysis\animal', ...
    string(animalArea)+"_parsedTrial_sessionInfoBeh.mat");

opsFile = fullfile('B:\',animalArea,'ops.mat');
tracking = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',["Int","T1E","T1M","T1L","T2E","T2M","T2L"], ...
    'MinSessionsPerStage',5, ...
    'MatchRemaining',false, 'SessionInfoFile',sessionFile,...
    'Method','greedy');
%%
animalArea=  'zz180_AC';
RTwindow = [.15 2.6];

files = fullfile('B:\analysis\animal',string(animalArea)+"_parsedTrial_trialInfo.mat");
animalLabels = strsplit(animalArea,"_");
animalLabels = animalLabels{1};
learningPeriods = ["T1E","T1M"];
types = table(["T1L,reward";"T1R,reward"],[1;2],[1;2], ...
    'VariableNames',{'label','stimulus','action'});
trialTypeInfoT1 = fn_selectNeuralTrials(files, ...
    'AnimalLabels',animalLabels,'RT',RTwindow, ...
    'TrialTypes',types,'LearningPeriods',learningPeriods);

trials = vertcat(trialTypeInfoT1{:});
sessionFile = fullfile('B:\analysis\animal', ...
    string(animalArea)+"_parsedTrial_sessionInfoBeh.mat");

opsFile = fullfile('B:\',animalArea,'ops.mat');
tracking = fn_evaluateTrialTrackingBalanced(trials,opsFile, ...
    'PhaseOrder',["T1E","T1M"], ...
    'MinSessionsPerStage',5, ...
    'MatchRemaining',false, 'SessionInfoFile',sessionFile,...
    'Method','greedy');

% Neural activity comes from sessionInfo, not the sessionInfoBeh metadata file.
sessionInfoFile = fullfile('B:\analysis\animal',string(animalArea)+"_parsedTrial.mat");
nSessionsToUse = size(tracking.sessions,1); % Edit to your chosen session count.
[TC, neuralTrialInfo, neuronInfo] = fn_loadTrackedNeuralActivity( ...
    sessionInfoFile,tracking,trials,learningPeriods,types, ...
    'NumSessions',nSessionsToUse,'ActivityField','dffStim');

pooled = cat(3, TC{:});
pooled = reshape(pooled, size(pooled,1), []);

% One normalization factor per neuron.
scale = sqrt(mean(pooled.^2, 2, 'omitnan'));
scale(scale == 0) = 1;

TC{1,1}  = fn_cell2mat(TC(:,1),3);
TC{1,2}  = fn_cell2mat(TC(:,2),3);
TC(2,:) = [];

nGroups = 10;
% Apply the same factor to that neuron in every condition.
TCnorm = cellfun(@(x) x ./ scale, ...
    TC, 'UniformOutput', false);
TCmeanNorm = {};
for c = 1:numel(TCnorm)
    x = TCnorm{c};
    nPerGroup = floor(size(x,3) / nGroups);
    assert(nPerGroup >= 1, 'Each entry needs at least 10 trials.');

    for g = 1:nGroups
        idx = (g-1)*nPerGroup + (1:nPerGroup);
        TCmeanNorm{c}{g} = nanmean(x(:,:,idx),3);
    end
    TCmeanNorm{c} = fn_cell2mat(TCmeanNorm{c},3);
    %TCleftover{c} = x(:,:,nGroups*nPerGroup+1:end);
end

% Average trials after normalization.
%TCmeanNorm = cellfun(@(x) mean(x, 3, 'omitnan'), ...
%    TCnorm, 'UniformOutput', false);

save(['B:\analysis\TCA2026_RTmatch\' animalArea '_TCA_T1EM.mat'],'animalArea','files','neuronInfo','neuralTrialInfo','learningPeriods',...
'RTwindow','TC','TCmeanNorm','TCnorm','tracking','trials','types')
%%
tic;
types = table(["T1L,reward";"T1R,reward";"T2L,reward";"T2R,reward"],[1;2;3;4],[1;2;1;2], ...
    'VariableNames',{'label','stimulus','action'});

% Neural activity comes from sessionInfo, not the sessionInfoBeh metadata file.
sessionInfoFile = fullfile('B:\analysis\animal',string(animalArea)+"_parsedTrial.mat");
TCA_trialSelection_param; 
nSessionsToUse = trialSel_param.(animalArea); % Edit to your chosen session count.
[TC, neuralTrialInfo, neuronInfo] = fn_loadTrackedNeuralActivity( ...
    sessionInfoFile,tracking,trials,phases,types, ...
    'NumSessions',nSessionsToUse,'ActivityField','dffStim');
toc;

TC(1:3,3:4) = TC(5:7,3:4);
TC(5:7,:) = [];

pooled = cat(3, TC{:});
pooled = reshape(pooled, size(pooled,1), []);

% One normalization factor per neuron.
scale = sqrt(mean(pooled.^2, 2, 'omitnan'));
scale(scale == 0) = 1;

% Apply the same factor to that neuron in every condition.
TCnorm = cellfun(@(x) x ./ scale, ...
    TC, 'UniformOutput', false);

% Average trials after normalization.
TCmeanNorm = cellfun(@(x) mean(x, 3, 'omitnan'), ...
    TCnorm, 'UniformOutput', false);

save(['B:\analysis\TCA2026_RTmatch\' animalArea '_TCA.mat'],'animalArea','files','neuronInfo','neuralTrialInfo','learningPeriods',...
'phases','RTwindow','TC','TCmeanNorm','TCnorm','tracking','trials','trialSel_param','trialTypeInfoT1','trialTypeInfoT2','types')
% a{phase,type} is common neurons x frames x trials.
% a{s,t}(:,:,r) corresponds to neuralTrialInfo{s,t}(r,:).
% neuronInfo.neuronIDs gives the original neuron rows.
% For an arbitrary session subset, pass tracking.sessions(chosenRows,:) as
% the second argument and omit NumSessions. Use NeuronSelection='all' to
% retain all neurons and inspect neuronInfo.commonNeuronMask afterward.
end 