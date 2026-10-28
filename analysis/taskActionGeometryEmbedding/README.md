# Trial-averaged neural UMAP

Fit **one unsupervised 2D embedding** of all condition × selected-time population
vectors. Recolor the same coordinates by trial condition, action, task, or other
condition-table labels. All retained neurons from all animals are concatenated
as features. There is no separate fit per animal, condition, or label panel.

## Relation to the paper

[*Learning produces an orthogonalized state machine in the hippocampus*, Nature
(2025)](https://www.nature.com/articles/s41586-024-08548-w) uses a shared UMAP
embedding of longitudinal neural activity, with one point per imaging frame.
Its methods specify 100 neighbors, correlation distance, minimum distance 0.1,
and **three** embedding components.

Here the requested adaptation uses **two components and trial means**, with one
point per condition/time bin and neurons pooled across animals. It retains the
paper's neighborhood, distance, and minimum-distance settings as starting values.
It is not a replication of the paper's frame-level, longitudinal analysis.

## Install and run

Requires MATLAB (tested with R2023b), Statistics and Machine Learning Toolbox,
and the external [Herzenberg MATLAB UMAP package (`run_umap`)](https://www.mathworks.com/matlabcentral/fileexchange/71902).
Integration was checked with the installed UMAP 4.1 backend. The package is not
copied into this repository. Your existing installation is
`C:\Users\zzhu34\Documents\GitHub\umap`; adjust this on another computer. Use a
package release compatible with your MATLAB version and its platform-specific MEX.

```matlab
addpath('analysis/taskActionGeometryEmbedding');
umapRoot='C:\Users\zzhu34\Documents\GitHub\umap';
addpath(genpath(umapRoot));
javaaddpath(fullfile(umapRoot,'util','suh.jar')); % Once per MATLAB session if needed.

conditions=table(["Int_S1_L";"Int_S2_R";"Int_S3_L";"Int_S4_R"], ...
    ["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','action','task'});
[cfg,plotCfg]=fn_neuralEmbeddingConfig();
cfg.normalization='none';
cfg.timeWindow=[];
plotCfg.colorBy=["conditionName","action","task"];
[embedding,figures]=fn_analyzeNeuralEmbedding(intAct,conditions,cfg,plotCfg);
```

`intAct`/`tempAct` must be **nCondition × nAnimal cells**, each holding
**nNeuron × nTime × nTrial** activity. Rows match the condition table exactly.
Select the intended training period beforehand (for example, fully interleaved
`Int`). Task in this example is stimulus set S1/S2 versus S3/S4; labels are supplied
explicitly, never inferred from names. Any extra variables are annotation columns,
not training targets. `cfg.variables` chooses which are included by default in plots.

## Exact data construction

Let $A^{(a)}_{n,t,r,c}$ denote raw activity for animal $a$, neuron $n$, selected
time bin $t$, trial $r$, and condition $c$. For each animal, optionally estimate
one offset $b_n$ and scale $s_n$ across **all selected raw time bins, trials and
conditions**, then calculate

$$M^{(a)}_{n,t,c}=\frac1{R_{a,c}}\sum_r
\frac{A^{(a)}_{n,t,r,c}-b_n}{s_n}.$$

`none` uses $(b,s)=(0,1)$; `zscore` uses pooled mean and sample SD; `rms` uses zero
offset and $\sqrt{\operatorname{mean}(A^2)}$. Zero scales are replaced by one.
The linear scaling can be applied to the means after averaging with the same
result. Normalization is not fitted separately within each condition.

Each UMAP row is a **neuron vector at one time in one condition**:

$$X_{i,:}=[M^{(1)}_{:,t,c};\ldots;M^{(a)}_{:,t,c};\ldots]^\top,
\qquad i=(c-1)T+t.$$

Thus $X$ has $(C T)\times N_{pooled}$ entries. For 4 conditions, 100 bins, and
5,000 pooled neurons, UMAP receives a **400 × 5,000 matrix**, returning **400 × 2**
coordinates. Time is not appended as a feature; the embedding is not supervised
by task/action, and it has no temporal smoothness constraint. No PCA pre-reduction,
time smoothing, or single-trial resampling is applied.

Neuron identity/order must match across conditions within an animal, and times
must match across animals. Trial counts can differ: each condition/time mean
still contributes one point. Animals with more retained neurons contribute more
features; there is no animal-block reweighting. Unrelated trials are never paired.
An animal missing any condition is excluded wholesale by default. A neuron with
any nonfinite selected raw sample is dropped across every condition, preserving
a common feature set. Nothing is filled with zeros. One trial per cell is allowed,
but then that “mean” is only a single-trial observation; inspect `trialCounts`.

## Distance and UMAP optimization

Default correlation distance between population vectors is

$$d(x_i,x_j)=1-
\frac{(x_i-\bar x_i\mathbf1)^\top(x_j-\bar x_j\mathbf1)}
{\|x_i-\bar x_i\mathbf1\|\,\|x_j-\bar x_j\mathbf1\|}.$$

This centers **across neurons within each point**, even when normalization is
`none`. It emphasizes population-pattern similarity over global amplitude and
offset. Select `euclidean` to retain amplitude differences, or `cosine` for
uncentered angular distance. Constant population vectors make correlation
undefined; zero vectors make cosine undefined. The function stops with an
explanation rather than substituting an arbitrary distance.

UMAP constructs a local nearest-neighbor graph with adaptive distance scales.
Conceptually, directed memberships have the form
$p_{j|i}=\exp[-\max(0,d_{ij}-\rho_i)/\sigma_i]$ on neighbors, combined into a fuzzy
union $p_{ij}=p_{j|i}+p_{i|j}-p_{j|i}p_{i|j}$. Low-dimensional affinities use a
curve $q_{ij}=(1+a\|y_i-y_j\|^{2b})^{-1}$, with shape set by `minDist` and `spread`.
The optimizer balances attraction for graph edges and repulsion via negative
sampling. The ideal fuzzy-set cross-entropy is

$$\sum_{i<j}\left[p_{ij}\log\frac{p_{ij}}{q_{ij}}+
(1-p_{ij})\log\frac{1-p_{ij}}{1-q_{ij}}\right].$$

The installed package performs the actual numerical optimization; this wrapper
does not implement an alternative UMAP or report the ideal expression as an
exact optimized loss. See the [UMAP paper](https://arxiv.org/abs/1802.03426)
and [parameter guide](https://umap-learn.readthedocs.io/en/latest/parameters.html).

| Analysis option | Default / meaning |
| --- | --- |
| `nNeighbors` | 100; capped at number of points minus 1, with warning. Current MATLAB wrapper accepts integers 3–199. Larger values emphasize broader neighborhoods. |
| `minDist`, `spread` | 0.1, 1; control embedding compactness. Require `0 < minDist <= spread <= 10` for this backend. |
| `metric` | `'correlation'`; also `'euclidean'`, `'cosine'`. |
| `nEpochs` | 500 optimizer epochs. |
| `randomize` | false; the package uses its fixed default RNG seed, with one optimization worker. Caller RNG and warning settings are restored. True allows stochastic reruns; this wrapper does not expose a numeric seed. |
| `init` | `'spectral'` (default) or `'random'`. Random initialization avoids spectral eigensolver degeneracy on small/disconnected graphs and remains reproducible when `randomize=false`. |
| `backendMethod` | `'MEX'`; use `'MATLAB'` for the package's slower MATLAB optimizer. |
| `time`, `timeWindow` | Explicit time vector overrides `(frame-eventFrame)/frameRate`; window restricts all preparation and fitting. |
| `normalization` | `'none'`, `'zscore'`, or `'rms'`, as defined above. |
| `missingAnimal`, `dropNonfiniteNeurons` | `'exclude'`, true; alternatives stop instead. |
| `animalLabels` | Optional unique label for each input animal column. |
| `diagnosticNeighbors` | 10, capped below half the number of points. Independent of UMAP's graph neighborhood size. |
| `maxDiagnosticPoints` | 2000; larger datasets skip exact quadratic-memory diagnostics. `[]` removes this limit. |

Reproducibility is within the same package/environment, not a promise of identical
coordinates across backend versions/platforms. Keep the external package version
with published analyses. Compare neighborhood sizes, metrics, and stochastic
reruns before interpreting a pattern; rotating/reflected embeddings are equivalent.

## Metrics: embedding fidelity, not explained variance

`diagnostics.neighborOverlap` is

$$\frac1P\sum_i\frac{|N_k^X(i)\cap N_k^Y(i)|}{k}.$$

The input uses the configured neural-space metric; the embedding uses 2D Euclidean
distance. Values range from 0 to 1, with 1 retaining every evaluated neighbor.

`diagnostics.trustworthiness` penalizes false neighbors introduced by the embedding:

$$T(k)=1-\frac{2}{Pk(2P-3k-1)}\sum_i\sum_{j\in U_k(i)}(r_X(i,j)-k).$$

$U_k(i)$ contains output neighbors absent from input neighbors; $r_X(i,j)$ is the
input-distance rank (nearest nonself point has rank 1). Higher values, up to 1,
indicate fewer severe false neighbors. See the
[trustworthiness definition](https://scikit-learn.org/stable/modules/generated/sklearn.manifold.trustworthiness.html).
Ties follow stable point order. Duplicate/near-duplicate vectors and temporally
adjacent bins can inflate local agreement. The metrics do not use condition labels,
do not establish task/action separation, and do not give p-values.

UMAP does **not** yield fixed neuron-weight axes, a linear explained-variance ratio,
or intrinsic task/action angles. Separated clouds are exploratory: nonlinear
embedding can change global distances, densities, and apparent gaps. Trial means
remove trial noise from this display and do not quantify single-trial decoding.
Use the [linear geometry analysis](../taskActionGeometry/README.md) for its explicitly
defined weight/variance metrics. Validate nonlinear claims in the original neural
space or with held-out data; points at adjacent time bins are not independent trials.

## Outputs and plots

| Field | Shape / purpose |
| --- | --- |
| `embedding` | Point × 2 UMAP coordinates. |
| `populationVectors` | Point × pooled-neuron trial means actually passed to UMAP. |
| `pointInfo` | Point, condition, selected-time and original-frame indices, plus seconds. Time varies fastest within each condition. |
| `pointLabels` | Condition-table row replicated for each time bin, aligned to embedding rows. |
| `neurons` | Feature-column mapping: animal index, animal label, original neuron row. |
| `animalAudit`, `trialCounts` | Exclusions, dropped-neuron counts, contributing raw trial counts. |
| `normalization` | Method and retained neurons' offsets/scales. |
| `backend` | Package and MATLAB versions, entry-point path, optimizer, effective neighbor count, dimensions, randomization and epochs. |
| `diagnostics` | Neighbor overlap, trustworthiness, neighborhood size, computed/skipped status. |
| `cfg`, `conditions`, `variables`, `time` | Reproducible analysis setup and labels. |
| `plotFiles` | Saved PNG paths. No figure handles, raw trial arrays, or UMAP model object in the first output. |

The single grouped figure reuses exactly the same coordinates, axis limits, and
aspect ratio in every panel. Colors change according to `plotCfg.colorBy`; they
never cause a refit. A final time panel (`plotCfg.showTime=true` by default) colors
all points by time within the trial in seconds, using one continuous blue-to-yellow
scale regardless of condition, task, or action. The usual four panels use a 2-by-2
layout. Set `showTime=false` to omit the final panel.
`connectTime=true` adds within-condition connecting lines in the label panels;
lines do not assert that UMAP preserves velocity or temporal order.

```matlab
plotCfg.colorBy=["conditionName","action","task"];
plotCfg.connectTime=true;
plotCfg.visible=false; plotCfg.savePath='B:\analysis\neuralEmbedding';
[figures,files]=fn_plotNeuralEmbedding(embedding,plotCfg);
save('embedding.mat','embedding');
```

`makePlot=false` skips rendering. Hidden exported figures are closed automatically.
Visible figure handles are returned separately as `figures.umap`. Replotting does
not require UMAP or the original trial arrays. Existing examples in other folders
are not modified.

## Implementation and checks

- `fn_neuralEmbeddingConfig.m`: own analysis/plot options, independent of linear geometry.
- `fn_analyzeNeuralEmbedding.m`: validation, trial means, pooling, one label-free
  `run_umap` call, point provenance, and fidelity diagnostics. It requests one
  backend output, avoiding optional clustering, templates, or model serialization.
- `fn_plotNeuralEmbedding.m`: rendering a saved result.
- `example_neuralEmbedding.m`: simple example using `intAct`.
- `tests/testNeuralEmbedding.m`: actual-backend integration, label independence,
  point/animal mapping, windowing, normalization, missing data, and hidden export.

```matlab
results=runtests('analysis/taskActionGeometryEmbedding/tests');
assertSuccess(results);
```

The integration tests are skipped if `run_umap` is absent; input-validation tests
still run. Test the dependency separately on any new MATLAB/platform installation.
