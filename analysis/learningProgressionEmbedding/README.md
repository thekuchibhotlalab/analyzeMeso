# Learning progression embedding

General-purpose successor to `earlyLearningEmbedding`, which remains available.
Use stimulus-aligned `intAct` cells, a condition-label table, and matching
`trialInfoNeural` tables to follow selected trial groups through any learning
interval. One point is a **bin mean**, not an individual trial. Neurons from
retained animals concatenate into one feature space for a shared UMAP and PCA.

Start with [example_learningProgressionEmbedding.m](example_learningProgressionEmbedding.m).
It uses already loaded data; it does not load large neural files again.

## Inputs

```matlab
% intAct: condition x animal cells; each cell = neurons x time x trials, dffStim.
% intNames: the actual condition names used when constructing intAct.
conditions=table(string(intNames(:)), ...
    ["S1";"S2";"S3";"S4"],["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','stimulus','action','task'});
[cfg,plotCfg]=fn_learningProgressionEmbeddingConfig();
cfg.animalLabels=string(animals);
[result,figures]=fn_analyzeLearningProgressionEmbedding( ...
    intAct,conditions,cfg,plotCfg,trialInfo);
```

Add one table row for every input row, including separate rows for different
phases or outcomes if that is how you selected the data. Labels can be strings,
categoricals or numeric scalars. Extra categorical columns such as `outcome` are
supported. Condition names must be unique. `task` means whatever you explicitly
label: the example uses **stimulus set** (S1/S2 = T1, S3/S4 = T2), not recorded
task context. Use another column if both distinctions matter.

`trialInfo{condition,animal}` must contain the exact activity trials in the same
order. Required columns: `dayLabel` and unique per-animal `sourceTrialRow`.
Reward extraction also needs `stimulusFrame` and `responseFrame`. The example
retrieves metadata using the same condition names as `intAct`. A size mismatch
is an error; trials are never silently truncated or paired by position across
different conditions. Same neuron identities/order are required across selected
conditions within an animal.

Only supplied trials are available. Choosing `Int` in this analysis cannot
recover Int trials if your original neural selection included only T2E. To compare
phases, select/load all needed phases with a common tracked-neuron mask first.

## Select any interval and trial types

```matlab
% T2 introduction: only T2 stimuli.
cfg.learningPeriods=["T2E","T2M"];
cfg.select=struct('task',"T2");

% Interleaving introduction: both tasks.
cfg.learningPeriods="Int";
cfg.select=struct('task',["T1","T2"]);

% Across learning, select specified stimuli and optional outcome.
cfg.learningPeriods=["T1L","T2E","T2M","T2L","Int"];
cfg.select=struct('stimulus',["S1","S3"]);
cfg.responseTypes=1; % Actual metadata outcome: rewarded only.

% Alternatively/additionally select exact input condition names.
cfg.trialTypes=["T2E_S3_L","T2M_S3_L","Int_S3_L"];
```

Defaults select all supplied condition rows and all canonical phases, with no
extra outcome filter. `cfg.select` filters condition-table labels; multiple fields
are ANDed, and multiple values within one field are ORed. `trialTypes` filters
condition names; `learningPeriods` filters each trial's metadata. All filters are
combined. `responseTypes=[]` honors the supplied outcomes; nonempty values filter
the actual `responseType` metadata (1 rewarded, 2 probe, -1 incorrect).

Chronology follows `cfg.phaseOrder`:

**T1E → T1M → T1L → T2E → T2M → T2L → Int**.

Within a phase, trials sort by `sourceTrialRow`, regardless of input condition
row order or trial-array order. Only selected trials advance the progression
ordinal; excluded outcomes/conditions do not occupy bins. Duplicate physical
trials across selected conditions are rejected. Additional custom phases require
adding their order explicitly to `phaseOrder`.

## Progression groups and bins

Default `groupBy=["stimulus","action","task"]` creates one progression per unique
combination, merging rows with the same labels across phases. You can instead use
`groupBy="stimulus"` to pool choices, `groupBy="task"` to pool stimuli/actions,
or include an `outcome` column to keep outcome progressions separate. Labels that
vary inside a pooled group are displayed as `mixed` rather than falsely assigning
one value. Grouping combines individual trials, so the means reflect their actual
counts rather than giving each source condition equal weight.

For each group/animal, N selected trials are divided into K=`nBins` relative-progress
windows, with overlap o=`overlap`:

```text
width = N / (1 + (K-1)*(1-o))
step = (1-o)*width
first(b) = round((b-1)*step)+1
last(b) = round((b-1)*step+width)
```

Default K=30, o=1/3. Set `overlap=0` for disjoint bins with approximately equal
counts; rounding handles indivisible trial counts. Windows cover the entire
selected sequence and can span phase boundaries. Each window needs at least
`minTrialsPerBin` paired-finite observations for a neuron. Exact ranges, actual
overlap, start/end phase, and counts by phase are saved in `windows`.

