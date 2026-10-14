function cfg = fn_earlyT1TrialSelectionConfig()
%FN_EARLYT1TRIALSELECTIONCONFIG Six conditions each for T1E and T1M.
cfg=fn_trialSelectionSettings();
% Last column filters responseType: 1=rewarded, 2=probe, []=any outcome.
% Incorrect-choice combinations include trials in probe blocks too.
cfg.conditionDef = [ ...
    fn_trialCondition("T1E_S1_L",       "T1E", [], 1, 1, 1);
    fn_trialCondition("T1E_S1_R",       "T1E", [], 1, 2, []);
    fn_trialCondition("T1E_S2_L",       "T1E", [], 2, 1, []);
    fn_trialCondition("T1E_S2_R",       "T1E", [], 2, 2, 1);
    fn_trialCondition("T1E_S1_L_probe", "T1E", [], 1, 1, 2);
    fn_trialCondition("T1E_S2_R_probe", "T1E", [], 2, 2, 2);
    fn_trialCondition("T1M_S1_L",       "T1M", [], 1, 1, 1);
    fn_trialCondition("T1M_S1_R",       "T1M", [], 1, 2, []);
    fn_trialCondition("T1M_S2_L",       "T1M", [], 2, 1, []);
    fn_trialCondition("T1M_S2_R",       "T1M", [], 2, 2, 1);
    fn_trialCondition("T1M_S1_L_probe", "T1M", [], 1, 1, 2);
    fn_trialCondition("T1M_S2_R_probe", "T1M", [], 2, 2, 2)];
cfg.RTRange=[0.35 0.65];
cfg.trackingMethod='greedy';
cfg.minSessionsPerStage=3;
cfg.requireCorrect=false; % Preserve errors and responseType=2 probes.

cfg.sessionCountMethod='fixed'; % 'auto', 'manual', or 'fixed' with cfg.numSessions.
cfg.autoSessionRange=[0.30 1.00];
cfg.autoSessionSmoothWindow=5;
cfg.manualSessionCounts=struct('zz153_PPC',[]); % Fill in the experimenter's count.
end
