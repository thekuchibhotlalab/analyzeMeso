Run plotTCA_components.m. It loads PPC from TCA-nonneg_allAni.mat and, when
available, AC from TCA-nonneg_allAni_CA.mat in B:\analysis\TCA2026_concat.
Absent AC data are skipped; PPC plotting remains available.

Set the options before running, or edit the defaults in the script:
  tcaPlotOptions=struct();
  tcaPlotOptions.ppcModel=7;
  tcaPlotOptions.ppcComponents=[5 6];
  tcaPlotOptions.acModel=6;
  tcaPlotOptions.acComponents=[2 8];
  tcaPlotOptions.ppcGroups={[5 6],[1 3 8]};
  tcaPlotOptions.acGroups={[2 8]};
  tcaPlotOptions.visible=false;
  plotTCA_components

Model numbers are cell indices in M, not component counts. The current fit
routine uses ranks 1:2:15, so model index 7 has 13 components. Component IDs
are the original factor-column indices. Matching is manual by list position:
PPC 5 overlays AC 2 in row 1; PPC 6 overlays AC 8 in row 2. Both lists must
have equal length if AC is present. Groups can have any number of components
and are independent of the matched-component lists. Use {} to omit grouped
plots or [] component lists to omit the matched plot.

Every component row contains:
  1. All TC weights (gray), with the selected component highlighted.
     AC and PPC weight profiles are stacked separately when both are loaded.
  2. Temporal factors, overlaid by region, split into closely spaced stimulus-
     and choice-aligned segments with separate time axes and a shared vertical scale.
  3. Learning factors: E, M, L, Int.
  4. Action factors: L, R (mode 4).
  5. Task factors: T1, T2 (mode 5).
Area colors come from multitaskColors('AC') and multitaskColors('PPC').
All axis ticks point outward. Mode sizes must be neuron x time x 4 x 2 x 2.

Grouped figures are separate for AC/PPC, one row per group. All selected TC
weights are highlighted on the left. Individual factor curves are gray; the
colored curve is their arithmetic mean with equal weight per component.
Action and task weights are sorted descending WITHIN each component before
averaging: Preferred, Unpreferred. This shows selectivity strength, not a
common action/task identity. Ties have no preferred category (NaN in output).
The preferredAction and preferredTask output arrays retain original category
IDs (1=L/T1, 2=R/T2). Gray curves are components, not SEM or animal replicates.
Components are grouped manually; no automatic clustering is performed.

CP factors have arbitrary multiplicative scaling. For consistent overlays and
group averages, each factor column is L1-normalized (sums to 1) and all scale
is absorbed into lambda. This leaves the reconstructed tensor unchanged.
Left bars are lambda/sum(lambda), sorted by weight within each model; these
are relative component mass weights, NOT per-component variance explained.
Saved source models are never modified. Sorted bar-to-original-ID mappings
are stored in each weight axes UserData.

For the current crop 21:50, stimFrame=10 and choiceFrame=16. The left temporal
segment contains frames 1:12 (through stimulus +2), and the right contains
frames 13:30 (starting at choice -3). Each segment is aligned to its own event;
no line connects the two segments. Each horizontal axis shows seconds from
its own event onset (stimulus or choice); vertical axes are hidden.
Both segments use the same horizontal time scale, with a two-frame-width
blank gap between their plotting areas. Coordinates are seconds relative to
each event, using tcaPlotOptions.frameRate (default 15 Hz). Segment widths
are proportional to their frame counts, rather than equal-width panels.
The concatenation is not continuous elapsed time. Change these options
for another crop/alignment; AC and PPC must use the same time bins.

Outputs default to B:\analysis\TCA2026_concat\component_figures:
  tca_matched.png/.fig
  tca_groups_PPC.png/.fig and tca_groups_AC.png/.fig when available
  tca_factors_REGION.png/.fig (heatmaps with separate action/task dimensions)
  tca_diagnostics_REGION.png/.fig (weights, neural correlation, model VE)
  tca_component_summary.mat (normalized factors, selections and group means)
Set showDiagnostics=false to omit diagnostic/heatmap figures. Other options:
savePath, fontSize, rowHeight, figureWidth, stimFrame, choiceFrame.
Function entry point: fn_plotTCAComponents(ppcLoadedStruct,acLoadedStruct,opts).
