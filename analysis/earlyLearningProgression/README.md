# Early-learning trial progression

## AC stimulus/reward alignment

Run [example_stimRewardAlignment.m](example_stimRewardAlignment.m) for the AC
analysis. It loads Animal objects, queries rewarded S1/L and S2/R trials in
T1E, T1M, and T1L, loads **`dffStim`**, and applies each animal's common tracked
neuron mask. The original `example_trialProgression.m` uses `dffChoice`;
stimulus alignment is specific to the new stimulus/reward analysis example.
Reload activity after changing alignment; changing a config does not realign
already-loaded `dffChoice` arrays.

```matlab
[cfg,plotCfg]=fn_stimRewardAlignmentConfig();
cfg.animalLabels=string(animals);
cfg.binSize=50;
cfg.phaseOrder=["T1E","T1M","T1L"];
cfg.normalization='zscore'; % Optional; default is 'none'.
cfg.nEarlyTrials=500;
cfg.pooledBinSize=50;
% Optional shared prestimulus baseline: cfg.baselineOffsets=-5:-1;
% plotCfg.visible=false; plotCfg.savePath='B:\analysis\stimRewardAlignment';
[alignment,figures]=fn_analyzeStimRewardAlignment( ...
    tempAct,selectionCfg,cfg,plotCfg,trialInfo);
```

Inputs have the same condition × animal cell layout as progression. Pass the
`trialInfoNeural` tables matching the activity's third dimension exactly.
`responseType==1` selects rewarded trials; incorrect and probe trials are
excluded even if the input selection includes them. Metadata must contain
`dayLabel`, `sourceTrialRow`, `stimulusFrame`, and `responseFrame`. Stimulus IDs
come from `stimuli`/`stimulus` in trial metadata, or the condition's `stimulus`.
Frame column names can be overridden in `cfg`. Neuron rows must have identical
identities across all conditions within an animal, not just matching counts.

For neuron n and trial r, with stimulus-aligned activity X and onset index e=31:

```text
choiceIndex(r) = e + responseFrame(r) - stimulusFrame(r)
S(n,r) = mean(X(n, e + [1 2 3], r))
R(n,r) = mean(X(n, choiceIndex(r) + [3 4], r))
```

Thus stimulus frames are 32–34 by default. The reward-period response is measured
3–4 imaging frames after **choice threshold**, following the requested timing;
it does not use `rewardFrame`. Offsets are in frames, with no RT rounding or
seconds conversion. No extra normalization or baseline subtraction occurs by
default. Set `cfg.normalization='zscore'` to use one mean and sample standard
deviation per neuron/animal, fitted over **all finite time × trial samples in
all supplied conditions and phases**. Samples have equal weight, so conditions
with more trials contribute more. The same mean/scale applies to stimulus and
reward responses; they are not normalized separately. The example enables
z-scoring. Parameters and finite sample counts are in `alignment.normalization`.
Constant/insufficient-data scales are replaced with 1 and flagged `degenerate`.

Setting `baselineOffsets` subtracts the same trial's prestimulus mean from both
responses. With z-scoring this is equivalent to normalizing first, then
subtracting the normalized baseline: `(response - baseline)/sigma`, since the
common offset cancels. No baseline subtraction gives `(response - mu)/sigma`.
Both are computed on reduced responses without copying normalized time series.
Keep these settings consistent when comparing analyses.

Within each animal and stimulus, sort by configured learning phase and then
`sourceTrialRow`. Merge phases before splitting into consecutive 50-rewarded-trial
bins. S1 and S2 have independent sequences, and bins may cross phase boundaries.
The trial-selection preset still controls RT and session filters: these are
selected rewarded trials, not necessarily all trials the animal experienced.

For each bin b, average each neuron's responses across its trials to obtain
vectors S_b and R_b. Each scatter point is `(S_b(n), R_b(n))`. Pearson correlation
is measured **across neurons**, independently for each animal and stimulus:

```text
C(i,j) = dot(S_i - mean(S_i), R_j - mean(R_j)) /
         (norm(S_i - mean(S_i)) * norm(R_j - mean(R_j)))
```

