function [meanDiff, stdDiff, respMask, dprimeMat, details] = fn_reduceStimByPeriod(T, varargin)
% Reduce a parsed activity table T into [N x P x K] matrices using stim - baseline.
% T is the nested cell array: {nPeriods x 1} each {1x8} with [N x Time x nTrials].
% Optionally: per-trial detrend, global per-neuron z-score (via fn_zscoreTable).
%
% Name-Value
%   'periodIdx'     : periods to include (default: all existing)
%   'trialTypes'    : trial types to include (default: [1 4 5 8])
%   'stimWindow'    : frames for stimulus window (recommended)
%   'baseWindow'    : frames for baseline window (recommended)
%   'detrendWin'    : [] (default) or scalar frames for movmean per trial
%   'zscoreAll'     : false (default) | true  (calls fn_zscoreTable on the fly)
%   'frameAgg'      : 'sum' (default) | 'mean' (within-window aggregation)
%   'cap'           : d′ cap (default 3)
%   'minTrials'     : min trials for stats (default 3)
%   'dprimeThresh'  : responsiveness threshold on |d′| (default 1)
%
% Output
%   meanDiff  : [N x P x K] mean over trials of (stim - base)
%   stdDiff   : [N x P x K] std  over trials of (stim - base)
%   respMask  : [N x P x K] logical, true if |d′| >= dprimeThresh
%   dprimeMat : [N x P x K] d′(stim vs base) per neuron
%   details   : struct with metadata

p = inputParser;
addParameter(p,'periodIdx',[]);
addParameter(p,'trialTypes',[1 4 5 8]);
addParameter(p,'stimWindow',[]);
addParameter(p,'baseWindow',[]);
addParameter(p,'detrendWin',[]);
addParameter(p,'zscoreAll',false);
addParameter(p,'frameAgg','sum');          % 'sum' | 'mean'
addParameter(p,'cap',3);
addParameter(p,'minTrials',3);
addParameter(p,'dprimeThresh',1);
parse(p,varargin{:});
opt = p.Results;

assert(iscell(T) && ~isempty(T), 'Input T must be the parsed table {nPeriods x 1}.');

% periods/trial types
if isempty(opt.periodIdx), periods = 1:numel(T);
else, periods = opt.periodIdx(:).'; end
trialTypes = opt.trialTypes(:).';
trialTypes = trialTypes(trialTypes>=1 & trialTypes<=8);
if isempty(trialTypes), trialTypes = [1 4 5 8]; end

% infer N
first = [];
for per = periods
    if per>numel(T) || isempty(T{per}), continue; end
    for tt = trialTypes
        if tt<=numel(T{per}) && ~isempty(T{per}{tt})
            first = T{per}{tt}; break; 
        end
    end
    if ~isempty(first), break; end
end
assert(~isempty(first), 'No data in selected periods/trialTypes.');
N = size(first,1);

% optional global z-score (applies detrend first inside)
if opt.zscoreAll
    [T, muAll, sdAll, infoZ] = fn_zscoreTable(T, 'detrendWin', opt.detrendWin, 'types', 1:8); %#ok<ASGLU>
    detrendWinEff = [];   % already detrended during z-scoring
else
    detrendWinEff = opt.detrendWin;
end

P = numel(periods); K = numel(trialTypes);
meanDiff  = nan(N, P, K, 'like', first);
stdDiff   = nan(N, P, K, 'like', first);
dprimeMat = nan(N, P, K);
respMask  = false(N, P, K);
nTrials   = zeros(N, P, K);

% helpers
    function [Ssum,Bsum] = getWinSums(blk, stimWin, baseWin)
        nT = size(blk,2);
        sw = stimWin(stimWin>=1 & stimWin<=nT);
        bw = baseWin(baseWin>=1 & baseWin<=nT);
        if isempty(sw) || isempty(bw), Ssum=[]; Bsum=[]; return; end
        XS = blk(:, sw, :); XB = blk(:, bw, :);
        if ndims(XS)==2, XS = reshape(XS, size(XS,1), size(XS,2), 1); end
        if ndims(XB)==2, XB = reshape(XB, size(XB,1), size(XB,2), 1); end
        switch lower(opt.frameAgg)
            case 'sum'
                Ssum = squeeze(nansum(XS, 2));
                Bsum = squeeze(nansum(XB, 2));
            case 'mean'
                Ssum = squeeze(nanmean(XS, 2));
                Bsum = squeeze(nanmean(XB, 2));
            otherwise
                error('frameAgg must be ''sum'' or ''mean''.');
        end
    end

    function d = dprime_from_SB(Ssum, Bsum, capVal, minTr)
        nS = sum(~isnan(Ssum), 2);  nB = sum(~isnan(Bsum), 2);
        muS = nanmean(Ssum, 2);     muB = nanmean(Bsum, 2);
        sdS = nanstd (Ssum, 0, 2);  sdB = nanstd (Bsum, 0, 2);
        pooled = sqrt(0.5*(sdS.^2 + sdB.^2)) + eps;
        d = (muS - muB) ./ pooled;
        d = max(min(d, capVal), -capVal);
        d(min(nS,nB) < minTr) = NaN;
    end

for ip = 1:P
    per = periods(ip);
    if per>numel(T) || isempty(T{per}), continue; end
    for ik = 1:K
        tt = trialTypes(ik);
        if tt>numel(T{per}) || isempty(T{per}{tt}), continue; end
        blk = T{per}{tt};                      % [N x Time x nTr]

        % optional per-trial detrend (only if we did not z-score globally)
        if ~isempty(detrendWinEff) && detrendWinEff>1
            blk = blk - movmean(blk, detrendWinEff, 2, 'omitnan');
        end

        [Ssum, Bsum] = getWinSums(blk, opt.stimWindow, opt.baseWindow);
        if isempty(Ssum), continue; end

        D = Ssum - Bsum;                        % [N x nTr]
        meanDiff(:, ip, ik) = nanmean(D, 2);
        stdDiff (:, ip, ik) = nanstd (D, 0, 2);
        nTrials(:, ip, ik)  = sum(~isnan(D), 2);

        d = dprime_from_SB(Ssum, Bsum, opt.cap, opt.minTrials);
        dprimeMat(:, ip, ik) = d;
        respMask (:, ip, ik) = abs(d) >= opt.dprimeThresh;
    end
end

details = struct( ...
    'periods',      periods, ...
    'trialTypes',   trialTypes, ...
    'stimWindow',   opt.stimWindow, ...
    'baseWindow',   opt.baseWindow, ...
    'detrendWin',   opt.detrendWin, ...
    'zscoreAll',    logical(opt.zscoreAll), ...
    'frameAgg',     lower(opt.frameAgg), ...
    'cap',          opt.cap, ...
    'minTrials',    opt.minTrials, ...
    'dprimeThresh', opt.dprimeThresh, ...
    'nTrials',      nTrials);
end
