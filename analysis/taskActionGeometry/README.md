# Task/action geometry: fixed linear neural axes

This analysis asks **which fixed combinations of neurons separate task, action,
or other categorical variables**, and how those contrasts evolve over the trial.
All animals' retained neurons form one population. Time is a sequence of observations,
not a set of additional neuron weights. The separate
[UMAP analysis](../taskActionGeometryEmbedding/README.md) visualizes nonlinear
neighborhood structure in trial-averaged responses.

## Run it

```matlab
addpath('analysis/taskActionGeometry');
conditions=table(["Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','action','task'});
[cfg,plotCfg]=fn_neuralGeometryConfig();
cfg.method='lda'; cfg.nAxes=3; cfg.normalization='none';
cfg.timeWindow=[]; % All bins; or [start end] in seconds.
cfg.separationSummary='choiceTask'; % Three fixed window bars, as in example_neuralGeometry.
cfg.separationTimeWindow=[]; % Separation summary only; e.g. [0 0.4] seconds.
% Alternatively: cfg.separationTimePoints=([31 33 37]-cfg.eventFrame)/cfg.frameRate;
cfg.crossValidate=true; cfg.cvFolds=5; cfg.cvRepeats=5;
cfg.decoderTopFractions=[0.10 0.25]; % Single-neuron time courses.
cfg.decoderWindowFrames=3; % Fixed -3:-1 at 15 Hz; input must be choice-aligned dffChoice.
plotCfg.trialTypes=conditions.conditionName;
plotCfg.trajectory='both';
plotCfg.showConditionContribution=false;
[geometry,figures]=fn_analyzeNeuralGeometry(intAct,conditions,cfg,plotCfg);
```

`intAct` is **condition × animal** cells; each cell is **neuron × time × trial**.
Rows must match `conditions`. Use the intended training period, such as `Int`,
when assembling the input. Here task means **stimulus set**: S1/S2 versus S3/S4,
not necessarily the recorded task context. The function uses supplied labels;
it never infers them from condition names. Additional categorical columns are
supported; `cfg.variables` selects a subset. Numeric factor values are level
identifiers, not continuous predictors.

## Preparation and weighting

1. Neuron identities and ordering must match across conditions within each animal.
   Animal neuron counts and trial counts may differ. Time alignment must match.
2. An empty condition excludes its entire animal by default (`missingAnimal='exclude'`);
   use `'error'` to stop instead. Nonfinite neurons are removed globally across the
   selected conditions/time/trials. With five-fold CV, at least ten trials per cell
   are required (two per test fold for variance). Incomplete animals are excluded
   before splitting. Non-CV analysis requires two trials per cell.
3. `time` explicitly supplies seconds, or time is `(frame-eventFrame)/frameRate`.
   `timeWindow` restricts fitting, normalization, metrics, and plots together.
   The example uses `cfg.separationSummary='choiceTask'`: three bars per axis,
   action/choice in [-0.15, 0] s, task in [-0.15, 0] s, and task in [0, 0.5] s.
   Both intervals include zero. Each bar uses its own window's population
   variance denominator, including trial noise. The analysis time grid must
   cover both windows; at 15 Hz the bins are [-2, -1, 0]/15 and [0:7]/15 s.
   Leave `separationTimeWindow` and `separationTimePoints` empty in this mode.
   Results are in `variance.windowedVariableFraction` (axis x 3),
   `variance.windowedVariableEnergy`, and `variance.windowedPopulationVariance`.
   `geometry.separationBars` records their order, variables, windows and actual
   times. CV computes each ratio on held-out trials before fold/repeat averaging;
   SEM is in `crossValidation.varianceSEM.windowedVariableFraction`.
   Existing generic configurations retain `separationSummary='selected'`.
   In that mode, to restrict only the task-variable separation summary bars, set
   `cfg.separationTimeWindow=[start end]` (inclusive seconds), or set
   `cfg.separationTimePoints` to explicit bin times in seconds, including
   noncontiguous bins. Use only one; both empty retains all analyzed bins.
   Explicit times must match bins remaining after `timeWindow` (within 1e-9 s);
   repeated times count only once. An empty selection raises an error.
   The numerator and population denominator both use the selected bins, with
   population means recentered over those bins and conditions. Axis fitting,
   normalization, other metrics, and time-course plots retain `timeWindow`.
   Rerun the analysis to change this selection. CV applies it separately to
   each held-out split before averaging ratios and computing repeat SEM.
   `geometry.separationTime` records the bins and
   `variance.separationPopulationVariance` records the denominator (mean of
   split denominators for CV). The bars remain fractions, not percentages:
   0.005 means 0.5% of population total variance. They measure unique additive
   main-effect separation, not the projection's total trial-by-trial R-squared.
