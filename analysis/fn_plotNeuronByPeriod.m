function fn_plotNeuronByPeriod(T, neuronIdx, varargin)
% Plot a given neuron's (or group's) mean activity (±SEM) over periods, by tasks.
% Top row: Task 1 ([1 4]); Bottom row: Task 2 ([5 8]).
% If neuronIdx is a vector/logical, plot group mean ± SEM across neurons.
%
% Name-Value:
%   'alignVar'         : 'dffStim' (default) or 'dffChoice')
%   'periodIdx'        : vector of periods to show (default: all)
%   'timeWindow'       : frame indices to plot (default: all)
%   'frameRate'        : Hz for x-axis in seconds (default: 15)
%   'stimFrame'        : frame index of stimulus within trial (default: 20)
%   'smoothWin'        : movmean window (frames). 0/1 disables (default: 1)
%   'colors'           : 2×3 RGB for the two curves (default: lines(2))
%   'yLim'             : [ymin ymax] (manual override; applies to all subplots)
%   'sameAxis'         : true to use the same y-limits for both tasks (default: false)
%   'padFrac'          : fraction padding added to auto y-lims (default: 0.05)
%   'useSEMInYLim'     : include ±SEM in auto limits (default: true)
%   'zscore'           : true to z-score each neuron per period (per trial-type) before averaging (default: false)

p = inputParser;
addParameter(p,'alignVar','dffStim');
addParameter(p,'periodIdx',[]);
addParameter(p,'timeWindow',[]);
addParameter(p,'frameRate',15);
addParameter(p,'stimFrame',20);
addParameter(p,'smoothWin',1);
addParameter(p,'colors',[]);
addParameter(p,'yLim',[]);
addParameter(p,'sameAxis',false);
addParameter(p,'padFrac',0.05);
addParameter(p,'useSEMInYLim',true);
addParameter(p,'zscore',false);                 % <-- NEW
parse(p,varargin{:});

%T = obj.trialTypeInfo.(p.Results.alignVar);  % {nPeriods×1}, each: {1×8}, inner: [nNeu × nTime × nTrials]
assert(iscell(T) && ~isempty(T), 'trialTypeInfo.%s is empty; run chunkDaysByTrialType/selTrialType first.', p.Results.alignVar);

nPeriods = numel(T);
periods = p.Results.periodIdx; if isempty(periods), periods = 1:nPeriods; end

% trial-type sets
ttT1 = [1 4];  ttT2 = [5 8];

% infer sizes & default window (from first available block)
firstMat = [];
for ip = 1:numel(periods)
    per = periods(ip);
    if ~isempty(T{per}) && ~isempty(T{per}{ttT1(1)})
        firstMat = T{per}{ttT1(1)}; break;
    end
end
assert(~isempty(firstMat), 'No non-empty T{period}{trialType} found in requested periods.');
nTime = size(firstMat,2);
twin  = p.Results.timeWindow; if isempty(twin), twin = 1:nTime; end

% colors
if isempty(p.Results.colors), C = lines(2); else, C = p.Results.colors; end

% normalize neuronIdx into indices & decide mode
Nall = size(firstMat,1);
if islogical(neuronIdx), neuronIdx = find(neuronIdx); end
neuronIdx = neuronIdx(:);
isGroup = numel(neuronIdx) > 1;

% time vector centered on stim = 0 s
t = (twin - p.Results.stimFrame) ./ p.Results.frameRate;

