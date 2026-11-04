# Per-animal task/action decoding

This accuracy-only analysis uses the corrected `ziyiFunction/analysis/fn_runDecoder.m`.
Single neurons use binary LDA. Populations use **linear SVMs fitted separately
within each animal**, preserving simultaneous real-trial rows. There are no
cross-animal pseudo-trials or projection-axis fits here.

Start with [example_taskActionDecoding.m](example_taskActionDecoding.m) after
creating `intAct`, `intNames`, and `animals` with your existing loader. The loader
must request `cfg.neuralField='dffChoice'`, with choice at frame 31 (15 Hz).
`custom_code_LDA.m` is left unchanged. Its last section currently compares rows
2 and 4 (S2R versus S4R), which is a task comparison within R, rather than L/R
within T1. This analysis defines all comparisons explicitly using the table.

```matlab
addpath('analysis/taskActionDecoding');
addpath('../ziyiFunction/analysis');
conditions=table(string(intNames(:)),["L";"R";"L";"R"], ...
    ["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','action','task'});
[cfg,p]=fn_taskActionDecodingConfig();
cfg.animalLabels=string(animals);
cfg.topFractions=.05:.05:1;
[decoding,figures]=fn_analyzeTaskActionDecoding(intAct,conditions,cfg,p);
```

Input is condition x animal cells, each neuron x frame x trial. Rows must match
the condition table. For each trial and analysis window, **average its activity
across frames before fitting or evaluating any decoder**. This differs from the
earlier geometry decoder, which averaged per-frame accuracies. No trial averaging
is performed: every real trial remains one observation.

## Comparisons and figures

| Comparison | Classes | Frames averaged within each trial |
| --- | --- | --- |
| `choice_T1` | L versus R, only T1 trials | 28:30 |
| `choice_T2` | L versus R, only T2 trials | 28:30 |
| `task_preTrial` | T1 versus T2, pool L/R | 16:20 |
| `task_choice` | T1 versus T2, pool L/R | 28:30 |
| `task_postChoice` | T1 versus T2, pool L/R | 31:37 |
| `task_fullWindow` | T1 versus T2, pool L/R | 16:37 |

These are the exact requested frame indices. With frame 31 at zero, frame 16 is
-1 s, frame 37 is +0.4 s, and 31:37 contains seven samples (about 467 ms of bins).
The code uses the supplied frame indices rather than silently extending to +0.5 s.
Change `taskWindows` and matching `taskWindowNames` if needed.

By default, `cfg.balanceTaskActions=true` randomly subsamples without replacement
to equal L/R counts within each task and animal before task decoding: S1/S2 in
T1, and S3/S4 in T2 for the standard four-condition input. The two tasks can retain
different total trial counts; balanced accuracy and SVM class weights handle that
task-class imbalance. Selection uses labels/counts only and is reproducible from
`cfg.seed`; the same subset is used across all task windows and CV repeats.
It matches counts in the selected dataset; CV folds are stratified by task, so
exact L/R equality is not enforced separately within each fold. Choice decoding
continues to use all available trials. Set `cfg.balanceTaskActions=false` to pool
all trials as before. Inspect available and selected counts in
`decoding.fits{comparison,animal}.trialBalance`; `sourceClass1/sourceClass2`
map the retained trials to their original input conditions and trial indices.

- `choiceAccuracy`: same-neuron T1 versus T2 choice-accuracy scatter, colored by
  animal, and overlaid single-cell histograms. Pairs are matched by animal and
  original input neuron row, not by rank or independently sorted accuracy.
- `taskAccuracy`: four single-neuron accuracy histograms, one per task window.
- `populationSVM`: six panels with a separate held-out SVM subset curve per
  animal. X is the top-neuron percentage; set `p.populationXAxis='count'` for the
  actual number. Shading is SEM across repeated CV estimates.

Histogram/scatter plots concatenate cell results after fitting independently per
animal. They are descriptive cell distributions, not independent-animal tests.

## Corrected cross-validation and LDA math

The legacy `fn_runDecoder(X1,X2,.8)` call remains supported. Now `.8` specifies
five-fold CV: `percTrain=1-1/K` in general. Default `Repeats=5` produces 25 outer
splits. The two classes are partitioned separately, keeping each real trial and
all its neuron columns together. **Every trial is tested exactly once per
repeat**, including all trials of the larger class. No minimum-count truncation
or cross-animal trial pairing is used.

For a single neuron, learn class means and variances from the outer training set:

$$v_j=\tfrac12(s_{1j}^2+s_{2j}^2),\qquad
w_j=\frac{\mu_{1j}-\mu_{2j}}{v_j+\lambda},\qquad
h_j=\tfrac12(\mu_{1j}+\mu_{2j}).$$

This is equal-prior scalar LDA with an equal-class estimate of the shared variance.
The small ridge is `Ridge * max(mean(v),eps)`. Class 1 is predicted when
$w_j(x_j-h_j)>0$. Constant/no-signal neurons remain finite; exact ties score 0.5.
The main accuracy is balanced accuracy:

$$BA=\tfrac12\left(\frac{correct_1}{N_1}+\frac{correct_2}{N_2}\right).$$

Repeat accuracy pools held-out correct counts within each class across all folds
before applying this formula, so slightly different fold sizes receive the right
weight. Training accuracies are computed similarly and are descriptive only.
Mean and SEM use repeat-level estimates. Repeats reuse the same dataset, so this
SEM describes partition variability rather than a population confidence interval.

