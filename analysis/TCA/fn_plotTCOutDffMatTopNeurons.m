function [figHandles, topNeuronInfo] = fn_plotTCOutDffMatTopNeurons(outDffMat, M, nModel, varargin)
% fn_plotTCOutDffMatTopNeurons Plot top-neuron activity for TCA components.
%
%   [figHandles, topNeuronInfo] = fn_plotTCOutDffMatTopNeurons(outDffMat, M, nModel)
%
% Inputs:
%   outDffMat - neuron x time x stage x trialType matrix.
%   M         - cell array of ktensor models, or one ktensor-like model.
%   nModel    - model/rank index if M is a cell array. Use [] if M is one model.
%
% Name-value options:
%   'components'    - components to plot. Default: all components.
%   'topN'          - rank(s) among neurons assigned to this TC, sorted by
%                     this TC's neural weight. Default: 1:20.
%                     Example: 2 plots only the second strongest assigned
%                     neuron; 1:2 plots the mean +/- SEM of the top two
%                     assigned neurons.
%   'exclusiveOnly' - legacy switch. true uses best-component assigned
%                     neurons, which is the intended/default behavior.
%                     false uses global neural weights across all neurons.
%   'smoothWin'     - moving average over time. Default: 3 frames.
%   'eventFrame'    - event frame for x = 0. Default: 10.
%   'frameRate'     - imaging frame rate. Default: 15 Hz.
%   'xLim'          - x-axis limits. Default: [-0.5 1.4].
%   'stageLabels'   - stage labels. Default: {'E','M','L','Int'}.
%   'trialLabels'   - trial labels. Default: {'T1L','T1R','T2L','T2R'}.

p = inputParser;
addParameter(p,'components',[]);
addParameter(p,'topN',1:20);
addParameter(p,'exclusiveOnly',true);
addParameter(p,'smoothWin',3);
addParameter(p,'eventFrame',10);
addParameter(p,'frameRate',15);
addParameter(p,'xLim',[-0.5 1.4]);
addParameter(p,'yLim',[]);
addParameter(p,'stageLabels',{'E','M','L','Int'});
addParameter(p,'trialLabels',{'T1L','T1R','T2L','T2R'});
parse(p,varargin{:});

model = getModel(M,nModel);
factorCell = model.U;
neuralLoading = factorCell{1};

if size(outDffMat,1) ~= size(neuralLoading,1)
    error('fn_plotTCOutDffMatTopNeurons:NeuronCountMismatch', ...
        ['outDffMat contains %d neurons, but the TCA model contains %d. ' ...
        'Use activity and TCA results generated from the same neuron set.'], ...
        size(outDffMat,1),size(neuralLoading,1));
end

nComponent = size(neuralLoading,2);
components = p.Results.components;
if isempty(components)
    components = 1:nComponent;
end
components = components(:)';
if any(components < 1) || any(components > nComponent)
    error('fn_plotTCOutDffMatTopNeurons:InvalidComponent', ...
        'components must be between 1 and %d.',nComponent);
end

nStage = size(outDffMat,3);
nTrialType = size(outDffMat,4);
nTime = size(outDffMat,2);
timeAxis = ((1:nTime) - p.Results.eventFrame) ./ p.Results.frameRate;

stageLabels = p.Results.stageLabels;
if numel(stageLabels) < nStage
    stageLabels = arrayfun(@(x) sprintf('Stage %d',x),1:nStage,'UniformOutput',false);
end

trialLabels = p.Results.trialLabels;
if numel(trialLabels) < nTrialType
    trialLabels = arrayfun(@(x) sprintf('Trial %d',x),1:nTrialType,'UniformOutput',false);
end

trialColors = defaultTrialColors(nTrialType);

% Assign every neuron to the TC where its neural loading is largest. The
% plotted neurons are then ranked only within the target TC's assigned pool.
[~,bestComponentByNeuron] = max(neuralLoading,[],2);