% ---- helpers
    function [m,se,nBase] = meanSem_cell(ttCell)
        % Return mean/SEM timecourse for either a single neuron or a group
        if isempty(ttCell) || size(ttCell,3)==0
            m = nan(numel(twin),1); se = m; nBase = 0; return;
        end

        % local safe clip for this cell's available frames
        Tlen = size(ttCell,2);
        twinLocal = twin(twin >= 1 & twin <= Tlen);
        if isempty(twinLocal)
            m = nan(numel(twin),1); se = m; nBase = 0; return;
        end
        putBackMask = ismember(twin, twinLocal);

        idx = neuronIdx(neuronIdx >= 1 & neuronIdx <= size(ttCell,1));
        if isempty(idx), m = nan(numel(twin),1); se = m; nBase = 0; return; end

        if isGroup
            % group: avg each neuron across trials, then mean±SEM across neurons
            X = ttCell(idx, twinLocal, :);                 % [nSel x |twinL| x nTr]

            % --- optional z-score per neuron within this period & trial-type ---
            if p.Results.zscore
                Xr = reshape(X, numel(idx), []);           % [nSel x (time*trials)]
                mu = nanmean(Xr, 2);
                sd = nanstd (Xr, 0, 2);  sd(sd==0 | ~isfinite(sd)) = 1;
                X  = (X - reshape(mu, [],1,1)) ./ reshape(sd, [],1,1);
            end

            perNeuron = squeeze(nanmean(X,3));             % [nSel x |twinL|] (trial-avg per neuron)
            if isvector(perNeuron), perNeuron = reshape(perNeuron, numel(idx), []); end
            mLocal  = nanmean(perNeuron, 1).';             % [|twinL| x 1]
            seLocal = nanstd (perNeuron, 0, 1).' ./ sqrt(size(perNeuron,1));
            nBase   = size(perNeuron,1);                   % neurons contributing
        else
            % single neuron: mean±SEM across trials
            X = squeeze(ttCell(idx, twinLocal, :));        % [|twinL| x nTr]
            if isvector(X), X = reshape(X, numel(twinLocal), []); end

            % --- optional z-score for this neuron within this period & trial-type ---
            if p.Results.zscore
                mu = nanmean(X(:));
                sd = nanstd (X(:)); if ~isfinite(sd) || sd==0, sd = 1; end
                X  = (X - mu) ./ sd;
            end

            nTr    = size(X,2);
            mLocal = nanmean(X, 2);
            seLocal= nanstd (X, 0, 2) ./ max(sqrt(nTr),1);
            nBase  = nTr;                                  % trials contributing
        end

        % place back into full twin-length vectors
        m  = nan(numel(twin),1); se = m;
        m(putBackMask)  = mLocal;
        se(putBackMask) = seLocal;
    end

    function [mOut,seOut,nOut] = curve(ttCell)
        [mOut,seOut,nOut] = meanSem_cell(ttCell);
        if p.Results.smoothWin > 1
            mOut  = smoothdata(mOut,'movmean',p.Results.smoothWin);
            seOut = smoothdata(seOut,'movmean',p.Results.smoothWin);
        end
    end

    function shaded(x, m, se, col)
        if all(isnan(m)), return; end
        xx = x(:); mm = m(:); ss = se(:);
        fill([xx; flipud(xx)], [mm-ss; flipud(mm+ss)], col, ...
             'FaceAlpha',0.2, 'EdgeColor','none'); hold on;
        plot(x, m, 'Color', col, 'LineWidth',1.5);
    end

    function yl = autoYLim(statsCell)
        % statsCell: cell array of structs with fields m1,se1,m2,se2 (per period)
        vals = [];
        for ii = 1:numel(statsCell)
            S = statsCell{ii};
            if isempty(S), continue; end
            if p.Results.useSEMInYLim
                vals = [vals; S.m1(:)-S.se1(:); S.m1(:)+S.se1(:); S.m2(:)-S.se2(:); S.m2(:)+S.se2(:)]; %#ok<AGROW>
            else
                vals = [vals; S.m1(:); S.m2(:)]; %#ok<AGROW>
            end
        end
        if isempty(vals), yl = []; return; end
        vals = vals(isfinite(vals));
        if isempty(vals), yl = []; return; end
        mn = min(vals); mx = max(vals);
        if (~isfinite(mn)) || (~isfinite(mx)) || (mx<=mn)
            d = max(abs([mn mx])); if d==0, d=1; end
            pad = 0.05*d; yl = [mn-pad, mx+pad];
        else
            pad = p.Results.padFrac * (mx - mn + eps);
            yl = [mn - pad, mx + pad];
        end
    end

% ---- pre-pass: compute y-lims per task (across all periods)
row1Stats = cell(1,numel(periods));   % Task 1
row2Stats = cell(1,numel(periods));   % Task 2

