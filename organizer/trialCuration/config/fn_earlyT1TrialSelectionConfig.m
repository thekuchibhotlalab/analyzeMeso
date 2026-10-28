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
cfg.neuralField = 'dffChoice';

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
