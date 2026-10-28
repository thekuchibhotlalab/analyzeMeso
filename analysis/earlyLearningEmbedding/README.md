# Early-learning stimulus/reward embedding

This AC analysis fits **one unsupervised 2D UMAP and a shared PCA** to stimulus-evoked and
reward-period population responses as learning progresses. Inputs match
`example_stimRewardAlignment.m`: condition × animal activity cells containing
neuron × time × trial `dffStim`, condition definitions, and matching
`trialInfoNeural` cells.

Run [example_earlyLearningEmbedding.m](example_earlyLearningEmbedding.m).
Its loading section queries rewarded S1/L and S2/R trials in T1E, T1M, and T1L
from Animal objects, preserving a common tracked-neuron mask within each animal.
If these inputs are already loaded, run only the analysis section.

```matlab
[cfg,plotCfg]=fn_earlyLearningEmbeddingConfig();
cfg.response.animalLabels=string(animals);
cfg.response.phaseOrder=["T1E","T1M","T1L"];
cfg.response.stimulusOffsets=1:3;
cfg.response.rewardOffsets=3:4;
cfg.response.normalization='zscore'; % Or 'none' if input is already normalized.
cfg.nBins=30;
cfg.overlap=1/3;
cfg.umap.nNeighbors=15;
cfg.umap.minDist=0.1;
cfg.umap.metric='correlation';
cfg.umap.init='random'; % Fixed RNG by default; no label-dependent initialization.
[learningEmbedding,figures]=fn_analyzeEarlyLearningEmbedding( ...
    activity,selectionCfg,cfg,plotCfg,trialInfo);
```

## Response extraction

The preparation function calls `fn_analyzeStimRewardAlignment` with plotting
disabled, reusing its trial filtering, event-frame indexing, shared per-neuron
normalization, and phase/source-trial ordering. It does not load any neural files
itself. Only `responseType==1` trials contribute. By default:

```text
stimulus onset index e = 31
choiceIndex(r) = e + responseFrame(r) - stimulusFrame(r)
S(n,r) = mean(X(n, e + [1 2 3], r))
R(n,r) = mean(X(n, choiceIndex(r) + [3 4], r))
```

