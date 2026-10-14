TRIAL CURATION - GENERAL TRIAL SELECTION AND SESSION TRACKING

LOADING NEURAL DATA AFTER COPYING AN ANIMAL

  saved = load('D:\localData\zz153_AC_animal.mat','ani');
  ani = saved.ani;
  curated = ani.fn_prepareTrialData(cfg,'MakePlot',true);
  neural = ani.fn_prepareNeuralData(curated, ...
      'DataPath','D:\localData\parsedTrial');

DataPath overrides the neural source for this call without changing ani.ops.
Pass the exact MAT file, or a folder containing the original neural filename.
If no original filename is available, a folder uses animalID_parsedTrial.mat.
Use DataPath=pwd for the current directory; relative paths resolve from pwd.
Folders are not searched recursively. For renamed files, pass the full filename.
The file must contain sessionInfo for the same animal and selected trials.
The resolved path is recorded in neural.neuralSourceFile (empty for table input).
Omitting DataPath retains the saved source; an invalid override raises an error.
The standalone function also accepts the override:
  neural = fn_prepareNeuralData(curated,[], ...
      'DataPath','D:\localData\zz153_AC_parsedTrial.mat');

INDEPENDENT PLOT CONTROLS (function arguments, not cfg)

  curated = ani.fn_prepareTrialData(cfg,'MakePlot',true);
  neural = ani.fn_prepareNeuralData(curated,'ShowPlots',false, ...
      'PlotSavePath','B:\analysis\trialSelection');

MakePlot defaults to false and controls RT and session/neuron tradeoff plots.
ShowPlots independently defaults to false for neural QC. PlotSavePath saves
PNGs, including the tracking curve, without showing them when ShowPlots=false.
The standalone fn_prepareTrialData(trialInfo,sessionInfoBeh,cfg,...) accepts
the same MakePlot option. Legacy cfg.makePlots fields no longer control plots.

CHOOSING HOW MANY RANKED SESSIONS TO KEEP

Session ranking (greedy/lookahead/error) is separate from the final cutoff.
Each preset file exposes cfg.sessionCountMethod and the following settings.
The default remains 'fixed' with cfg.numSessions=Inf for backward compatibility.

Automatic:
  cfg.sessionCountMethod = 'auto';
  cfg.autoSessionRange = [0.30 1.00];
  cfg.autoSessionSmoothWindow = 5;
  curated = ani.fn_prepareTrialData(cfg);

Let N be the eligible ranked sessions and C(k) the number of neurons common to
the first k sessions. Loss(k)=C(k)-C(k+1). Search cutoffs starting at
max(ceil(0.30*N), tracking.minimumPrefixLength, 1) and ending just before N.
Smooth these losses with a centered five-sample moving average, using smaller
windows at the endpoints. Smoothing uses only losses in the allowed range, so
large drops before the search range cannot dominate the result. Choose k with
the largest smoothed loss, then keep max(lowerBound, k-floor(window/2)) sessions.
This moves the cutoff to before the drop region: a window of five moves it
two sessions earlier. The 30% lower bound and achievable minimum still apply.
The decision records peakDropCutoff, cutoffShift and appliedCutoffShift;
dropSessionRank continues to identify the peak transition's added session.
Break smoothing ties with the larger raw loss, then the larger session count.
If the curve is flat, keep all sessions. If no transition can be considered
without breaking the minimum, keep the allowed upper prefix. The minimum quota
overrides a custom range that ends too early. Percentages refer to eligible
sessions after trial/metadata filters, not every session in the animal's file.

Manual per animal/area (replace these example numbers with your own):
  cfg.sessionCountMethod = 'manual';
  cfg.manualSessionCounts = struct('zz153_AC',40,'zz159_PPC',50);
  curated = ani.fn_prepareTrialData(cfg);

Keep this structure in the chosen preset file to reuse experimenter decisions.
Animal supplies its ID automatically. Direct file calls infer the ID from
ID_parsedTrial_trialInfo.mat or cfg.sessionInfoFile; for table-only calls set
cfg.animalID explicitly. Missing/empty entries are errors, not silent fallbacks.
Counts below the achievable minimum are raised to it; counts above availability
are capped. The requested and applied values and adjustment reason are saved.
If there are no eligible sessions, auto/manual return zero selected sessions.
An unattainable stage quota remains reported by tracking.minimumStatus.

