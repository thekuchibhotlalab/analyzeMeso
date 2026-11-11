# Choice-decoding axes over learning

Run `example_learningChoiceAxes.m` after loading `allAni`, or use the three
functions directly:

```matlab
[cfg,plotCfg,selectionCfg]=fn_learningChoiceAxesConfig();
cfg.nT2Bins=10;                 % Or 5
cfg.windowWidthChunks=2;       % One-chunk steps, 50% interior overlap
cfg.decoder='lda';             % Or 'svm'
selectionCfg.neuralField='dffStimChoice'; % Or existing dffChoice
[selected,plan]=fn_prepareLearningChoiceData( ...
    ani.trialInfo,ani.sessionInfoBeh,ani.ops.sessionInfoName,selectionCfg,cfg);
[result,figures]=fn_analyzeLearningChoiceAxes(selected,cfg,plotCfg);
```

The example processes one animal at a time to release large neural arrays,
then combines the per-animal results for group plots. It saves PNG, FIG, CSV,
and the compact analysis/selection audits in `B:/analysis/learningChoiceAxes`.

## Alignment and trials

`dffChoice` uses frames **28:30**, offsets -3:-1 at 15 Hz. `dffStimChoice` uses
**33:35**, containing exactly those same source samples; choice onset is 36.
The three bins are averaged within each trial. Missing/nonfinite neural
features exclude that trial, with original row IDs recorded. No window-specific
neuron replacement is performed.

Task identity is defined by stimulus: S1/S2 = T1, S3/S4 = T2. Action is the
actual recorded 1/2 response, including both actions for each stimulus.
Task labels do not exclude occasional T1 probe trials during T2 training.
The selection cfg retains the usual RT/correct/miss controls. Default RT range
is inherited from `fn_T2E_Int_TrialSelectionConfig` (0.2–0.65 s); correct-only
filtering is off. Set `selectionCfg.requireCorrect=true` if required. Probe
and rewarded trials are both eligible. Choice decoding can reflect stimulus
information when stimulus and action are correlated; no stimulus-balanced
error-trial control is implied.

## Behavioral clock and tracking

Anchors are the first T2E and first Int rows in the original chronological
trialInfo. N equal chunks divide the row span between them. Row counts include
behavioral trials later excluded by RT, session quality, tracking, or neural
availability. Exclusion never compresses the learning clock.

Window centers are at chunk centers; width defaults to two chunks, with one
chunk between centers. Windows are clipped at the T2/Int boundaries and the
last trial. Therefore edge windows can be shorter, and T2 and Int windows do
not mix across their anchor. The first T2 window additionally includes T1
trials from the last T1L training date before the T2 anchor. The same chunk
width continues from Int until the end; a final partial bin is retained.
Change binning options before preparation, not after loading.

T1L, T2E/M/L, T1R, and Int labels define eligible sessions only; analysis
windows do not follow their phase boundaries. The tracker is run **once over
the full selected timeline per animal**, using existing ranking and prefix
selection cfg. Every window then uses the same common tracked-neuron IDs.
Tracking phase quotas remain selection controls, not analysis bins. Use
`selectionCfg.trackingMethod`, `sessionCountMethod`, `numSessions`, and existing
tracking options normally. Fewer sessions may improve the neuron intersection
but leave windows without data. These windows remain missing rather than
being moved or silently refilled. Anchors must exist even if their imaging
sessions are later excluded. Missing anchors or a preceding T1L day raise an
explicit error.

## Decoder and axes

Each animal, window, and task is decoded independently. L/R counts are
subsampled equally for each repeat; five stratified folds and five repeats are
the defaults. Each class needs at least max(minTrialsPerClass, 2*folds) trials.
If one task is insufficient, its results and the between-task angle are NaN;
the other task's accuracy and axis can still be retained.

All centering/scaling uses training trials only. LDA is a regularized
**diagonal-covariance** LDA; SVM is a linear `fitcsvm` classifier with fixed
BoxConstraint. No tuning uses held-out trials. Accuracy is class-balanced and
held out. Folds, sampled source trial rows, class counts, and missing-bin
status are stored for audit.

Decoder coefficients are transformed back to the original loaded neural
feature coordinates before unit normalization, so different windows are not
compared in different z-score spaces. Positive scores point toward R. Fold
unit normals are averaged and renormalized per repeat. For each repeat:

`cosine = wT1' * wT2`, `angleDegrees = acosd(cosine)`.

Cosines are signed: +1 means parallel with the same L/R orientation, 0 means
orthogonal, -1 means opposite. Angles summarize estimated training axes;
they are not held-out accuracy or an unbiased angle estimator. Constant or
undefined axes remain NaN. Per-window cosine/angle is averaged over repeats.
Repeat-consensus axes also give all-bin pairwise cosine matrices and cosine
relative to the first valid bin for each task. Reference bins are recorded;
they may differ if early T1 or T2 data are missing.

No axes are concatenated across animals. Group curves average scalar animal
metrics at matching T2/Int bin numbers. Group SEM uses animals; single-animal
SEM uses CV repeats. Group coverage is plotted. Different animals' bins have
different absolute trial counts because each is anchored to its own learning
duration. Overlapping windows reuse trials, and no independence-based tests
across bins or learning phases are performed.

## Main output

`result.animals{a}` contains:

- `windows`, `plan`, `counts`, `balancedTrialsPerClass`, `status`
- `neuronIDs`, `selectedSessions`, `invalidTrialRows`, `choiceFrames`
- `accuracy`, `accuracySEM`, `accuracyByRepeat`
- `axesByRepeat` (neurons x 2 tasks x bins x repeats), `consensusAxes`
- `cosine`, `cosineSEM`, `cosineByRepeat`, `angleDegrees`, `angleDegreesByRepeat`
- `temporalCosine{task}` (bin x bin), `referenceBin`, `cosineToReference`
- `trialRows` and `foldAssignments` (bin x task x repeat)

Group figures show accuracy, between-task axis cosine, drift from the first
valid bin, and animal coverage. Individual figures show accuracy/cosine with
CV-repeat SEM and the four available task/action trial counts.
