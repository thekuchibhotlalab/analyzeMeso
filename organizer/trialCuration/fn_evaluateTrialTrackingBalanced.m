function tracking = fn_evaluateTrialTrackingBalanced(trials, opsFile, varargin)
%FN_EVALUATETRIALTRACKINGBALANCED Select sessions in learning-phase rounds.
% tracking = fn_evaluateTrialTrackingBalanced(trials, opsFile, ...
%     'PhaseOrder', ["T1E","T1M","T1L"], 'Method', 'error')
%
% Inputs: one animal's selected trials table (including dayLabel), and ops.mat.
% Reuses fn_evaluateTrialTracking for loading/mapping only; no parsedTrial
% activity is loaded. Its ranking and reference are replaced here.
%
% Reference(p) = median of eligible session offset maps at pixel p.
% Error(s) = mean((offsetMap_s(p)-Reference(p)).^2) over finite pixels.
% Sessions have equal weight, regardless of selected trial counts. The
% reference stays fixed throughout selection. Nonfinite values are omitted.
%
% Method 'error' (default): lowest mean squared error among candidates.
% Method 'greedy': largest intersection of ishere==1 with ALL previously
% selected sessions. The first session maximizes its own neuron count.
% Greedy ties use lower squared error; all remaining ties use opsSessionIndex.
% Method 'lookahead': maximize nCommon + LookaheadWeight * mean(top pairwise
% overlaps with LookaheadSessions other remaining sessions). Defaults: 0.75, 5.
% The first term intersects ALL selected sessions; the second compares the
% candidate separately with each future neighbor, using all its neurons.
% Neighbors may be from any phase, exclude the candidate/selected sessions,
% and are recomputed each step. Use all available if fewer than five; none=0.
% Ties use lower MSE then source index, just like greedy.
% Lookahead always releases phase matching after the minimum quotas; it
% overrides MatchRemaining to false. Quotas still apply before that point.
% This is a greedy heuristic, not a globally optimal subset search.
%
% PhaseOrder: phase labels in cycling order. Default: first appearance in
% trials.dayLabel. Must include every input phase; extra empty phases are
% allowed. Each session must have one consistent dayLabel. Exhausted phases
% are skipped, so session counts are balanced only while phases have candidates.
% Trials per phase are not balanced. Each session is taken at most once.
% MinSessionsPerStage (default 3): nonnegative integer, or one integer per
% PhaseOrder entry. First cycle through phases until each minimum is reached.
% MatchRemaining (default true): continue cycling through phases afterward.
% If false, consider ALL remaining sessions regardless of phase, choosing
% by Method. With Method='greedy', this maximizes the surviving intersection.
% If a stage has fewer eligible sessions than required, use all available
% sessions for that stage and warn; minimumStatus reports the shortfall.
% Selection is automatic: no interactive prompts. All eligible sessions are
% ranked; these options control their order, not a final stopping criterion.
% Plot (default true), TrackingFile: as in fn_evaluateTrialTracking.
% SessionInfoFile: MAT file containing sessionInfoBeh, with session-level
% offsetMap and ishere. Use opsFile=[] to bypass ops entirely. This handles
% daily registrations already split into sessions in the saved table.
% sessions.sessionInfoRow indexes that table; opsSessionIndex is then NaN.
% 'SessionInfo',table accepts the already-loaded sessionInfoBeh table instead.
%
% Outputs follow fn_evaluateTrialTracking: sessions in selection order,
% curve, trackedNeurons, trialSessionRank, uniqueTrialMask, excludedSessions.
% Additional fields: method, phaseOrder, referenceSessionCounts (per pixel).
% sessions.meanSquaredOffset and offsetScore hold the MSE for all methods;
% for greedy/lookahead, MSE is only the tie-breaker, not the primary score.
% sessions.selectionScore holds the maximized score at each choice. For
% lookahead, lookaheadMeanShared and lookaheadSessionRec record its future term.
% sessions.nTrackedAfterSelection holds each prefix's intersection count.
% curve.nSessionsByPhase columns correspond to phaseOrder.
% minimumPrefixLength: prefix covering all achievable minimum quotas.
% minimumMet: true only if every requested minimum is achievable.
% minimumStatus: requested/available counts and shortfall for each phase.
%
% k = 6;
% chosenTrials = trials(tracking.uniqueTrialMask & tracking.trialSessionRank<=k,:);
% neuronIDs = find(tracking.trackedNeurons(:,k));

p = inputParser;
addParameter(p,'Method','error');
addParameter(p,'LookaheadWeight',0.75,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=0);
addParameter(p,'LookaheadSessions',5,@(x)isnumeric(x)&&isscalar(x)&&isfinite(x)&&x>=1&&x==fix(x));
addParameter(p,'PhaseOrder',[]);
addParameter(p,'MinSessionsPerStage',3,@(x)isnumeric(x)&&isvector(x)&& ...
    ~isempty(x)&&all(isfinite(x(:))&x(:)>=0&x(:)==fix(x(:))));