for ip = 1:numel(periods)
    per = periods(ip);

    % Task 1 curves
    [m1a,se1a,~] = curve(T{per}{ttT1(1)});    % stim1-correct
    [m1b,se1b,~] = curve(T{per}{ttT1(2)});    % stim2-correct
    row1Stats{ip} = struct('m1',m1a,'se1',se1a,'m2',m1b,'se2',se1b);

    % Task 2 curves (may be absent)
    has5 = ~isempty(T{per}{ttT2(1)}) && size(T{per}{ttT2(1)},3) > 0;
    has8 = ~isempty(T{per}{ttT2(2)}) && size(T{per}{ttT2(2)},3) > 0;
    if has5 || has8
        [m2a,se2a,~] = curve(T{per}{ttT2(1)});
        [m2b,se2b,~] = curve(T{per}{ttT2(2)});
        row2Stats{ip} = struct('m1',m2a,'se1',se2a,'m2',m2b,'se2',se2b);
    else
        row2Stats{ip} = [];
    end
end

% decide y-lims
if ~isempty(p.Results.yLim)
    ylRow1 = p.Results.yLim;
    ylRow2 = p.Results.yLim;
else
    ylRow1 = autoYLim(row1Stats);
    ylRow2 = autoYLim(row2Stats);
    if p.Results.sameAxis
        ylBoth = autoYLim([row1Stats row2Stats]);
        if ~isempty(ylBoth), ylRow1 = ylBoth; ylRow2 = ylBoth; end
    end
end

% ---- layout: 2 rows (Task 1 / Task 2), columns = periods
figure('Color','w');
tl = tiledlayout(2, numel(periods), 'TileSpacing','compact', 'Padding','compact');

% -------- Row 1: Task 1 (types 1,4)
for ip = 1:numel(periods)
    per = periods(ip);
    nexttile(tl, ip); hold on;
    S = row1Stats{ip};
    shaded(t, S.m1, S.se1, C(1,:));   % stim1-correct
    shaded(t, S.m2, S.se2, C(2,:));   % stim2-correct
    xline(0,'k:'); yline(0,'k:');
    title(sprintf('P%d  (T1)', per));
    if ~isempty(ylRow1), ylim(ylRow1); end
    if ip==1
        if isGroup
            ylabel(sprintf('Task 1 — Group mean (n=%d)%s', numel(neuronIdx), tern(p.Results.zscore,' (z)','')));
        else
            ylabel(sprintf('Task 1%s', tern(p.Results.zscore,' — z','')));
        end
        legend({'','stim1','','stim2'},'Location','best','Box','off');
    end
    xlabel('Time (s)');
end

% -------- Row 2: Task 2 (types 5,8). Skip panel if both are absent.
for ip = 1:numel(periods)
    per = periods(ip);
    nexttile(tl, numel(periods)+ip); hold on;

    S = row2Stats{ip};
    if isempty(S)
        axis off; title(sprintf('P%d', per));
        continue;
    end

    shaded(t, S.m1, S.se1, C(1,:));
    shaded(t, S.m2, S.se2, C(2,:));

    xline(0,'k:'); yline(0,'k:');
    title(sprintf('P%d  (T2)', per));
    if ~isempty(ylRow2), ylim(ylRow2); end
    if ip==1
        if isGroup
            ylabel(sprintf('Task 2 — Group mean (n=%d)%s', numel(neuronIdx), tern(p.Results.zscore,' (z)','')));
        else
            ylabel(sprintf('Task 2%s', tern(p.Results.zscore,' — z','')));
        end
        legend({'stim1','stim2'},'Location','best','Box','off');
    end
    xlabel('Time (s)');
end

if isGroup
    sgtitle(sprintf('Group mean (n=%d) — %s aligned%s', numel(neuronIdx), p.Results.alignVar, tern(p.Results.zscore,' — z-scored','')));
else
    sgtitle(sprintf('Neuron %s — %s aligned%s', mat2str(neuronIdx.'), p.Results.alignVar, tern(p.Results.zscore,' — z-scored','')));
end
end

% tiny helper for conditional suffixes
function out = tern(cond, a, b)
if cond, out = a; else, out = b; end
end
