# Task/stimulus geometry in AC

Run your existing `example_prepareNeuralDataTaskStim.m` to load `intAct`, then
run [example_taskStimGeometry.m](example_taskStimGeometry.m). This analysis needs
only base MATLAB and the functions in this folder.

The loading example's `intNames` chooses early or interleaved conditions. The
analysis example uses these same names for `conditions.conditionName` and for
metadata lookup; keep `intNames` alongside `intAct`. Its four rows must remain
ordered S1, S2, S3, S4. Activity and metadata are selected together from the same
`neuralSelection` entries. If you manually subset trials, subset the matching
metadata rows in the same order too.

```matlab
[cfg,plotCfg]=fn_taskStimGeometryConfig();
cfg.period='stimulus'; % or 'reward'
[taskStim,figures]=fn_analyzeTaskStimGeometry(intAct,conditions,cfg,plotCfg,trialInfo);
```

## Inputs and comparisons

`intAct` is condition x animal cells, each neuron x time x trial, aligned to
stimulus (`dffStim`). Neuron identities/order must be the same in every condition
within an animal. Neurons concatenate across animals. The condition table must
match the input rows exactly:

| conditionName | stimulus | stimT1 | stimT2 | task | stimS1S3 | stimS2S4 | action |
|---|---|---|---|---|---|---|---|
| Int_S1_L | S1 | S1 | | T1 | S1 | | L |
| Int_S2_R | S2 | S2 | | T1 | | S2 | R |
| Int_S3_L | S3 | | S3 | T2 | S3 | | L |
| Int_S4_R | S4 | | S4 | T2 | | S4 | R |

`stimulus` controls plot colors; its labels can be arbitrary strings/numbers.
`cfg.comparisons` names six table columns by default, each containing exactly two nonempty
levels. Empty strings or missing labels exclude a condition from that comparison
only. All trials still project onto all fitted axes. Change names/labels or add
condition rows freely. The first encountered level is the negative class, the
second the positive class. Task uses equal weighting of S1/S2 versus S3/S4.
The added axes compare S1/S3, S2/S4, and L/R (S1/S3 versus S2/S4). All six axes
are fitted independently with the same LDA method. Three-column configurations
are still supported by setting `cfg.comparisons` to just the original names.
These axes can reflect action as well as stimulus if only correct trials are
supplied; the labels alone do not separate those confounded effects.

`trialInfo` is a matching cell array of tables in exactly the activity's trial
order. It is optional for stimulus analysis; reward requires the configured
stimulus/choice frame columns. No additional reward/outcome filter is applied:
your selection determines which trials enter the analysis.

## Reduced responses

For neuron n, trial r, stimulus onset e (`cfg.eventFrame=31`):

```text
stimulus response = mean(X(n, e+[1 2 3], r))
choice index(r)   = e + responseFrame(r) - stimulusFrame(r)
reward response  = mean(X(n, choice index(r)+[3 4], r))
```

The reward window is a choice-threshold-relative proxy, as in earlyLearningEmbedding,
not a measured reward-delivery alignment. Configure offsets and field names as
needed. Only the selected response period is used for the fit. Invalid timing or
out-of-range windows exclude that trial and are recorded in `trialMap`. Neurons
with any nonfinite reduced response are dropped across all retained trials and
conditions. Animals need at least `minTrials=2` valid trials in every supplied
condition; otherwise they are excluded (or error with `missingAnimal='error'`).
Check `animalAudit`, `trialCounts`, and `neurons`.

**Keep the original animal columns and labels; no manual deletion is needed.**
If any activity cell is empty (including a zero-trial array), the entire animal
is skipped before its metadata is processed. The command window reports its name
and missing conditions. `includedAnimalLabels` and `includedAnimalIndices` list
the retained animals. Audit rows and neuron/source mappings preserve the original
input-column numbers; excluded columns in `reducedActivity`/`trialMap` are empty.
For animals skipped at this early check, `trialCounts` is zero because their data
was not processed. Leave `cfg.missingAnimal='exclude'` (default) for this behavior.
If labels are supplied, keep one per original input column; an already shortened
activity array cannot be matched to a longer label list safely. Empty
`cfg.animalLabels=[]` generates labels from the input-column numbers.

Default normalization is none. Optional `normalization='zscore'` uses one mean and
sample SD per neuron over all retained reduced responses across conditions/trials,
before fitting. It does not normalize each condition separately. Trial-rich
conditions contribute more samples to normalization; class fitting remains balanced.
Constant neurons use scale 1. This normalization scope differs from normalizing
the original full traces in earlyLearningEmbedding.

## LDA math