4. Normalization defaults to none. For each neuron, `zscore` subtracts one pooled
   mean and divides by one sample SD; `rms` divides by the square root of its
   pooled mean squared activity without centering. These pools contain **all raw
   training trials and selected time bins across conditions** in CV mode. Larger trial counts affect
   normalization. Zero scales are replaced by one.
5. Axes and variance metrics balance condition means, rather than giving conditions
   with more trials extra weight. Each factor's levels are equally weighted when
   constructing its axis target. All neurons have features in the same fit;
   animals with more retained neurons contribute more features.

Trials are **not paired across animals**. Means concatenate along the neuron
dimension. Cross-animal trial covariance is unknown and assumed zero. The default
LDA covariance is diagonal; `cfg.covariance='withinAnimal'` permits full covariance
blocks within each animal. Projected trial variance uses within-animal covariance
even when the fitting metric is diagonal. This is a pooled pseudo-population,
not an animal-replicate statistical test. Decoding uses each neuron's own real
held-out trials: there is no pooled population decoder or pseudo-trial sampling.

## Repeated five-fold LDA and decoding (default)

`method='lda'` now defaults to `crossValidate=true`, `cvFolds=5`, and
`cvRepeats=5`: 25 training/test splits. `cvSeed=1` gives reproducible private
random streams without changing MATLAB's global RNG. Each condition/animal is
partitioned independently; **all time bins of a trial stay in the same fold**.
Training normalization, moments, all residual-axis fits, and decoder thresholds
are learned without the outer test trials. The original in-sample behavior is
available with `cfg.crossValidate=false`; other axis methods remain descriptive.

Each training model is evaluated on its held-out trials. Projections and every
variance/separation metric are computed per split and then averaged. Variance
fractions are the mean of split-wise ratios, not a ratio of pooled numerators.
These are held-out descriptive variances, not prediction R-squared and not
noise-corrected estimates: squared differences of finite test means retain noise.
A rank is reported only if it is estimable in every split.

For a metric $q_{rf}$ from repeat $r$, fold $f$:

$$q_r=F^{-1}\sum_f q_{rf},\quad \bar q=R^{-1}\sum_r q_r,
\quad SEM=SD(q_1,\ldots,q_R)/\sqrt R.$$

The SEM describes sensitivity to repeated partitions of this dataset; repeated
partitions are not independent subjects. It is **not** an animal-level or
population-sampling confidence interval. Marginal projections are averaged
across conditions *within each split* before computing SEM.

Binary axes are oriented toward level 2 using training means. Higher residual
ranks retain their training rank; unstable ranks may average to weak directions.
For multiclass axes, signs align to the first training fit. Each split's weights
are converted to raw neuron coordinates and unit normalized before averaging:

$$v_s=\frac{w_s/\sigma_s}{\|w_s/\sigma_s\|},\qquad
\bar v=S^{-1}\sum_s v_s.$$

`meanWeights` stores this arithmetic average. `weights` and `weightsRaw` store
its unit-normalized direction; similarity plots use these raw-coordinate mean
directions. Averaging **does not preserve orthogonality** between residual ranks.
The averaged vector is not used to score test data. The plotted projections are
means of split projections in their respective training-normalized coordinates;
applying the mean vector to raw data will not reproduce them. `conditionMeans`
and the activity sanity figure remain full-data **raw** descriptive PSTHs.

### Real-trial single-neuron decoding

