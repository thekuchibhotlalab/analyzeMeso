function [obj, scores, details] = fn_findNeuronEvoCorr(obj, varargin)
% Classify how neurons evolve across periods via correlation to pattern templates.
% Supports RESPONSE metric (original) or STIMULUS-SELECTIVITY (SI or d′).
% Optional per-trial detrending by subtracting a moving average.
%
% Name-Value (additions):
%   'metricType'        : 'response' (default) | 'selectivity'
%   'selectivityMetric' : 'SI' (default) | 'dprime'
%   'task'              : 1 | 2  (default 2)   % ignored if 'trialTypePair' is given
%   'trialTypePair'     : [tLeft tRight]       % overrides 'task' (selectivity)
%   'aggAcrossTrials'   : 'mean' (default) | 'sum'  % for SI
%   'minTrials'         : min trials per side (default 3)
%   'cap'               : d′ cap (default 3)
%   'detrendWin'        : moving-average window (frames) to subtract per trial (default [])
%
% Existing:
%   'task','trialTypeIdx','phase','periodIdx','alignVar','timeWindow',
%   'baselineWindow','neuronMask','agg','pattern','corrType',
%   'transientCenter','transientWidth'

% ----------------- parse -----------------
p = inputParser;
addParameter(p,'metricType','response');
addParameter(p,'selectivityMetric','dprime');
addParameter(p,'task',2);
addParameter(p,'trialTypePair',[]);
addParameter(p,'trialTypeIdx',[]);
addParameter(p,'phase','T2');
addParameter(p,'periodIdx',[]);
addParameter(p,'alignVar','dffStim');
addParameter(p,'timeWindow',[]);
addParameter(p,'baselineWindow',[]);
addParameter(p,'neuronMask',[]);
addParameter(p,'agg','mean');
addParameter(p,'aggAcrossTrials','mean');
addParameter(p,'minTrials',3);
addParameter(p,'cap',3);
addParameter(p,'pattern','increase');
addParameter(p,'corrType','pearson');
addParameter(p,'transientCenter','middle');
addParameter(p,'transientWidth',[]);
addParameter(p,'detrendWin',[]);                      % DETREND
parse(p,varargin{:});
opt = p.Results;

% ---- data ----
T = obj.trialTypeInfo.(opt.alignVar);  % {nPeriods×1}, each {1×8}: [N × Time × nTrials]
assert(iscell(T) && ~isempty(T), 'trialTypeInfo.%s is empty.', opt.alignVar);

% ---- periods ----
if isempty(opt.periodIdx)
    switch lower(string(opt.phase))
        case "t1",              periods = [1 2 3];
        case "t2",              periods = [3 4 5 6];
        case "interleave",      periods = 7;
        case "t1+t2",           periods = [1 2 3 4 5 6];
        case "t2+interleave",   periods = [3 4 5 6 7];
        case "all",             periods = 1:min(numel(T),7);
        otherwise, error('Unknown phase: %s', opt.phase);
    end
else
    periods = opt.periodIdx(:)';
end

% ---- trial types ----
if strcmpi(opt.metricType,'response')
    if isempty(opt.trialTypeIdx)
        tt = (opt.task==1) * [1 4] + (opt.task==2) * [5 8];
    else
        tt = opt.trialTypeIdx(:)';
    end
else
    if isempty(opt.trialTypePair)
        ttPair = (opt.task==1)*[1 4] + (opt.task==2)*[5 8];
    else
        ttPair = opt.trialTypePair(:)';
    end
end

% ---- infer sizes & default window ----
first = [];
if strcmpi(opt.metricType,'response')
    probeTT = tt(1);
else
    probeTT = ttPair(1);
end

% find a non-empty block to infer N and nTime
for per = periods
    if ~isempty(T{per}) && ~isempty(T{per}{probeTT})
        first = T{per}{probeTT};
        break
    end
end
assert(~isempty(first), 'Selected periods/trial types have no data.');
N = size(first,1);
nTime = size(first,2);

% default time window
if isempty(opt.timeWindow)
    twinDefault = 1:nTime;
else
    twinDefault = opt.timeWindow;
end

if isempty(opt.neuronMask), mask = true(N,1);
else, mask = opt.neuronMask; assert(islogical(mask) && numel(mask)==N, 'neuronMask must be logical length %d', N);
end
if isempty(opt.timeWindow), twinDefault = 1:nTime; else, twinDefault = opt.timeWindow; end

