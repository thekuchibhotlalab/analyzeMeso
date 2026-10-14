function [Tz, muAll, sdAll, info] = fn_zscoreTable(T, varargin)
% Z-score each neuron across ALL periods, ALL trial types, ALL time points (and trials).
% Optionally detrend each trial first (moving-average along time).
%
% Input:
%   T : {nPeriods x 1} each {1x8} with numeric [N x Time x nTrials] (dffStim/dffChoice-like)
%
% Name-Value:
%   'detrendWin' : [] (default) or scalar frames for movmean per trial BEFORE z-stats
%   'types'      : trial types to include when computing mu/sd (default 1:8)
%
% Output:
%   Tz    : same structure as T, but (detrended if requested) and z-scored per neuron
%   muAll : [N x 1] per-neuron global mean used
%   sdAll : [N x 1] per-neuron global std used (zeros/NaNs protected → 1)
%   info  : struct with fields N, nPeriods, types, detrendWin

p = inputParser;
addParameter(p,'detrendWin',[]);
addParameter(p,'types',1:8);
parse(p,varargin{:});
opt = p.Results;

% ----- infer N, sanity -----
nPeriods = numel(T);
first = [];
for i = 1:nPeriods
    if isempty(T{i}), continue; end
    for tt = 1:min(8,numel(T{i}))
        if ~isempty(T{i}{tt}), first = T{i}{tt}; break; end
    end
    if ~isempty(first), break; end
end
assert(~isempty(first), 'fn_zscoreTable: T appears empty.');
N = size(first,1);

types = opt.types(:).';
types = types(types>=1 & types<=8);
if isempty(types), types = 1:8; end

% ----- accumulate mu/std across ALL periods & selected types -----
sumX  = zeros(N,1);
sumX2 = zeros(N,1);
cnt   = zeros(N,1);

for i = 1:nPeriods
    if isempty(T{i}), continue; end
    for tt = types
        if tt>numel(T{i}) || isempty(T{i}{tt}), continue; end
        blk = T{i}{tt};                % [N x Time x nTr]
        if ~isempty(opt.detrendWin) && opt.detrendWin>1
            blk = blk - movmean(blk, opt.detrendWin, 2, 'omitnan');
        end
        X = reshape(blk, N, []);       % [N x (Time*Trials)]
        valid = isfinite(X);
        X(~valid) = 0;
        sumX  = sumX  + sum(X, 2);
        sumX2 = sumX2 + sum(X.^2, 2);
        cnt   = cnt   + sum(valid, 2);
    end
end

muAll = zeros(N,1);
sdAll = ones (N,1);
nz = cnt>0;
muAll(nz) = sumX(nz) ./ cnt(nz);
varAll = zeros(N,1);
varAll(nz) = max(sumX2(nz)./cnt(nz) - muAll(nz).^2, 0);
sdAll(nz)  = sqrt(varAll(nz));
sdAll(~isfinite(sdAll) | sdAll==0) = 1; % protect

% ----- apply to build Tz (same structure) -----
Tz = T;
for i = 1:nPeriods
    if isempty(T{i}), continue; end
    Tz{i} = T{i};
    for tt = 1:min(8,numel(T{i}))
        if isempty(T{i}{tt}), Tz{i}{tt} = T{i}{tt}; continue; end
        blk = T{i}{tt};
        if ~isempty(opt.detrendWin) && opt.detrendWin>1
            blk = blk - movmean(blk, opt.detrendWin, 2, 'omitnan');
        end
        % z-score per neuron using global mu/sd
        blk = (blk - reshape(muAll,[],1,1)) ./ reshape(sdAll,[],1,1);
        Tz{i}{tt} = blk;
    end
end

info = struct('N',N,'nPeriods',nPeriods,'types',types,'detrendWin',opt.detrendWin);
end
