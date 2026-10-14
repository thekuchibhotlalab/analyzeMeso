%% 1. Query trials and inspect session/cell tracking using metadata only.
% Run sections separately. Add the package and its function subfolders.
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));
animalArea="zz159_PPC";
base=fullfile('B:\animal\parsedTrial',animalArea+"_parsedTrial");
cfg=fn_defaultTrialSelectionConfig();
% Other presets: fn_expertTrialSelectionConfig(),
% fn_earlyT1TrialSelectionConfig(), fn_earlyT2TrialSelectionConfig().
% Optional: select only the two T1 stimulus/action conditions in early learning.
% cfg.conditionDef=cfg.conditionDef(1:2);
% for k=1:2, cfg.conditionDef(k).dayLabels=["T1E";"T1M"]; end
% cfg.RTRange=[0.35 0.65];
cfg.trackingMethod='greedy'; % Or 'error' for median-map squared error.
cfg.minSessionsPerStage=3;
cfg.matchRemaining=true;
% cfg.phaseOrder=["T1L","T2L","T1R","Int"]; % Must cover selected labels.
cfg.numSessions=Inf; % Display the full curve before choosing a prefix.
cfg.loadNeural=false;
curated=fn_prepareTrialData(base+"_trialInfo.mat", ...
    base+"_sessionInfoBeh.mat",cfg);
disp(curated.tracking.curve);

%% 2. Choose a prefix after inspecting the curve; no file reload.
nSessions=12; % Change to your preferred point on the curve.
curated=fn_chooseTrackedSessions(curated,nSessions);
selectedSessions=curated.tracking.selectedSessions;
commonNeuronIDs=curated.tracking.selectedNeuronIDs;
disp(curated.selectionQC);
% Each condition's table: curated.selection(k).trials.
% Exclusions and reasons: curated.sessionExcludedTrials.

%% 3. Only now load the large file and extract those trials.
% Keep the metadata result so a different cutoff can be tried later.
neuralCurated=fn_prepareNeuralData(curated,base+".mat");
% neuralCurated.byCondition.T1L_S1_L.neuralRaw: neurons x time x selected trials.
% neuralCurated.byCondition.T1L_S1_L.trialInfo: corresponding third-dimension rows.
% All neuron rows remain. Apply commonNeuronIDs yourself if desired:
% X=neuralCurated.byCondition.T1L_S1_L.neuralRaw(commonNeuronIDs,:,:);
