function [obj, idxSorted, changeVals, perNeuronPeriodVals] = fn_findNeuronEvo(obj, varargin)
% Find neurons whose responses change most between two (or more) periods
% Uses trial-type-parsed data stored in obj.trialTypeInfo.(alignVar)
%
% Name-Value args:
%   'trialTypeIdx' : vector of trial-type indices to include (default [5 8])
%   'periodIdx'    : vector of period rows to compare (default [3 4])
%   'neuronMask'   : logical vector (length = nNeurons) to restrict analysis (default: all true)
%   'alignVar'     : 'dffStim' (default) or 'dffChoice'
%   'timeWindow'   : vector of frame indices (default: all frames present)
%   'agg'          : 'mean' (default), 'peak', or 'auc'
%   'signed'       : false (use absolute change) or true (signed change between consecutive periods)
%
% Returns:
%   idxSorted            : neuron indices sorted by descending |change|
%   changeVals           : per-neuron change value (NaN outside mask)
%   perNeuronPeriodVals  : [nNeurons × numel(periodIdx)] summary value per period

    p = inputParser;
    addParameter(p,'trialTypeIdx',[5 8]);
    addParameter(p,'periodIdx',[3 4]);
    addParameter(p,'neuronMask',[]);
    addParameter(p,'alignVar','dffStim');       % or 'dffChoice'
    addParameter(p,'timeWindow',[]);            % e.g., 31:50
    addParameter(p,'agg','mean');               % 'mean' | 'peak' | 'auc'
    addParameter(p,'signed',false);             % false => absolute change
    parse(p,varargin{:});
    tt = p.Results.trialTypeIdx;
    pp = p.Results.periodIdx;
    nm = p.Results.neuronMask;
    alignVar = p.Results.alignVar;
    twin = p.Results.timeWindow;
    agg = lower(p.Results.agg);
    signedFlag = p.Results.signed;

    % ---- pull trial-type data ----
    T = obj.trialTypeInfo.(alignVar);      % size: nPeriods × 1 cell, each {1×8 cell}, each inner: [nNeurons × nTime × nTrials]
    assert(~isempty(T) && iscell(T), 'trialTypeInfo.%s is empty or not parsed.', alignVar);

    % infer sizes
    firstBlock = T{pp(1)}{tt(1)};
    nNeurons = size(firstBlock,1);
    if isempty(nm), nm = true(nNeurons,1); end
    assert(islogical(nm) && numel(nm)==nNeurons, 'neuronMask must be logical and length = %d', nNeurons);

    % default time window = all frames
    if isempty(twin), twin = 1:size(firstBlock,2); end

    % ---- compute a single summary value per neuron per selected period ----
    perNeuronPeriodVals = nan(nNeurons, numel(pp));
    for k = 1:numel(pp)
        % concat selected trial types along 3rd dimension (trials)
        mats = T{pp(k)}(tt);                         % 1×numTrialTypes cell of [n×t×tr]
        trialMat = cat(3, mats{:});                  % [nNeurons × nTime × nTrialsTotal]

        % restrict to mask + time window
        X = trialMat(nm, twin, :);                   % [nSel × |twin| × nTrials]
        % mean over trials first
        mTrials = nanmean(X, 3);                      % [nSel × |twin|]

        % aggregate over time
        switch agg
            case 'mean'
                val = nanmean(mTrials, 2);           % [nSel × 1]
            case 'peak'
                val = nanmax(mTrials, [], 2);
            case 'auc'
                % simple trapezoid rule; assumes uniform frame spacing
                val = trapz(mTrials, 2);
            otherwise
                error('Unknown agg: %s (use mean|peak|auc)', agg);
        end

        perNeuronPeriodVals(nm, k) = val;            % put back into full-length vector
    end

    % ---- collapse across multiple periods: compare consecutive periods ----
    % If more than 2 periods are given, we summarize the net change as the sum of consecutive diffs.
    if size(perNeuronPeriodVals,2) == 1
        changeVals = perNeuronPeriodVals(:,1);   % trivial, but allowed
    else
        diffs = diff(perNeuronPeriodVals, 1, 2); % [nNeurons × (numPeriods-1)]
        if signedFlag
            changeVals = nansum(diffs, 2);
        else
            changeVals = nansum(abs(diffs), 2);
        end
    end

    % ---- sort and return only valid (masked) neurons ----
    changeMasked = changeVals;
    changeMasked(~nm) = -inf;                       % exclude from ranking
    [~, order] = sort(changeMasked, 'descend');
    idxSorted = order(isfinite(changeMasked(order)));  % drop -inf

    % stash results
    obj.analysis.evolvingNeurons = struct( ...
        'trialTypes', tt, ...
        'periods', pp, ...
        'alignVar', alignVar, ...
        'timeWindow', twin, ...
        'agg', agg, ...
        'signed', signedFlag, ...
        'mask', nm, ...
        'changeVals', changeVals, ...
        'sortedIdx', idxSorted, ...
        'perNeuronPeriodVals', perNeuronPeriodVals);

end