Bins match **relative progression within each group/animal**, not equal absolute
trial numbers or common phase boundaries. For example, bin 10 can cover different
sessions or phases across animals. Separate S1 and S3 sequences may start at
different phases. Use a single `learningPeriods` value to restrict the comparison
to one phase. Overlapping windows create dependent points, not new observations.

An empty cell for one phase does not by itself exclude an animal: other selected
phases may supply enough trials in that group. If a required group cannot supply
all bins, the animal is excluded entirely (or errors with `missingAnimal='error'`).
The neuron set remains fixed across every group/period/bin. Check `animalAudit`.
The function cannot create a group absent from all supplied data; adjust the
selection/grouping/bin count or load the missing trials.

## Response periods and normalization

```matlab
cfg.responsePeriods="stimulus";              % Stimulus only.
cfg.responsePeriods="reward";                % Reward-period proxy only.
cfg.responsePeriods=["stimulus","reward"];   % Both in ONE shared fit (default).
cfg.eventFrame=31;
cfg.stimulusOffsets=1:3;
cfg.rewardOffsets=3:4;
```

Stimulus response is `mean(X(:,eventFrame+stimulusOffsets,trial),2)`.
Reward-period response is taken at
`eventFrame + responseFrame - stimulusFrame + rewardOffsets`.
It is aligned after the **choice threshold**, not measured reward delivery.
The stimulus input must be `dffStim`. Frame-field names are configurable.
Response extraction uses a switch over response-period names so another response
layer can be added later; choice is not implemented in this version.

Invalid event windows remain in the selected trial sequence as NaNs, preserving
their progression position. When both periods are used, each neuron uses the same
paired-finite trials for both responses. Neurons missing sufficient finite data in
any bin are dropped across all points. Stimulus-only analysis does not require
choice timing or discard trials based on reward-window availability.

`normalization='none'` is the default. Optional `zscore` estimates a single mean
and sample SD per neuron from selected, paired-finite **reduced responses**, pooled
across groups and chosen response periods, before overlapping windows are formed.
Thus overlap does not count a sample again for normalization. There is no per-group
normalization or second UMAP normalization. This scope differs from the older
earlyEmbedding full-trace z-scoring.

## Embeddings, figures and dependencies

One unsupervised UMAP uses group x period x bin population vectors as observations
and all retained neurons as features. The same coordinates are colored by stimulus,
action, task, response period, and learning bin. Labels never enter the fit.
Change `plotCfg.colorBy` to use other `pointInfo` columns. Trajectories connect
bins only within each group/period; circles identify their first bins.

PCA centers each neuron across these same points, with no extra scaling. Economy
SVD gives unit orthogonal weights and the top three scores. The PCA figure shows
PC1/PC2, PC1/PC3, and PC2/PC3, with explained percentages relative to total variance
of the **bin means**, not single trials. Colors identify groups; marker shapes
identify response periods. UMAP distances/angles are not neural-weight angles.

Add `analysis/learningProgressionEmbedding` and `analysis/taskActionGeometryEmbedding`
to the path. UMAP reuses `fn_analyzeNeuralEmbedding` and its existing Herzenberg
`run_umap` installation; see its README for setup. Default initialization is
`random` with the backend's deterministic mode, avoiding observed spectral
instability. No new external dependencies. `cfg.runUMAP=false` runs preparation
and PCA without needing `run_umap`; PCA uses base MATLAB `svd`.

## Inspect, save, and replot

- `pointInfo`, `groupLabels`: point/group labels and relative progression.
- `populationVectors`: point x pooled neurons; `neurons` maps every feature.
- `trialMap{group,animal}`: ordered `sourceCondition`, `sourceTrial`,
  `sourceTrialRow`, `dayLabel`, and per-period `validWindow` flags.
- `sourceMetadata{condition,animal}`: selected original metadata.
  `trialMap.metadataRow` indexes this table; original activity indices are
  `sourceTrial`, so outcome/phase filtering does not lose identity.
- `windows{group,animal}`: exact ordinal ranges, phase endpoints, and `phaseCounts`
  (columns correspond to `cfg.phaseOrder`).
- `trialCounts`: selected counts per group/animal; for animals skipped early,
  later groups may be unprocessed and remain zero. `selectedTrialCounts` gives
  filtered counts per input condition/animal before binning.
- `validTrialCounts`: per-neuron paired-finite counts in each bin.
- `animalAudit`, `normalization`, `pca`, `embedding`, `backend`, `diagnostics`.

```matlab
% Prepare vectors/mappings without fitting either embedding:
prepared=fn_prepareLearningProgressionEmbedding(intAct,conditions,cfg,trialInfo);

% Save PNGs without showing figures; original time traces are not saved in result.
plotCfg.visible=false;
plotCfg.savePath='B:\analysis\learningProgressionEmbedding';
[figures,files]=fn_plotLearningProgressionEmbedding(result,plotCfg);
save('learningProgressionEmbedding.mat','result'); % Figure handles are separate.
```