The former implementation had these problems:

1. It sampled only indices `1:min(N1,N2)`, excluding later trials of the larger class.
2. Shuffling the first `2*min(N1,N2)` concatenated rows could omit much of a class.
3. Zero variances could create Inf/NaN weights, and ties were counted as wrong in both classes.
4. `squeeze` changed the shape of `cellAcc` for one-neuron inputs.
5. The correlation-diagonal expression indexed repeated element 1 rather than masking the diagonal.
6. Population scoring summed independent scalar LDA scores, ignoring neuron covariance.

Single-cell LDA was otherwise the intended equal-prior mean/variance rule.
Importantly, selecting `max(decoder.cellAcc(:,2))` selects the winner using the
test scores. Its maximum is optimistic as an estimate of a prospectively chosen
best neuron, especially among many neurons. Population performance below that
maximum does not itself establish failure of Gaussian assumptions.

## Population SVM and top-neuron subsets

Within each outer training set, use three-fold **inner CV** to rank individual
neurons by balanced LDA accuracy. For every requested fraction, select
`ceil(fraction*nNeurons)` and fit a new linear SVM using all outer-training trials
and only those columns. SVM features are standardized using outer-training means
and SDs, then the same transform is applied to test trials. Class priors are
uniform, giving the two classes equal aggregate weight despite unequal trial
counts. The fixed `BoxConstraint=1` is configurable and is not optimized on test
accuracy. Details of class weighting are in the official
[fitcsvm documentation](https://www.mathworks.com/help/stats/fitcsvm.html).

All-neuron SVM is always included, even if `TopFractions` omits 1. The same outer
test observations evaluate every subset. Subsets are nested within a split;
their identities can vary between splits. When two percentages select the same
number of neurons, the fitted model is reused. No model is saved as a bulky SVM
object: weights and intercepts are converted back to raw activity coordinates.

$$z=(x-\mu_{train})/\sigma_{train},\quad
score=z^T\beta+b=x^Tw_{raw}+b_{raw},$$
$$w_{raw}=\beta/\sigma_{train},\quad b_{raw}=b-\mu_{train}w_{raw}.$$

The curve is **not forced to increase**. Extra features can provide useful
complementary signals, but noise, redundancy, finite training samples and fixed
regularization can cause plateaus or decreases. Ranking individual cells also
does not necessarily find the best joint subset. The ideal classifier could
ignore useless inputs; a finite-sample fitted SVM need not achieve that ideal.

## Output and options

```matlab
decoding.neurons     % Per-cell held-out accuracy/SEM, LDA weight/threshold, full SVM weight.
decoding.population  % Per-animal/per-window subset accuracy and SEM.
decoding.choicePairs % Matched cell accuracy in T1 and T2.
decoding.audit       % Trial counts, neuron counts, per-comparison inclusion/reason.
d=decoding.fits{1,1}.decoder;
d.cellAcc(:,2)       % Legacy API: one held-out accuracy per cell.
d.popAcc(2)          % All-neuron linear SVM accuracy.
d.population.weightsBySplit % neuron x fraction x split, raw coordinates; excluded features = 0.
d.cv.foldAssignments % {class1,class2}: original class-trial row x repeat -> held-out fold.
```

Each `fits{comparison,animal}` also stores original `neuronRows` and source tables
mapping class-trial rows to input condition and trial index. Raw neural arrays
and figure handles are not stored. Normalized/zero-filled coefficient averages
do not define an independently validated new decoder: reported accuracy always
comes from each split's own fitted model. Neuron identities differ between animals,
so their weight vectors are not averaged into a shared physical neuron axis.

Empty/insufficient comparisons are skipped independently; an animal with no T2-R
can still contribute to T1 choice. With task balancing enabled, either task missing
an action excludes that animal's task comparisons. With balancing disabled,
available task trials are pooled even when an action subcondition is empty.
Neurons with nonfinite reduced responses are excluded
per comparison, with the original row mapping retained. At least K trials per
class are required for K-fold CV.

`fn_runDecoder` name-value options: `Repeats`, `Seed`, `InnerFolds`, `TopFractions`,
`BoxConstraint`, `Ridge`, `Shuffle`, `Verbose`. `Shuffle=false` is the default to
avoid doubling runtime. When enabled, train/test pools stay disjoint and labels
are permuted independently within each pool while retaining both class counts.
Legacy shuffle fields remain present (empty when disabled). All training and test
accuracy arrays remain well shaped with one neuron. Private random streams and
restoration of the global RNG make calls reproducible without altering your RNG.

This analysis requires **MATLAB Statistics and Machine Learning Toolbox** for
`fitcsvm`, plus the updated `ziyiFunction/analysis/fn_runDecoder.m` on your path.
There is no UMAP dependency. The large default grid is six comparisons x animals
x 25 outer splits x 20 fractions; reduce `topFractions`/`repeats` for a quick check.

The separate [taskActionGeometry](../taskActionGeometry/README.md) code handles
axis projections. Set its `cfg.decode=false` for projection/variance analysis
without its older decoding figures. This new analysis never calls it.

```matlab
p.visible=false; p.savePath='B:\analysis\taskActionDecoding';
[figures,files]=fn_plotTaskActionDecoding(decoding,p); % No neural reload/refit.
results=runtests('analysis/taskActionDecoding/tests'); assertSuccess(results);
```