The correlation heatmap has stimulus bin i on the vertical axis and reward bin
j on the horizontal axis. It need not be symmetric. Its diagonal is the
stimulus/reward alignment within each bin, also plotted as a learning curve.
Colors are blue=-1, white=0, red=1; undefined correlations are gray. Scatter
plots use shared limits across bins for a given animal/stimulus and paginate
after `plotCfg.maxScatterPanels` panels. Animals are analyzed separately.

The final partial bin is included by default with its actual count; set
`cfg.includePartialBin=false` to omit it. Invalid/noninteger/out-of-range event
windows yield NaN responses and do not shift trial ordinals or bin boundaries.
A fixed neuron cohort, finite in both responses on all included valid-window
trials, is used throughout each animal/stimulus comparison. Bins with no valid
trials, constant response vectors, or fewer than three usable neurons have
undefined correlations. NaN-padded traces can reduce this cohort; inspect the
mask and counts. Overlapping stimulus/reward frame windows are recorded.

Useful outputs:

- `alignment.reduced.stimulus{c,a}` and `.reward{c,a}`: neuron × rewarded-trial
  matrices in original condition order. `.trials{c,a}` maps columns to inputs.
- `alignment.byStimulus(s,a).stimulusActivity` and `.rewardActivity`: neuron ×
  rewarded-trial matrices after concatenating learning phases. `.trials` retains
  source condition, source trial, source row, phase, and window validity.
- `.bins`: trial ranges, actual counts, valid-window counts, and overlap counts.
- `.neuronRows` / `.neuronMask`: rows used in correlations, relative to input
  tracked-neuron arrays. `.stimulusMean` / `.rewardMean`: usable neuron × bin.
- `.crossBinCorrelation` and `.withinBinCorrelation`: full matrix and diagonal.
- `figures` is separate from data. Replot with
  `[figures,files]=fn_plotStimRewardAlignment(alignment,plotCfg)`.

An increasing diagonal correlation means neurons with stronger stimulus
responses tend to have stronger reward-period responses. It is descriptive
alignment, not proof of reward-specific recruitment or causality. Common
activity, baseline differences, and calcium-response overlap can contribute.
The correlation does not quantify absolute response growth; inspect the scatter
values as well. This analysis uses all eligible tracked neurons and does not
select a stimulus-responsive subset using the same trials.

### Pooled S1 and S2 figures over learning

`plotCfg.showPooledEarlyTrials=true` adds `figures.pooledEarlyTrials_S1` and
`figures.pooledEarlyTrials_S2`, each with up to 10 scatter subplots. Defaults
are `cfg.nEarlyTrials=500` and `cfg.pooledBinSize=50`. Panels use non-overlapping
rewarded-trial ranges 1–50, 51–100, ..., 451–500 **within each stimulus/animal's
phase-concatenated sequence**. These are not interleaved behavioral-trial numbers.
Each stimulus figure stops at its last bin with valid responses, capped at 10
panels. Internal empty bins retain their position; an entirely absent stimulus
gets a labeled empty figure.

Average each neuron's stimulus and reward responses within each bin, then pool
animals separately for S1 and S2. Each point is one neuron, and each panel's
Pearson correlation uses only that figure's stimulus. Animals with more neurons
contribute more points. Every subplot labels the number of **animals remaining**:
animals with at least one finite stimulus/reward neuron pair in that bin.

The figure uses the same normalization and response windows as the other views.
Missing ordinals are never repeated or replaced. Within each neuron/bin, both
response averages use exactly the same trials with finite stimulus/reward pairs.
Partially available bins use their available pairs; empty bins remain NaN.
Actual pair counts are saved in `trialCounts`. Counts of
neurons and contributing animals appear in every panel. Unlike the per-animal plots'
fixed cohort, this display uses available finite pairs within each bin,
so the contributing population can change across panels. Repeated
neuron–stimulus points are not independent samples; no inferential p-value is
computed. The pooled correlation can reflect between-animal offsets
as well as within-group alignment.

`alignment.pooledEarlyTrials` stores:

