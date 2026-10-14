function cfg = fn_interleaveTrialSelectionConfig()
%FN_EXPERTTRIALSELECTIONCONFIG Late learning, T2 probes, retraining and interleaving.
% Edit this file to configure a selection, or modify the returned cfg directly.
cfg = fn_trialSelectionSettings();

%% Learning periods and trial types: one output condition per row.
% Columns: label, dayLabels, taskLabels, stimulus, action.
% One label (stored as .name) is used for reports and output identification.
% Spaces/punctuation are allowed; byCondition uses matlab.lang.makeValidName.
% dayLabels=["T1E","T1M"] pools those periods within the condition.
% Use separate rows with unique names to keep periods in separate outputs.
% taskLabels=[] accepts any task (needed for interleaved sessions).
% Keep/delete/add rows here, or subset cfg.conditionDef after calling this file.

%   conditionDef       Name    Period  TaskLabel S A
cfg.conditionDef = [ ...
    fn_trialCondition("T1_S1_L", "Int", "T1",   1, 1);
    fn_trialCondition("T1_S2_R", "Int", "T1",   2, 2);
    fn_trialCondition("T2_S3_L", "Int", "T2",   3, 1);
    fn_trialCondition("T2_S4_R", "Int", "T2",   4, 2);
    fn_trialCondition("Int_S1_L", "Int", "Int",   1, 1);
    fn_trialCondition("Int_S2_R", "Int", "Int",   2, 2);
    fn_trialCondition("Int_S3_L", "Int", "Int",   3, 1);
    fn_trialCondition("Int_S4_R", "Int", "Int",   4, 2)];

% RT filtering can be disabled for raw-data curation.
cfg.minTrials = 10;
cfg.useRTFilter = true;
cfg.RTRange = [0.2 0.65];

% Shared trial/session options; edit these per preset as needed.
cfg.trackingMethod='lookahead'; % Or 'error' or 'greedy'.
cfg.minSessionsPerStage=4;
cfg.matchRemaining = false;    % Continue phase rounds after the minimum quotas.
cfg.lookaheadWeight = 0.75;
cfg.lookaheadSessions = 5;

% Final prefix size (independent of the session ranking method).
cfg.sessionCountMethod='auto'; % 'auto', 'manual', or 'fixed' with cfg.numSessions.
cfg.autoSessionRange=[0.8 1.0]; % percentage of sessions to include in neural tracking 
cfg.autoSessionSmoothWindow=5;
cfg.manualSessionCounts=struct(); % e.g. cfg.manualSessionCounts.zz153_AC=40;
end
