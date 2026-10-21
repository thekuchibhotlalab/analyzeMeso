TASK / ACTION POPULATION GEOMETRY

Both main functions accept a simple 4 x nAnimal cell array and options from
fn_taskActionGeometryConfig(). Rows MUST be T1-left, T1-right, T2-left, T2-right.
Each entry is tracked-neuron x time x trials; trial counts may differ between
conditions/animals. All four entries within an animal must have the same neuron
identities in the same row order. All animals need the same time sampling and
alignment. One animal can be a four-element cell vector. For example:
  linear=fn_analyzeTaskActionSubspaces(intAct,opts);
  geometry=fn_analyzeTaskActionManifold(intAct,opts);
The new Int-only block at the end of step1_prepareNeuralData/example_prepareNeuralData.m
selects the four Int rows from tempAct by condition NAME, checking their dayLabel.
It never includes T1L or T1R/retraining trials. Your existing selection code stays
above that block. Set the actual frameRate/eventFrame and desired timeWindow.

RAW CELL INPUT / CONCATENATING ANIMALS
The functions fit condition means within each animal and concatenate along
NEURONS. No unrelated trials are paired, truncated, zero-filled or concatenated
as if their neuron identities were the same. Normalization is per neuron using
its own animal's training trials. Every split independently divides trials in
each animal/condition, then concatenates the training and test means separately.
Thus this is a pseudo-population; it measures reproducibility across trial halves,
not held-out animals or sessions. opts.splitUnit='auto' resolves to 'trial' here.
Session splitting requires session metadata and is rejected for raw cell input.
Noise covariance is block diagonal across animals; cross-animal correlations
cannot be observed. Animals with more retained neurons contribute more dimensions.
The pooled geometry is not evidence of a jointly recorded population trajectory.

result.conditionMeans is concatenated-neuron x selected-time x four conditions.
result.data.neurons maps rows to animalIndex, animalLabel, and rowInAnimal (the
row in the INPUT tracked-neuron array, not necessarily the original ROI number).
For the example, map it to original IDs through
allTrialsel{animalIndex}.tracking.selectedNeuronIDs(rowInAnimal).
data.trialsPerAnimal gives condition counts. Animals missing a condition or
having fewer than 2*minTrialsPerHalf trials in any condition are excluded with a
warning and a data.excludedAnimals record. Nonfinite neurons are also recorded.
cv.splits{s}.animals{a} records each included animal's train/test rows in its
condition-concatenated trial array; these are repeated splits, not independent CIs.
Raw cells contain no period/condition labels: subset those BEFORE calling, and
leave opts.dayLabels/conditionNames/neuronIDs empty. Defaults: eventFrame=31,
frameRate=15; these must match your data. Cell arrays already contain selected
neurons. Do not feed trial averages when requesting trial-based validation.

CURATED STRUCTURE INPUT (BACKWARD COMPATIBLE)
Both functions still accept the output of a.fn_prepareNeuralData(curated).
See example_expertTaskActionGeometry.m for that form. They never load MAT files.
opts.splitUnit='auto' resolves to 'session' for this metadata-rich input.

INPUT AND DEFINITIONS
The functions use neuralSelection.neuralRaw, the corresponding trial tables,
and tracking.selectedNeuronIDs. All time bins and conditions use the same
tracked neurons. Repeated sessionRec/trialInSession identities are deduplicated.
Neurons with ANY nonfinite sample in the selected window are removed and listed
in data.droppedNeuronIDs. Shorten the time window if padding removes too many.
data.counts reports the four cells: T1-left, T1-right, T2-left, T2-right.

taskDefinition='stimulusSet': S1/S2 versus S3/S4 (default).
taskDefinition='context': trialInfo.taskLabel T1 versus T2; other labels excluded.
These definitions differ for T1-stimulus probes presented in T2 context.
dayLabels and conditionNames optionally subset the already-selected trials.
timeWindow is seconds relative to alignedEventFrame. Set frameRate correctly.
The example restricts to Int; set dayLabels=[] to pool the supplied periods.

NORMALIZATION AND REPLICATION
Each neuron has ONE scale fitted over pooled training trials and time points,
reused on held-out data. zscore subtracts its pooled mean and divides by SD;
rms divides by sqrt(mean(activity.^2)); none preserves original units.
Four condition means enter the contrasts with equal weight. Trials/sessions
within a condition are not reweighted, so a session with more trials contributes
more to that condition mean. The output data.trials permits auditing this.
Session halves are the default independent partitions; time bins are correlated
observations along a trajectory, never independent CV replicates. If sessions
cannot be partitioned with all four cells represented, the code errors. Trial
splitting is available explicitly but cannot establish cross-session stability.
Repeated random splits overlap; their SD describes split sensitivity, NOT a CI.

LINEAR SUBSPACES: fn_analyzeTaskActionSubspaces
Let C1..C4 be neuron x time means in the cell order above. Define:
  task        = (C3+C4-C1-C2)/2
  action      = (C2+C4-C1-C3)/2
  interaction = (C1+C4-C2-C3)/2
  time        = 2*(grandMean - mean(grandMean, time))
