function fn_plotOutDffNeuronByStage(outDff, neuronIdx, varargin)
%FN_PLOTOUTDFFNEURONBYSTAGE Plot trial-by-trial mean +/- SEM for outDff.
%
% outDff is a nPeriod x 4 cell array. Each cell is [neuron x time x trial].
% Trial type order is expected to be: T1L, T1R, T2L, T2R.

p = inputParser;
addParameter(p,'periodLabels',{'E','M','L','Int'});
addParameter(p,'trialLabels',{'T1L','T1R','T2L','T2R'});
addParameter(p,'timeWindow',[]);
addParameter(p,'frameRate',15);
addParameter(p,'eventFrame',10);
addParameter(p,'smoothWin',1);
addParameter(p,'colors',[]);
addParameter(p,'yLim',[]);
addParameter(p,'xLim',[]);
addParameter(p,'sameAxis',true);
addParameter(p,'padFrac',0.05);
parse(p,varargin{:});

assert(iscell(outDff) && size(outDff,2) == 4, ...
    'outDff must be a cell array with four trial-type columns: T1L, T1R, T2L, T2R.');

nPeriod = size(outDff,1);
periodLabels = p.Results.periodLabels;
if numel(periodLabels) < nPeriod
    periodLabels = arrayfun(@(x)(['P' int2str(x)]),1:nPeriod,'UniformOutput',false);
end

firstMat = findFirstNonEmpty(outDff);
assert(~isempty(firstMat), 'No non-empty outDff cell found.');
nTime = size(firstMat,2);
twin = p.Results.timeWindow;
if isempty(twin)
    twin = 1:nTime;
end
t = (twin - p.Results.eventFrame) ./ p.Results.frameRate;

if islogical(neuronIdx)
    neuronIdx = find(neuronIdx);
end
neuronIdx = neuronIdx(:);
isGroup = numel(neuronIdx) > 1;

if isempty(p.Results.colors)
    taskColor = [0.20 0.45 0.85; 0.85 0.30 0.25];
    C = [taskColor(1,:); taskColor(1,:)*0.55 + 0.45; taskColor(2,:); taskColor(2,:)*0.55 + 0.45];
else
    C = p.Results.colors;
end

stats = cell(nPeriod,4);
for ip = 1:nPeriod
    for it = 1:4
        [m,se,n] = curve(outDff{ip,it});
        stats{ip,it} = struct('m',m,'se',se,'n',n);
    end
end

yl = p.Results.yLim;
if isempty(yl) && p.Results.sameAxis
    yl = autoYLim(stats);
end

figure('Color','w');
tl = tiledlayout(2,nPeriod,'TileSpacing','compact','Padding','compact');

for ip = 1:nPeriod
    nexttile(tl,ip); hold on
    plotOnePanel(stats(ip,1:2),C(1:2,:),p.Results.trialLabels(1:2),yl);
    title([periodLabels{ip} ' T1']);
    if ip == 1
        ylabel(getYLabel(isGroup,neuronIdx));
    end
    xlabel('Time (s)');

    nexttile(tl,nPeriod+ip); hold on
    plotOnePanel(stats(ip,3:4),C(3:4,:),p.Results.trialLabels(3:4),yl);
    title([periodLabels{ip} ' T2']);
    if ip == 1
        ylabel(getYLabel(isGroup,neuronIdx));
    end
    xlabel('Time (s)');
end

if isGroup
    sgtitle(sprintf('Group mean (n=%d)',numel(neuronIdx)));
else
    sgtitle(sprintf('Neuron %d',neuronIdx));
end

    function firstMat = findFirstNonEmpty(T)
        firstMat = [];
        for ii = 1:numel(T)
            if ~isempty(T{ii})
                firstMat = T{ii};
                return
            end
        end
    end

    function [m,se,nBase] = curve(mat)
        [m,se,nBase] = meanSemOutDff(mat);
        if p.Results.smoothWin > 1
            m = smoothdata(m,'movmean',p.Results.smoothWin);
            se = smoothdata(se,'movmean',p.Results.smoothWin);
        end
    end

    function [m,se,nBase] = meanSemOutDff(mat)
        m = nan(numel(twin),1);
        se = m;
        nBase = 0;
        if isempty(mat) || size(mat,3) == 0
            return
        end

        idx = neuronIdx(neuronIdx >= 1 & neuronIdx <= size(mat,1));
        if isempty(idx)
            return
        end

        tLocal = twin(twin >= 1 & twin <= size(mat,2));
        if isempty(tLocal)
            return
        end
        putBack = ismember(twin,tLocal);

        X = mat(idx,tLocal,:);
        if isGroup
            perNeuron = squeeze(nanmean(X,3));
            if isvector(perNeuron)
                perNeuron = reshape(perNeuron,numel(idx),[]);
            end
            mLocal = nanmean(perNeuron,1).';
            seLocal = nanstd(perNeuron,0,1).' ./ max(sqrt(size(perNeuron,1)),1);
            nBase = size(perNeuron,1);
        else
            trialMat = squeeze(X);
            if isvector(trialMat)
                trialMat = reshape(trialMat,numel(tLocal),[]);
            end
            mLocal = nanmean(trialMat,2);
            seLocal = nanstd(trialMat,0,2) ./ max(sqrt(size(trialMat,2)),1);
            nBase = size(trialMat,2);
        end

        m(putBack) = mLocal;
        se(putBack) = seLocal;
    end

    function plotOnePanel(statRow,colors,labels,ylLocal)
        lineHandle = gobjects(numel(statRow),1);
        for jj = 1:numel(statRow)
            lineHandle(jj) = shaded(t,statRow{jj}.m,statRow{jj}.se,colors(jj,:));
        end
        xline(0,'k:'); yline(0,'k:');
        if ~isempty(ylLocal)
            ylim(ylLocal);
        end
        if ~isempty(p.Results.xLim)
            xlim(p.Results.xLim);
        end
        validHandle = isgraphics(lineHandle);
        legend(lineHandle(validHandle),labels(validHandle),'Location','best','Box','off');
    end

    function lineHandle = shaded(x,m,se,col)
        lineHandle = gobjects(1);
        if all(isnan(m))
            return
        end
        xx = x(:); mm = m(:); ss = se(:);
        fill([xx; flipud(xx)],[mm-ss; flipud(mm+ss)],col, ...
            'FaceAlpha',0.18,'EdgeColor','none'); hold on
        lineHandle = plot(x,m,'Color',col,'LineWidth',1.5);
    end

    function ylOut = autoYLim(statCell)
        vals = [];
        for jj = 1:numel(statCell)
            S = statCell{jj};
            if isempty(S)
                continue
            end
            vals = [vals; S.m(:)-S.se(:); S.m(:)+S.se(:)]; %#ok<AGROW>
        end
        vals = vals(isfinite(vals));
        if isempty(vals)
            ylOut = [];
            return
        end
        mn = min(vals); mx = max(vals);
        if mx <= mn
            pad = max(abs([mn mx]));
            if pad == 0
                pad = 1;
            end
        else
            pad = p.Results.padFrac * (mx - mn);
        end
        ylOut = [mn-pad mx+pad];
    end

    function yLabel = getYLabel(isGroupPlot,idx)
        if isGroupPlot
            yLabel = sprintf('mean +/- SEM across neurons (n=%d)',numel(idx));
        else
            yLabel = 'mean +/- SEM across trials';
        end
    end
end
