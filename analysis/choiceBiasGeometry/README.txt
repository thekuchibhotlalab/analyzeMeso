Choice-bias geometry
====================
Run example_choiceBiasGeometry.m after editing animals and paths. It annotates
ani.trialInfo immediately after loading, BEFORE behavioral/neural filtering.
Saved Animal files are not overwritten. Standard session/tracking selection is
retained. This example includes all eight stimulus x actual-action combinations,
including errors, and disables RT filtering by default.

Behavior
--------
fn_addChoiceBias(T,40) adds choiceBias, choiceBiasT1/T2, choiceBiasAccL/R,
choiceBiasTask, choiceBiasBlock, choiceBiasBlockValue and choiceBiasBlockN.
Task is stimulus 1/2 vs 3/4, including interleaved sessions labelled Int.
Bias = left-stimulus accuracy minus right-stimulus accuracy. The calculation
matches fn_getAccBiasSmooth's centered indexing: a window ending at j is
assigned to j-20. Windows use 40 SAME-TASK trials within a session; the first
19 and last 20 task trials have undefined smooth bias. Sessions never mix.
responseType==1 is correct; 0/NaN is missed and omitted from accuracy denominators;
other response types are incorrect, exactly as in the existing helper. More
than 4 left and 4 right stimuli are required. Unlike the helper's returned
accuracy arrays, stored accuracies are not clipped to [.05,.95]. Bias agrees.
This is a descriptive centered behavioral measure, not a causal prediction of
future choice; the window contains the current and subsequent trials.

Neural analysis
---------------
Use dffChoice with choice onset at frame 31. Defaults average frames
1:15 (pre-trial ITI window), and 28:30 (3 strictly pre-choice frames).
Both windows are choice-aligned: ITI -2 to -1.067 s, pre-choice -0.2 to -0.067 s at 15 Hz. Configure itiFrames to change the ITI window. This fixed choice-relative window is not guaranteed to precede stimulus on every trial.
Per animal/task, fit balanced-covariance ridge LDA using choice-period averages
and actual L/R action labels. Stratified cross-validation projects every trial
with a model trained on OTHER trials. Training-only neuron standardization,
centering and projection noise scaling are saved in foldModels. Positive points
toward L; projection units are training within-class SD. A full-data model is
saved for inspection but NOT used for the plotted projections. Entire trials
are held out (all their frames), so ITI data never train the axes.
CV does not eliminate session drift or within-session dependence.
Neurons must have finite data in both windows across all retained trials;
animals/tasks lacking enough L/R trials are listed in animalAudit and skipped.

Figures
-------
1. Rows T1/T2; columns ITI/pre-choice. All valid trials with |smooth bias|
   > .4 or < .2 are drawn as faint traces, with trial-weighted group means.
   L is black/solid; R red/dashed; unbiased traces are lighter shades. Intermediate
   bias and undefined edge windows do not enter these two groups. showTrials=false
   suppresses individual curves. These pooled means are descriptive, not animal SEM.
2. Two scatter panels show L-minus-R projection separation against |bias|.
   Each point is an animal x task x non-overlapping FULL 40-trial behavioral block.
   Block bias is computed from all behavioral trials before neural filtering.
   At least minBinTrialsPerAction neural L and R trials must survive selection.
   Slopes and correlations remove animal-specific mean offsets. Lines are shown
   at the grand mean. Repeated blocks are not independent animals: no naive
   bin-level p-values are reported. biasMagnitude=false uses signed bias instead.

Outputs
-------
result.entries: trial metadata/provenance, fold IDs/models, full model, all
held-out traces, preProjection and choiceProjection per trial.
result.bins: bias, counts, and pre/choice separation per valid block.
result.regression: descriptive animal-adjusted slopes and correlations.
result.animalAudit: inclusion/counts and finite-neuron audit.
Plot savePath creates PNG, editable visible-on-reopen FIG and result MAT files.
Replot via fn_plotChoiceBiasGeometry(result,plotCfg). No source data are modified.