- `stimulusActivity`, `rewardActivity`: neuron–stimulus pair × bin, storing means.
- `bins`: requested `firstTrial` and `lastTrial` for each subplot.
- `trialCounts`: actual paired finite trials per neuron–stimulus pair × bin.
- `points`: animal index/label, stimulus ID, and neuron row in the input arrays.
- `correlation`, `nPoints`, `nAnimals`, `nStimuli`: one value per plotted bin.
- `byStimulus(s)`: the **separate-stimulus results used by the figures**:
  `stimulus`, `correlation`, `nPoints`, `nAnimals`, `bins`, and `binIndices`.
  `pointRows` indexes that stimulus's neurons in the parent arrays. The parent
  combined-stimulus correlation is retained for compatibility and is not plotted.

Set `plotCfg.showPooledEarlyTrials=false` to suppress this additional figure.
Set `cfg.pooledBinSize=1` for individual-trial panels (still capped at 10).

## Population trial progression

A preliminary visual analysis of how population responses change during early
learning. Inputs match the geometry analyses: **condition × animal cells**, each
holding **neuron × time × trial** activity. Condition labels can come from a
table, a trial-selection config's `conditionDef` struct array, or the full
trial-selection config. A stimulus-only table is still supported;
`conditionName` is optional for table inputs.

For the 12 x animal `tempAct` array from the early-T1 selection preset:

```matlab
selectionCfg=fn_earlyT1TrialSelectionConfig(); % Same preset/order used to build tempAct.
[cfg,plotCfg]=fn_trialProgressionConfig();
cfg.animalLabels=string(animals);             % One label per column.
[progression,figures]=fn_analyzeTrialProgression( ...
    tempAct,selectionCfg,cfg,plotCfg);
% Passing selectionCfg.conditionDef as argument 2 works identically.
```

The preset defines all 12 rows, retaining T1E/T1M, stimulus, action, and probe
metadata. Selection settings are used only as labels here; this analysis does
not reapply RT/trial filters. With `cfg.groupBy='condition'` (default), rows are neither merged nor reordered. Keep
`selectionCfg` separate from the progression `cfg` so the definitions are not
overwritten. Empty entries (including a whole animal column) are skipped per
condition. A wholly empty condition keeps its output row with status
`"no usable neurons"` and displays a placeholder. No missing trials are filled
with zeros. Original animal-column indices and labels remain in `animalAudit`
and each condition's `neurons` table.

## Rewarded, incorrect, and probe comparisons

The example uses `cfg.groupBy='outcome'` to combine stimulus types and concatenate
**T1E -> T1M -> T1L**, keeping **rewarded, incorrect, and probe** separate.
Provide a fifth input containing trial metadata aligned with every activity cell:

```matlab
trialInfo=cell(size(tempAct));
for a=1:size(tempAct,2)
    for c=1:size(tempAct,1)
        trialInfo{c,a}=allTrialsel{a}.neuralSelection(c).trialInfoNeural;
    end
end
[cfg,plotCfg]=fn_trialProgressionConfig();
cfg.groupBy='outcome';
cfg.phaseOrder=["T1E","T1M","T1L"];
cfg.animalLabels=string(animals);
cfg.nProgressionTrials=50;
cfg.startTrials=1:10; cfg.nEndTrials=10;
cfg.comparisonReference='progression'; % Last ten within the first 50, not the whole phase.
plotCfg.heatmapMethod='bin';           % Or 'smooth', 'none'.
plotCfg.heatmapWindow=5;
[progression,figures]=fn_analyzeTrialProgression( ...
    tempAct,selectionCfg,cfg,plotCfg,trialInfo);
```

Use `trialInfoNeural`, not the pre-extraction trials table: its rows correspond
to `neuralRaw(:,:,trial)`, including any extraction exclusions. Grouping uses
actual `responseType`: **1 = rewarded, -1 = incorrect, 2 = probe**, with the phase
from `dayLabel`. Incorrect-choice selections can contain probe-block trials;
those trials join the probe group. Other outcome codes require filtering before
this analysis. No reward labels are inferred from stimulus/action combinations.

