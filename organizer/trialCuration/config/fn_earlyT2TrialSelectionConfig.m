function cfg = fn_earlyT2TrialSelectionConfig()
%FN_EARLYT2TRIALSELECTIONCONFIG Twelve conditions each for T2E and T2M.
% Include S1/S2 and S3/S4 with both choices during early T2 learning.
% No taskLabel restriction: T1-only, T2-only and mixed blocks can contribute.
cfg=fn_trialSelectionSettings();
% Last column: responseType 1=rewarded, 2=probe, []=any (incorrect choices).
cfg.conditionDef = [ ...
    fn_trialCondition("T2E_S1_L",       "T2E", [], 1, 1, 1);
    fn_trialCondition("T2E_S1_R",       "T2E", [], 1, 2, []);
    fn_trialCondition("T2E_S2_L",       "T2E", [], 2, 1, []);
    fn_trialCondition("T2E_S2_R",       "T2E", [], 2, 2, 1);
    fn_trialCondition("T2E_S3_L",       "T2E", [], 3, 1, 1);
    fn_trialCondition("T2E_S3_R",       "T2E", [], 3, 2, []);
    fn_trialCondition("T2E_S4_L",       "T2E", [], 4, 1, []);
    fn_trialCondition("T2E_S4_R",       "T2E", [], 4, 2, 1);
    fn_trialCondition("T2E_S1_L_probe", "T2E", [], 1, 1, 2);
    fn_trialCondition("T2E_S2_R_probe", "T2E", [], 2, 2, 2);
    fn_trialCondition("T2E_S3_L_probe", "T2E", [], 3, 1, 2);
    fn_trialCondition("T2E_S4_R_probe", "T2E", [], 4, 2, 2);
    fn_trialCondition("T2M_S1_L",       "T2M", [], 1, 1, 1);
    fn_trialCondition("T2M_S1_R",       "T2M", [], 1, 2, []);
    fn_trialCondition("T2M_S2_L",       "T2M", [], 2, 1, []);
    fn_trialCondition("T2M_S2_R",       "T2M", [], 2, 2, 1);
    fn_trialCondition("T2M_S3_L",       "T2M", [], 3, 1, 1);
    fn_trialCondition("T2M_S3_R",       "T2M", [], 3, 2, []);
    fn_trialCondition("T2M_S4_L",       "T2M", [], 4, 1, []);
    fn_trialCondition("T2M_S4_R",       "T2M", [], 4, 2, 1);
    fn_trialCondition("T2M_S1_L_probe", "T2M", [], 1, 1, 2);
    fn_trialCondition("T2M_S2_R_probe", "T2M", [], 2, 2, 2);
    fn_trialCondition("T2M_S3_L_probe", "T2M", [], 3, 1, 2);
    fn_trialCondition("T2M_S4_R_probe", "T2M", [], 4, 2, 2)];
cfg.RTRange=[0.35 0.65];
cfg.trackingMethod='greedy';
cfg.minSessionsPerStage=3;
cfg.requireCorrect=false;
cfg.sessionCountMethod='fixed'; % 'auto', 'manual', or 'fixed' with cfg.numSessions.
cfg.autoSessionRange=[0.30 1.00];
cfg.autoSessionSmoothWindow=5;
cfg.manualSessionCounts=struct(); % e.g. cfg.manualSessionCounts.zz153_AC=40;
end
