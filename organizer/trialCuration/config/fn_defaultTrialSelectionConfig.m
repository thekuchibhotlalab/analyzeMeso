function cfg = fn_defaultTrialSelectionConfig()
%FN_DEFAULTTRIALSELECTIONCONFIG TCA: 16 conditions, four per learning bin.
% Order: early, middle, late, interleaved; within each: S1L, S2R, S3L, S4R.
% T1 uses T1E/M/L; T2 uses T2E/M/L. Both use Int at the end.
cfg=fn_trialSelectionSettings();
% Columns: label, dayLabels, taskLabels, stimulus, action.
% Select stimulus/action pairs regardless of reward outcome.
cfg.conditionDef = [ ...
    fn_trialCondition("T1E_S1_L", "T1E", "T1", 1, 1);
    fn_trialCondition("T1E_S2_R", "T1E", "T1", 2, 2);
    fn_trialCondition("T2E_S3_L", "T2E", "T2", 3, 1);
    fn_trialCondition("T2E_S4_R", "T2E", "T2", 4, 2);
    fn_trialCondition("T1M_S1_L", "T1M", "T1", 1, 1);
    fn_trialCondition("T1M_S2_R", "T1M", "T1", 2, 2);
    fn_trialCondition("T2M_S3_L", "T2M", "T2", 3, 1);
    fn_trialCondition("T2M_S4_R", "T2M", "T2", 4, 2);
    fn_trialCondition("T1L_S1_L", "T1L", "T1", 1, 1);
    fn_trialCondition("T1L_S2_R", "T1L", "T1", 2, 2);
    fn_trialCondition("T2L_S3_L", "T2L", "T2", 3, 1);
    fn_trialCondition("T2L_S4_R", "T2L", "T2", 4, 2);
    fn_trialCondition("Int_S1_L", "Int", [], 1, 1);
    fn_trialCondition("Int_S2_R", "Int", [], 2, 2);
    fn_trialCondition("Int_S3_L", "Int", [], 3, 1);
    fn_trialCondition("Int_S4_R", "Int", [], 4, 2)];
cfg.RTRange=[0.35 0.65];
cfg.trackingMethod='lookahead'; % Or 'error' or 'greedy'.
cfg.minSessionsPerStage=3;
cfg.lookaheadWeight = 0.75;
cfg.lookaheadSessions = 5;
% Final prefix size (independent of the session ranking method).
cfg.sessionCountMethod='auto'; % 'auto', 'manual', or 'fixed' with cfg.numSessions.
cfg.autoSessionRange=[0.30 1.00];
cfg.autoSessionSmoothWindow=5;
cfg.manualSessionCounts=struct(); % e.g. cfg.manualSessionCounts.zz153_AC=40;
end
