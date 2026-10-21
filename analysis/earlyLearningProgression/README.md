# Early-learning trial progression

A preliminary visual analysis of how population responses change during early
learning. Inputs match the geometry analyses: **condition × animal cells**, each
holding **neuron × time × trial** activity, and a table describing the condition
rows. A stimulus-only table is supported; `conditionName` is optional.

```matlab
addpath('analysis/earlyLearningProgression');
conditions=table([1;2],'VariableNames',{'stimulus'});
[cfg,plotCfg]=fn_trialProgressionConfig();
cfg.nProgressionTrials=30;
cfg.selectionMethod='variance';
cfg.selectedFraction=0.2;
[progression,figures]=fn_analyzeTrialProgression(earlyAct,conditions,cfg,plotCfg);
```

## Trial order, alignment, and pooling

**Preserve chronological order in the third dimension.** Trial 1 means the first
occurrence of this condition in each animal's provided data, not the first trial
of the experiment or a shared trial across animals. Randomly sampled or shuffled
input cannot support this progression analysis. Filtering earlier trials also
changes what “first” means. The arrays alone cannot recover missing chronology.

Use the same tracked neuron identities/order across conditions within each animal,
and match time alignment across animals. Activity is used as provided, without
normalization, baseline subtraction, rectification, or smoothing. Normalize
upstream consistently if neuron-scale differences should not drive selection.

For each condition, early progression uses `min(nProgressionTrials, available
trial count across contributing animals)`, so the same cohort contributes at
every early ordinal. Animals with empty or fewer than two trials are excluded
for that condition only. Short ranges produce a warning. A neuron with a nonfinite
value anywhere in the early or comparison trials is removed for the condition,
or raises an error with `dropNonfiniteNeurons=false`. Exclusions and exact indices
are recorded in each condition's `animalAudit`.

All retained neurons pool across animals; animals with more neurons contribute
more to the average. Start/end trial means are calculated within each neuron
before pooling, so larger trial counts do not automatically give an animal more
weight. Neurons and population cohorts can differ between conditions.

The function does not infer reward timing from stimulus identity. Supply
reward-aligned input, or a suitable window relative to the existing alignment,
if the question concerns rapid reward-related changes in AC. Observed changes
are not automatically identifiable as reward effects rather than other trial changes.

## Configurable ranges

| Option | Default and meaning |
| --- | --- |
| `nProgressionTrials` | 30; early trial range used for neuron scores, trial heatmaps and progression curves. |
| `psthTrials` | `1:3`; individual early trial PSTHs to overlay. Indices beyond the common early range are omitted. |
| `startTrials` | `1:5`; explicit within-condition indices for the start average. |
| `endTrials` | `[]`; choose the last `nEndTrials` in the comparison reference. Set explicit indices, e.g. `26:30`, to override. |
| `nEndTrials` | 5; used only when `endTrials=[]`. |
| `comparisonReference` | `'all'`: last five available input trials in each animal (can have different absolute indices). `'progression'`: last five of the common first N early trials. |
| `time` | Explicit increasing seconds. Otherwise `(frame-eventFrame)/frameRate` with defaults 31 and 15 Hz. |
| `scoreTimeWindow` | `[]` uses all bins; `[start end]` restricts neuron scoring and the scalar progression curve. PSTHs and heatmaps still show the full input time range. |
| `selectionMethod` | `'variance'` or `'progression'`, defined below. |
| `progressionDirection` | `'positive'` by default; `'negative'` or `'both'`. Used only with progression selection. |
| `selectedFraction` | 0.2; select the top 20% of eligible pooled neurons independently within each condition (rounded up). |
| `nSelectedNeurons` | `[]`; set a positive integer to override the fraction. Capped at the number of eligible neurons. |

Explicit comparison indices beyond the reference are removed; exact retained
indices are in the audit. An empty comparison raises an error. If start/end sets
overlap (e.g. fewer than ten available trials), the audit flags it and a warning
is emitted. There is no silent padding or repeated-trial sampling.

To compare first five vs last five **within the first 30 trials**:

```matlab
cfg.nProgressionTrials=30;
cfg.comparisonReference='progression';
cfg.startTrials=1:5; cfg.endTrials=[]; cfg.nEndTrials=5;
```

For explicit windows, use e.g. `startTrials=1:3`, `endTrials=18:22` and
`comparisonReference='all'` (or ensure those indices fall inside the early range).