Inspect curated.tracking.sessionCountSelection for the applied method, cutoff,
minimum, search bounds and diagnostic curve (raw and smoothed neuron losses).
The selected cutoff is also marked on the existing tracking figure. To change
methods on an existing metadata result without reranking or reloading:
  curated.cfg.sessionCountMethod = 'auto';
  curated = fn_chooseTrackedSessions(curated);
An explicit fn_chooseTrackedSessions(curated,12) switches back to 'fixed' and
replaces the automatic/manual diagnostic; legacy fixed counts can still be
below the minimum (with the existing warning). Auto/manual always preserve it.

LOOKAHEAD SESSION SELECTION

cfg.trackingMethod = 'lookahead';
cfg.minSessionsPerStage = 3;    % Existing minimum quotas still apply.
cfg.lookaheadWeight = 0.75;
cfg.lookaheadSessions = 5;
curated = ani.fn_prepareTrialData(cfg);

For a candidate session s, let A_s be its neurons with ishere==1 and C the
intersection across ALL previously selected sessions. Before any selection,
C contains all neuron IDs. Let R contain all remaining sessions except s.
The score is:
  |C intersect A_s| + 0.75 * mean(top five values of |A_s intersect A_r|, r in R).
The future term is pairwise overlap with the candidate, not a joint intersection
of the five neighbors and not restricted to neurons surviving in C. Average all
available neighbors when fewer than five remain; use zero when none remain.
Every candidate is scored. Ties use lower median-map MSE, then source row/index.

Before quotas are met, candidates come from the next stage in the phase cycle.
After all achievable minimums are met, candidates are ALL remaining sessions,
regardless of stage. Lookahead automatically sets matchRemaining=false; it
does not remove the minimum quotas. Neighbors for the future term always come
from all remaining stages. Trials do not weight this score.

tracking.sessions records selectionScore, lookaheadMeanShared and
lookaheadSessionRec (the neighbor identities at selection time).
nTrackedAfterSelection is the first term. sessions.offsetScore remains the
median-map MSE used to break ties, rather than the new selection score.
See example/example_compareTrackingMethods.m to compare with greedy at equal
session or trial counts. This heuristic is not guaranteed to beat greedy.

CONFIGURATION PRESETS (config folder)

fn_defaultTrialSelectionConfig()   TCA, 16 conditions.
  Early: T1E S1L/S2R, T2E S3L/S4R.
  Middle: T1M S1L/S2R, T2M S3L/S4R.
  Late: T1L S1L/S2R, T2L S3L/S4R.
  Interleaved: Int S1L/S2R/S3L/S4R.
  This is four analysis bins with four types each, using seven actual dayLabels.
  These stimulus/action conditions include all outcomes (including probes).

fn_expertTrialSelectionConfig()    Original 12-condition configuration.
  Late T1/T2, T1 stimuli in T2 blocks, T1 retraining, and interleaved trials.
  Its historical T2probe labels refer to T1 stimuli in T2 blocks; those labels
  do not impose an unrewarded-outcome filter.

fn_earlyT1TrialSelectionConfig()   12 conditions: six each for T1E and T1M.
  S1L rewarded, S1R, S2L, S2R rewarded, S1L probe, S2R probe.

fn_earlyT2TrialSelectionConfig()   24 conditions: twelve each for T2E and T2M.
  All eight S1/S2/S3/S4 x L/R combinations, plus four probe conditions for
  S1L, S2R, S3L and S4R. Both stimulus sets are selected during T2E/T2M,
  regardless of taskLabel; this does not add T1E/T1M sessions.

In the early presets, normal correct-pair conditions require responseType=1;
probe conditions require responseType=2. Incorrect-choice conditions accept
any outcome, including incorrect choices within probe blocks. Thus a selected
trial belongs to only one condition. Misses (action=0) are outside these types.
Absent conditions remain in the output with zero trials. rewardFrame is not
used to detect probes because it can be missing on non-probe trials too.
Missing responseType produces an error for outcome-filtered conditions.

Each preset file contains its editable condition list and RT/tracking overrides.
Shared options live in helper/fn_trialSelectionSettings.m. Add the full package
with addpath(genpath(packageRoot)) so the presets can find these helpers.
For example:
cfg = fn_earlyT2TrialSelectionConfig();
cfg.RTRange = [0.35 0.65];
cfg.trackingMethod = 'greedy';
curated = ani.fn_prepareTrialData(cfg);

