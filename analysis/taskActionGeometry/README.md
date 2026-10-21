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
   selected conditions/time/trials. At least two trials per cell are required.
3. `time` explicitly supplies seconds, or time is `(frame-eventFrame)/frameRate`.
   `timeWindow` restricts fitting, normalization, metrics, and plots together.
4. Normalization defaults to none. For each neuron, `zscore` subtracts one pooled
   mean and divides by one sample SD; `rms` divides by the square root of its
   pooled mean squared activity without centering. These pools contain **all raw
   trials and selected time bins across conditions**. Larger trial counts affect
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
not an animal-replicate statistical test.

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

| Metric / result field | Definition and interpretation |
| --- | --- |
| `variance.variableUniqueFractionByTime` | Main-effect regression on condition means at each time: $(SSE_{reduced}-SSE_{full})/(C V_{total})$. Reduced model removes only the target variable. Unique explained **total variance**, not partial eta-squared. Unidentifiable effects are NaN. This is what the task/action variance panels plot. |
| `variance.variableMarginalFractionByTime` | Variance of factor-level predicted means divided by total variance. Can overlap for unbalanced/confounded designs; not the default variance panel. |
| `variance.allConditionFractionByTime` | $V_{signal}/V_{total}$: dashed “All conditions” curve. Includes interactions and other condition differences not assigned to unique main effects. |
| `variance.conditionContributionByTime` | $(z_c-\bar z)^2/(C V_{total})$ for each condition. Sums to the all-condition fraction. A condition far from the grand mean contributes more, regardless of which variable caused the difference. |
| `variance.conditionTotalVarianceByTime` | $v_c+(z_c-\bar z)^2$, in squared activity units; includes within-condition variation. |
| `factors(f).separationCaptureByTime` | Between-level energy along this factor axis divided by that factor's between-level energy across all neurons. Assesses the fixed axis on the time-resolved level means. |
| `factors(f).cumulativeSeparationCapture` | Cumulative capture over that factor's orthogonal axes; at most 1 apart from round-off. |
| `variance.axisFractionOfPopulationTotalByTime` | Total projected variance divided by trace of the full neuron-space total covariance. Do not sum across overlapping variable bases. |
| `axisInfo.fitObjective` | In-sample axis-fitting objective. Not cross-validated accuracy and not comparable across methods. |

Summary fractions (fields without `ByTime`) are **mean numerator / mean denominator**,
not the mean of pointwise fractions. Zero denominators produce NaN. Interaction
variance is not assigned to individual main effects. All estimates are descriptive,
with no finite-sample noise correction, bootstrap CI, or held-out validation.

For separation capture, let $\delta_l(t)$ be a factor level's neuron-space mean
minus the equal-level mean. Axis $u_k$ captures
$\sum_l[u_k^\top\delta_l(t)]^2/\sum_l\|\delta_l(t)\|^2$.
This denominator is **between-level separation energy**, different from the
total trial variance denominator used in the task/action explained-variance plots.

## Similarity and plots

`plotCfg.similarity` supports:

- `'correlation'` (default): Pearson correlation of weight columns after centering
  across neurons. Orthogonal axes need not have zero centered correlation.
- `'cosine'`: $u_i^\top u_j$ for unit-length weights; orthogonal axes give zero.
- `'angle'`: $\cos^{-1}(|u_i^\top u_j|)$ in degrees; parallel/antiparallel is 0°,
  orthogonal is 90°. The absolute value removes sign orientation.

Correlation/cosine use blue = -1, white = 0, red = +1. Constant-weight Pearson
correlations are undefined and gray. These compare **weights**, not activity-trace
correlations. Similarity is measured in the analyzed, optionally normalized coordinates.

| Figure | Panels |
| --- | --- |
| `activity` | Per-condition neuron PSTHs with one shared peak-time ordering and color scale; mean population traces marginalized by variable, with SEM across neuron-wise trial means. |
| `projections` | Marginalized traces and optional `trialTypes` condition traces on each axis. |
| `variance` | Unique variable variance, weight similarity, time-resolved variance and separation capture. Condition-contribution heatmap/time courses are optional (`showConditionContribution=false` by default). |
| `trajectories` | With `trajectory='both'`: separate action/task 3D views, all within-variable 2D pairs among axes 1–3, then same-rank action/task pairs. Extra variables extend the layout. Missing axes skip unavailable panels. |

`trajectoryAxes=[]` uses the factor-based layout; an explicit three-index vector
overrides it with one custom triplet. These projections may use nonorthogonal
cross-variable axes and need not preserve distances. Population SEM is descriptive
across neurons, **not** an animal-level confidence interval.

```matlab
plotCfg.visible=false; plotCfg.savePath='B:\analysis\neuralGeometry';
[figures,files]=fn_plotNeuralGeometry(geometry,plotCfg); % No fitting repeated.
save('geometry.mat','geometry'); % Graphics are separate.
```

## Output and implementation map

`geometry.weights` is pooled neuron × axis; `neurons` maps rows to original animal
and neuron IDs; `axisInfo` maps columns to variable/rank. `weightsRaw` and
`projectionOffset` give the equivalent transform of raw input:
`weightsRaw' * rawActivity + projectionOffset`. `conditionMeans` is neuron × time ×
condition; `projection.conditionMean` is axis × time × condition.

`animalAudit` records exclusions and `trialCounts` records contributing trial
counts. Original trial arrays and figure handles are not retained in the result.
PNG paths are in `plotFiles`; visible figure handles are the second output only.

- `fn_neuralGeometryConfig.m`: analysis and plot defaults.
- `fn_analyzeNeuralGeometry.m`: validation, normalization, pooled moments, constrained
  axis fitting, projections, and time-resolved metrics; local helpers keep the API small.
- `fn_plotNeuralGeometry.m`: independent rendering and hidden PNG export.
- `example_neuralGeometry.m`: editable use with `intAct`/`tempAct`.
- `tests/testNeuralGeometry.m`: synthetic checks for pooling, raw transforms,
  Fisher directions, deflation, variance identities, confounding, and figure separation.
- `legacy/`: previous analysis implementation; not needed for the current API.

```matlab
results=runtests('analysis/taskActionGeometry/tests/testNeuralGeometry.m');
assertSuccess(results);
```
