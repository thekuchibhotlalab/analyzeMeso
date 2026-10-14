function curated = fn_chooseTrackedSessions(curated,nSessions)
%FN_CHOOSETRACKEDSESSIONS Keep a ranked prefix without reloading files or reranking.
% curated=fn_chooseTrackedSessions(curated,12);
% Omit nSessions to use cfg.sessionCountMethod ('fixed', 'auto', or 'manual').
% Inspect curated.tracking.curve first. Neural extraction follows separately.
assert(~curated.neuralLoaded,'trialCuration:AlreadyLoaded', ...
    'Choose sessions on the metadata result before loading neural activity.');
if nargin<2
    [nSessions,decision]=fn_selectTrackingSessionCount(curated.tracking,curated.cfg);
else
    % An explicit override replaces the earlier automatic/manual decision.
    explicit=curated.cfg;
    explicit.sessionCountMethod='fixed'; explicit.numSessions=nSessions;
    if ~isfield(explicit,'animalID'), explicit.animalID=''; end
    [~,decision]=fn_selectTrackingSessionCount(curated.tracking,explicit);
    curated.cfg.sessionCountMethod='fixed';
end
validateattributes(nSessions,{'numeric'},{'scalar','real','nonnegative'});
assert(isinf(nSessions)||nSessions==fix(nSessions),'trialCuration:SessionCount', ...
    'Number of sessions must be a nonnegative integer or Inf.');
tracking=curated.tracking;
tracking.sessionCountSelection=decision;
hasTracking=isfield(tracking,'sessions');
if hasTracking
    n=min(nSessions,height(tracking.sessions));
    tracking.sessions.selected=tracking.sessions.rank<=n;
    tracking.selectedSessions=tracking.sessions(tracking.sessions.selected,:);
    tracking.numSessionsSelected=n;
    tracking.selectedSessionRec=tracking.selectedSessions.sessionRec;
    tracking.selectedNeuronMask=false(size(tracking.trackedNeurons,1),1);
    if n>0, tracking.selectedNeuronMask=tracking.trackedNeurons(:,n); end
    tracking.selectedNeuronIDs=find(tracking.selectedNeuronMask);
    tracking.selectedMinimumMet=tracking.minimumMet && n>=tracking.minimumPrefixLength;
    if ~isempty(tracking.figure)&&isgraphics(tracking.figure)
        delete(findall(tracking.figure,'Tag','TrialSelectionPrefix'));
        axesList=findall(tracking.figure,'Type','axes');
        for ax=reshape(axesList,1,[])
            xline(ax,n,'--r','Selected','Tag','TrialSelectionPrefix');
        end
    end
    if n<tracking.minimumPrefixLength && curated.cfg.verbose
        warning('trialCuration:PrefixMinimum', ...
            'This prefix has %d sessions; %d are needed for all achievable phase minimums.', ...
            n,tracking.minimumPrefixLength);
    end
elseif ~curated.cfg.selectSessionsByTracking
    assert(isinf(nSessions),'trialCuration:TrackingDisabled', ...
        'Enable selectSessionsByTracking to choose a finite ranked prefix.');
end
selection=curated.selectionAllSessions;
nCondition=numel(selection);
Condition=strings(nCondition,1);
NBeforeRT=zeros(nCondition,1); NAfterRT=NBeforeRT; NSelected=NBeforeRT;
NExcludedBySession=NBeforeRT;
reports={};
for k=1:nCondition
    T=selection(k).trials;
    if hasTracking
        keep=ismember(T.sessionRec,tracking.selectedSessionRec);
        dropped=T(~keep,:);
        dropped.dropReason=repmat("sessionNotSelected",height(dropped),1);
        selection(k).excludedSessionTrials=[selection(k).excludedSessionTrials;dropped];
        T=T(keep,:);
    end
    selection(k).trials=T;
    selection(k).nAfterSessionSelection=height(T);
    mask=false(size(selection(k).maskAfterRT));
    mask(T.sourceTrialRow)=true;
    selection(k).maskAfterSessionSelection=mask;
    Condition(k)=selection(k).name;
    NBeforeRT(k)=selection(k).nBeforeRT;
    NAfterRT(k)=selection(k).nAfterRT;
    NSelected(k)=height(T);
    report=selection(k).excludedSessionTrials;
    NExcludedBySession(k)=height(report);
    report.Condition=repmat(Condition(k),height(report),1);
    reports{end+1,1}=report; %#ok<AGROW>
end
EnoughSelected=NSelected>=curated.cfg.minTrials;
curated.selection=selection;
curated.tracking=tracking;
curated.cfg.numSessions=nSessions;
curated.selectionQC=table(Condition,NBeforeRT,NAfterRT,NSelected, ...
    NExcludedBySession,EnoughSelected);
curated.sessionExcludedTrials=vertcat(reports{:});
end
