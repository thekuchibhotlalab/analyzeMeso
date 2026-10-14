function cfg = fn_expertTrialSelectionConfig()
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
cfg.conditionDef = [ ...
    fn_trialCondition("T1_S1_L", "T1L", "T1", 1, 1);
    fn_trialCondition("T1_S2_R", "T1L", "T1", 2, 2);
    fn_trialCondition("T2_S3_L", "T2L", "T2", 3, 1);
    fn_trialCondition("T2_S4_R", "T2L", "T2", 4, 2);
    fn_trialCondition("T2probe_S1_L", "T2L", "T2", 1, 1);
    fn_trialCondition("T2probe_S2_R", "T2L", "T2", 2, 2);
    fn_trialCondition("RetrainT1_S1_L", "T1R", "T1", 1, 1);
    fn_trialCondition("RetrainT1_S2_R", "T1R", "T1", 2, 2);
    fn_trialCondition("IntT1_S1_L", "Int", [],   1, 1);
    fn_trialCondition("IntT1_S2_R", "Int", [],   2, 2);
    fn_trialCondition("IntT2_S3_L", "Int", [],   3, 1);
    fn_trialCondition("IntT2_S4_R", "Int", [],   4, 2)];


% Shared trial/session options; edit these per preset as needed.
cfg.RTRange=[0.2 0.65];
cfg.trackingMethod='lookahead'; % Or 'error' or 'greedy'.
cfg.minSessionsPerStage=3;
cfg.lookaheadWeight = 0.75;
cfg.lookaheadSessions = 5;
% Final prefix size (independent of the session ranking method).
cfg.sessionCountMethod='auto'; % 'auto', 'manual', or 'fixed' with cfg.numSessions.
cfg.autoSessionRange=[0.30 0.8]; % percentage of sessions to include in neural tracking 
cfg.autoSessionSmoothWindow=5;
cfg.manualSessionCounts=struct(); % e.g. cfg.manualSessionCounts.zz153_AC=40;
end
