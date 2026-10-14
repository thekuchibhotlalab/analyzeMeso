function fn_plotNeuronOnePeriod(obj, groupIdx, varargin)
% Plot a given neuron's mean activity (±SEM) over all periods, separated by tasks.
% Top row: Task 1 (trial types [1 4]); Bottom row: Task 2 (trial types [5 8]).
% Skips Task 2 panels for periods where T2 hasn't appeared yet.
%
% Name-Value:
%   'alignVar'         : 'dffStim' (default) or 'dffChoice')
%   'periodIdx'        : vector of periods to show (default: all)
%   'timeWindow'       : frame indices to plot (default: all)
%   'frameRate'        : Hz for x-axis in seconds (default: 15)
%   'stimFrame'        : frame index of stimulus within trial (default: 20)
%   'smoothWin'        : movmean window (frames). 0/1 disables (default: 4)
%   'colors'           : 2×3 RGB for the two curves (default: lines(2))
%   'yLim'             : [ymin ymax] (manual override; applies to all subplots)
%   'sameAxis' : true to use the same y-limits for both tasks (default: false)
%   'padFrac'          : fraction padding added to auto y-lims (default: 0.05)
%   'useSEMInYLim'     : include ±SEM in auto limits (default: true)

p = inputParser;
addParameter(p,'alignVar','dffStim');
addParameter(p,'periods',7);
addParameter(p,'timeWindow',[]);
addParameter(p,'frameRate',15);
addParameter(p,'stimFrame',20);
addParameter(p,'smoothWin',1);
addParameter(p,'colors',[]);
addParameter(p,'yLim',[]);
addParameter(p,'sameAxis',false);
addParameter(p,'padFrac',0.05);
addParameter(p,'useSEMInYLim',true);
addParameter(p,'zscore',false);
parse(p,varargin{:});

T = obj.trialTypeInfo.(p.Results.alignVar);  % {nPeriods×1}, each: {1×8}, inner: [nNeu × nTime × nTrials]
assert(iscell(T) && ~isempty(T), 'trialTypeInfo.%s is empty; run chunkDaysByTrialType/selTrialType first.', p.Results.alignVar);

if p.Results.zscore
    [T, stats] = zscoreTrialTypeTable(T);
end 

nPeriods = numel(T);
periods = p.Results.periods;

% trial-type sets
ttT1 = [1 4];
ttT2 = [5 8];

% infer sizes & default window
firstMat = T{periods(1)}{ttT1(1)};
nTime = size(firstMat,2);
twin = p.Results.timeWindow; if isempty(twin), twin = 1:nTime; end

% colors
if isempty(p.Results.colors), C = lines(2); else, C = p.Results.colors; end

% time vector centered on stim = 0 s
t = (twin - p.Results.stimFrame) ./ p.Results.frameRate;

% ---- helpers
    function [m,se,nNeu] = meanSem(ttCell,groupIdx)
        if isempty(ttCell), m = nan(numel(twin),1); se = m; nTr = 0; return; end
        X = squeeze(ttCell(groupIdx, twin, :));      % [|twin| × nTrials]
        if isvector(X), X = reshape(X, numel(twin), []); end

        % if p.Results.zscore
        %     [N,Time,K] = size(X);
        %     Xr = reshape(double(X), N, Time*K);          % [neurons x observations]
        %     Zr = zscore(Xr,0,2);
        %     X = reshape(single(Zr), N, Time, K);
        % end
        

        X   = nanmean(X, 3);
        m   = nanmean(X, 1);
        nNeu = size(X,1);
        se  = nanstd(X, 0, 1) ./ sqrt(max(nNeu,1));
    end

    function [mOut,seOut,nOut] = curve(ttCell,groupIdx)
        [mOut,seOut,nOut] = meanSem(ttCell,groupIdx);
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
    % statsCell: cell array of structs with fields m1,se1,m2,se2
        vals = [];
        for ii = 1:numel(statsCell)
            S = statsCell{ii};
            if isempty(S), continue; end
            % force column vectors with (:)
            v = [S.m1(:)-S.se1(:); S.m1(:)+S.se1(:); S.m2(:)-S.se2(:); S.m2(:)+S.se2(:)];
            vals = [vals; v]; %#ok<AGROW>
        end
    
        % flatten, drop non-finite
        vals = vals(:);
        vals = vals(isfinite(vals));
    
        if isempty(vals)
            yl = [];  % nothing to scale from
            return;
        end
    
        mn = min(vals);
        mx = max(vals);
    
        if (~isfinite(mn)) || (~isfinite(mx)) || (mx <= mn)
            % degenerate case: pick a symmetric pad around mn/mx
            d = max(abs([mn mx])); if d==0, d = 1; end
            pad = d * 0.05;          % 5% of a reasonable scale
            yl = [mn - pad, mx + pad];
        else
            pad = p.Results.padFrac * (mx - mn + eps);
            yl = [mn - pad, mx + pad];
        end
    end


