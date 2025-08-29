function [obj, metrics, details] = fn_findTaskSelectiveNeuron(obj, varargin)
% Compute task-selectivity metrics for all neurons (full-length vectors).
% Returns BOTH SI-based and d′-based discrimination metrics.
% Optional per-trial detrending via moving-average subtraction.
%
% Name-Value:
%   'periodIdx'      : scalar or vector of periods (default 7)
%   'neuronMask'     : logical [N×1] (default: all true)
%   'alignVar'       : 'dffStim' (default) or 'dffChoice'
%   'timeWindow'     : frame indices to sum (default: all)
%   'baselineWindow' : optional frame indices to subtract (default: [])
%   'trialTypePairs' : { [1 4], [5 8] }  % (Task1 L,R) , (Task2 L,R)
%   'cap'            : cap for d′ (default 3)
%   'minTrials'      : minimum trials per side to compute metrics (default 3)
%   'aggAcrossTrials': 'mean' (default) or 'sum'  % affects T1/T2 and SI
%   'detrendWin'     : moving-average window (frames) to subtract per trial (default [])
%
% Notes:
%   - Detrending is applied per trial along time BEFORE stim/baseline windows.
%   - SI uses trial-aggregated L/R (per 'aggAcrossTrials').
%   - d′ uses per-trial frame-sums.

% ----------------- parse -----------------
p = inputParser;
addParameter(p,'periodIdx',7);
addParameter(p,'neuronMask',[]);
addParameter(p,'alignVar','dffStim');
addParameter(p,'timeWindow',[]);
addParameter(p,'baselineWindow',[]);
addParameter(p,'trialTypePairs',{[1 4],[5 8]});
addParameter(p,'cap',3);
addParameter(p,'minTrials',3);
addParameter(p,'aggAcrossTrials','mean');   % 'mean' or 'sum'
addParameter(p,'detrendWin',[]);            % NEW
parse(p,varargin{:});

periods   = p.Results.periodIdx;
pairs     = p.Results.trialTypePairs;
alignVar  = p.Results.alignVar;
basewin   = p.Results.baselineWindow;
capVal    = p.Results.cap;
minTrl    = p.Results.minTrials;
aggMode   = lower(p.Results.aggAcrossTrials);
detrendWin= p.Results.detrendWin;           % NEW

% ---- pull trial-type-parsed data ----
T = obj.trialTypeInfo.(alignVar);  % {nPeriods×1} each {1×8}: [N × Time × nTr]
assert(iscell(T) && ~isempty(T), 'trialTypeInfo.%s is empty.', alignVar);

% infer sizes / default time window
first = [];
for ip = 1:numel(periods)
    if ~isempty(T{periods(ip)}) && ~isempty(T{periods(ip)}{pairs{1}(1)})
        first = T{periods(ip)}{pairs{1}(1)}; break
    end
end
N = size(first,1);
if isempty(p.Results.neuronMask)
    mask = true(N,1);
else
    mask = p.Results.neuronMask;
    assert(islogical(mask) && numel(mask)==N, 'neuronMask must be logical length %d', N);
end
if isempty(p.Results.timeWindow)
    twin = 1:size(first,2);
else
    twin = p.Results.timeWindow;
end

% ---- collect per-trial (stim - baseline) frame-sums for each side & task ----
L1 = collectFrameSums(T, periods, pairs{1}(1), twin, basewin, detrendWin);  % [N × nTr1L]
R1 = collectFrameSums(T, periods, pairs{1}(2), twin, basewin, detrendWin);  % [N × nTr1R]
L2 = collectFrameSums(T, periods, pairs{2}(1), twin, basewin, detrendWin);  % [N × nTr2L]
R2 = collectFrameSums(T, periods, pairs{2}(2), twin, basewin, detrendWin);  % [N × nTr2R]

% ---- aggregate across trials (per neuron) ----
[meanL1, nT1L] = aggTrials(L1, aggMode);
[meanR1, nT1R] = aggTrials(R1, aggMode);
[meanL2, nT2L] = aggTrials(L2, aggMode);
[meanR2, nT2R] = aggTrials(R2, aggMode);

% Overall magnitude per task (sum of L&R aggregates) — unbiased to trial count if 'mean'
T1 = meanL1 + meanR1;
T2 = meanL2 + meanR2;

% ---- Task responsiveness selectivity (−1..1) ----
respIndex = nan(N,1);
validResp = mask & ( (nT1L + nT1R) > 0 ) & ( (nT2L + nT2R) > 0 );
respIndex(validResp) = (T2(validResp) - T1(validResp)) ./ ...
                       (abs(T2(validResp)) + abs(T1(validResp)) + eps);