For each contrast M, take M=U*S*V'. Columns of U are successive axes maximizing
captured marginal squared signal, constrained orthogonal WITHIN that factor.
Task and action bases are fit separately; overlap between them is allowed.
This is balanced factor-marginal SVD, inspired by demixed population analyses;
it is not the full dPCA optimization and does not optimize classification.

task/action.axes: neuron x retained axis; row IDs in data.neuronIDs.
task/action.trajectories: axis x time x four conditions.
variance: energies of all four marginals. Their sum equals the total squared
variation of the four condition means after removing each neuron's grand mean.
It is CONDITION-MEAN variance, not the variance of all single-trial activity.
task/action.varianceFraction: fraction of that factor's energy per ranked axis.
crossCapture: fraction of each column factor captured by each row factor basis.
cv.predictiveVariance: split x rank x [task, action, interaction]. For each rank:
  predicted test contrast = U_train*U_train'*M_train
  score = 1 - ||M_test - predicted||_F^2 / ||M_test||_F^2.
Negative values are valid and indicate worse prediction than a zero contrast.
Unavailable ranks have NaN. nComponents caps the number, not the true dimension.
With averageTime=true each binary contrast is a single vector and rank <=1.
Retain time to find additional axes as coding changes over a trial.

TRAJECTORY GEOMETRY: fn_analyzeTaskActionManifold
A time bin is a POINT in neuron-dimensional space; successive points form a
trajectory. Treating time bins as new neuron axes instead would answer a
different question. The analysis uses all neuron dimensions for distances.

Noise normalization estimates within-condition/time residual covariance from
training trials. Default diagonal uses residual variances, ignoring correlations.
shrinkage uses (1-lambda)*S + lambda*diag(S), then adds a relative ridge.
identity uses Euclidean distance in the chosen activity normalization.
For independent split means A,B and training-derived metric P=W'*W:
  D(i,j) = (A_i-A_j)' * P * (B_i-B_j) / nNeurons.
This is a crossvalidated squared distance (crossnobis with noise normalization).
It estimates separation with an interpretable zero under independent zero-mean
noise. Negative estimates are retained, not clipped. Session drift, imbalanced
conditions and nonstationary noise can violate those assumptions. Fitting the
metric from residuals is most justified when residuals and means are independent.

cv.rdm: averaged distance matrix for all condition/time points; points lists the
exact index order (all T1-left times, then T1-right, T2-left, T2-right).
cv.distanceByTime: 4 x 4 x time simultaneous-condition distances.
cv.factorEnergy: time x [task, action, interaction], crossvalidated inner products
of corresponding contrast vectors from the two halves, divided by nNeurons.
cv.actionGeneralization: average cross-split inner product between the action
contrast in T1 and in T2; positive values support shared directional action coding.
timeGeometry: descriptive full-data angles and energies. Across-task action angle
near 0 means parallel action coding; near 180 means reversal. Task/action angle
near 90 means orthogonality at that time. Zero-length vectors yield NaN angles.
taskActionOverlap: principal angles between separately fitted temporal bases;
0 degrees is overlap, 90 degrees is orthogonality. Mean squared cosine summarizes
overlap. The expected random-orientation overlap is also provided because high-
dimensional random directions are often nearly orthogonal.
Manifold basis axes and embedding axes are in noise-normalized coordinates;
metricTransform is W. taskBasis/actionBasis.neuronWeights = W'*axes project the
normalized activity before whitening. Linear and manifold angles need not match
because the latter includes noise weighting; use noiseMetric='identity' for
the same metric as the linear analysis.
interactionFraction: descriptive interaction energy / (task+action+interaction).
trajectoryShape: arc length and average tangent turning angle in full metric
space. These depend on sampling/smoothing and are descriptive, not intrinsic
manifold dimension estimates. embedding is PCA FOR DISPLAY ONLY; inference does
not use 2D/3D projected distances, UMAP or t-SNE.

INTERPRETATION
Factorized coding is supported by reliable task and action signals, parallel
action contrasts across tasks, low interaction, and separable subspaces.
Orthogonality alone is not enough; compare overlap for plausible retained ranks
and examine held-out results. An additive code can still have overlapping axes.
The expert correct-trial conditions couple stimulus identity and action: S1/S3
usually mean left, S2/S4 right. Thus 'action' here is an action-associated
contrast, not proof of motor choice coding. Include matched error trials to
disentangle action from stimulus. Likewise, late T1 versus late T2 comparisons
confound task with training period and often recording session. The Int example
reduces this confound. More general context/stimulus dissociation requires a
crossed design. These analyses are exploratory, not significance tests.

METHOD REFERENCES
Kobak et al. (2016), Demixed principal component analysis of neural population data.
https://elifesciences.org/articles/10989
Walther et al. (2016), Reliability of dissimilarity measures for multi-voxel pattern analysis.
https://www.diedrichsenlab.org/pubs/Walther_Neuroimage_2016.pdf

Run synthetic verification: runtests('analysis/taskActionGeometry/tests').