% small helper for detrending per trial
    function Y = detrendTrials(A)
        % A: [N x Time x nTr]
        if isempty(opt.detrendWin) || ~isfinite(opt.detrendWin) || opt.detrendWin<=1
            Y = A; return;
        end
        % subtract moving average along time, per trial & neuron
        Y = A - movmean(A, opt.detrendWin, 2, 'omitnan');
    end

% ---- per-period summaries (N × M) ----
M = numel(periods);
perNeuronPeriodVals = nan(N, M);

switch lower(opt.metricType)
    case 'response'
        for k = 1:M
            per = periods(k);
            blocks = T{per}(tt);
            if all(cellfun(@isempty, blocks)), continue; end
            trialMat = cat(3, blocks{:});                  % [N × Time × nTrialsCombined]
            trialMat = detrendTrials(trialMat);            % DETREND (before any windowing)

            nT = size(trialMat,2);
            tw = twinDefault(twinDefault>=1 & twinDefault<=nT);
            if isempty(tw), continue; end

            X  = trialMat(:, tw, :);
            TA = nanmean(X, 3);                            % trial-avg → [N × |tw|]

            switch lower(opt.agg)
                case 'mean'
                    v = nanmean(TA, 2);                    % mean over time
                    % optional baseline subtraction (on detrended data)
                    if ~isempty(opt.baselineWindow)
                        bw = opt.baselineWindow(opt.baselineWindow>=1 & opt.baselineWindow<=nT);
                        if ~isempty(bw)
                            Xb  = trialMat(:, bw, :);
                            TAb = nanmean(Xb, 3);
                            v   = v - nanmean(TAb, 2);
                        end
                    end
                case 'peak'
                    v = nanmax(TA, [], 2);
                case 'auc'
                    v = trapz(TA, 2);
                otherwise
                    error('agg must be mean|peak|auc');
            end
            perNeuronPeriodVals(:,k) = v;
        end

    case 'selectivity'
        tL = ttPair(1); tR = ttPair(2);
        switch lower(opt.selectivityMetric)
            case 'si'
                for k = 1:M
                    per = periods(k);
                    L = collectFrameSums_onePeriod(T, per, tL, twinDefault, opt.baselineWindow, opt.detrendWin); % DETREND
                    R = collectFrameSums_onePeriod(T, per, tR, twinDefault, opt.baselineWindow, opt.detrendWin);
                    if isempty(L) || isempty(R), continue; end
                    nL = sum(~isnan(L),2); nR = sum(~isnan(R),2);
                    mL = aggTrialsVec(L, opt.aggAcrossTrials);
                    mR = aggTrialsVec(R, opt.aggAcrossTrials);
                    ok = (nL>=opt.minTrials) & (nR>=opt.minTrials);
                    SI = nan(N,1);
                    SI(ok) = (mL(ok) - mR(ok)) ./ (abs(mL(ok)) + abs(mR(ok)) + eps);
                    perNeuronPeriodVals(:,k) = SI;
                end
            case 'dprime'
                for k = 1:M
                    per = periods(k);
                    L = collectFrameSums_onePeriod(T, per, tL, twinDefault, opt.baselineWindow, opt.detrendWin); % DETREND
                    R = collectFrameSums_onePeriod(T, per, tR, twinDefault, opt.baselineWindow, opt.detrendWin);
                    if isempty(L) || isempty(R), continue; end
                    d = dprimeLR_mat(L, R, opt.cap, opt.minTrials);
                    perNeuronPeriodVals(:,k) = d;
                end
            otherwise
                error('selectivityMetric must be SI|dprime');
        end
    otherwise
        error('metricType must be response|selectivity');
end

% ---- pattern template ----
switch lower(opt.pattern)
    case 'increase',  tmpl = linspace(1, M, M);
    case 'decrease',  tmpl = linspace(M, 1, M);
    case 'transient'
        if ischar(opt.transientCenter) || isstring(opt.transientCenter), c = ceil(M/2);
        else, c = max(1, min(M, round(opt.transientCenter)));
        end
        if isempty(opt.transientWidth), sigma = max(1, M/4); else, sigma = opt.transientWidth; end
        x = 1:M; tmpl = exp(-0.5*((x - c)/sigma).^2);
    case 'stable',    tmpl = ones(1,M);
    otherwise, error('Unknown pattern: %s', opt.pattern);