Within each animal and outcome, trials sort first by `cfg.phaseOrder`, then by
`sourceTrialRow` within each phase. The source table must itself be chronological.
Overlapping source rows raise an error rather than counting a trial twice.
The activity arrays alone cannot recover interleaving; aligned metadata is
required for this mode. Missing cells remain supported.

Output has three rows: rewarded, incorrect, and probe. Phase transitions do not
restart trial counting or create separate plots. The first-50 limit is applied
**after** concatenation; if T1E contains 50 trials, that view contains only T1E.
Use `cfg.nProgressionTrials=Inf` to retain the full common sequence per outcome
(limited by the smallest trial count among contributing animals, so the cohort
stays fixed). Phase boundaries may occur at different ordinals in different
animals; the pooled trial index does not imply phase alignment across animals.

The example extends the early-T1 query with six T1L definitions. Existing
`tempAct` arrays containing only T1E/T1M cannot supply T1L without preparing those
trials too. Missing phases are skipped for each animal; unexpected observed
phases absent from `phaseOrder` raise an error. Set `phaseOrder=[]` to use the
definition/observed order instead. To restore separate phase plots, use
`cfg.groupBy='phaseOutcome'`.

`progression.trialMap{group,animal}` records the ordered `sourceCondition`,
`sourceTrial`, `sourceTrialRow`, `dayLabel`, and `responseType`; original condition
definitions are retained in `sourceConditions`. This allows every grouped trial
to be traced back to the input. Stimuli are pooled by their actual trial order
and frequency, not averaged with equal weight per stimulus.

The extra `outcomeComparison` figure overlays the three outcome PSTHs over
the combined sequence, averaged over that group's early analyzed trials and the
full population. Legends report
the actual early range and neuron count; sparse groups can have fewer than 50
trials and a different neuron cohort. These differences matter when comparing
the curves. No missing trials are padded or duplicated.

## Ten equal-count bins per animal and stimulus

An additional `stimulusBins` figure shows one heatmap for every stimulus × animal
pair. Each heatmap has time on the x-axis and ten progression bins on the y-axis.
Trials are first concatenated in `cfg.phaseOrder`, with chronological order
within each phase. Each animal's **entire available sequence for that stimulus**
is then divided independently into ten nearly equal-count bins. This view does
not use the first-50 limit or truncate animals to a common trial count.

```matlab
cfg.nStimulusBins=10;          % 0 disables calculation.
plotCfg.showStimulusBins=true;
```

Stimulus comes from `trialInfoNeural.stimuli` (or `stimulus`), falling back to a
single numeric `stimulus` value per input condition. This plot pools action and
outcome within each stimulus; the existing rewarded/incorrect/probe figures are
unchanged. Only supplied, selected trials contribute. Aligned trial metadata is
required; this view is skipped when no fifth input is supplied.

For an animal with N trials of one stimulus, the bin edges are
`floor((0:10)*N/10)`. Every trial is used exactly once, and bin counts differ by
at most one. For example, 103 trials yield bins of 10 or 11 trials. Fewer than
ten trials produce empty bins (gray), without duplicating or interpolating
trials. Bin 1 is the first approximately 10% of an animal's sequence; it need
not contain the same number of trials or learning phase as bin 1 in another
animal.

Each pixel is the mean across the bin's trials and all retained neurons in that
animal. A fixed neuron cohort is used across all ten bins for each stimulus:
neurons with nonfinite activity anywhere in the full sequence within
`cfg.timeWindow` are excluded and audited (or error if `dropNonfiniteNeurons=false`).
No neuron ranking or extra smoothing is applied. Heatmaps share color limits and
honor `cfg.timeWindow`.

`progression.stimulusBins` stores:

- `meanPsth`: time × bin × stimulus × animal population means.
- `conditions`, `animalLabels`, `trialCounts`, `binCounts`: labels and counts.
- `binRanges{stimulus,animal}`: first/last trial ordinal and count for every bin.
- `trialMap{stimulus,animal}`: ordered source rows and original phase labels.
- `neuronRows`, `nNeurons`, `nDroppedNeurons`, `status`: cohort and missing-data audit.