addParameter(p,'MatchRemaining',true,@(x)islogical(x)&&isscalar(x));
addParameter(p,'Plot',true,@(x)islogical(x)&&isscalar(x));
addParameter(p,'TrackingFile','');
addParameter(p,'SessionInfoFile','');
addParameter(p,'SessionInfo',[],@(x)isempty(x)||istable(x));
parse(p,varargin{:});
method = validatestring(p.Results.Method,{'error','greedy','lookahead'});
matchRemaining = p.Results.MatchRemaining;
if strcmp(method,'lookahead'), matchRemaining=false; end
assert(istable(trials)&&height(trials)>0&& ...
    ismember('dayLabel',trials.Properties.VariableNames), ...
    'balancedTrialTracking:Phases','Provide a nonempty trials table with dayLabel.');
labels = string(trials.dayLabel);
assert(iscolumn(labels)&&~any(ismissing(labels)|strlength(strtrim(labels))==0), ...
    'balancedTrialTracking:Phases','Each trial must have a nonempty dayLabel.');
phaseOrder = string(p.Results.PhaseOrder);
phaseOrder = phaseOrder(:);
if isempty(phaseOrder), phaseOrder = unique(labels,'stable'); end
assert(~any(ismissing(phaseOrder)|strlength(strtrim(phaseOrder))==0)&& ...
    numel(unique(phaseOrder))==numel(phaseOrder)&&all(ismember(labels,phaseOrder)), ...
    'balancedTrialTracking:PhaseOrder','PhaseOrder must be unique and include every input dayLabel.');
minimum = double(p.Results.MinSessionsPerStage(:));
if isscalar(minimum), minimum = repmat(minimum,numel(phaseOrder),1); end
assert(numel(minimum)==numel(phaseOrder),'balancedTrialTracking:Minimum', ...
    'MinSessionsPerStage must be scalar or have one value per PhaseOrder entry.');

% Reuse the existing data mapping without editing the original method.
tracking = fn_evaluateTrialTracking(trials,opsFile, ...
    'TrackingFile',p.Results.TrackingFile,'SessionInfoFile',p.Results.SessionInfoFile, ...
    'SessionInfo',p.Results.SessionInfo,'Plot',false);
sessions = tracking.sessions;
if ismember('sessionInfoRow',sessions.Properties.VariableNames)
    sourceIndex = sessions.sessionInfoRow;
else
    sourceIndex = sessions.opsSessionIndex;
end
oldTrialRank = tracking.trialSessionRank;
nSession = height(sessions);
phase = strings(nSession,1);
for j = 1:nSession
    values = unique(labels(oldTrialRank==j));
    assert(numel(values)==1,'balancedTrialTracking:SessionPhase', ...
        'Each session must have one dayLabel; source session %d has multiple phases.', ...
        sourceIndex(j));
    phase(j) = values;
end
[~,phaseIndex] = ismember(phase,phaseOrder);
available = accumarray(phaseIndex,1,[numel(phaseOrder),1]);
target = min(minimum,available);
shortfall = max(minimum-available,0);
if any(shortfall>0)
    details = compose('%s: %d available, %d requested', ...
        phaseOrder(shortfall>0),available(shortfall>0),minimum(shortfall>0));
    warning('balancedTrialTracking:InsufficientSessions', ...
        'Some stage minimums cannot be met (%s). Using all available sessions in those stages.', ...
        strjoin(details,'; '));
end

maps = cellfun(@double,sessions.offsetMap,'UniformOutput',false);
stack = cat(3,maps{:});
stack(~isfinite(stack)) = NaN;
reference = median(stack,3,'omitnan');
referenceSessionCounts = sum(isfinite(stack),3);
clear stack maps
mse = zeros(nSession,1);
presence = false(numel(sessions.ishere{1}),nSession);
for j = 1:nSession
    map = double(sessions.offsetMap{j});
    valid = isfinite(map)&isfinite(reference);
    mse(j) = mean((map(valid)-reference(valid)).^2);
    presence(:,j) = sessions.ishere{j}(:)==1;
end

order = zeros(nSession,1);
selectionScore = nan(nSession,1);
lookaheadMean = zeros(nSession,1);
lookaheadNeighbors = repmat({zeros(0,1)},nSession,1);
if strcmp(method,'lookahead')
    % Compute pairwise overlaps once; selected sessions are removed below.
    pairwise = double(presence)'*double(presence);