% ---- Task discrimination via Selectivity Index (SI) ----
SI1 = nan(N,1); SI2 = nan(N,1);
ok1 = (nT1L >= minTrl) & (nT1R >= minTrl);
ok2 = (nT2L >= minTrl) & (nT2R >= minTrl);
SI1(ok1) = (meanL1(ok1) - meanR1(ok1)) ./ (abs(meanL1(ok1)) + abs(meanR1(ok1)) + eps);
SI2(ok2) = (meanL2(ok2) - meanR2(ok2)) ./ (abs(meanL2(ok2)) + abs(meanR2(ok2)) + eps);

discIndexSigned_SI = nan(N,1); 
discIndexAbs_SI    = nan(N,1);
validSI = mask & ~isnan(SI1) & ~isnan(SI2);
discIndexSigned_SI(validSI) = SI2(validSI) - SI1(validSI);
discIndexAbs_SI(validSI)    = abs(SI2(validSI)) - abs(SI1(validSI));

% ---- Task discrimination via d′ (per-trial) ----
d1 = dprimeLR(L1, R1, capVal, minTrl);     % [N×1], NaN if too few trials
d2 = dprimeLR(L2, R2, capVal, minTrl);
discIndexSigned_dp = nan(N,1); 
discIndexAbs_dp    = nan(N,1);
validDP = mask & ~isnan(d1) & ~isnan(d2);
discIndexSigned_dp(validDP) = d2(validDP) - d1(validDP);
discIndexAbs_dp(validDP)    = abs(d2(validDP)) - abs(d1(validDP));

% ---- package outputs ----
metrics = struct( ...
    'respIndex',              respIndex, ...
    'discIndexSigned_SI',     discIndexSigned_SI, ...
    'discIndexAbs_SI',        discIndexAbs_SI, ...
    'discIndexSigned_dprime', discIndexSigned_dp, ...
    'discIndexAbs_dprime',    discIndexAbs_dp);

details = struct( ...
    'T1',T1, 'T2',T2, ...
    'meanL1',meanL1, 'meanR1',meanR1, ...
    'meanL2',meanL2, 'meanR2',meanR2, ...
    'SI1',SI1, 'SI2',SI2, ...
    'd1',d1, 'd2',d2, ...
    'nT1L',nT1L, 'nT1R',nT1R, 'nT2L',nT2L, 'nT2R',nT2R, ...
    'periods',periods, 'twin',twin, 'alignVar',alignVar, ...
    'pairs',{pairs}, 'aggAcrossTrials',aggMode, 'minTrials',minTrl, 'mask',mask, ...
    'baselineWindow',basewin, 'detrendWin',detrendWin);   % NEW

% stash for reuse
obj.analysis.taskSelectivity = struct('metrics',metrics,'details',details);
end

% ================= helpers =================
function M = collectFrameSums(T, periods, trialIdx, twin, basewin, detrendWin)
    M = [];   % [N × nTrialsTotal]
    for ip = 1:numel(periods)
        blk = T{periods(ip)}{trialIdx};          % [N x Time x nTr] or []
        if isempty(blk), continue; end

        % ---- DETREND: subtract moving average per trial along time ----
        if ~isempty(detrendWin) && isfinite(detrendWin) && detrendWin > 1
            blk = blk - movmean(blk, detrendWin, 2, 'omitnan');   % preserves class
        end

        nTime = size(blk,2);
        tw = twin( twin>=1 & twin<=nTime );
        bw = [];
        if ~isempty(basewin), bw = basewin( basewin>=1 & basewin<=nTime ); end

        % Stim sum
        if isempty(tw)
            S = zeros(size(blk,1), size(blk,3), 'like', blk);
        else
            X = blk(:, tw, :);
            if ndims(X)==2, X = reshape(X, size(X,1), size(X,2), 1); end
            S = squeeze(nansum(X, 2));     % [N x nTr]
        end

        % Baseline sum
        if isempty(bw)
            B = 0;
        else
            Xb = blk(:, bw, :);
            if ndims(Xb)==2, Xb = reshape(Xb, size(Xb,1), size(Xb,2), 1); end
            B = squeeze(nansum(Xb, 2));    % [N x nTr]
        end

        M = cat(2, M, S - B);              % per-trial (stim - baseline) on detrended signal
    end
end

function [m, n] = aggTrials(M, mode)
    n = sum(~isnan(M), 2);
    switch mode
        case 'mean'
            m = nanmean(M, 2);
        case 'sum'
            m = nansum(M, 2);
        otherwise
            error('aggAcrossTrials must be mean|sum');
    end
end

function d = dprimeLR(L, R, capVal, minTrl)
    nL = sum(~isnan(L),2);  nR = sum(~isnan(R),2);
    muL = nanmean(L,2);  muR = nanmean(R,2);
    sdL = nanstd(L,0,2); sdR = nanstd(R,0,2);
    pooled = sqrt(0.5*(sdL.^2 + sdR.^2)) + eps;
    d = (muL - muR) ./ pooled;
    d = max(min(d, capVal), -capVal);
    tooFew = min(nL, nR) < minTrl;
    d(tooFew) = NaN;
end
