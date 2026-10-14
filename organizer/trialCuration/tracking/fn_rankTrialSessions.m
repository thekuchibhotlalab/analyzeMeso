function [selection,tracking] = fn_rankTrialSessions(selection,sessionInfoBeh,cfg,makePlot)
%FN_RANKTRIALSESSIONS Check metadata and rank sessions represented by selected trials.
% No neural activity is loaded. sessionInfoRow in tracking indexes METADATA.
% Counts in the curve deduplicate trials shared by multiple conditions.
if nargin<4, makePlot=false; end
required={'sessionRec'};
if cfg.requireGoodTracking, required{end+1}='goodTracking'; end
if cfg.selectSessionsByTracking, required=[required,{'ishere','offsetMap'}]; end
assert(all(ismember(required,sessionInfoBeh.Properties.VariableNames)), ...
    'trialCuration:Metadata','sessionInfoBeh is missing required metadata columns.');

for k=1:numel(selection)
    T=selection(k).trials;
    reason=strings(height(T),1);
    metadataRow=nan(height(T),1);
    recs=unique(T.sessionRec,'stable');
    for j=1:numel(recs)
        rec=recs(j);
        rows=find(T.sessionRec==rec | (isnan(T.sessionRec)&isnan(rec)));
        why="";
        if ~isfinite(rec)||rec<=0
            why="behaviorOnly";
        else
            hit=find(sessionInfoBeh.sessionRec==rec);
            if numel(hit)>1 && ismember('sessionType',sessionInfoBeh.Properties.VariableNames)
                hit=hit(strcmpi(strtrim(string(sessionInfoBeh.sessionType(hit))),'2AFC'));
            end
            assert(numel(hit)<=1,'trialCuration:Mapping', ...
                'sessionRec=%g matches multiple metadata rows.',rec);
            if isempty(hit)
                why="sessionRecNotFound";
            else
                metadataRow(rows)=hit;
                for name={'date','sessionName','dayLabel'}
                    field=name{1};
                    if ismember(field,T.Properties.VariableNames)&& ...
                            ismember(field,sessionInfoBeh.Properties.VariableNames)
                        assert(all(strcmpi(strtrim(string(T.(field)(rows,:))), ...
                            strtrim(string(sessionInfoBeh.(field)(hit,:)))),'all'), ...
                            'trialCuration:Identity','%s disagrees for sessionRec=%g.',field,rec);
                    end
                end
                if cfg.requireGoodTracking
                    good=fn_valueAt(sessionInfoBeh.goodTracking,hit);
                    if isempty(good)||~isscalar(good)||~isfinite(good)||good~=1
                        why="badTracking";
                    end
                end
                if why=="" && cfg.selectSessionsByTracking
                    map=fn_valueAt(sessionInfoBeh.offsetMap,hit);
                    flags=fn_valueAt(sessionInfoBeh.ishere,hit);
                    if isempty(map)||~isnumeric(map)||~isreal(map)|| ...
                            ~ismatrix(map)||~any(isfinite(map(:)))
                        why="missingOffsetMap";
                    elseif isempty(flags)
                        why="missingIshere";
                    end
                end
            end
        end
        reason(rows)=why;
    end
    invalid=~isfinite(T.trialInSession)|T.trialInSession<1| ...
        T.trialInSession~=fix(T.trialInSession);
    reason(reason=="" & invalid)="invalidTrialIndex";
    T.metadataSessionRow=metadataRow;
    selection(k).trialsAfterRT=T;
    selection(k).trials=T(reason=="",:);
    selection(k).excludedSessionTrials=T(reason~="",:);
    selection(k).excludedSessionTrials.dropReason=reason(reason~="");
end

tracking=struct();
allTrials=vertcat(selection.trials);
if ~cfg.selectSessionsByTracking || isempty(allTrials), return; end
% The shared tracker is retained in the archived selection folder.
repo=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if isempty(which('fn_evaluateTrialTrackingBalanced'))
    addpath(fullfile(repo,'analysis','trialSelection_archive'));
end
allTrials.dayLabel=strtrim(string(allTrials.dayLabel));
phaseOrder=strtrim(string(cfg.phaseOrder));
if isempty(phaseOrder), phaseOrder=unique(allTrials.dayLabel,'stable'); end
[found,phaseID]=ismember(lower(allTrials.dayLabel),lower(phaseOrder));
assert(all(found),'trialCuration:Phases','cfg.phaseOrder must include every selected dayLabel.');
allTrials.dayLabel=reshape(phaseOrder(phaseID),[],1);
tracking=fn_evaluateTrialTrackingBalanced(allTrials,[], ...
    'SessionInfo',sessionInfoBeh,'Method',cfg.trackingMethod, ...
    'PhaseOrder',phaseOrder,'MinSessionsPerStage',cfg.minSessionsPerStage, ...
    'LookaheadWeight',cfg.lookaheadWeight,'LookaheadSessions',cfg.lookaheadSessions, ...
    'MatchRemaining',cfg.matchRemaining,'Plot',makePlot);
tracking.inputTrials=allTrials(:,{'sessionRec','trialInSession','sourceTrialRow'});
end

function v=fn_valueAt(column,row)
if iscell(column), v=column{row}; else, v=column(row,:); end
end