Each comparison has its own two-class regularized Fisher LDA. For condition c,
let m_c be its pooled mean neural vector and C_c the block-diagonal sample noise
covariance (each animal's true trial covariance, cross-animal noise zero).
With K_l conditions in class l:

```text
mu_l  = mean(m_c for c in class l)
alpha_c = 1/(2*K_l)
Sigma = sum_c alpha_c * [C_c + (m_c-mu_l)*(m_c-mu_l)']
lambda = cfg.ridge * mean(diag(Sigma))
w0 = (Sigma + lambda*I) \ (mu_2-mu_1)
w = w0 / norm(w0)
threshold = w'*(mu_1+mu_2)/2
score = x'*w; positive class if score > threshold
```

The scale for lambda falls back to 1 if covariance is zero. This uses equal class
priors and equal conditions within each class, regardless of trial counts. The
condition-mean term includes cross-animal stimulus differences; only residual
trial noise between animals is assumed independent. `covariance='diagonal'`
removes off-diagonal within-condition noise; the condition-mean term remains.
A block solve plus the Woodbury identity avoids constructing a dense pooled
covariance. Zero mean separation gives an invalid axis (NaN weights/boundary),
not a fabricated direction.

There is one unit-length neural-weight vector per comparison, no residual axes.
Axes are independent fits and need not be orthogonal. Pairwise figures display
two discriminant scores; they are not an orthonormal reconstruction of the neural
plane. Vertical/horizontal dashed lines show each classifier's exact threshold
in these score coordinates. Each boundary only classifies the levels used in
that axis's fit (e.g. the S1/S2 boundary does not classify S3/S4).

## Pseudo-trials and outputs

Animals do not share simultaneous trials. For every condition, draw a trial
independently from each included animal, concatenate its reduced neural response,
and project on all fitted axes. This preserves within-animal neural covariance.
The fit uses analytic means/covariances of the original trials, not the random
pseudo-trials. Default `nPseudoTrials=[]` uses the smallest available count for
that condition and samples without replacement within each animal. Set an integer
to draw that many points with replacement. A private RNG (`cfg.seed`) makes
sampling reproducible without changing the caller's RNG. With one included animal,
all real trials are plotted without resampling.

- `weights`: pooled neurons x 6 (or 3); `neurons` maps each row to its animal/input row.
- `axisInfo`, `fits`, `thresholds`: class orientation, means, ridge and boundaries.
- `weightsRaw`, `thresholdsRaw`: equivalent classifier before optional z-scoring.
- `reducedActivity{condition,animal}`: retained neurons x retained trials.
- `projection.scores{condition}`: points x number of axes; `margins` subtracts thresholds.
- `projection.sourceTrial{condition}`: points x included animals, original trial
  index in each input activity cell. `animalIndices` identifies those animal columns.
- `projection.sourceRowInReduced{condition}`: corresponding row in
  `trialMap{condition,animal}.metadata`, preserving supplied source/session IDs.
- `projection.animalContribution{condition,animal}`: true-trial contributions to
  pooled scores, before other animals' contributions and before threshold subtraction.
- `trialMap` includes original retained trial indices and invalid-window trials.

These are descriptive in-sample fits and plots, not held-out decoding accuracy.
Repeated pseudo-trials are not additional observations. Figures stay in the second
output; original full time traces are not stored. Replot without refitting:

```matlab
plotCfg.visible=false;
plotCfg.savePath='B:\analysis\taskStimGeometry';
[figures,files]=fn_plotTaskStimGeometry(taskStim,plotCfg);
```

The first row contains stimT1 vs stimT2, stimT1 vs task, and stimT2 vs task.
The second row contains stimS1S3 vs stimS2S4, stimS1S3 vs action, and stimS2S4
vs action. Each row contains the three pairwise 2D plots of its axis triplet. Axis
labels, ticks, and their decision-boundary lines use consistent comparison colors
across panels; stimulus point colors remain unchanged. Customize the six RGB
rows of `plotCfg.axisColors` in comparison order.

`figures.similarity` shows a separate 6 x 6 neural-weight cosine matrix, with
both cosine and angle in degrees annotated in each cell. Because weights are unit
vectors, cosine is `weights'*weights`; `angleDegrees=acosd(cosine)`. These are
oriented angles (0 parallel, 90 orthogonal, 180 opposite), not absolute/unsigned
angles or correlations of activity. The red-white-blue scale is fixed to [-1,1],
with zero white; undefined axes are gray. Matrix labels match the comparison
colors. Results are stored as `taskStim.cosine` and `taskStim.angleDegrees`.

PNG export writes `taskStimGeometry_stimulus.png` and
`taskStimGeometry_stimulus_similarity.png` (or the corresponding `reward` names).
Replotting existing results computes the similarity directly from their weights.
To obtain the three new axes, rerun `example_taskStimGeometry.m` with your already
loaded `intAct` and `allTrialsel`; replotting an old three-axis result alone cannot
add newly fitted axes. Its original three-axis figures remain supported.