ANIMAL OBJECT WORKFLOW

Start with example/example_animalTrialSelection.m for object-based use:
ani = Animal('zz159_PPC');
cfg = fn_defaultTrialSelectionConfig();
curated = ani.fn_prepareTrialData(cfg);
curated = fn_chooseTrackedSessions(curated,12);
neural = ani.fn_prepareNeuralData(curated);

The first method reads ani.trialInfo and ani.sessionInfoBeh. The second uses
ani.ops.sessionInfoName; neural results are returned separately, not stored in
the object. cfg.loadNeural=true also allows a combined selection/extraction call.
trialInfo is the stored trial table. Old saved objects with trialData are
migrated on load; subsequent saves contain only trialInfo. Existing scripts
must use ani.trialInfo instead of ani.trialData.

Storage locations are configured in the animal's _param.m:
  myOps.sessionInfoName   full neural sessionInfo MAT file (existing setting)
  myOps.animalObjectFile  separate MAT file containing the metadata object ani
  myOps.sessionInfoBehFile  MAT file containing sessionInfoBeh
  myOps.trialInfoFile       MAT file containing trialInfo
All animal parameter files specify these paths explicitly. Objects are saved to
B:\animal\ID_animal.mat; the neural and two metadata files are under
B:\animal\parsedTrial. Both the object property and the sidecar variable
are named trialInfo.

Fresh construction builds sessionInfo locally and saves it externally. Animal
has no sessionInfo property. Use ani.fn_loadSessionInfo() for explicit full-table
access and ani=ani.fn_saveSessionInfo(sessionInfo) to persist edits and refresh
matching metadata. The constructor saves the metadata object automatically;
ani.fn_saveObject() saves subsequent object changes. Reload using:
saved=load(ani.ops.animalObjectFile,'ani'); ani=saved.ani;

Construction follows this order:
1. If animalObjectFile exists, load its saved ani metadata. This takes priority
   even when the parsed files are missing or contain different trial tables.
   Return it using current _param.m options; do not rewrite any cache files.
2. Otherwise, require sessionInfoName, sessionInfoBehFile, AND trialInfoFile.
   Load only sessionInfoBeh and trialInfo, then save the new Animal object.
   Check the neural file's existence without opening its activity arrays.
3. If any member of that three-file set is missing, rebuild from raw inputs and
   save the resulting neural file, metadata files, and Animal object.
A combined parsedTrial file by itself no longer supplies a fallback cache.
Invalid existing cache contents produce an error rather than silent rebuilding.
loadNeural=false creates/reuses behavior metadata without creating neural data.
An existing Animal still wins when loadNeural=true. To rebuild a metadata-only
Animal with neural data, remove its object cache first. Explicit parseDay=true
can load neural arrays after the constructor has selected its metadata source.
The obsolete saveParseTrial option has been removed: newly built neural tables
are always saved externally. Remove that option from old constructor calls.
The unfinished selData method has been removed; use fn_prepareTrialData instead.
The unused visualizePSTHcluster method, which referenced a missing property,
has also been removed. Existing day parsing and tracking methods remain available.
One animal/area per object.
Legacy parseTrial/parseDay methods load sessionInfo locally when explicitly run.
dayInfo, chunkedDayInfo, and analysis are transient: available during analysis,
but omitted from saved Animal objects. Save those results separately if needed.
Alignment options retained in the object contain only refStackSelLoc; session
maps and presence flags are in sessionInfoBeh.

For fresh construction, specify manual learning-stage labels in _param.m:
myOps.dayLabel = {'T1E'; 'T1M'; 'T1L'};
Provide one label per sessionInfo row after behavior matching and sorting by
date/sessionName, including any behavior-only or tuning sessions. An empty label
can mark a session you do not want to assign to a stage. Row vectors are accepted.
Alternatively, myOps.dayLabelName can point to a MAT file containing dayLabel.
A bare dayLabel variable in the parameter script is also accepted. Direct labels
take priority over the file. Without manual labels, learning stages are detected
automatically. Manual labels skip stage detection but retain computed task labels,
accuracy, and trial counts; trial parsing does not overwrite the manual labels.
Cached metadata is reused as saved; changing _param.m does not relabel a cache.

FILE/TABLE WORKFLOW