figHandles = gobjects(numel(components),1);
topNeuronInfo = table('Size',[numel(components) 8], ...
    'VariableTypes',{'double','cell','cell','cell','cell','double','double','string'}, ...
    'VariableNames',{'Component','RankIdx','NeuronIdx','NeuronWeight', ...
    'AssignedComponent','NCandidate','NNeuron','SelectionMode'});

for iComp = 1:numel(components)
    componentToPlot = components(iComp);
    neuralWeight = neuralLoading(:,componentToPlot);

    if p.Results.exclusiveOnly
        candidateNeuronIdx = find(bestComponentByNeuron == componentToPlot);
        selectionMode = "bestComponentAssigned";
    else
        candidateNeuronIdx = (1:size(neuralLoading,1))';
        selectionMode = "globalWeight";
    end

    if isempty(candidateNeuronIdx)
        warning('TC %d has no candidate neurons. Skipping.',componentToPlot);
        continue
    end

    [sortedWeight,componentOrder] = sort(neuralWeight(candidateNeuronIdx),'descend');
    sortedNeuronIdx = candidateNeuronIdx(componentOrder);
    requestedRankIdx = unique(round(p.Results.topN(:)'),'stable');
    requestedRankIdx = requestedRankIdx(requestedRankIdx >= 1 & requestedRankIdx <= numel(sortedNeuronIdx));
    if isempty(requestedRankIdx)
        warning('TC %d has no valid requested rank indices. Skipping.',componentToPlot);
        continue
    end
    topNeuronIdx = sortedNeuronIdx(requestedRankIdx);
    topNeuronWeight = sortedWeight(requestedRankIdx);
    nTopNeuron = numel(topNeuronIdx);

    topNeuronActivity = outDffMat(topNeuronIdx,:,:,:);
    if p.Results.smoothWin > 1
        topNeuronActivity = smoothdata(topNeuronActivity,2,'movmean',p.Results.smoothWin);
    end

    topNeuronInfo.Component(iComp) = componentToPlot;
    topNeuronInfo.RankIdx{iComp} = requestedRankIdx;
    topNeuronInfo.NeuronIdx{iComp} = topNeuronIdx;
    topNeuronInfo.NeuronWeight{iComp} = topNeuronWeight;
    topNeuronInfo.AssignedComponent{iComp} = bestComponentByNeuron(topNeuronIdx);
    topNeuronInfo.NCandidate(iComp) = numel(candidateNeuronIdx);
    topNeuronInfo.NNeuron(iComp) = nTopNeuron;
    topNeuronInfo.SelectionMode(iComp) = selectionMode;

    figHandles(iComp) = figure('Color','w', ...
        'Name',sprintf('TC %d top-neuron activity',componentToPlot), ...
        'NumberTitle','off');
    plotAxes = gobjects(2,nStage);
    tl = tiledlayout(2,nStage,'TileSpacing','compact','Padding','compact');

    for stageIdx = 1:nStage
        plotAxes(1,stageIdx) = nexttile(tl,stageIdx);
        hold on
        plotTrialIfAvailable(timeAxis,topNeuronActivity(:,:,stageIdx,:),1,trialColors,trialLabels);
        plotTrialIfAvailable(timeAxis,topNeuronActivity(:,:,stageIdx,:),2,trialColors,trialLabels);
        xline(0,'k-'); yline(0,'k:');
        title(stageLabels{stageIdx});
        if stageIdx == 1
            ylabel('Task 1 activity');
        end
        xticklabels([]);
        box off

        plotAxes(2,stageIdx) = nexttile(tl,nStage+stageIdx);
        hold on
        plotTrialIfAvailable(timeAxis,topNeuronActivity(:,:,stageIdx,:),3,trialColors,trialLabels);
        plotTrialIfAvailable(timeAxis,topNeuronActivity(:,:,stageIdx,:),4,trialColors,trialLabels);
        xline(0,'k-'); yline(0,'k:');
        xlabel('Time (s)');
        if stageIdx == 1
            ylabel('Task 2 activity');
        end
        box off
    end

    if isempty(p.Results.yLim)
        allYLim = nan(numel(plotAxes),2);
        for axisIdx = 1:numel(plotAxes)
            allYLim(axisIdx,:) = ylim(plotAxes(axisIdx));
        end
        sharedYLim = [min(allYLim(:,1)) max(allYLim(:,2))];
        if ~all(isfinite(sharedYLim)) || diff(sharedYLim) == 0
            sharedYLim = [-0.5 0.5];
        end
    else
        sharedYLim = p.Results.yLim;
    end
    linkaxes(plotAxes(:),'xy');
    set(plotAxes,'XLim',p.Results.xLim,'YLim',sharedYLim);

    sgtitle(sprintf('TC %d: %s %s neurons (mean weight = %.3g)', ...
        componentToPlot,rankSelectionLabel(requestedRankIdx),selectionLabel(selectionMode), ...
        mean(topNeuronWeight,'omitnan')), ...
        'FontWeight','bold');
end
end


function model = getModel(M,nModel)
if iscell(M)
    if nargin < 2 || isempty(nModel)
        error('nModel is required when M is a cell array of models.');
    end
    model = M{nModel};
else
    model = M;
end

try
    factorCell = model.U;
catch
    error('Model should be a ktensor-like object with property U.');
end
if ~iscell(factorCell) || isempty(factorCell)
    error('Model U should be a non-empty cell array of factor matrices.');
end
end


function trialColors = defaultTrialColors(nTrialType)
fallback = [ ...
    0.20 0.45 0.85; ...
    0.45 0.70 0.95; ...
    0.85 0.30 0.25; ...
    0.95 0.60 0.40];
trialColors = fallback(1:min(nTrialType,size(fallback,1)),:);

if exist('multitaskColors','file') == 2 && nTrialType >= 4
    try
        trialColors(1:4,:) = [ ...
            multitaskColors('s1a1'); ...
            multitaskColors('s2a2'); ...
            multitaskColors('s3a1'); ...
            multitaskColors('s4a2')];
    catch
    end
end
end


function plotTrialIfAvailable(timeAxis,stageActivity,trialIdx,trialColors,trialLabels)
if trialIdx > size(stageActivity,4)
    return
end
trialMat = squeeze(stageActivity(:,:,:,trialIdx));
if isempty(trialMat) || all(isnan(trialMat(:)))
    return
end
if isvector(trialMat)
    trialMat = reshape(trialMat,1,[]);
end

lineColor = trialColors(min(trialIdx,size(trialColors,1)),:);
lineLabel = trialLabels{trialIdx};
[m,se] = meanSemRows(trialMat);
shadedLine(timeAxis,m,se,lineColor,lineLabel);
end


function [m,se] = meanSemRows(mat)
m = mean(mat,1,'omitnan');
n = sum(isfinite(mat),1);
se = std(mat,0,1,'omitnan') ./ sqrt(max(n,1));
end


function shadedLine(x,m,se,lineColor,lineLabel)
x = x(:)';
m = m(:)';
se = se(:)';
valid = isfinite(x) & isfinite(m) & isfinite(se);
if ~any(valid)
    return
end
xv = x(valid);
mv = m(valid);
sev = se(valid);
fill([xv fliplr(xv)],[mv-sev fliplr(mv+sev)],lineColor, ...
    'FaceAlpha',0.22,'EdgeColor','none','HandleVisibility','off');
plot(xv,mv,'Color',lineColor,'LineWidth',2,'DisplayName',lineLabel);
%legend('show','Location','best','Box','off');
end


function label = selectionLabel(selectionMode)
switch selectionMode
    case "bestComponentAssigned"
        label = 'best-component assigned';
    case "globalWeight"
        label = 'global-weight';
    otherwise
        label = char(selectionMode);
end
end


function label = rankSelectionLabel(rankIdx)
if isscalar(rankIdx)
    label = sprintf('rank %d',rankIdx);
elseif isequal(rankIdx,rankIdx(1):rankIdx(end))
    label = sprintf('ranks %d-%d',rankIdx(1),rankIdx(end));
else
    label = sprintf('ranks [%s]',num2str(rankIdx));
end
end