% ---- pre-pass: compute y-lims per task (across all periods)
row1Stats = cell(1,length(groupIdx));   % Task 1
row2Stats = cell(1,length(groupIdx));   % Task 2

for ip = 1:length(groupIdx)
    per = periods;

    % Task 1 curves
    [m1a,se1a,~] = curve(T{per}{ttT1(1)},groupIdx{ip});    % stim1-correct
    [m1b,se1b,~] = curve(T{per}{ttT1(2)},groupIdx{ip});    % stim2-correct
    row1Stats{ip} = struct('m1',m1a,'se1',se1a,'m2',m1b,'se2',se1b);

    % Task 2 curves (may be absent)
    has5 = ~isempty(T{per}{ttT2(1)}) && size(T{per}{ttT2(1)},3) > 0;
    has8 = ~isempty(T{per}{ttT2(2)}) && size(T{per}{ttT2(2)},3) > 0;
    if has5 || has8
        [m2a,se2a,~] = curve(T{per}{ttT2(1)},groupIdx{ip});
        [m2b,se2b,~] = curve(T{per}{ttT2(2)},groupIdx{ip});
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
        % unify both rows using combined range
        ylBoth = autoYLim([row1Stats row2Stats]);
        if ~isempty(ylBoth), ylRow1 = ylBoth; ylRow2 = ylBoth; end
    end
end

% ---- layout: 2 rows (Task 1 / Task 2), columns = periods
figure('Color','w');
tl = tiledlayout(2, length(groupIdx), 'TileSpacing','compact', 'Padding','compact');

% -------- Row 1: Task 1 (types 1,4)
for ip = 1:length(groupIdx)
    nexttile(tl, ip); hold on;
    % stim1-correct
    S = row1Stats{ip};
    shaded(t, S.m1, S.se1, C(1,:));
    % stim2-correct
    shaded(t, S.m2, S.se2, C(2,:));

    xline(0,'k:'); yline(0,'k:');
    tempCount = sum(groupIdx{ip}~=0);
    title(sprintf('Group%d (T1) n=%d', ip,tempCount));
    if ~isempty(ylRow1), ylim(ylRow1); end
    if ip==1, ylabel('Task 1'); legend({'stim1','stim2'},'Location','best','Box','off'); end
    xlabel('Time (s)');
end

% -------- Row 2: Task 2 (types 5,8). Skip panel if both are absent.
for ip = 1:length(groupIdx)
    nexttile(tl, length(groupIdx)+ip); hold on;

    S = row2Stats{ip};
    if isempty(S)
        axis off; title(sprintf('Group%d', ip));
        continue;
    end

    shaded(t, S.m1, S.se1, C(1,:));
    shaded(t, S.m2, S.se2, C(2,:));

    xline(0,'k:'); yline(0,'k:');
    tempCount = sum(groupIdx{ip}~=0);
    title(sprintf('Group%d (T2) n=%d', ip, tempCount));
    if ~isempty(ylRow2), ylim(ylRow2); end
    if ip==1, ylabel('Task 2'); legend({'stim1','stim2'},'Location','best','Box','off'); end
    xlabel('Time (s)');