Start with example/example_trialSelection.m. Run its three sections separately.
For command-window use, add the package and subfolders once:
addpath(genpath('C:\Users\zzhu34\Documents\GitHub\analyzeMeso\organizer\trialCuration'));

Folder layout:
  root       fn_prepareTrialData, fn_prepareNeuralData: workflow entry points
  config     default settings and the editable condition-definition template
  tracking   session ranking, prefix selection, and tracked-neuron QC
  helper     trial filters, extraction, normalization, tables, and plots
  example    runnable example_trialSelection script (scripts have no fn_ prefix)
Shared fn_evaluateTrialTracking* functions stay in analysis/trialSelection
because other workflows also use them. Tests stay in trialSelection/tests.

1. SELECT TRIALS / INSPECT TRACKING WITHOUT LOADING NEURAL ACTIVITY

cfg = fn_defaultTrialSelectionConfig();
cfg.trackingMethod = 'greedy';     % or 'error'
cfg.minSessionsPerStage = 3;
cfg.matchRemaining = true;
cfg.numSessions = Inf;
cfg.loadNeural = false;            % NEW DEFAULT
base = 'B:\animal\parsedTrial\zz159_PPC_parsedTrial';
curated = fn_prepareTrialData([base '_trialInfo.mat'], ...
    [base '_sessionInfoBeh.mat'], cfg);

The first file must contain trialInfo; the second must contain sessionInfoBeh.
Already-loaded tables are also accepted. Only these named variables are read.
The code never falls back to opening parsedTrial.mat during metadata selection.
Choose one of the config presets above for learning periods, trial types,
RT filtering, tracking method and session counts.
Its cfg.conditionDef list contains one row per output condition. Edit the stage,
stimulus and action in each row, and add/remove rows to select trial types.
The original 12 conditions are now the expert preset. For your own selection,
set cfg.conditionDef to a struct array with any number of conditions, containing
name, dayLabels, taskLabels, stimulus, and action. The single name label is used
in reports and plots; byCondition converts it with matlab.lang.makeValidName
for field access. Labels must remain unique after conversion. Older saved
definitions with a separate displayName are still supported. For example:
cfg = fn_defaultTrialSelectionConfig();
cfg.conditionDef = cfg.conditionDef(1:2); % Only S1/action1 and S2/action2 in T1.
for k=1:2, cfg.conditionDef(k).dayLabels=["T1E";"T1M"]; end
cfg.RTRange = [0.35 0.65];
cfg.trackingMethod = 'greedy';
cfg.minSessionsPerStage = 3;
curated = ani.fn_prepareTrialData(cfg);

Multiple dayLabels pool periods in one condition; use separate definitions with
unique names when separate outputs are needed. cfg.phaseOrder controls session
ranking order, not which learning periods are included.
The separate fn_buildConditionDefinitions file and cfg.dayLabels groups have
been removed. Set periods directly in cfg.conditionDef(k).dayLabels instead.
Missing/empty cfg.conditionDef uses the default list from the config file.
An empty taskLabels value allows any task; dayLabels lists the stages to include.
Optional responseTypes filters trialInfo.responseType; [] accepts any outcome.
The RT filter and correct/miss options also apply to custom definitions.
Default RT filtering is ON, [0.35 0.65]; set cfg.useRTFilter=false to disable.
RT plots use six columns, ordered T1E/M/L, then T2E/M/L, then T1R (if present),
then Int. Each group starts on a new row; larger groups continue across rows.
This changes only plot placement, not the condition order in returned data.
One animal/area per call: different animals do not share neuron identities.

2. CHOOSE THE SESSION / TRACKED-CELL TRADEOFF

Inspect curated.tracking.curve and its two-panel figure:
  nSessions: size of each ranked prefix
  nTrials: unique selected trials across all conditions in that prefix
  nTrackedNeurons: intersection of ishere==1 across that prefix
  nSessionsByPhase: counts in the order given by tracking.phaseOrder

curated = fn_chooseTrackedSessions(curated,12);

This changes the retained prefix without reloading metadata or recomputing the
ranking. It can be called again with a larger or smaller count, including 0.
Inf keeps every eligible session. Finite counts above availability keep all.
The red line on the tracking curve marks the current cutoff.