Graphics are returned separately as `figures.stimulusBins`. PNG export and
hidden-figure behavior follow the same plotting settings as the other figures.

For a simple stimulus-only table:

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
and match time alignment across animals. Activity is unnormalized by default;
optional pooled per-neuron normalization is described below. No baseline subtraction
or rectification is applied. Heatmap smoothing/binning
is display-only; scores and comparison means use unsmoothed activity after the
optional normalization.

## Per-neuron normalization across phases and trial types

```matlab
cfg.normalization='zscore'; % 'none' (default), 'zscore', or 'rms'.
```

One offset and scale are fitted per neuron **within each animal**, pooling every
supplied phase, stimulus/action/outcome condition, trial, and time point within
`cfg.timeWindow`. This uses all supplied trials, not just the first
`nProgressionTrials`, and is independent of the narrower `scoreTimeWindow`.
Every finite time × trial sample has equal weight, so conditions with more
trials contribute more samples. Neurons in different animals are not paired.

For the pooled finite samples of neuron n, with count N:

- `zscore`: `offset = mean(x)`, `scale = sqrt(sum((x-offset).^2)/(N-1))`,
  and `normalized = (x-offset)/scale` (MATLAB sample-standard-deviation convention).
- `rms`: `offset = 0`, `scale = sqrt(mean(x.^2))`, and `normalized = x/scale`.
  This preserves the original zero and uses mean squared activity, not total
  squared activity, so scale does not grow merely because more trials were supplied.
- `none`: uses the supplied activity without modification.

The same parameters apply to every condition, phase, trial, and bin for that
neuron. There is no separate normalization within a phase, condition, time point,
or progression bin. Both neuron selection scores and all plots, including the
full-sequence stimulus-bin figure, use these normalized values. The original
input cell array is unchanged.

Nonfinite values are omitted only when fitting the normalization; they remain
nonfinite in the transformed data and follow the existing neuron-exclusion rules.
A zero scale or insufficient finite samples uses scale 1 and is flagged as
`degenerate`; constant neurons become zero under z-scoring. With no finite
samples, offset is zero. These parameters are saved in
`progression.normalization.offset{animal}`, `.scale{animal}`, `.nSamples{animal}`,
and `.degenerate{animal}`, aligned to the original input neuron rows.
`inputTimeBins` records the time columns used for fitting. With normalization
disabled, offsets/scales are identity transforms and sample counts are not fitted.

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
| `groupBy` | `'condition'` preserves input rows; `'outcome'` concatenates phases by outcome; `'phaseOutcome'` keeps phases separate. Both outcome modes use metadata input 5. |
| `phaseOrder` | `["T1E","T1M","T1L"]`; phase ordering for `'outcome'`. `[]` uses definition/observed order. |
| `nProgressionTrials` | 50; early range after grouping, used for neuron scores, heatmaps and progression curves. `Inf` uses the full common sequence. |
| `psthTrials` | `1:3`; individual early trial PSTHs to overlay. Indices beyond the common early range are omitted. |
| `startTrials` | `1:10`; explicit within-condition indices for the start average. |
| `endTrials` | `[]`; choose the last `nEndTrials` in the comparison reference. Set explicit indices, e.g. `26:30`, to override. |
| `nEndTrials` | 10; used only when `endTrials=[]`. |
| `comparisonReference` | Default `'progression'`: last ten of the common first N early trials. `'all'`: last ten available input trials in each animal (can have different absolute indices). |
| `time` | Explicit increasing seconds. Otherwise `(frame-eventFrame)/frameRate` with defaults 31 and 15 Hz. |
| `timeWindow` | `[]` uses the full input; `[start end]` seconds restricts **both analysis and every PSTH/heatmap**. Original event-relative time labels are retained. |
| `scoreTimeWindow` | `[]` scores all retained bins; `[start end]` optionally restricts scoring and the scalar progression curve further, within `timeWindow`. |
| `selectionMethod` | `'variance'` or `'progression'`, defined below. |
| `progressionDirection` | `'positive'` by default; `'negative'` or `'both'`. Used only with progression selection. |
| `selectedFraction` | 0.2; select the top 20% of eligible pooled neurons independently within each condition (rounded up). |
| `nSelectedNeurons` | `[]`; set a positive integer to override the fraction. Capped at the number of eligible neurons. |
| `normalization` | `'none'` by default; `'zscore'` or `'rms'` uses one pooled offset/scale per neuron across all phases, conditions, and trials within `timeWindow`. |