## Condition-specific neuron selection: math

For one condition, let $x_{n,t,r}$ be neuron activity over the first $R$ common
trials; $\mathcal T$ is the scoring-time window.

**Variance mode** ranks neurons by

$$V_n=\frac1{|\mathcal T|}\sum_{t\in\mathcal T}
\frac1{R-1}\sum_r(x_{n,t,r}-\bar x_{n,t})^2.$$

Variance is evaluated **across trials at each fixed time**, then averaged over
time. A strong but perfectly repeatable PSTH has zero score. High values may
reflect noise or outliers as well as learning, so variance is not evidence of
ordered progression. This mode does not impose an increasing-trend criterion.

**Progression mode** fits a separate linear slope at each time:

$$\beta_{n,t}=\frac{\sum_r(r-\bar r)x_{n,t,r}}{\sum_r(r-\bar r)^2},\qquad
P_n=\operatorname{Var}(r)\frac1{|\mathcal T|}\sum_t\beta_{n,t}^2.$$

$P_n$ is the time-average variance of the fitted linear trend, in squared activity
units. For `'positive'`, eligibility additionally requires the time-average slope
to be positive; `'negative'` requires negative; `'both'` imposes neither restriction.
A positive average slope does not require a positive slope at every bin.
Rapid saturating/nonmonotonic changes may not be well described by a linear trend;
inspect the trial heatmap instead of relying on this score alone.

Only finite, strictly positive scores are eligible. There is no arbitrary
selection of silent/constant neurons. Ties use input neuron order. Ranking is
across pooled neurons, independently for each condition; it does not enforce
equal numbers per animal or the same subset for stimulus 1 and stimulus 2.
The result retains both scores and the signed average slope regardless of method.

Selection and display use the same trials. These selected-subpopulation plots
are exploratory and selection-biased, not a significance test or held-out
demonstration of progression. Variance/trend scores depend on activity scale.

## Figures and output

Two compact figures (`allNeurons`, `selectedNeurons`) use one row per condition:

1. Individual trial PSTHs (first three by default), averaging neurons at each time.
2. Start versus end PSTHs, averaging configured trials within neuron, then neurons.
3. Time × trial population-mean heatmap across the early range.
4. Population mean in the scoring-time window versus trial ordinal.

Optional shading is SEM across neuron responses (or neuron-wise trial means for
the start/end panel). It is **not** an animal-level CI or trial-to-trial error bar.
One-neuron groups have undefined SEM and no shading. No selected neurons produces
an explicitly empty panel, rather than substituting the full population.

`progression.byCondition(c)` contains:

- `neurons`: original `animalIndex`, `animalLabel`, `rowInAnimal`, variance/trend
  scores, average slope per trial, selection score, and `selected` flag.
- `selectedNeuronMask`: aligned to rows of that condition's `neurons` table.
- `allPopulation`, `selectedPopulation`: aggregate PSTHs, SEMs, heatmap data,
  and scalar progression curves; no original trial arrays are retained.
- `animalAudit`: included/excluded animals, trial counts, dropped neurons, actual
  start/end trial indices, and overlap flags.
- `nProgressionTrials`, `psthTrials`, `status`: actual analyzed ranges and status.

Use the neuron table to map selected IDs back to the original arrays. Because
animals concatenate and exclusions vary by condition, do not apply the pooled
mask directly to one animal's original activity array.

```matlab
S=progression.byCondition(1).neurons;
selectedAnimal1=S.rowInAnimal(S.selected & S.animalIndex==1);
selectedActivity=earlyAct{1,1}(selectedAnimal1,:,:);

plotCfg.visible=false; plotCfg.savePath='B:\analysis\earlyLearningProgression';
[figures,files]=fn_plotTrialProgression(progression,plotCfg);
save('progression.mat','progression'); % Graphics are separate.
```

`makePlot=false` skips plots; `showSEM=false` removes shading. Hidden exported
figures are closed. Replotting uses the saved aggregates without loading raw data.
See `example_trialProgression.m` for a simple editable entry point. Tests use
known constant PSTHs and increasing/decreasing trials to check the mathematics,
condition-specific ranking, pooling, trial ranges, and hidden export:

```matlab
results=runtests('analysis/earlyLearningProgression/tests');
assertSuccess(results);
```
