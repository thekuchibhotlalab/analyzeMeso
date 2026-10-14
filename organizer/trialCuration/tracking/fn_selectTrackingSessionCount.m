function [n,decision]=fn_selectTrackingSessionCount(tracking,cfg)
%FN_SELECTTRACKINGSESSIONCOUNT Resolve a fixed, automatic or per-animal cutoff.
% Auto smooths losses C(k)-C(k+1), locates their peak, then moves the cutoff
% earlier by floor(window/2). Both auto/manual preserve achievable quotas.
method=validatestring(cfg.sessionCountMethod,{'fixed','auto','manual'});
N=0; minimum=0;
if isfield(tracking,'sessions')
    N=height(tracking.sessions);
    minimum=tracking.minimumPrefixLength;
end
decision=struct('method',string(method),'animalID',string(cfg.animalID), ...
    'availableSessions',N,'minimumSessions',minimum,'requestedCount',NaN, ...
    'selectedCount',NaN,'reason',"",'searchRange',[], ...
    'smoothingWindow',[],'dropSessionRank',NaN,'peakDropCutoff',NaN, ...
    'cutoffShift',0,'appliedCutoffShift',0,'curve',table());
if strcmp(method,'fixed')
    n=cfg.numSessions;
    decision.requestedCount=n; decision.selectedCount=min(n,N);
    decision.reason="fixedCount";
    return
end
assert(cfg.selectSessionsByTracking,'trialCuration:TrackingDisabled', ...
    'Automatic/manual session counts require selectSessionsByTracking=true.');
if N==0
    n=0; decision.selectedCount=0; decision.reason="noEligibleSessions";
    return
end
if strcmp(method,'manual')
    id=string(cfg.animalID);
    assert(isscalar(id)&&~ismissing(id)&&strlength(id)>0, ...
        'trialCuration:AnimalID','Set cfg.animalID to the full animal/area ID for manual session counts.');
    counts=cfg.manualSessionCounts;
    assert(isstruct(counts)&&isscalar(counts)&&isfield(counts,char(id)), ...
        'trialCuration:ManualSessionCount','No manual session count for %s in cfg.manualSessionCounts.',id);
    requested=counts.(char(id));
    assert(~isempty(requested),'trialCuration:ManualSessionCount', ...
        'Fill in cfg.manualSessionCounts.%s with the experimenter-selected session count.',id);
    validateattributes(requested,{'numeric'},{'scalar','real','finite','integer','nonnegative'}, ...
        mfilename,['cfg.manualSessionCounts.' char(id)]);
    n=min(N,max(minimum,double(requested)));
    decision.requestedCount=requested;
    decision.selectedCount=n;
    decision.reason="manualCount";
    if requested<minimum, decision.reason="raisedToMinimum";
    elseif requested>N, decision.reason="limitedToAvailable"; end
    return
end

range=cfg.autoSessionRange;
assert(isnumeric(range)&&isreal(range)&&numel(range)==2&& ...
    all(isfinite(range(:)))&&range(1)>=0&&range(2)<=1&&range(1)<=range(2), ...
    'trialCuration:SessionRange','autoSessionRange must be increasing fractions within [0,1].');
window=cfg.autoSessionSmoothWindow;
validateattributes(window,{'numeric'},{'scalar','real','finite','integer','positive'});
counts=double(tracking.curve.nTrackedNeurons(:));
assert(numel(counts)==N&&all(isfinite(counts)&counts>=0)&&all(diff(counts)<=0), ...
    'trialCuration:TrackingCurve','Tracked-neuron counts must be finite, nonnegative and nonincreasing.');
lower=min(N,max([1,ceil(range(1)*N),minimum]));
upper=min(N,max(lower,floor(range(2)*N))); % Minimum quota has priority over range.
eligible=false(N,1); eligible(lower:upper-1)=true;
rawDrop=[-diff(counts);NaN];
smoothed=nan(N,1);
if any(eligible)
    % Smooth only within the allowed range: excluded early drops cannot leak in.
    smoothed(eligible)=movmean(rawDrop(eligible),window,'Endpoints','shrink');
end
decision.searchRange=[lower upper];
decision.smoothingWindow=window;
n=upper;
decision.reason="noPositiveDrop";
if ~any(eligible)
    decision.reason="noEligibleTransition";
elseif max(smoothed(eligible))>0
    % Smoothing an isolated drop can create a plateau. Locate the actual drop
    % within that plateau; remaining ties keep the greater number of sessions.
    candidates=find(eligible);
    [~,order]=sortrows([-smoothed(candidates),-rawDrop(candidates),-candidates],[1 2 3]);
    peak=candidates(order(1));
    decision.peakDropCutoff=peak;
    decision.dropSessionRank=peak+1;
    decision.cutoffShift=floor(window/2);
    n=max(lower,peak-decision.cutoffShift);
    decision.appliedCutoffShift=peak-n;
    decision.reason="largestSmoothedDrop";
end
decision.selectedCount=n;
decision.curve=table((1:N)',counts,rawDrop,smoothed,eligible,(1:N)'==n, ...
    'VariableNames',{'nSessions','nTrackedNeurons','dropToNext','smoothedDropToNext', ...
    'eligibleCutoff','selected'});
end
