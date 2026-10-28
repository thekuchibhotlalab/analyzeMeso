# Task/stimulus geometry in AC

Run your existing `example_prepareNeuralDataTaskStim.m` to load `intAct`, then
run [example_taskStimGeometry.m](example_taskStimGeometry.m). The loader is
unchanged. This analysis needs only base MATLAB and the functions in this folder.

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

| conditionName | stimulus | stimT1 | stimT2 | task |
|---|---|---|---|---|
| Int_S1_L | S1 | S1 | | T1 |
| Int_S2_R | S2 | S2 | | T1 |
| Int_S3_L | S3 | | S3 | T2 |
| Int_S4_R | S4 | | S4 | T2 |

`stimulus` controls plot colors; its labels can be arbitrary strings/numbers.
`cfg.comparisons` names three table columns, each containing exactly two nonempty
levels. Empty strings or missing labels exclude a condition from that comparison
only. All trials still project onto all fitted axes. Change names/labels or add
condition rows freely. The first encountered level is the negative class, the
second the positive class. Task uses equal weighting of S1/S2 versus S3/S4.
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
and project on the three axes. This preserves within-animal neural covariance.
The fit uses analytic means/covariances of the original trials, not the random
pseudo-trials. Default `nPseudoTrials=[]` uses the smallest available count for
that condition and samples without replacement within each animal. Set an integer
to draw that many points with replacement. A private RNG (`cfg.seed`) makes
sampling reproducible without changing the caller's RNG. With one included animal,
all real trials are plotted without resampling.

- `weights`: pooled neurons x 3; `neurons` maps each row to its animal/input row.
- `axisInfo`, `fits`, `thresholds`: class orientation, means, ridge and boundaries.
- `weightsRaw`, `thresholdsRaw`: equivalent classifier before optional z-scoring.
- `reducedActivity{condition,animal}`: retained neurons x retained trials.
- `projection.scores{condition}`: points x 3; `margins` subtracts thresholds.
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

The three panels are stimT1 vs stimT2, stimT1 vs task, and stimT2 vs task. One PNG
is saved as `taskStimGeometry_stimulus.png` or `taskStimGeometry_reward.png`.