The population decoder has been removed. Every accuracy is evaluated on that
neuron's **actual held-out trials from its own animal**, with the same five-fold
partitions used by geometry. No trials are paired or sampled across animals.
Binary variables are supported; multilevel variables retain geometry but skip
decoding. Neuron identities/order must still match across conditions within each
animal.

**Choice (`decoderChoiceVariable='action'`):** the input must be choice-aligned
`dffChoice`, with time zero at choice threshold. Fit the scalar neuron classifier
using only frames **-3, -2, -1**, and summarize its test accuracy only on these
frames. At 15 Hz the sample times are -200, -133.33 and -66.67 ms; frame zero and
all post-choice frames are excluded. All three frames must be present in
`cfg.timeWindow`. The code checks the time grid and errors on incompatible
alignment/rates instead of silently choosing a different window. There is no
search for a best window. Stimulus-aligned data cannot be used as if its zero were
choice; realign it before calling this analysis.

**Task and other binary variables:** fit using all selected time points, and
average the test accuracies across the full selected window. For both choice and
task, the summary averages per-frame accuracies, **not trial responses before
classification**. Geometry axis fitting is unchanged: it still uses the full
selected time window; choice single-neuron coefficients now use the narrower
pre-choice window and need not match those geometry coefficients.

With equal class priors, single-neuron LDA has

$$w_j=(\mu_{2j}-\mu_{1j})/(s_j^2+\lambda),\qquad
h_j=(\mu_{1j}+\mu_{2j})/2.$$

Classify as level 2 when $w_j(x_j-h_j)>0$. The means and variances pool training
trials and the variable's fitting frames, balancing classes and conditions
within classes. Zero-score ties count as 0.5. Test accuracy similarly balances
classes and their subconditions. Normalization parameters are learned only from
training trials; positive affine single-neuron normalization does not change
these scalar decisions.

The `decodingNeurons` figure plots **one point per neuron**, ranked by its own
mean held-out accuracy, with SEM across repeat means and color indicating its
animal. This final sorting is descriptive: it is not independent evidence that
the best displayed neuron will perform as well on a new dataset. No averaging
across neurons is done in this figure.

The existing `decodingTime` figure still plots mean single-neuron accuracy for
`decoderTopFractions=[0.10 0.25]`. For these groups, `decoderInnerFolds=3` ranks
neurons using inner-training CV only: pre-choice accuracy for choice, whole-window
accuracy for task. The resulting fixed neuron group is evaluated across the outer
test time course. The choice classifier's fixed pre-choice threshold is also
applied at other times to show temporal generalization; the **choice summary**
only uses pre-choice frames. This top-group plot and its ranking are separate
from the descriptive sorting in the individual-neuron plot.

### Investigating low accuracy despite selective mean traces

The previous implementation fitted one decision threshold over the entire time
window for every variable, and ranked choice neurons by whole-window accuracy.
A short-lived pre-choice response could therefore be diluted by baseline and
other periods. Choice fitting/ranking now use only the fixed pre-choice frames.

A second issue can persist, especially for task: the baseline of both class
responses may change strongly over time. One scalar threshold pooled across time
can put *both* classes on the same side at a given time even when their means
are clearly separated there. To diagnose this, every split also fits a separate
single-neuron threshold/direction **at each time bin using training trials only**:

- `decoding.mean.neuronTime`: fixed-window classifier, neuron x time x variable.
- `decoding.mean.neuronSummary`: each neuron's accuracy in the stated summary window.
- `decoding.mean.timeResolvedNeuronTime` / `timeResolvedNeuronSummary`: held-out
  diagnostic with per-time-bin fits. A substantial increase indicates a cost of
  using one fixed threshold/direction across time. This diagnostic does not replace
  the main fixed-window metric or change the geometry axes.

Synthetic tests reproduce 50% fixed-threshold versus near-perfect time-specific
accuracy with a strong shared temporal baseline and perfectly separated classes.
That establishes a possible mechanism, not the cause of an individual animal's
scores. Trial-averaged traces also conceal trial-to-trial overlap. Finally, a
neuron selective for S1 alone may distinguish L/R in T1 but not in T2; averaging
across both tasks can weaken its action accuracy, and opposite preferences can
cancel. Thus visible condition selectivity is not necessarily robust marginal
choice/task decoding.

