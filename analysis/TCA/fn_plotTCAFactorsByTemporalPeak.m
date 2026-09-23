function [componentOrder, peakFrame] = fn_plotTCAFactorsByTemporalPeak(model, varargin)
% fn_plotTCAFactorsByTemporalPeak Plot TCA factors ordered by temporal peak.
%
%   componentOrder = fn_plotTCAFactorsByTemporalPeak(model)
%   [componentOrder, peakFrame] = fn_plotTCAFactorsByTemporalPeak(model, ...)
%
% The temporal factor is model.U{2} by default. Components are sorted from
% earliest to latest temporal peak, then every factor matrix is plotted with
% rows in that same component order.

p = inputParser;
p.addParameter('factorLabels', {}, @(x) iscell(x) || isstring(x));
p.addParameter('temporalMode', 2, @(x) isnumeric(x) && isscalar(x));
p.addParameter('eventFrame', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x)));
p.addParameter('figureName', 'TCA factors sorted by temporal peak', @(x) ischar(x) || isstring(x));
p.parse(varargin{:});

factorLabels = cellstr(p.Results.factorLabels);
temporalMode = p.Results.temporalMode;
eventFrame = p.Results.eventFrame;

try
    factorCell = model.U;
catch
    error('Input model should be a fitted ktensor-like model with property or field U.');
end
if ~iscell(factorCell)
    error('Input model U should be a cell array of factor matrices.');
end
if temporalMode < 1 || temporalMode > numel(factorCell)
    error('temporalMode must be between 1 and the number of model modes.');
end

nMode = numel(factorCell);
nComponent = size(factorCell{temporalMode}, 2);
temporalFactor = factorCell{temporalMode};

[~, peakFrame] = max(temporalFactor, [], 1);
[~, componentOrder] = sort(peakFrame, 'ascend');

if isempty(factorLabels)
    factorLabels = arrayfun(@(x) sprintf('mode %d', x), 1:nMode, 'UniformOutput', false);
elseif numel(factorLabels) < nMode
    for modeIdx = (numel(factorLabels)+1):nMode
        factorLabels{modeIdx} = sprintf('mode %d', modeIdx);
    end
end

figure('Name', char(p.Results.figureName), 'Color', 'w');
for modeIdx = 1:nMode
    subplot(1, nMode, modeIdx);
    factorToPlot = factorCell{modeIdx}(:, componentOrder)';
    imagesc(factorToPlot);
    colorbar;

    factorClim = prctile(factorToPlot(:), [5 95]);
    if all(isfinite(factorClim)) && factorClim(2) > factorClim(1)
        clim(factorClim);
    end

    xlabel(factorLabels{modeIdx});
    ylabel('TC sorted by time peak');
    yticks(1:nComponent);
    yticklabels(arrayfun(@num2str, componentOrder, 'UniformOutput', false));
    title(sprintf('%s factor', factorLabels{modeIdx}));

    if modeIdx == temporalMode && ~isempty(eventFrame)
        xline(eventFrame);
    end
end
end