end

sgtitle(sprintf('Period: %d — %s aligned', periods, p.Results.alignVar));
end

function [Tz, stats] = zscoreTrialTypeTable(T)
%ZSCORETRIALTYPETABLE Z-score per neuron across all periods/types/trials/time.
%   [Tz, stats] = zscoreTrialTypeTable(T)
%
%   Input
%     T   : {nPeriods x 1} cell; each T{p} is {1 x 8} trial-type cells;
%           each T{p}{tt} is [nNeurons x nTime x nTrials] (can be empty).
%
%   Output
%     Tz    : same structure as T, z-scored per neuron (global across all cells)
%     stats : struct with fields:
%               .mu     [nNeurons x 1] pooled mean (ignoring NaNs)
%               .sigma  [nNeurons x 1] pooled std  (sample, n-1; NaN-safe)
%               .count  [nNeurons x 1] number of finite samples pooled
%
%   Notes
%   - Z-scoring is done per neuron after flattening all time×trials and
%     concatenating across *all* periods and trial types.
%   - Empty cells and NaNs are ignored when computing mu/sigma.
%   - The output is cast back to the input array class (e.g., 'single').

    assert(iscell(T) && ~isempty(T), 'T must be a non-empty cell array');

    % ---------- discover nNeurons and collect size sanity ----------
    nPeriods = numel(T);
    firstBlk = [];
    for p = 1:nPeriods
        if ~isempty(T{p})
            for tt = 1:numel(T{p})
                if ~isempty(T{p}{tt})
                    firstBlk = T{p}{tt};
                    break;
                end
            end
        end
        if ~isempty(firstBlk), break; end
    end
    assert(~isempty(firstBlk), 'No non-empty blocks found in T.');
    N = size(firstBlk,1);

    % ---------- pooled stats per neuron (ignore NaNs) ----------
    % Accumulate sum, sumsq, count across all cells without concatenating everything
    sumX   = zeros(N,1,'double');
    sumX2  = zeros(N,1,'double');
    countX = zeros(N,1,'double');

    for p = 1:nPeriods
        if isempty(T{p}), continue; end
        for tt = 1:numel(T{p})
            A = T{p}{tt};
            if isempty(A), continue; end
            assert(size(A,1)==N, 'Mismatch in neuron count at T{%d}{%d}.', p, tt);

            A2 = double(A);                       % [N x nTime x nTrials]
            A2 = reshape(A2, N, []);              % [N x (nTime*nTrials)]
            mask = isfinite(A2);                  % ignore NaNs
            A2(~mask) = 0;                        % zero out NaNs for sums

            sumX   = sumX  + sum(A2, 2);
            sumX2  = sumX2 + sum(A2.^2, 2);
            countX = countX + sum(mask, 2);
        end
    end

    % Means and (sample) std per neuron
    mu = sumX ./ max(countX, 1);  % avoid 0/0
    % sample variance: (sum(x^2) - n*mu^2) / (n-1)
    denom = max(countX - 1, 1);
    varSample = (sumX2 - countX .* (mu.^2)) ./ denom;
    varSample(varSample < 0) = 0;          % numerical guard
    sigma = sqrt(varSample);
    sigma(~isfinite(sigma) | sigma==0) = 1; % safe scale

    % ---------- apply z-score back to T (preserve structure/class) ----------
    Tz = T;
    mu3 = reshape(mu,   [N 1 1]);          % broadcast
    sg3 = reshape(sigma,[N 1 1]);          % broadcast

    for p = 1:nPeriods
        if isempty(T{p}), continue; end
        for tt = 1:numel(T{p})
            A = T{p}{tt};
            if isempty(A)
                Tz{p}{tt} = A;             % keep empty as is
                continue;
            end
            A2 = double(A);
            Z  = (A2 - mu3) ./ sg3;        % implicit expansion
            Tz{p}{tt} = cast(Z, 'like', A);
        end
    end

    % ---------- stats out ----------
    stats = struct('mu', mu, 'sigma', sigma, 'count', countX);
end

