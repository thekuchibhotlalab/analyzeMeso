function cfg = fn_trialSelectionSettings()
%FN_TRIALSELECTIONSETTINGS Shared options; each preset overrides these as needed.
cfg=struct();
cfg.conditionDef=[];
%% Trial filters shared by all conditions.
% RT filtering can be disabled for raw-data curation.
cfg.useRTFilter = true;
cfg.RTRange = [0.35 0.65];   % provisional only
cfg.minTrials = 10;

cfg.requireCorrect = false;
cfg.excludeMiss = false;

cfg.neuralField = 'dffChoice';
cfg.requireGoodTracking = true;

%% Session selection and neural loading.
% Select trials and inspect tracking using only the two metadata files.
cfg.loadNeural = false;
cfg.sessionInfoFile = ''; % Large parsedTrial.mat, opened only if loadNeural=true.
cfg.selectSessionsByTracking = true;
cfg.trackingMethod = 'greedy'; % 'greedy', 'lookahead', or 'error' median-map MSE.
cfg.lookaheadWeight = 0.75;
cfg.lookaheadSessions = 5;
cfg.phaseOrder = [];          % Default: selected dayLabels in order of appearance.
cfg.minSessionsPerStage = 3;
cfg.matchRemaining = true;    % Continue phase rounds after the minimum quotas.
cfg.numSessions = Inf;        % Ranked prefix to retain; Inf retains all eligible.
cfg.sessionCountMethod = 'fixed'; % 'fixed' (numSessions), 'auto', or 'manual'.
cfg.autoSessionRange = [0.30 1.00]; % Fractions of eligible ranked sessions.
cfg.autoSessionSmoothWindow = 5;   % Moving average of neuron losses.
cfg.manualSessionCounts = struct(); % e.g. struct('zz153_AC',40,'zz159_PPC',50).
cfg.animalID = '';                 % Animal supplies its full animal/area ID.

% fn_parseTrialTC uses 30 pre-event frames -> event at MATLAB index 31.
cfg.alignedEventFrame = 31;
switch lower(cfg.neuralField)
    case 'dffchoice'
        cfg.alignedEventName = 'Choice';
    case 'dffstim'
        cfg.alignedEventName = 'Stimulus';
    case 'dffreward'
        cfg.alignedEventName = 'Reward';
    otherwise
        cfg.alignedEventName = 'Event';
end

% Leave empty until Ziyi's normalization is finalized.
cfg.normalizationFcn = [];

% QC only; does NOT filter neurons.
cfg.runTrackedNeuronQC = true;

cfg.verbose = true;
cfg.saveFile = '';
end
