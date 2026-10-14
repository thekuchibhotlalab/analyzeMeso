%% 1. Create/load a metadata-only Animal object.
packageRoot=fileparts(fileparts(mfilename('fullpath')));
repo=fileparts(fileparts(packageRoot));
addpath(genpath(packageRoot),fullfile(repo,'organizer','object_organzier'), ...
    fullfile(repo,'organizer','ops_param'),fullfile(repo,'organizer','helper'), ...
    fullfile(repo,'analysis'));
ani=Animal('zz159_PPC');
% Priority: saved _animal.mat -> complete neural/metadata file set -> raw data.
% The first two paths reuse metadata without opening neural arrays.
% New object saved as variable ani at myOps.animalObjectFile (B:\animal).

%% 2. Select trials using the object's trialInfo and sessionInfoBeh.
cfg=fn_defaultTrialSelectionConfig();
% Other presets: fn_expertTrialSelectionConfig(),
% fn_earlyT1TrialSelectionConfig(), fn_earlyT2TrialSelectionConfig().
% Edit periods, trial types, RT and tracking in the chosen preset file.
% Or override here, e.g. keep only the first two conditions:
% cfg.conditionDef=cfg.conditionDef(1:2);
% for k=1:2, cfg.conditionDef(k).dayLabels=["T1E";"T1M"]; end
cfg.trackingMethod='greedy';
cfg.minSessionsPerStage=3;
% Optional final cutoff, independent of greedy/lookahead/error ranking:
% cfg.sessionCountMethod='auto';
% cfg.autoSessionRange=[0.30 1.00]; cfg.autoSessionSmoothWindow=5;
% Or use experimenter counts (examples only; enter your own choices):
% cfg.sessionCountMethod='manual';
% cfg.manualSessionCounts=struct('zz153_AC',40,'zz159_PPC',50);
curated=ani.fn_prepareTrialData(cfg);

%% 3. Choose the session count, then load only when ready for neural analysis.
curated=fn_chooseTrackedSessions(curated,12);
neural=ani.fn_prepareNeuralData(curated);
% Returned neural arrays are separate from ani.
X=neural.byCondition.T1L_S1_L.neuralRaw;
trials=neural.byCondition.T1L_S1_L.trialInfo;
commonNeuronIDs=curated.tracking.selectedNeuronIDs;

%% 4. Reload the saved metadata object later (no constructor/raw-data parsing).
saved=load(ani.ops.animalObjectFile,'ani');
ani=saved.ani;
% ani.trialInfo is the stored trial table.
% For explicit access to the full table: sessionInfo=ani.fn_loadSessionInfo();