`cfg.response` controls the same frame offsets, metadata field names, phase
order, stimulus IDs, normalization, and optional baseline subtraction as
[stimulus/reward alignment](../earlyLearningProgression/README.md#ac-stimulusreward-alignment).
The reward-period response is a **choice-threshold-relative proxy**, not a
window relative to recorded reward delivery. Shared z-scoring pools all finite
time/trial samples of all supplied conditions for each neuron. No second
normalization is applied by UMAP: leave `cfg.umap.normalization='none'`.

## Thirty overlapping learning chunks

For each animal and stimulus independently, concatenate rewarded trials in
`cfg.response.phaseOrder`, then sort by `sourceTrialRow` within each phase.
All selected trials contribute to defining the learning sequence; selection
filters still apply. Chunks can span phase boundaries.

Let N be the number of selected rewarded trials, K the number of chunks, and
o the fractional overlap. Continuous window width and step are:

```text
width = N / (1 + (K-1)*(1-o))
step  = (1-o) * width
first(b) = round((b-1)*step) + 1
last(b)  = round((b-1)*step + width)
```

Thus the first window begins at trial 1 and the last ends at N. With K=3,
o=1/3, N=140, windows are 1–60, 41–100, and 81–140: exactly 20/60 overlap.
For K=30, o=1/3, width is about N/20.33. Integer rounding makes actual overlap
approximate; every exact range and actual overlap is saved in `windows`.

Average stimulus and reward responses within each chunk using **the same finite
trial pairs for each neuron**. `cfg.minTrialsPerBin=2` requires at least two
paired observations per neuron/chunk. Invalid event windows stay at their trial
positions and cannot shift the windows. No trials are duplicated to fill gaps;
intentional overlap reuses trials across neighboring chunks.

## Pooled neural space and embedding points

There are **30 chunks × 2 stimuli × 2 response periods = 120 points**, not 120
individual raw trials. Each point is a chunk-averaged population vector. For a
fixed stimulus/response/chunk, concatenate the neuronal values from each included
animal into a single vector. Fit one UMAP to the resulting:

```text
populationVectors: 120 points × total retained neurons across animals
```

Neurons remain distinct features across animals; they are not matched to one
another. Each animal's chunk b represents the same **relative position within
its selected learning sequence**, not a simultaneous trial, identical absolute
trial number, or necessarily the same learning phase. Animals with more retained
neurons contribute more dimensions. A fixed neuron population is used for every
embedding point.

An animal must supply all requested stimuli and distinct usable windows.
`cfg.missingAnimal='exclude'` omits animals that cannot; `'error'` stops instead.
Neurons with insufficient finite observations in any stimulus/event/chunk are
dropped across all points. Animals with no remaining neurons are excluded.
`animalAudit`, `trialCounts`, and `validTrialCounts` document these decisions.

The UMAP fit reuses `fn_analyzeNeuralEmbedding` from
`taskActionGeometryEmbedding`, including its backend validation, deterministic
mode, RNG restoration, and local-neighborhood diagnostics. Condition labels do
not enter the fit. This analysis defaults to `cfg.umap.init='random'` with
`randomize=false` (fixed backend seed). This avoids the installed backend's
spectral initialization instability observed for small/disconnected synthetic
chunk graphs. `'spectral'` remains available and is the unchanged default in the
older embedding analysis. All three subplots display **identical coordinates**:

1. Colored by S1 versus S2.
2. Colored continuously by learning chunk, early to late.
3. Colored by stimulus versus reward response period.

`plotCfg.connectBins=true` draws four trajectories (stimulus × response period)
and circles their first chunks. Overlapping windows naturally smooth trajectories
and create dependent points. UMAP spacing is a visualization of neighborhood
structure, not a direct estimate of neural distance or independent trial-level
evidence of learning.

## PCA comparison

PCA uses the exact same `populationVectors` as UMAP: rows are chunk means and
columns are pooled neurons. It centers each neuron across all stimulus, reward,
and learning-chunk points, without any additional scaling. For centered input
`X = populationVectors - mean(populationVectors,1)`, the economy SVD is
`X = U*S*V'`. The first three columns of `V` are unit, orthogonal neural weights,
and `X*V(:,1:3)` gives the plotted projections. Each PC's explained percentage is
`100 * S(k,k)^2 / sum(diag(S).^2)`, relative to total variance of these chunk
means, not single-trial variance. UMAP's correlation distance is not used by PCA.

`figures.pca` contains PC1–PC2, PC1–PC3, and PC2–PC3 in one figure. Color identifies
stimulus and marker identifies stimulus/reward period. Endpoint numbers identify
the first and last learning chunks; `connectBins` controls trajectory lines.
Axis labels include explained percentages. `plotCfg.showPCA=false` hides this
figure while retaining the PCA results. With fewer than three input dimensions,
unavailable PC pairs are marked accordingly. Zero-variance data have undefined
explained percentages. Previously saved results without PCA still replot their
UMAP; rerun the analysis to add PCA.

## Dependencies and outputs

Add these repository folders to the MATLAB path:

```matlab
addpath('analysis/earlyLearningEmbedding');
addpath('analysis/earlyLearningProgression');
addpath('analysis/taskActionGeometryEmbedding');
```

Use the same MATLAB `run_umap` installation as the existing embedding analysis;
see its [setup instructions](../taskActionGeometryEmbedding/README.md#install-and-run).
There is no automatic installation or replacement with another embedding method.

Useful fields in `learningEmbedding`:

- `embedding`: point × 2 coordinates.
- `pca`: `scores` (point × up to 3 PCs), `weights` (pooled neuron × PC), `mean`
  (centering vector), `latent`, `totalVariance`, and `explained` (percent).
- `populationVectors`: exact point × pooled-neuron input to UMAP.
- `pointInfo`: stimulus, response period, learning chunk, and relative progress
  for each row. Chunk varies fastest, then response period, then stimulus.
- `neurons`: original animal and input neuron row for each feature column.
- `windows{stimulusIndex,animalIndex}`: exact trial ranges, counts, actual overlap,
  and start/end phase labels.
- `trialMap{stimulusIndex,animalIndex}`: original condition/trial/source-row
  identities in the sorted rewarded-trial sequence.
- `validTrialCounts{stimulusIndex,animalIndex}`: input neuron × chunk counts.
- `trialCounts`, `animalAudit`, `normalization`: data availability and preprocessing.
- `backend`, `embeddingConfig`, `diagnostics`: UMAP settings and neighborhood checks.

Inspect the prepared vectors without fitting UMAP:

```matlab
prepared=fn_prepareEarlyLearningEmbedding(activity,selectionCfg,cfg,trialInfo);
```

Figure handles stay separate from data. Hidden PNG export and replotting:

```matlab
plotCfg.visible=false;
plotCfg.savePath='B:\analysis\earlyLearningEmbedding';
[figures,files]=fn_plotEarlyLearningEmbedding(learningEmbedding,plotCfg);
save('earlyLearningEmbedding.mat','learningEmbedding');
```

PNG export writes both `_umap.png` and `_pca.png` by default. PCA uses base MATLAB
`svd`; it adds no toolbox dependency.