```matlab
geometry.decoding.neuronTable  % Animal, original neuron row, accuracy, SEM, rank,
                              % and timeResolvedAccuracy for the same cell.
geometry.decoding.mean.neuronSummary       % neuron x variable
geometry.decoding.mean.neuronTime          % neuron x time x variable
geometry.decoding.displayOrder             % neuron indices sorted for each variable
```

`crossValidation.assignments{condition,animal}` is original trial x repeat;
entries give the held-out fold. `crossValidation.models{s}` stores training
weights, scaling and axis labels. `crossValidation.splits{s}` stores held-out
projection/variance/factor metrics. `crossValidation.varianceSEM` and `factorSEM`
contain plotted repeat SEMs. `decoding.splits{s}` stores actual test `sourceTrial`
indices, training ranks, thresholds, fit/summary window indices, and per-neuron
accuracies. `decoding.mean` and `.sem` aggregate these over repeats.
`decoderFractions` and `decoderPseudoTrials` are accepted but ignored for
compatibility with saved configuration structures; no population curves are made.
Old saved results lack held-out accuracies for individual neurons: rerun analysis
rather than trying to recover them from old top-group averages.

Training-only top-group selection follows
[nested CV](https://scikit-learn.org/stable/auto_examples/model_selection/plot_nested_cross_validation_iris.html).

## Axis fitting: math and implementation

Let $x_{c,t,r}$ denote normalized neural activity. Each neuron has a single weight
per axis, shared across all time points. First average each condition over time
and trials to get $m_c$. For the target variable with $L$ levels, define

$$
\mu_l=\frac{1}{|C_l|}\sum_{c\in C_l}m_c,\qquad
D=\frac{1}{\sqrt L}[\mu_1-\bar\mu,\ldots,\mu_L-\bar\mu],\quad B=DD^\top.
$$

Subconditions are **averaged**, not summed, so unequal numbers of condition rows
do not increase a level's weight. Pooling time before constructing $D$ means
oppositely signed early/late contrasts can cancel. No time-specific axis is fitted.

### `method='lda'` (default)

The axis maximizes the Fisher separation ratio:

$$J(u)=\frac{u^\top B u}{u^\top S u},\qquad \|u\|_2=1.$$

The unregularized within-level covariance is

$$
S_w=\frac1L\sum_l\frac1{|C_l|}\sum_{c\in C_l}
\left[\Sigma_c+(m_c-\mu_l)(m_c-\mu_l)^\top\right].
$$

$\Sigma_c$ uses time and trials pooled within condition $c$, with population
denominator (number of samples). For a pseudo-population it has zero cross-animal
blocks. The subcondition mean-offset term is also block restricted in the
`withinAnimal` implementation; the diagonal version retains only diagonal terms.
Thus this is a specified block/diagonal approximation to a full population metric.
The fitted denominator is $S=S_w+\lambda I$, with
$\lambda=\texttt{ridge}\,\operatorname{mean}(\operatorname{diag}S_w)$; the scale
is 1 if the mean diagonal is zero. Default `ridge=1e-3`.

This denominator is **variance**, not the RMS of variances. Its square root
represents a within-group SD along the projected direction.

After selecting orthonormal columns $U$, require $u\perp U$. Equivalently, remove
$UU^\top x$ and refit in the complementary neural space. The code avoids allocating
a neuron × neuron projector. With $Z=S^{-1}U$, it computes

$$V=S^{-1}D-Z(U^\top Z)^{-1}U^\top S^{-1}D,$$

then the largest eigenvector $q$ of $D^\top V$ and normalizes $Vq$. A final
orthogonalization removes round-off along $U$. Each variable starts with its
**own empty $U$**: action axes are orthogonal to earlier action axes, while task
axes may overlap action axes.

Binary LDA has **one canonical discriminant**. Additional axes here are
residual-separation directions after Euclidean deflation, not additional
canonical discriminants or proof of independent information dimensions.

### `method='meanSquared'`

Maximize $u^\top B u$ with unit norm, without a noise denominator. Successive
directions are left singular vectors of $(I-UU^\top)D$. A binary pooled contrast
has rank at most one, so this method ordinarily returns one axis per binary factor.

### `method='regression'`

Build a condition × predictor design $H$ containing an intercept and effect-coded
main effects for **all** variables. Fit the pooled means jointly, $\hat\beta=H\backslash M$,
then isolate each variable's fitted effect matrix and apply residual SVD to it.
Perfectly confounded predictors cause an error. Each factor's basis is fitted
independently; no cross-factor QR step forces artificial orthogonality.

This is inspired by targeted encoding regression, but **is not an exact reproduction**
of [Mante et al. (2013)](https://doi.org/10.1038/nature12742): it does not implement
their time-dependent coefficient selection, PCA denoising, and final QR pipeline.

`nAxes` is a maximum per variable. Stop when remaining pooled signal falls below
`tolerance` (default `1e-9` relative to the original target), or dimensions run out.
The sign convention makes each axis's largest-magnitude weight positive.

## Projections and metrics

At time $t$ on one axis, let $z_c(t)$ be the condition-mean projection and $v_c(t)$
the trial variance along that axis. The latter sums within-animal projected trial
variances, using population denominators. All conditions receive equal weight.

$$
\bar z=\frac1C\sum_c z_c,\quad
V_{\rm signal}=\frac1C\sum_c(z_c-\bar z)^2,\quad
V_{\rm noise}=\frac1C\sum_c v_c,\quad
V_{\rm total}=V_{\rm signal}+V_{\rm noise}.
$$

These quantities are calculated **at each time point**. Shared temporal changes
are not included as a competing explanatory factor.

The time courses show **total projected variance divided by total population
variance at each time**, including condition differences and trial variability. Let

$$
V_{\rm population}(t)=\sum_n\left[
\frac1C\sum_c(\mu_{nc}(t)-\bar\mu_n(t))^2+
\frac1C\sum_c\operatorname{Var}_{r}(x_{nctr})\right].
$$

For axis $k$, the time course plots $V_{total,k}(t)/V_{population}(t)$.
The left summary uses a population denominator pooled across **conditions,
trials, and time**, about one grand mean. Define

$$
M_k=\operatorname{Var}_{c,t}(z_{kc}(t)),\qquad
M_{pop}=\sum_n\operatorname{Var}_{c,t}(\mu_{nc}(t)).
$$

The left summary plots a separate bar for each variable on each axis:
$\operatorname{Mean}_t E_{kf}(t)/
[M_{pop}+\operatorname{Mean}_t V_{noise,pop}(t)]$,
where $E_{kf}$ is unique variable-related variance from the joint main-effect
regression (defined below). The numerator captures time-varying action/task
separation; it excludes trial noise and temporal changes shared across conditions.
The denominator includes shared temporal dynamics, condition differences, and
trial variability throughout the pooled population.
For this bar summary, every time average and variance in the formula uses
the bar's fixed window in `choiceTask` mode. In `selected` mode it uses
the separation time selection when supplied; otherwise it uses all analyzed bins.
Writing the denominator explicitly for a window W:

$$
D(W)=\sum_n\left[\operatorname{Var}_{c,t\in W}(\mu_{nc}(t))+
\frac{1}{C|W|}\sum_c\sum_{t\in W}\operatorname{Var}_r(x_{nctr})\right],
\qquad F_{kf}(W)=\frac{|W|^{-1}\sum_{t\in W}E_{kf}(t)}{D(W)}.
$$

The fixed three bars are F(action, [-0.15, 0]), F(task, [-0.15, 0]),
and F(task, [0, 0.5]), on every axis. Variances use population normalization
(divide by sample count, matching MATLAB `var(...,1,...)`). Temporal averaging
is applied to squared separation energy, not to the responses before squaring.
Estimated condition means still have finite-trial noise; these numerators are
not explicitly noise-bias-corrected estimates.
The adjacent condition-mean summary in the same `variance` figure first averages all trials within each
condition, then plots $M_k/M_{pop}$ across conditions and time. It includes
temporal dynamics and condition differences, but excludes within-condition trial
variability. Both use equal condition/time weights, regardless of trial counts;
individual trials receive equal weight within each animal-condition. Animals'
trials are not paired; projected residual variances add across animals.
The left panel has grouped variable bars. The condition-mean panel has one total
variance bar per axis; the time courses also retain total projected variance.
An axis named `action 1` can capture variance from other sources, including task.
Values are fractions (0.01 means 1%). All quantities use the analyzed, optionally
normalized neuron coordinates. Different variable bases can overlap, so do not
add fractions across action and task axis sets.

Variable-specific metrics remain available in the result. For variable $f$ on
axis $k$, its unique projected variance is
$E_{kf}(t)=(SSE_{reduced}-SSE_{full})/C$ from the joint main-effect model.
For a balanced binary action comparison, this equals
$[u_k^\top(\mu_L(t)-\mu_R(t))]^2/4$.

| Metric / result field | Definition and interpretation |
| --- | --- |
| `variance.windowedVariableFraction` | Fixed choiceTask summary, axis x 3; each bar uses its own window in numerator and denominator. |
| `variance.variableUniquePooledPopulationFraction` | Mean unique variable variance on each axis / total population variance pooled over conditions, trials and selected separation times (all analyzed times by default). Grouped bars in selected mode. |
| `variance.pooledAllTrialsFraction` | Total projected variance / population total, pooling conditions, time and trials about one grand mean. Retained in the output. |
| `variance.pooledTrialMeanFraction` | Projected variance / population total of condition-mean PSTHs pooled across conditions and time. Right summary in `variance`. |
| `variance.pooledAllTrialsProjectedVariance`, `pooledAllTrialsPopulationVariance` | Numerator (per axis) and denominator (scalar) of the all-trial pooled fraction. Corresponding `pooledTrialMean...` fields hold the trial-averaged quantities. |
| `variance.variableUniquePopulationFractionByTime` | $E_{kf}/V_{population}$; retained as a variable-specific metric, not plotted in the total-variance panels. Unidentifiable effects are NaN. |
| `variance.variableUniqueEnergyByTime` | $E_{kf}$, unique projected main-effect variance in squared activity units. |
| `variance.allConditionPopulationFractionByTime` | $V_{signal}/V_{population}$, including interactions and other condition differences; retained in the result. |
| `variance.populationTotalVarianceByTime` | Sum across neurons of between-condition and within-condition variance at each time point. |
| `variance.variableUniqueFractionByTime` | Original within-axis metric, retained for comparison: $E_{kf}/V_{total}$, where $V_{total}$ is variance on that axis. Not partial eta-squared; no longer used in the task/action panels. |
| `variance.variableMarginalFractionByTime` | Variance of factor-level predicted means divided by total variance. Can overlap for unbalanced/confounded designs; not the default variance panel. |
| `variance.allConditionFractionByTime` | Original within-axis all-condition fraction $V_{signal}/V_{total}$, retained for comparison. |
| `variance.conditionContributionByTime` | $(z_c-\bar z)^2/(C V_{total})$ for each condition. Sums to the all-condition fraction. A condition far from the grand mean contributes more, regardless of which variable caused the difference. |
| `variance.conditionTotalVarianceByTime` | $v_c+(z_c-\bar z)^2$, in squared activity units; includes within-condition variation. |
| `factors(f).separationCaptureByTime` | Between-level energy along this factor axis divided by that factor's between-level energy across all neurons. Assesses the fixed axis on the time-resolved level means. |
| `factors(f).cumulativeSeparationCapture` | Cumulative capture over that factor's orthogonal axes; at most 1 apart from round-off. |
| `variance.axisFractionOfPopulationTotalByTime` | Total projected variance divided by trace of the full neuron-space total covariance; plotted in the per-axis time courses. The field without `ByTime` retains the old ratio of time-averaged variances, not the new pooled-time summary. Do not sum across overlapping variable bases. |
| `axisInfo.fitObjective` | In-sample axis-fitting objective. Not cross-validated accuracy and not comparable across methods. |

For time-resolved metrics, summary fractions (fields without `ByTime`) are **mean numerator / mean denominator**,
not the mean of pointwise fractions. Zero denominators produce NaN. Interaction
variance is not assigned to individual main effects. All estimates are descriptive,
with no finite-sample noise correction or bootstrap CI. In CV mode these
calculations use held-out trials separately for each training axis.

For separation capture, let $\delta_l(t)$ be a factor level's neuron-space mean
minus the equal-level mean. Axis $u_k$ captures
$\sum_l[u_k^\top\delta_l(t)]^2/\sum_l\|\delta_l(t)\|^2$.
This denominator is **between-level separation energy**, different from the
full population total variance denominator used in the axis variance-captured plots.
Previously saved geometry results can be replotted with the new population
denominator using `fn_plotNeuralGeometry`; no neural-data reload or axis refit is needed.

## Similarity and plots

`plotCfg.similarity` supports:

- `'correlation'`: Pearson correlation of weight columns after centering
  across neurons. Orthogonal axes need not have zero centered correlation.
- `'cosine'` (default): $u_i^\top u_j$ for unit-length weights; orthogonal axes give zero.
- `'angle'`: $\cos^{-1}(|u_i^\top u_j|)$ in degrees; parallel/antiparallel is 0°,
  orthogonal is 90°. The absolute value removes sign orientation.

Correlation/cosine use blue = -1, white = 0, red = +1. Constant-weight Pearson
correlations are undefined and gray. These compare **weights**, not activity-trace
correlations. In CV mode similarity uses the mean raw-coordinate unit directions;
non-CV mode uses the analyzed, optionally normalized coordinates.

| Figure | Panels |
| --- | --- |
| `activity` | Per-condition neuron PSTHs with one shared peak-time ordering and color scale; mean population traces marginalized by variable, with SEM across neuron-wise trial means. |
| `projections` | Marginalized and condition traces with trial SEM by default (`projectionError='trialsem'`). `'sem'` retains CV-repeat SEM; `'sd'` shows repeat SD in CV mode; `'none'` hides bands. |
| `variance` | Adjacent variable-separation / pooled population total and condition-mean total variance summaries, per-time variance capture, weight similarity, and separation capture. Condition-contribution heatmap/time courses are optional (`showConditionContribution=false` by default). |
| `decodingTime` | Held-out mean single-neuron accuracy for training-ranked top 10% and 25%, one panel per binary variable. |
| `decodingNeurons` | Individual neurons ranked by held-out accuracy, colored by animal, with repeat SEM. Choice uses fixed pre-choice frames -3:-1; task uses the full window. |
| `trajectories` | With `trajectory='both'`: separate action/task 3D views, all within-variable 2D pairs among axes 1–3, then same-rank action/task pairs. Extra variables extend the layout. Missing axes skip unavailable panels. |

`trajectoryAxes=[]` uses the factor-based layout; an explicit three-index vector
overrides it with one custom triplet. These projections may use nonorthogonal
cross-variable axes and need not preserve distances. Population SEM is descriptive
across neurons, **not** an animal-level confidence interval.

**Saved trial-based projection uncertainty.**
`geometry.projection.conditionTrialSEM` explicitly stores trial-based SEM as
axis x time x condition, for both CV and non-CV analyses. Its interpretation
is recorded in `geometry.projection.trialSEMEstimation`. The existing
`conditionSEM` field is unchanged (CV-repeat SEM in CV analyses).
To upgrade an existing saved structure without rerunning fits:

```matlab
geometry=fn_addNeuralGeometryTrialSEM(geometry);
save('geometry.mat','geometry'); % Use your actual filename.
```

Trial-based projection shading is selected by
`plotCfg.projectionError='trialsem'` (default), including when replotting saved
CV results. `fn_neuralGeometryTrialSEM` reads each held-out split's original
trial SEM, rather than the top-level `projection.conditionSEM` (which in CV
results contains repeat SEM). For F folds, marginal trial variance V_s in each
fold is combined as sum(V_s)/F^2. The displayed band is the square root of the
mean of these variances across repeats: a typical-repeat, fixed-axis trial SEM
estimate. It is not divided by sqrt(number of repeats), since repeats reuse
trials. Conditions are averaged with equal weights before this combination.
Fitted axes are treated as fixed; dependence from fitting overlapping training
sets is not modeled. This estimates trial sampling uncertainty, not uncertainty
over axes or animals. Missing per-split trial SEM requires rerunning analysis;
it is not silently replaced with CV-repeat SEM.

For non-CV results, trial SEM follows the formula below directly.
Projection uncertainty is separate from the neuron-wise SEM in the activity
sanity plots. Use `'sem'` to restore the previous CV-repeat bands.
For animal $a$, condition $c$, and fixed axis $k$, project the actual trials
using that animal's weight block, and calculate sample variance $s^2_{ack}(t)$.
With $R_{ac}$ trials, the pooled mean's SEM is

$$
SEM_{ck}(t)=\sqrt{\sum_a s^2_{ack}(t)/R_{ac}}.
$$

For a marginal trace averaging $m$ conditions equally, its SEM is
$\sqrt{\sum_c SEM_{ck}(t)^2}/m$. This uses independent trial/animal
contributions, without pairing trials across animals or using neuron count as
sample size. SEM estimates uncertainty of the mean; it is not individual-trial
spread. SD uses $\sqrt{\sum_a s^2_{ack}}$ per condition; a marginal SD also
includes between-condition mean differences, as a balanced mixture of trials.
Bands are +/-1 SEM or SD, not confidence intervals. They assume independent
trials and treat fitted axes as fixed: session dependence, axis-fit uncertainty,
and between-animal generalization are not estimated. These are descriptive
in-sample summaries, not a significance test of learning-phase differences.
`projection.conditionSEM` and `projection.conditionSD` store axis x time x
condition arrays. Older saved results lack per-animal variance contributions;
rerun `fn_analyzeNeuralGeometry` once to obtain SEM. Plotting an older result
without the requested uncertainty field emits a warning and shows mean traces.

```matlab
plotCfg.visible=false; plotCfg.savePath='B:\analysis\neuralGeometry';
[figures,files]=fn_plotNeuralGeometry(geometry,plotCfg); % No fitting repeated.
save('geometry.mat','geometry'); % Graphics are separate.
```

## Output and implementation map

`geometry.weights` is pooled neuron × axis; `neurons` maps rows to original animal
and neuron IDs; `axisInfo` maps columns to variable/rank. In **non-CV mode**, `weightsRaw` and
`projectionOffset` give the equivalent transform of raw input:
`weightsRaw' * rawActivity + projectionOffset`. `conditionMeans` is neuron × time ×
condition; `projection.conditionMean` is axis × time × condition.

`animalAudit` records exclusions and `trialCounts` records contributing trial
counts. Original trial arrays and figure handles are not retained in the result.
PNG paths are in `plotFiles`; visible figure handles are the second output only.

- `fn_neuralGeometryConfig.m`: analysis and plot defaults.
- `fn_analyzeNeuralGeometry.m`: public entry point and CV/descriptive dispatch.
- `fn_fitNeuralGeometry.m`: internal training fit or fixed-model held-out evaluation.
- `fn_crossvalidateNeuralGeometry.m`: stratified repeated folds, aggregation, provenance.
- `fn_decodeNeuralGeometry.m`: inner-CV ranking/window selection and outer-test decoding.
- `fn_plotNeuralGeometry.m`: independent rendering and hidden PNG export.
- `example_neuralGeometry.m`: editable use with `intAct`/`tempAct`.
- `tests/testNeuralGeometry.m`: synthetic checks for pooling, raw transforms,
  Fisher directions, deflation, variance identities, confounding, and figure separation.
- `legacy/`: previous analysis implementation; not needed for the current API.

```matlab
results=runtests({'analysis/taskActionGeometry/tests/testNeuralGeometry.m', ...
    'analysis/taskActionGeometry/tests/testCrossvalidatedGeometry.m'});
assertSuccess(results);
```
