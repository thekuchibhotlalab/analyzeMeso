function stats = fn_plotTCNeuralSelectivityProfile(modelOrWeights, varargin)
%FN_PLOTTCNEURALSELECTIVITYPROFILE Plot single-vs-mixed TC neural selectivity.
%
% For each neuron, this function sorts its neural-factor weights across TCs
% from largest to smallest, then plots the average sorted profile with SEM.
% A sharp drop from rank 1 to rank 2 suggests more single-TC selectivity;
% a flatter profile suggests mixed selectivity across multiple TCs.
%
% Usage:
%   stats = fn_plotTCNeuralSelectivityProfile(M{nModel});
%   stats = fn_plotTCNeuralSelectivityProfile(M);              % uses last non-empty M entry
%   stats = fn_plotTCNeuralSelectivityProfile(M, 'nModel', 14);
%   stats = fn_plotTCNeuralSelectivityProfile(M{10}, M{14});
%   stats = fn_plotTCNeuralSelectivityProfile(M1, M2, 'modelLabels', {'model 1','model 2'});
%   stats = fn_plotTCNeuralSelectivityProfile(M{14}, 'normalizeNeuron', true);
%   stats = fn_plotTCNeuralSelectivityProfile(M{14}, 'includeLambda', true);
%
% Input can be:
%   1) a ktensor-like model with U{1} or u{1}
%   2) a cell array M; by default the last non-empty entry is used, or
%      'nModel' selects M{nModel}
%   3) a neuron x TC numeric matrix of neural weights
%
% By default, each neuron's sorted weights are normalized by that neuron's
% total neural weight across all TCs, so the plotted y-axis is a fraction.

compareModel = [];
if ~isempty(varargin) && ~isParameterName(varargin{1})
    compareModel = varargin{1};
    varargin(1) = [];
end