Explicit comparison indices beyond the reference are removed; exact retained
indices are in the audit. An empty comparison raises an error. If start/end sets
overlap (e.g. fewer than twenty trials with the default ten-trial windows), the audit flags it and a warning
is emitted. There is no silent padding or repeated-trial sampling.

To restrict analysis **and visualization** to the same time window:

```matlab
cfg.timeWindow=[0 0.5];
cfg.scoreTimeWindow=[]; % Score the entire retained window.
```

No manual cropping of `tempAct` or `trialInfo` is needed. All returned PSTHs and
heatmap arrays contain only the retained bins; `progression.inputTimeBins` maps
them to the original activity columns. Nonfinite values outside this window do
not exclude neurons. An empty time selection (or a scoring window with no retained
bins) raises an error. `cfg.time`, if supplied, must still describe the full input.

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

Selected-subpopulation summaries use the same trials as selection. These summaries
are exploratory and selection-biased, not a significance test or held-out
demonstration of progression. Variance/trend scores depend on activity scale.

## Figures and output

The main figure (`allNeurons`) uses one row per condition:

1. Individual trial PSTHs (first three by default), averaging neurons at each time.
2. Start versus end PSTHs, averaging configured trials within neuron, then neurons.
3. Time × trial population-mean heatmap across the early range, binned in groups
   of five by default. `heatmapMethod='smooth'` uses a moving average across
   trials with shrinking endpoints; `'none'` shows raw trials. `heatmapWindow`
   sets the bin/window size. Bin labels show exact trial ranges, including a
   shorter final bin. Heatmaps share color limits within each population figure.
4. Population mean in the scoring-time window versus trial ordinal.

By default, `plotCfg.showAnimals=true` also makes these main figures separately
for each animal, along with the outcome-comparison figure when applicable. Set
it to `false` to show only the pooled main figures. The independent stimulus-bin
figure remains controlled by `showStimulusBins`.

The per-animal panels use the **same analyzed trial range, time window,
normalization, and neuron exclusions** as the pooled analysis. Missing conditions/animals are
explicitly labeled. SEM is calculated across that animal's contributing neurons.

For animal column `a`, summaries are saved in
`progression.byCondition(c).byAnimal(a).allPopulation` and `.selectedPopulation`,
with `animalIndex`, `animalLabel`, and `status`. These are aggregate responses,
so saved results can be replotted without loading neural arrays. Older results
without these summaries need the analysis rerun to produce per-animal plots.

Figure handles and exported-file paths use keys such as
`figures.animal1_allNeurons` and
`figures.animal1_outcomeComparison`. The number is the original input animal
column; figure titles show its label. PNG filenames use those same keys after
`plotCfg.prefix`. The original pooled figure keys remain unchanged.

Optional shading is SEM across neuron responses (or neuron-wise trial means for
the start/end panel). It is **not** an animal-level CI or trial-to-trial error bar.
One-neuron groups have undefined SEM and no shading. Selected-neuron summaries
remain in the results for later analysis, but are not plotted.

`progression.byCondition(c)` contains:

- `neurons`: original `animalIndex`, `animalLabel`, `rowInAnimal`, variance/trend
  scores, average slope per trial, selection score, and `selected` flag.
- `selectedNeuronMask`: aligned to rows of that condition's `neurons` table.
- `allPopulation`, `selectedPopulation`: aggregate PSTHs, SEMs, heatmap data,
  and scalar progression curves; `meanPsth`/`meanSEM` summarize all early analyzed
  trials. No original trial arrays are retained.
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
