# analyzeMeso

MATLAB and Python tools for mesoscopic calcium-imaging analysis across sessions,
learning stages, and animals. The workflow covers movie registration, neuron
tracking, fluorescence extraction and deconvolution, behavioral trial selection,
and population analyses such as TCA and task/action geometry.

Maintained by Ziyi Zhu — zzhu34@jh.edu.

## Workflow

```text
TIFF recordings -> ROI-specific HDF5 -> Suite2p motion correction
    -> cross-session Elastix + Suite2p registration
    -> reference-stack alignment and manual neuron tracking
    -> apply transforms to movies -> extract traces -> deconvolve
    -> organize session files -> Animal metadata + external neural file
    -> select trials/sessions -> load selected neural responses -> analysis
```

If you already have an `_animal.mat` file and its `_parsedTrial.mat` neural
file, start with [Animal and trial selection](#animal-and-trial-selection).
Trial selection uses lightweight metadata; it does not load neural activity
unless explicitly requested.

## Repository map

| Folder | Purpose |
| --- | --- |
| [organizer/object_organzier](organizer/object_organzier) | `Animal` class and metadata organization. |
| [organizer/ops_param](organizer/ops_param) | Per-animal/area `_param.m` files defining data locations and recording options. |
| [organizer/trialCuration](organizer/trialCuration) | Condition presets, trial filters, session tracking, and neural extraction. |
| [pythonPackageRockfish/registration](pythonPackageRockfish/registration) | Python registration, extraction, deconvolution, and Slurm launchers. |
| [preprocess/roiTracking](preprocess/roiTracking) | MATLAB registration checks, reference stacks, offset maps, and manual ROI tracking. |
| [preprocess](preprocess) | Additional alignment, image-processing, parsing, and tuning utilities. |
| [behavior](behavior) | Behavioral-data processing. |
| [helper_function](helper_function) | Shared MATLAB utilities. |
| [analysis/step0_createAnimals](analysis/step0_createAnimals) | Session organization and example Animal creation. |
| [analysis/step1_prepareNeuralData](analysis/step1_prepareNeuralData) | Editable example for preparing responses across animals. |
| [analysis/TCA](analysis/TCA) | Tensor component analysis workflows. |
| [analysis/taskActionGeometry](analysis/taskActionGeometry) | Task/action subspaces and population geometry. |
| [analysis/taskSpecific](analysis/taskSpecific), [analysis/trackingEval](analysis/trackingEval) | Additional task-specific and tracking analyses. |
| [analysis/oldAnalysis](analysis/oldAnalysis) | Archived analyses; these are not the current trial-selection entry points. |

## Setup

The current curation and plotting tests have been run with MATLAB R2023b.
Image-processing and statistical analyses use MATLAB toolboxes depending on the
workflow. Raw data and animal-specific paths are external to this repository.

From the repository root in MATLAB:

```matlab
repo = pwd;
addpath(genpath(fullfile(repo,'organizer')));
addpath(genpath(fullfile(repo,'helper_function')));
addpath(genpath(fullfile(repo,'behavior')));
addpath(genpath(fullfile(repo,'preprocess')));
addpath(fullfile(repo,'analysis','taskActionGeometry'));
```

Add other analysis folders as needed. Avoid adding the entire archived analysis
tree when working with the current workflow, because it contains older entry points.

Python scripts use NumPy, SciPy, h5py, tifffile, Suite2p, Numba, Matplotlib, and,
for deconvolution, pandas and `oasis-deconv`. Elastix scripts require a SimpleITK
build exposing `ElastixImageFilter` and `TransformixImageFilter`. There is no single
pinned environment for every pipeline stage in this repository. Existing Slurm
files activate stage-specific environments such as `suite2p` and `oasis`; edit
their environment names, account, partition, paths, and resource requests for
your cluster.

## Animal and trial selection

### Create an Animal or load saved metadata

Start from a parameter file such as
[zz153_AC_param.m](organizer/ops_param/zz153_AC_param.m). Set the raw trace,
behavior, tracking, and output locations before constructing an animal:

```matlab
ani = Animal('zz153_AC');
```

The constructor looks for the saved `_animal.mat` first. Otherwise, if the
external neural file and both metadata sidecars exist, it loads the metadata
sidecars. If that complete file set is unavailable, it rebuilds from the raw
inputs specified in the parameter file.

| Parameter / file | Contents |
| --- | --- |
| `myOps.animalObjectFile`: `<ID>_animal.mat` | Variable `ani`, containing `trialInfo`, `sessionInfoBeh`, options, and compact alignment metadata. |
| `myOps.sessionInfoName`: `<ID>_parsedTrial.mat` | Large `sessionInfo` table containing neural activity and session metadata. |
| `myOps.sessionInfoBehFile`: `<ID>_parsedTrial_sessionInfoBeh.mat` | Lightweight `sessionInfoBeh`, including session identities and tracking metadata. |
| `myOps.trialInfoFile`: `<ID>_parsedTrial_trialInfo.mat` | Lightweight behavioral `trialInfo` table. |

The Animal object does **not** retain the large neural `sessionInfo` table as a
property. To load an object copied to another machine, load the MAT file directly
instead of invoking a constructor with old parameter-file paths:

```matlab
objectFile = 'D:\localData\zz153_AC_animal.mat';
saved = load(objectFile,'ani');
ani = saved.ani;
```

`ani.fn_loadSessionInfo()` explicitly loads the full neural table from its saved
path. For selected neural responses and portable paths, use the methods below.

### Select trials and sessions using metadata

```matlab
cfg = fn_expertTrialSelectionConfig();
cfg.RTRange = [0.35 0.65];
cfg.trackingMethod = 'lookahead';
cfg.minSessionsPerStage = 3;

trialSel = ani.fn_prepareTrialData(cfg,'MakePlot',true);
```

`MakePlot` controls the RT distributions and tracked-neurons-versus-sessions
tradeoff curve. Its default is `false`. It is a function argument, independent
of neural plotting; `cfg.makePlots` is no longer used.

Available presets live in [organizer/trialCuration/config](organizer/trialCuration/config):

| Preset | Selection |
| --- | --- |
| `fn_defaultTrialSelectionConfig` | 16 TCA conditions: two T1 stimulus/action pairs across T1E/M/L and Int, and two T2 pairs across T2E/M/L and Int. |
| `fn_expertTrialSelectionConfig` | Late learning, T1-stimulus probes during T2, T1 retraining, and fully interleaved trials. |
| `fn_earlyT1TrialSelectionConfig` | T1E/M with all S1/S2 × left/right combinations and separate normally rewarded-choice probe conditions. |
| `fn_earlyT2TrialSelectionConfig` | T2E/M with both stimulus sets, both choices, and separate probe conditions. |
| `fn_interleaveTrialSelectionConfig` | Current custom preset with T1, T2, and Int labels; inspect its condition definitions before using it as an Int-only query. |

To specify your own conditions:

```matlab
% Arguments: name, learning labels, task labels, stimulus, action, responseType.
% [] leaves a filter unrestricted; action 1=left, 2=right.
cfg.conditionDef = [ ...
    fn_trialCondition("Int_S1_L","Int",[],1,1,[]);
    fn_trialCondition("Int_S2_R","Int",[],2,2,[])];
```

`responseType=1` selects rewarded trials; `2` selects unrewarded probes.
Learning labels such as `T1E`, `T1M`, `T1L`, `T1R`, and `Int` are matched to
the saved metadata. Selecting a stimulus/action pair alone does not impose
a reward-outcome filter.

### Choose the tracking tradeoff

Session ranking uses the selected trials and session metadata (`offsetMap` and
`ishere`). It supports median-reference squared offset error (`error`), maximum
intersection with previously selected neurons (`greedy`), and the same
intersection plus future pairwise overlap (`lookahead`). Minimum sessions per
learning stage are considered first. Lookahead compares all remaining sessions
after those minimum quotas are covered.

Ranking and choosing the final session count are separate:

```matlab
% Automatic: find a large smoothed tracking drop and stop before it.
cfg.sessionCountMethod = 'auto';
cfg.autoSessionRange = [0.30 1.00];
cfg.autoSessionSmoothWindow = 5;

% Alternatively, use experimenter counts per animal/area.
cfg.sessionCountMethod = 'manual';
cfg.manualSessionCounts.zz153_AC = 20;

trialSel = ani.fn_prepareTrialData(cfg,'MakePlot',true);
```

The automatic/manual count selection respects the achievable stage minimums.
An explicit override is available before loading neural data:

```matlab
trialSel = fn_chooseTrackedSessions(trialSel,20);
```

Inspect `trialSel.tracking.curve`, `selectedSessions`, `selectedSessionRec`,
`selectedNeuronIDs`, and `sessionCountSelection`. `sessionRec` identifies the
original session; it is not necessarily a table row number. Explicit overrides
can go below the stage minimum and are reported accordingly.

### Load selected neural responses, including from a copied dataset

```matlab
neural = ani.fn_prepareNeuralData(trialSel, ...
    'DataPath','D:\localData\parsedTrial', ...
    'ShowPlots',false, ...
    'PlotSavePath','D:\localData\figures');
```

`DataPath` accepts either the exact neural MAT file or its containing folder:

```matlab
neural = ani.fn_prepareNeuralData(trialSel, ...
    'DataPath','D:\localData\zz153_AC_parsedTrial.mat');

% If the neural file is in the current MATLAB directory:
neural = ani.fn_prepareNeuralData(trialSel,'DataPath',pwd);
```

With a folder, the loader uses the basename of the original neural file. If no
original filename is available, it uses `<animalID>_parsedTrial.mat`. Point to
the folder containing that file, not its parent; there is no recursive search.
If the file was renamed, pass the exact file path. Relative paths are resolved
from MATLAB's current directory, not from the saved object's location.

Omitting `DataPath` retains the existing `ani.ops.sessionInfoName` behavior.
An override does not change `ani.ops` or rewrite the object. The loaded file
must correspond to the same animal and session/trial identities; use
`neural.neuralSourceFile` to inspect the actual resolved file. An invalid override
raises an error instead of falling back to the old file.

`ShowPlots` defaults to `false`; `PlotSavePath` defaults to empty. Supplying only
a save folder exports hidden PNGs for trial counts, mean responses, session
amplitudes, and the tracking curve when available. Paths are returned in
`neural.plotFiles`. Trial-selection figures are controlled independently by
`fn_prepareTrialData(...,'MakePlot',true)`.

The default neural field is `dffChoice`; set `cfg.neuralField` before selecting
trials to request another parsed field. The field name is an alignment label;
the actual signal also depends on how the Animal was created (for example,
its `actType` and spike-normalization settings).

Each `neural.neuralSelection(k)` contains `neuralRaw` (neuron × time × trial),
`trialInfoNeural`, and the condition name. The loader retains all neuron rows;
apply the tracking mask explicitly when you need neurons shared by all selected
sessions:

```matlab
activity = cell(numel(neural.neuralSelection),1);
for k = 1:numel(activity)
    X = neural.neuralSelection(k).neuralRaw;
    if ~isempty(X)
        activity{k} = X(neural.tracking.selectedNeuronMask,:,:);
    end
end
```

Keep empty conditions empty. Do not index an empty response with a nonempty
logical mask. `neural.byCondition` provides named condition access.

Standalone functions are also available:

```matlab
trialSel = fn_prepareTrialData(trialInfo,sessionInfoBeh,cfg,'MakePlot',true);
neural = fn_prepareNeuralData(trialSel,[], ...
    'DataPath','D:\localData\zz153_AC_parsedTrial.mat');
```

See the [curation reference](organizer/trialCuration/README.txt) and
[multi-animal example](analysis/step1_prepareNeuralData/example_prepareNeuralData.m)
for more detail. Adapt the example's animal list, condition names, and paths to
your query.

## Registration, tracking, and extraction

The Python pipeline lives in [pythonPackageRockfish/registration](pythonPackageRockfish/registration).
Its stages exchange files with MATLAB tools in
[preprocess/roiTracking/main](preprocess/roiTracking/main). Folder numbers include
two different `step3` branches: reference-stack alignment and movie-transform
application.

| Stage | Entry points | Inputs and outputs |
| --- | --- | --- |
| Convert TIFF ROIs | [step0_convertH5/fn_parseROI.py](pythonPackageRockfish/registration/step0_convertH5/fn_parseROI.py) | Edit ROI order/heights for the acquisition. Converts TIFF recordings into ROI-specific HDF5 folders; run from the intended data directory. |
| Motion correction within sessions | [step1_suite2p/run-suite2p.py](pythonPackageRockfish/registration/step1_suite2p/run-suite2p.py) | Reads HDF5 files under `<base>/imagingSession/*`; runs Suite2p with ROI detection disabled. |
| Prepare cross-session images | [step1_createOps.m](preprocess/roiTracking/main/step1_createOps.m) | Writes `ops.mat`, enhanced session mean images under `elastix/rawElastix`, and `elastix/refImg.mat`. |
| Register session means | [simple_elastix.py](pythonPackageRockfish/registration/step2_elastix+suite2p/simple_elastix.py), then [suite2p_elastix.py](pythonPackageRockfish/registration/step2_elastix+suite2p/suite2p_elastix.py) | Run from the dataset's `elastix` directory. Produces Elastix parameters/aligned images, followed by Suite2p cross-session transforms. Alternative registration scripts live alongside these. |
| Check registration | [step2_checkElastixSuite2pAlign.m](preprocess/roiTracking/main/step2_checkElastixSuite2pAlign.m) | Reads the aligned results, writes `alignedOps.mat` and each session's `crossSessionSuite2p.mat`. |
| Align the reference stack | [refStack_elastix.py](pythonPackageRockfish/registration/step3_alignRefStack/refStack_elastix.py) | Reads `elastix/refImg.mat` and `roiTracking/refStack/refStack.mat`; writes aligned reference stacks and coordinate maps. Run from the animal/area directory. |
| Build tracking metadata and ROIs | [MATLAB tracking tools](preprocess/roiTracking/main) | Use offset registration/checking, reference-image reconstruction, `step5_manualTracking`, and `step6_adaptROI` to produce session-specific ROIs and `stackROI_final_tracked.mat`. |
| Apply transforms to movies | [step3_elastix+suite2p application](pythonPackageRockfish/registration/step3_elastix%2Bsuite2p%20application) | `elastix_apply.py` applies transforms to `data.bin`, producing `data_elastix.bin`; `suite2p_transformation_apply.py` then produces `data_suite2p.bin`. Edit dataset-specific run wrappers or use batch launchers. |
| Extract tracked-neuron traces | [step4_extractTC/extract_TC.py](pythonPackageRockfish/registration/step4_extractTC/extract_TC.py) | Uses registered movies and `stackROI_final_tracked.mat`; writes per-session `data_F.mat` with `allTraces`. |
| Deconvolve | [step4_extractTC/deconv/deconvolve_TC.py](pythonPackageRockfish/registration/step4_extractTC/deconv/deconvolve_TC.py) | Reads `data_F.mat`; writes `data_dff.mat`, `data_C.mat`, `data_S.mat`, and `data_spkOps.mat`. Fixed-decay variants and statistics tools are in the same folder. |
| Organize for MATLAB | [step5_organizeData/fn_step0_organizeData.py](pythonPackageRockfish/registration/step5_organizeData/fn_step0_organizeData.py) | Builds `<ID>_TC.mat`, `<ID>_sessionInfo.mat`, and, when spike inputs exist, `<ID>_spk.mat`. These are upstream of Animal's parsed-trial files. |

Command examples for stages with command-line arguments, from the repository
root on the cluster (run each only after its upstream inputs are prepared):

```bash
python pythonPackageRockfish/registration/step1_suite2p/run-suite2p.py --base-dir /data/zz153_AC
python pythonPackageRockfish/registration/step4_extractTC/extract_TC.py --base-dir /data/zz153_AC
python pythonPackageRockfish/registration/step4_extractTC/deconv/deconvolve_TC.py --base-dir /data/zz153_AC
python pythonPackageRockfish/registration/step5_organizeData/fn_step0_organizeData.py /data/zz153_AC
```

The organizer defaults to `data_F.mat` / `allTraces` for its trace input. To
organize deconvolved fluorescence instead, specify `--trace-file data_dff.mat
--trace-var dff`. Check that this choice matches the signal intended for the
Animal constructor. The organizer also supports changing the spike filename
and variable with `--spk-file` and `--spk-var`.

Slurm launchers are stored beside their stages; array-capable scripts support
session buckets via `--task-id` and `--n-tasks`. Some run wrappers contain animal
IDs or assume the current directory is the dataset root. Review these settings
before submitting jobs. Registration variants and manual ROI decisions are
dataset-specific; the directory sequence is not an unattended end-to-end runner.

## Downstream population analyses

[TCA](analysis/TCA) and [task/action geometry](analysis/taskActionGeometry) consume
curated responses. The geometry functions also accept a simple `4 × nAnimal`
cell array: rows are T1-left, T1-right, T2-left, T2-right; each entry is
neuron × time × trial. Keep neuron identities/order consistent across the four
conditions within each animal and use matching time alignment across animals.

```matlab
opts = fn_taskActionGeometryConfig();
linear = fn_analyzeTaskActionSubspaces(intAct,opts);
geometry = fn_analyzeTaskActionManifold(intAct,opts);
```

Use only the intended learning period when building `intAct` (for example,
fully interleaved `Int`). Animals may have different trial and neuron counts;
the analysis combines condition means along the neuron dimension rather than
pairing unrelated trials across animals. See the
[geometry reference](analysis/taskActionGeometry/README.txt) for definitions,
normalization, cross-validation, and output fields.

## Tests

From the repository root with the relevant MATLAB folders on the path:

```matlab
results = runtests('organizer/trialCuration');
assertSuccess(results);
results = runtests('organizer/object_organzier/tests');
assertSuccess(results);
results = runtests('analysis/taskActionGeometry/tests');
assertSuccess(results);
```

These tests use small fixtures to check mapping, selection, plotting, neural
loading, and analysis behavior. Registration and full dataset processing also
require inspecting the corresponding images, tracking results, and signal QC.