end

% ---- correlation / stability score ----
scores = nan(N,1);
vals = perNeuronPeriodVals;

switch lower(opt.pattern)
    case {'increase','decrease','transient'}
        ti = tmpl(:);
        for i = 1:N
            if ~mask(i) || all(~isfinite(vals(i,:))), continue; end
            xi = vals(i,:)';
            r = corr(xi, ti, 'type', opt.corrType, 'rows','complete');
            scores(i) = r;
        end
    case 'stable'
        ramp = (1:M)';
        for i = 1:N
            if ~mask(i) || all(~isfinite(vals(i,:))), continue; end
            xi = vals(i,:)';
            r = corr(xi, ramp, 'type', opt.corrType, 'rows','complete');
            if ~isfinite(r), r = 0; end
            scores(i) = 1 - abs(r);
        end
end

scores(~mask) = NaN;

% ---- details ----
details = struct( ...
    'periods', periods, ...
    'metricType', lower(opt.metricType), ...
    'trialTypes', [], ...
    'trialTypePair', [], ...
    'template', tmpl(:)', ...
    'perNeuronPeriodVals', perNeuronPeriodVals, ...
    'agg', opt.agg, ...
    'aggAcrossTrials', [], ...
    'selectivityMetric', [], ...
    'alignVar', opt.alignVar, ...
    'timeWindow', twinDefault, ...
    'baselineWindow', opt.baselineWindow, ...
    'detrendWin', opt.detrendWin, ...              % DETREND
    'pattern', opt.pattern, ...
    'corrType', opt.corrType, ...
    'mask', mask);

if strcmpi(opt.metricType,'response')
    details.trialTypes = tt;
else
    details.trialTypePair = ttPair;
    details.selectivityMetric = lower(opt.selectivityMetric);
    if strcmpi(opt.selectivityMetric,'si')
        details.aggAcrossTrials = lower(opt.aggAcrossTrials);
    end
end

obj.analysis.evoPattern = struct('scores', scores, 'details', details);
end

% =================== helpers ===================
function L = collectFrameSums_onePeriod(T, per, trialIdx, twinDefault, basewin, detrendWin)
    blk = T{per}{trialIdx};                 % [N x Time x nTr] or []
    if isempty(blk), L = []; return; end

    % DETREND: per-trial moving-average subtraction BEFORE any windowing
    if ~isempty(detrendWin) && isfinite(detrendWin) && detrendWin>1
        blk = blk - movmean(blk, detrendWin, 2, 'omitnan');
    end

    nTime = size(blk,2);
    tw = twinDefault(twinDefault>=1 & twinDefault<=nTime);
    if isempty(tw), L = []; return; end

    X = blk(:, tw, :);
    if ndims(X)==2, X = reshape(X, size(X,1), size(X,2), 1); end
    S = squeeze(nansum(X, 2));              % [N x nTr] stim sum on detrended signal

    if ~isempty(basewin)
        bw = basewin(basewin>=1 & basewin<=nTime);
        if ~isempty(bw)
            Xb = blk(:, bw, :);
            if ndims(Xb)==2, Xb = reshape(Xb, size(Xb,1), size(Xb,2), 1); end
            B = squeeze(nansum(Xb, 2));     % baseline sum on detrended signal
            S = S - B;
        end
    end
    L = S;
end

function v = aggTrialsVec(M, mode)
    switch lower(mode)
        case 'mean', v = nanmean(M, 2);
        case 'sum',  v = nansum (M, 2);
        otherwise, error('aggAcrossTrials must be mean|sum');
    end
end

function d = dprimeLR_mat(L, R, capVal, minTrl)
    nL = sum(~isnan(L),2); nR = sum(~isnan(R),2);
    muL = nanmean(L,2);  muR = nanmean(R,2);
    sdL = nanstd (L,0,2); sdR = nanstd (R,0,2);
    pooled = sqrt(0.5*(sdL.^2 + sdR.^2)) + eps;
    d = (muL - muR) ./ pooled;
    d = max(min(d, capVal), -capVal);
    tooFew = min(nL, nR) < minTrl;
    d(tooFew) = NaN;
end