end
tracked = false(size(presence));
remaining = true(nSession,1);
common = true(size(presence,1),1);
phaseCounts = zeros(1,numel(phaseOrder));
countsByPhase = zeros(nSession,numel(phaseOrder));
k = 0;
phaseID = 0;
while k<nSession
    fillingMinimum = any(phaseCounts(:)<target);
    if fillingMinimum || matchRemaining
        % Continue the phase cycle, skipping completed quotas or empty phases.
        for attempt = 1:numel(phaseOrder)
            phaseID = mod(phaseID,numel(phaseOrder))+1;
            if fillingMinimum && phaseCounts(phaseID)>=target(phaseID), continue; end
            candidates = find(remaining & phaseIndex==phaseID);
            if ~isempty(candidates), break; end
        end
    else
        candidates = find(remaining);
    end
    candidateMean = zeros(numel(candidates),1);
    candidateNeighbors = repmat({zeros(0,1)},numel(candidates),1);
    if ismember(method,{'greedy','lookahead'})
        nCommon = sum(presence(:,candidates)&common,1)';
        primaryScore = nCommon;
        if strcmp(method,'lookahead')
            for c = 1:numel(candidates)
                candidate = candidates(c);
                others = find(remaining & (1:nSession)'~=candidate);
                if isempty(others), continue; end
                overlap = pairwise(candidate,others)';
                [~,neighborOrder] = sortrows([-overlap,sourceIndex(others)],[1 2]);
                bestNeighbors = neighborOrder(1:min(p.Results.LookaheadSessions,numel(others)));
                candidateMean(c) = mean(overlap(bestNeighbors));
                candidateNeighbors{c} = others(bestNeighbors);
            end
            primaryScore = nCommon + p.Results.LookaheadWeight*candidateMean;
        end
        scores = [-primaryScore,mse(candidates),sourceIndex(candidates)];
    else
        primaryScore = -mse(candidates); % Larger is better for every method.
        scores = [mse(candidates),sourceIndex(candidates)];
    end
    [~,best] = sortrows(scores);
    chosen = candidates(best(1));
    k = k+1;
    order(k) = chosen;
    selectionScore(k) = primaryScore(best(1));
    lookaheadMean(k) = candidateMean(best(1));
    lookaheadNeighbors{k} = sessions.sessionRec(candidateNeighbors{best(1)});
    remaining(chosen) = false;
    common = common & presence(:,chosen);
    tracked(:,k) = common;
    chosenPhase = phaseIndex(chosen);
    phaseCounts(chosenPhase) = phaseCounts(chosenPhase)+1;
    countsByPhase(k,:) = phaseCounts;
end

% Remove fields belonging to the previous reference/ranking calculation.
obsolete = intersect({'trialWeight','trialPercent','scoreDivisor','meanAbsoluteOffset'}, ...
    sessions.Properties.VariableNames);
sessions(:,obsolete) = [];
sessions.meanSquaredOffset = mse;
sessions.offsetScore = mse;
sessions.phase = phase;
sessions = sessions(order,:);
sessions.rank = (1:nSession)';
sessions.nTrackedAfterSelection = sum(tracked,1)';
% Scores and neighbor identities are evaluated at the moment of selection.
sessions.selectionScore = selectionScore;
sessions.lookaheadMeanShared = lookaheadMean;
sessions.lookaheadSessionRec = lookaheadNeighbors;
trialRank = nan(height(trials),1);
for k = 1:nSession, trialRank(oldTrialRank==order(k)) = k; end
tracking.sessions = sessions;
tracking.referenceOffsetMap = reference;
if isfield(tracking,'referenceTrialCounts')
    tracking = rmfield(tracking,'referenceTrialCounts');
end
tracking.referenceSessionCounts = referenceSessionCounts;
tracking.method = string(method);
tracking.lookaheadWeight = p.Results.LookaheadWeight;
tracking.lookaheadSessions = p.Results.LookaheadSessions;
tracking.phaseOrder = phaseOrder;
tracking.minSessionsPerStage = minimum;
tracking.matchRemaining = matchRemaining;
tracking.minimumPrefixLength = sum(target);
tracking.minimumMet = ~any(shortfall>0);
tracking.minimumStatus = table(phaseOrder,minimum,available,shortfall, ...
    'VariableNames',{'phase','requested','available','shortfall'});
tracking.trackedNeurons = tracked;
tracking.trialSessionRank = trialRank;
tracking.curve = table((1:nSession)',cumsum(sessions.nTrials),sum(tracked,1)', ...
    countsByPhase,'VariableNames',{'nSessions','nTrials','nTrackedNeurons','nSessionsByPhase'});
tracking.figure = [];
if p.Results.Plot
    tracking.figure = figure('Color','w','Name',['Phase-balanced tracking: ' method]);
    layout = tiledlayout(tracking.figure,2,1,'TileSpacing','compact');
    ax = nexttile(layout);
    plot(ax,tracking.curve.nSessions,tracking.curve.nTrackedNeurons,'-o','LineWidth',1.5);
    xlabel(ax,'Sessions taken (selection order)');
    ylabel(ax,'Common tracked neurons'); grid(ax,'on');
    title(ax,['Selection method: ' method]);
    ax = nexttile(layout);
    plot(ax,tracking.curve.nSessions,tracking.curve.nTrials,'-o','LineWidth',1.5);
    xlabel(ax,'Sessions taken (same ordering)');
    ylabel(ax,'Unique selected trials'); grid(ax,'on');
end
end