curated.selection(k).trials               retained trials for condition k
curated.selectionQC                      before RT / after RT / retained counts
curated.sessionExcludedTrials            condition-level exclusions and reasons
curated.tracking.sessions                ALL eligible sessions in ranked order
curated.tracking.selectedSessions        chosen session rows, including sessionRec
curated.tracking.selectedSessionRec      original recording identifiers
curated.tracking.selectedNeuronIDs       common neuron indices for chosen sessions
curated.tracking.selectedNeuronMask      logical mask in original neuron order
curated.tracking.selectedMinimumMet      whether chosen prefix meets stage quotas
curated.tracking.minimumStatus           requested / available / shortfall by phase

Session scoring and balance:
  reference(p) = median_s(offsetMap_s(p)), equal weight for each eligible session.
  error(s) = mean_p((offsetMap_s(p)-reference(p))^2), finite pixels only.
  'error': choose the lowest error among eligible candidates.
  'greedy': maximize the intersection of ishere==1 with ALL previously selected
            sessions. The first session maximizes its own present cell count.
            Ties use lower error, then metadata row index.
There is no trial-count weighting. The reference is fixed over the full curve.
This greedy ordering is a heuristic, not an optimal search over all subsets.

cfg.phaseOrder controls learning-stage rounds; [] uses first appearance among
eligible selected trials. Labels are dayLabel values. By default choose 3
sessions per stage, skipping unavailable stages, then continue phase rounds.
Set cfg.matchRemaining=false to select from all remaining stages after quotas.
An explicit cfg.phaseOrder can include absent stages to report their shortage.
The quota does NOT set a final stopping point. cfg.numSessions/fn_chooseTrackedSessions
sets that point; a smaller prefix can cut off before quotas are met.

Session eligibility uses the trials actually selected by the condition and RT
filters. Behavior-only sessions, unmatched sessionRec, invalid trial indices,
and (when requireGoodTracking=true) bad goodTracking flags are excluded.
Tracking also excludes missing/invalid offset maps and empty ishere vectors.
Zero ishere flags are valid absent neurons. Present means exactly ishere==1.
Existing excludeNeuralAnalysis is not an additional filter in this pipeline.
Rows are joined by sessionRec, never by table position. Shared date/sessionName/
dayLabel columns are checked for consistency. Behavioral sessions already split
from daily registrations use their saved per-session maps and flags directly.

cfg.selectSessionsByTracking=false disables ranking and map/ishere requirements;
metadata mapping and cfg.requireGoodTracking still apply. Use numSessions=Inf.
An entirely empty eligible selection returns empty tracking and zero counts.

3. LOAD ACTIVITY ONLY WHEN READY

neuralCurated = fn_prepareNeuralData(curated,[base '.mat']);

Loads sessionInfo once and extracts the selected trials. No re-selection or
re-ranking occurs. Keep curated to try different session counts later.
All original neuron rows remain; selectedNeuronIDs is NOT applied automatically.
For example:
X = neuralCurated.byCondition.T1L_S1_L.neuralRaw;
T = neuralCurated.byCondition.T1L_S1_L.trialInfo;
% X(:,:,i) corresponds to row T(i,:).
Xcommon = X(curated.tracking.selectedNeuronIDs,:,:);

trialInfo sourceTrialRow indexes the input trialInfo table.
metadataSessionRow (and tracking.sessions.sessionInfoRow) indexes sessionInfoBeh.
sessionInfoRow in extracted trialInfoNeural indexes the neural sessionInfo table.
These row indices may differ: sessionRec is used again during neural extraction.
Empty neural arrays and invalid neural trial indices are reported separately in
neuralCurated.droppedTrialReport; pre-extraction exclusions stay in
neuralCurated.sessionExcludedTrials. Neural counts and fn_trackedNeuronQC reflect
sessions actually extracted, which can be fewer than the metadata prediction.

Neural outputs retain neuralSelection, byCondition, qc, sessionAudit,
droppedTrialReport, fn_trackedNeuronQC, and optional neural QC figures. Metadata
results leave those neural outputs empty and provide selectionQC instead.
Custom cfg.normalizationFcn behavior is unchanged. Outputs can feed any analysis;
this package handles selection, extraction, normalization, and QC only.

For a single-call load, set cfg.loadNeural=true and cfg.sessionInfoFile to the
large parsedTrial.mat. The old fn_prepareTrialData(trialInfo,sessionInfo,cfg)
in-memory call also works with cfg.loadNeural=true. To reproduce the old
unranked selection, additionally set cfg.selectSessionsByTracking=false.

Tests: analysis/trialSelection/tests/testTrialCuration.m
