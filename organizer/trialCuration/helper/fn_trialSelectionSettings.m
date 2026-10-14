function cfg = fn_trialSelectionSettings()
%FN_TRIALSELECTIONSETTINGS Shared options; each preset overrides these as needed.
cfg=struct();
cfg.conditionDef=[];
%% Trial filters shared by all conditions.
cfg.requireCorrect = false;
cfg.excludeMiss = false;

cfg.neuralField = 'dffChoice';
cfg.requireGoodTracking = true;

%% Session selection and neural loading.
% Select trials and inspect tracking using only the two metadata files.
cfg.loadNeural = false;
cfg.sessionInfoFile = ''; % Large parsedTrial.mat, opened only if loadNeural=true.
cfg.selectSessionsByTracking = true;
cfg.phaseOrder = [];          % Default: selected dayLabels in order of appearance.
cfg.numSessions = Inf;        % Ranked prefix to retain; Inf retains all eligible.
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