p = inputParser;
p.addParameter('nModel', [], @(x) isempty(x) || (isscalar(x) && x >= 1));
p.addParameter('nModelCompare', [], @(x) isempty(x) || (isscalar(x) && x >= 1));
p.addParameter('compareModel', [], @(x) true);
p.addParameter('modelLabels', {}, @(x) iscell(x) || isstring(x));
p.addParameter('useAbs', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('normalizeNeuron', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('normalization', 'sum', @(x) ischar(x) || isstring(x));
p.addParameter('includeLambda', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('plotIndividual', false, @(x) islogical(x) || isnumeric(x));
p.addParameter('lineColor', [0.15 0.15 0.15], @(x) isnumeric(x) && numel(x) == 3);
p.addParameter('lineColors', [0.12 0.35 0.75; 0.80 0.25 0.20], @(x) isnumeric(x) && size(x, 2) == 3);
p.addParameter('figureName', 'TC neural selectivity profile', @(x) ischar(x) || isstring(x));
p.parse(varargin{:});

useAbs = logical(p.Results.useAbs);
normalizeNeuron = logical(p.Results.normalizeNeuron);
includeLambda = logical(p.Results.includeLambda);
plotIndividual = logical(p.Results.plotIndividual);
normalization = lower(string(p.Results.normalization));

if ~isempty(p.Results.compareModel)
    compareModel = p.Results.compareModel;
end

if useAbs
    weightLabel = 'abs neural weight';
else
    weightLabel = 'neural weight';
end

profile1 = buildProfile(modelOrWeights, p.Results.nModel, includeLambda, useAbs, ...
    normalizeNeuron, normalization);

if isempty(compareModel)
    profiles = profile1;
    labels = {profile1.sourceLabel};
    lineColors = p.Results.lineColor;
else
    profile2 = buildProfile(compareModel, p.Results.nModelCompare, includeLambda, useAbs, ...
        normalizeNeuron, normalization);
    profiles = [profile1, profile2];
    labels = cellstr(p.Results.modelLabels);
    if isempty(labels)
        labels = {profile1.sourceLabel, profile2.sourceLabel};
    elseif numel(labels) == 1
        labels{2} = profile2.sourceLabel;
    end
    lineColors = p.Results.lineColors;
end

figure('Name', char(p.Results.figureName), 'Color', 'w');
hold on
legendHandles = gobjects(1, numel(profiles));
maxComponent = 0;

for iProfile = 1:numel(profiles)
    thisProfile = profiles(iProfile);
    thisColor = lineColors(min(iProfile, size(lineColors, 1)), :);
    nComponent = numel(thisProfile.meanSortedWeight);
    maxComponent = max(maxComponent, nComponent);

    if plotIndividual
        plot(1:nComponent, thisProfile.sortedWeightToPlot', '-', ...
            'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
    end

    legendHandles(iProfile) = errorbar(1:nComponent, thisProfile.meanSortedWeight, ...
        thisProfile.semSortedWeight, 'o-', ...
        'Color', thisColor, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerEdgeColor', thisColor, ...
        'LineWidth', 2, ...
        'CapSize', 8);
end

box off
xlim([0.5 maxComponent + 0.5]);
xticks(1:maxComponent);
xlabel('Within-neuron TC weight rank');
ylabel(profiles(1).yLabelText);
title('Sorted neural TC weights', 'Interpreter', 'none');
legend(legendHandles, labels(1:numel(profiles)), 'Location', 'northeast', 'Interpreter', 'none');

if numel(profiles) == 1
    stats = profiles;
else
    stats = struct();
    stats.model1 = profile1;
    stats.model2 = profile2;
end

for iProfile = 1:numel(profiles)
    fprintf('%s: n=%d neurons, mean single-TC fraction rank1/sum = %.3f +/- %.3f SEM\n', ...
        labels{iProfile}, profiles(iProfile).nNeuron, ...
        profiles(iProfile).meanSingleTCIndex, profiles(iProfile).semSingleTCIndex);
    fprintf('%s: mean rank2/rank1 ratio = %.3f +/- %.3f SEM\n', ...
        labels{iProfile}, profiles(iProfile).meanTop2Ratio, profiles(iProfile).semTop2Ratio);
end
end

function tf = isParameterName(x)
tf = ischar(x) || (isstring(x) && isscalar(x));
end

function profile = buildProfile(modelOrWeights, nModel, includeLambda, useAbs, normalizeNeuron, normalization)
[neuralWeight, sourceLabel] = getNeuralWeightMatrix(modelOrWeights, nModel, includeLambda);
neuralWeight = double(neuralWeight);

if useAbs
    neuralWeightForSort = abs(neuralWeight);
    weightLabel = 'abs neural weight';
else
    neuralWeightForSort = neuralWeight;
    weightLabel = 'neural weight';
end

validNeuron = any(isfinite(neuralWeightForSort), 2);
neuralWeightForSort = neuralWeightForSort(validNeuron, :);

if isempty(neuralWeightForSort)
    error('No valid neurons found in the neural weight matrix.');
end

[sortedWeight, componentOrder] = sort(neuralWeightForSort, 2, 'descend', 'MissingPlacement', 'last');

if normalizeNeuron
    switch normalization
        case "sum"
            denom = sum(sortedWeight, 2, 'omitnan');
            normLabel = 'fraction of total neural weight';
        case "max"
            denom = max(sortedWeight, [], 2, 'omitnan');
            normLabel = 'normalized by neuron max';
        case {"l2", "norm"}
            denom = sqrt(sum(sortedWeight.^2, 2, 'omitnan'));
            normLabel = 'L2 normalized per neuron';
        otherwise
            error('Unknown normalization "%s". Use ''sum'', ''max'', or ''l2''.', normalization);
    end

    denom(~isfinite(denom) | denom == 0) = NaN;
    sortedWeightToPlot = sortedWeight ./ denom;
    yLabelText = sprintf('%s, %s', weightLabel, normLabel);
else
    sortedWeightToPlot = sortedWeight;
    yLabelText = weightLabel;
end

nNeuron = size(sortedWeightToPlot, 1);
meanSortedWeight = mean(sortedWeightToPlot, 1, 'omitnan');
stdSortedWeight = std(sortedWeightToPlot, 0, 1, 'omitnan');
nPerRank = sum(isfinite(sortedWeightToPlot), 1);
semSortedWeight = stdSortedWeight ./ sqrt(nPerRank);

if size(sortedWeightToPlot, 2) >= 2
    singleTCIndex = sortedWeightToPlot(:, 1) ./ sum(sortedWeightToPlot, 2, 'omitnan');
    top2Ratio = sortedWeightToPlot(:, 2) ./ sortedWeightToPlot(:, 1);
else
    singleTCIndex = ones(nNeuron, 1);
    top2Ratio = nan(nNeuron, 1);
end

profile = struct();
profile.sourceLabel = sourceLabel;
profile.neuralWeight = neuralWeight;
profile.sortedWeight = sortedWeight;
profile.sortedWeightToPlot = sortedWeightToPlot;
profile.componentOrder = componentOrder;
profile.meanSortedWeight = meanSortedWeight;
profile.semSortedWeight = semSortedWeight;
profile.nPerRank = nPerRank;
profile.nNeuron = nNeuron;
profile.singleTCIndex = singleTCIndex;
profile.meanSingleTCIndex = mean(singleTCIndex, 'omitnan');
profile.semSingleTCIndex = std(singleTCIndex, 0, 'omitnan') ./ sqrt(sum(isfinite(singleTCIndex)));
profile.top2Ratio = top2Ratio;
profile.meanTop2Ratio = mean(top2Ratio, 'omitnan');
profile.semTop2Ratio = std(top2Ratio, 0, 'omitnan') ./ sqrt(sum(isfinite(top2Ratio)));
profile.validNeuron = validNeuron;
profile.yLabelText = yLabelText;
end

function [neuralWeight, sourceLabel] = getNeuralWeightMatrix(modelOrWeights, nModel, includeLambda)
sourceLabel = 'model';

if isnumeric(modelOrWeights)
    neuralWeight = modelOrWeights;
    sourceLabel = 'neural weight matrix';
    return
end

model = modelOrWeights;
if iscell(modelOrWeights)
    if isempty(nModel)
        nModel = find(~cellfun(@isempty, modelOrWeights), 1, 'last');
        if isempty(nModel)
            error('Input cell array M is empty.');
        end
        fprintf('No nModel provided; using last non-empty model M{%d}.\n', nModel);
    end
    model = modelOrWeights{nModel};
    sourceLabel = sprintf('M{%d}', nModel);

    if iscell(model)
        nestedModelIdx = find(~cellfun(@isempty, model), 1, 'last');
        if isempty(nestedModelIdx)
            error('%s is an empty nested cell array.', sourceLabel);
        end
        model = model{nestedModelIdx};
        sourceLabel = sprintf('%s{%d}', sourceLabel, nestedModelIdx);
        fprintf('Selected nested model %s.\n', sourceLabel);
    end
end

[factorCell, factorName] = getFactorCell(model);
if ~iscell(factorCell) || isempty(factorCell)
    error('Model factor field should be a non-empty cell array of factor matrices.');
end

neuralWeight = factorCell{1};

if includeLambda
    [hasLambda, lambda] = getOptionalModelValue(model, 'lambda');
    if hasLambda
        lambda = reshape(double(lambda), 1, []);
        if numel(lambda) ~= size(neuralWeight, 2)
            error('numel(model.lambda) does not match number of neural components.');
        end
        neuralWeight = neuralWeight .* lambda;
        sourceLabel = sprintf('%s lambda-scaled', sourceLabel);
    else
        error('includeLambda=true, but the model has no lambda field/property.');
    end
end

fprintf('Using neural factor %s.%s{1}, size [%d %d].\n', ...
    sourceLabel, factorName, size(neuralWeight, 1), size(neuralWeight, 2));
end

function [factorCell, factorName] = getFactorCell(model)
factorCell = [];
factorName = '';

try
    factorCell = model.U;
    factorName = 'U';
    return
catch
end

try
    factorCell = model.u;
    factorName = 'u';
    return
catch
end

if isstruct(model)
    if isfield(model, 'U')
        factorCell = model.U;
        factorName = 'U';
    elseif isfield(model, 'u')
        factorCell = model.u;
        factorName = 'u';
    end
end

if isempty(factorName)
    error('Input should be a fitted ktensor-like model with U/u factors, or a neuron x TC matrix.');
end
end

function [hasValue, value] = getOptionalModelValue(model, fieldName)
hasValue = false;
value = [];

try
    value = model.(fieldName);
    hasValue = true;
    return
catch
end

if isstruct(model) && isfield(model, fieldName)
    value = model.(fieldName);
    hasValue = true;
end
end
