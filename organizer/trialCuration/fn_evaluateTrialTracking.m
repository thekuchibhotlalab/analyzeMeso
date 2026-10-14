function tracking = fn_evaluateTrialTracking(trials, opsFile, varargin)
%FN_EVALUATETRIALTRACKING Rank sessions using ops.mat, without parsed activity.
% tracking = fn_evaluateTrialTracking(trials,'B:\zz172_PPC2\ops.mat')
% Concatenate trialTypeInfo tables from ONE animal to combine stages/types.
% Duplicate original trials count once. No parsedTrial.mat is opened.
%
% Offset maps come from ops.offsetMap. Session date/name are matched to
% ops.imagingFilename, independently of trial table order. If imagingFilename
% is absent, sessionRec must index the original recording order in ops.
% ops.mouseArea is not required or used to identify sessions.
%
% Presence flags come from trials.ishere when supplied. Otherwise loads only
% ishereFinal (sessions x neurons) from stackROI_final_tracked.mat beside ops.
% 'TrackingFile',path overrides that fallback. 'Plot',false suppresses plots.
% Alternatively, use fn_evaluateTrialTracking(trials,[], 'SessionInfoFile',file).
% Loads ONLY sessionInfoBeh from file and uses its per-session offsetMap and
% ishere directly. This supports registrations split from days into sessions.
% Matching uses date/sessionName, or sessionRec as an identifier (not a row).
% No ops or separate tracking file is read in this mode. Output sessionInfoRow
% indexes the saved table; opsSessionIndex is NaN because no ops mapping occurs.
% Saved sessionInfoBeh.ishere takes precedence over any trials.ishere column.
% 'SessionInfo',table uses an already-loaded sessionInfoBeh table instead of
% SessionInfoFile. Do not supply both. It never loads neural activity.
%
% For eligible sessions with n(s) unique selected trials:
%   reference(p) = sum_s n(s)*offsetMap_s(p) / sum_s n(s)
% where sums at each pixel omit nonfinite map values.
%   meanAbsoluteOffset(s) = mean(abs(offsetMap_s-reference), finite pixels)
%   trialWeight(s) = n(s)/sum_s n(s)
%   trialPercent(s) = 100*trialWeight(s)
%   scoreDivisor(s) = log(1+trialPercent(s))
%   offsetScore(s) = meanAbsoluteOffset(s)/scoreDivisor(s)
% Rank by increasing score; ties prefer more trials, then ops session index.
% log is the natural logarithm. Percentages use 1 for 1%, not 0.01.
% More selected trials reduce the score for a given offset error.
% Reference and percentages use eligible sessions only and remain fixed
% across the whole curve, not recalculated for each prefix.
% Actual tracking uses intersections of ishere==1; offset ranking does not
% directly optimize the number of common neurons or retained trials.
%
% .sessions: ranked metadata, opsSessionIndex, original maps/flags, counts,
%            trialWeight, trialPercent, scoreDivisor, meanAbsoluteOffset
%            and offsetScore.
% .referenceOffsetMap: trial-weighted average in original map units.
% .curve: nSessions, nTrials, nTrackedNeurons for every ranked prefix.
% .trackedNeurons: nOriginalNeurons x nSessions; column k gives common ROIs.
% .trialSessionRank: rank for each INPUT row (NaN for excluded sessions).
% .uniqueTrialMask: first occurrence of each original trial in the input.
% .excludedSessions: unmatched sessions or missing maps/flags, with reasons.
% .figure: plot handle, or [].
%
% Choose k after inspecting the curve:
%   keep = tracking.uniqueTrialMask & tracking.trialSessionRank<=k;
%   chosenTrials = trials(keep,:);
%   neuronIDs = find(tracking.trackedNeurons(:,k));
% No source data or input trials are modified.

p = inputParser;
addParameter(p,'Plot',true,@(x)islogical(x)&&isscalar(x));
addParameter(p,'TrackingFile','');
addParameter(p,'SessionInfoFile','');
addParameter(p,'SessionInfo',[],@(x)isempty(x)||istable(x));
parse(p,varargin{:});
assert(istable(trials)&&height(trials)>0,'evaluateTrialTracking:Input', ...
    'Provide a nonempty trials table, e.g. trialTypeInfo{1,1,1}.');
assert(ismember('trialInSession',trials.Properties.VariableNames), ...
    'evaluateTrialTracking:Columns','Trials must contain trialInSession.');
validateattributes(trials.trialInSession,{'numeric'},{'column','integer','positive','finite'});
sources = repmat("",height(trials),1);
if ismember('sourceFile',trials.Properties.VariableNames)
    sources = string(trials.sourceFile);
    assert(numel(unique(lower(replace(sources,'/','\'))))==1, ...
        'evaluateTrialTracking:MixedAnimals','Concatenate stages/types from one animal/file only.');
end
if ismember('animal',trials.Properties.VariableNames)
    assert(numel(unique(string(trials.animal)))==1,'evaluateTrialTracking:MixedAnimals', ...
        'Concatenate stages/types from one animal only.');
end
sessionInfoFile = string(p.Results.SessionInfoFile);
useSessionInfo = strlength(sessionInfoFile)>0 || istable(p.Results.SessionInfo);
if useSessionInfo
    if istable(p.Results.SessionInfo)
        assert(strlength(sessionInfoFile)==0,'evaluateTrialTracking:SessionInfo', ...
            'Provide SessionInfo or SessionInfoFile, not both.');
        si = p.Results.SessionInfo;
    else
    d = load(char(sessionInfoFile),'sessionInfoBeh');
    assert(isfield(d,'sessionInfoBeh')&&istable(d.sessionInfoBeh), ...
        'evaluateTrialTracking:SessionInfo','SessionInfoFile must contain the sessionInfoBeh table.');
    si = d.sessionInfoBeh; clear d
    end
    assert(all(ismember({'offsetMap','ishere'},si.Properties.VariableNames))&&iscell(si.offsetMap), ...
        'evaluateTrialTracking:SessionInfo','sessionInfoBeh needs offsetMap cells and ishere.');
    mapsAll = si.offsetMap;
    nMap = height(si);
else
    d = load(char(opsFile),'ops');
    assert(isfield(d,'ops')&&isstruct(d.ops)&&isfield(d.ops,'offsetMap'), ...
        'evaluateTrialTracking:Ops','opsFile must contain ops.offsetMap.');
    ops = d.ops; clear d
    mapsAll = ops.offsetMap;
    if iscell(mapsAll), nMap = numel(mapsAll);
    else
        assert(isnumeric(mapsAll)&&isreal(mapsAll)&&ndims(mapsAll)<=3, ...
            'evaluateTrialTracking:Map','ops.offsetMap must be rows x columns x sessions, or a cell vector.');
        nMap = size(mapsAll,3);
    end
end
hasDates = all(ismember({'date','sessionName'},trials.Properties.VariableNames));
if hasDates, keys = trials(:,{'date','sessionName'});
else
    assert(ismember('sessionRec',trials.Properties.VariableNames), ...
        'evaluateTrialTracking:Keys','Need date/sessionName or sessionRec.');
    assert(all(isfinite(trials.sessionRec)&trials.sessionRec>0), ...
        'evaluateTrialTracking:Keys','Without date/sessionName, sessionRec must identify recorded sessions.');
    keys = trials(:,{'sessionRec'});
end
[~,firstSession,inputSession] = unique(keys,'rows','stable');
nSession = numel(firstSession);
opsIndex = nan(nSession,1);
if useSessionInfo
    for j = 1:nSession
        row = firstSession(j);
        if hasDates && all(ismember({'date','sessionName'},si.Properties.VariableNames))
            hit = find(si.date==trials.date(row) & ...
                strcmpi(string(si.sessionName),string(trials.sessionName(row))));
        else
            assert(all(ismember('sessionRec',trials.Properties.VariableNames)) && ...
                ismember('sessionRec',si.Properties.VariableNames), ...
                'evaluateTrialTracking:Keys','Need date/sessionName or sessionRec in both tables.');
            ids = unique(trials.sessionRec(inputSession==j));
            assert(numel(ids)==1,'evaluateTrialTracking:Mapping','Session has conflicting sessionRec values.');
            hit = [];
            if isfinite(ids(1))&&ids(1)>0, hit = find(si.sessionRec==ids(1)); end
        end
        assert(numel(hit)<=1,'evaluateTrialTracking:Mapping', ...
            'Multiple sessionInfoBeh rows match selected session %d.',j);
        if ~isempty(hit), opsIndex(j) = hit; end
    end
elseif hasDates && isfield(ops,'imagingFilename')
    names = string(ops.imagingFilename(:));
    assert(numel(names)==nMap,'evaluateTrialTracking:Mapping', ...
        'ops.imagingFilename count must match the offsetMap session count.');
    dates = nan(nMap,1); sessionNames = strings(nMap,1);
    for j = 1:nMap
        pieces = regexp(char(names(j)),'[\\/]','split');
        base = regexprep(pieces{end},'_parsed$','');
        tokens = regexp(base,'_(\d{8})_(.+)$','tokens','once');
        assert(~isempty(tokens),'evaluateTrialTracking:Mapping', ...
            'Cannot identify date/session in ops.imagingFilename: %s.',names(j));
        dates(j) = str2double(tokens{1}); sessionNames(j) = string(tokens{2});
    end
    for j = 1:nSession
        row = firstSession(j);
        hit = find(dates==trials.date(row)&strcmpi(sessionNames,string(trials.sessionName(row))));
        assert(numel(hit)<=1,'evaluateTrialTracking:Mapping','Multiple ops maps match selected session %d.',j);
        if ~isempty(hit), opsIndex(j) = hit; end
    end
else
    assert(ismember('sessionRec',trials.Properties.VariableNames), ...
        'evaluateTrialTracking:Keys','Without ops session filenames, trials need sessionRec indices.');
    for j = 1:nSession
        ids = unique(trials.sessionRec(inputSession==j));
        assert(numel(ids)==1,'evaluateTrialTracking:Mapping','Session has conflicting sessionRec values.');
        id = ids(1);
        if isfinite(id)&&id>0&&id==fix(id)&&id<=nMap, opsIndex(j) = id; end
    end
end
clear ops
[~,first] = unique([inputSession trials.trialInSession],'rows','stable');
uniqueTrialMask = false(height(trials),1); uniqueTrialMask(first) = true;
presence = cell(nSession,1); maps = cell(nSession,1);
nTrials = zeros(nSession,1); nInputRows = zeros(nSession,1);
reason = strings(nSession,1); mapShape = []; nNeuron = [];
% In ops mode, use trials.ishere when supplied and verify consistency.
% SessionInfoFile mode instead uses the saved per-session flags directly.
tablePresence = ~useSessionInfo && ismember('ishere',trials.Properties.VariableNames);
presenceFile = ""; tracked = [];
if useSessionInfo
    tracked = si.ishere;
    presenceFile = sessionInfoFile;
elseif ~tablePresence && any(isfinite(opsIndex))
    presenceFile = string(p.Results.TrackingFile);
    if presenceFile=="", presenceFile = string(fullfile(fileparts(char(opsFile)),'stackROI_final_tracked.mat')); end
    assert(isfile(presenceFile),'evaluateTrialTracking:PresenceFile', ...
        'No trials.ishere. Provide TrackingFile or place stackROI_final_tracked.mat beside ops.mat.');
    d = load(char(presenceFile),'ishereFinal');
    assert(isfield(d,'ishereFinal')&&(isnumeric(d.ishereFinal)||islogical(d.ishereFinal)) ...
        &&ismatrix(d.ishereFinal)&&size(d.ishereFinal,1)==nMap, ...
        'evaluateTrialTracking:Presence','ishereFinal must have one row per ops offset map.');
    tracked = d.ishereFinal; clear d
end
for j = 1:nSession
    members = find(inputSession==j);
    nInputRows(j) = numel(members); nTrials(j) = nnz(uniqueTrialMask(members));
    idx = opsIndex(j); m = []; h = [];
    if ~isfinite(idx)
        if useSessionInfo, reason(j) = "No matching sessionInfoBeh row";
        else, reason(j) = "No matching ops recording"; end
    else
        if iscell(mapsAll), m = mapsAll{idx}; else, m = mapsAll(:,:,idx); end
        if tablePresence
            if iscell(trials.ishere), h = trials.ishere{members(1)}; else, h = trials.ishere(members(1),:); end
            for row = members'
                if iscell(trials.ishere), value = trials.ishere{row}; else, value = trials.ishere(row,:); end
                assert(isequaln(value,h),'evaluateTrialTracking:Presence', ...
                    'Inconsistent ishere flags within selected session %d.',j);
            end
        elseif useSessionInfo && iscell(tracked)
            h = tracked{idx};
        else
            h = tracked(idx,:);
        end
        if isempty(m)||~isnumeric(m)||~isreal(m)||~ismatrix(m)||~any(isfinite(m(:)))
            reason(j) = "Missing or invalid offsetMap";
        elseif isempty(h)
            reason(j) = "Missing ishere";
        else
            assert((isnumeric(h)||islogical(h))&&isvector(h), ...
                'evaluateTrialTracking:Presence','ishere must be a neuron vector.');
            if isempty(mapShape), mapShape = size(m); nNeuron = numel(h); end
            assert(isequal(size(m),mapShape),'evaluateTrialTracking:MapShape', ...
                'Offset map dimensions differ between selected sessions.');
            assert(numel(h)==nNeuron,'evaluateTrialTracking:NeuronCount', ...
                'ishere neuron counts differ between selected sessions.');
        end
    end
    maps{j} = m; presence{j} = h;
end
sessions = table((1:nSession)',opsIndex,nTrials,nInputRows,maps,presence,'VariableNames', ...
    {'inputSessionIndex','opsSessionIndex','nTrials','nInputRows','offsetMap','ishere'});
if useSessionInfo
    sessions.sessionInfoRow = opsIndex;
    sessions.opsSessionIndex(:) = NaN;
end
for name = {'date','sessionName','sessionRec','dayLabel','taskLabel'}
    if ismember(name{1},trials.Properties.VariableNames)
        sessions.(name{1}) = trials.(name{1})(firstSession,:);
    end
end
clear mapsAll tracked si

eligible = reason=="";
excluded = sessions(~eligible,:);
excluded.reason = reason(~eligible);
assert(any(eligible),'evaluateTrialTracking:NoSessions', ...
    'None of the selected sessions has both a finite offsetMap and a nonempty ishere.');
if any(~eligible)
    warning('evaluateTrialTracking:ExcludedSessions', ...
        'Excluded %d sessions (%d unique trials); see tracking.excludedSessions.', ...
        nnz(~eligible),sum(nTrials(~eligible)));
end
sessions = sessions(eligible,:);
nSession = height(sessions);
numerator = zeros(mapShape); denominator = zeros(mapShape);
for j = 1:nSession
    m = double(sessions.offsetMap{j}); finite = isfinite(m);
    numerator(finite) = numerator(finite)+sessions.nTrials(j)*m(finite);
    denominator(finite) = denominator(finite)+sessions.nTrials(j);
end
reference = nan(mapShape);
finite = denominator>0; reference(finite) = numerator(finite)./denominator(finite);
sessions.trialWeight = sessions.nTrials/sum(sessions.nTrials);
sessions.trialPercent = 100*sessions.trialWeight;
sessions.scoreDivisor = ones(size(sessions.trialPercent)); %log(sessions.trialPercent+30);
sessions.meanAbsoluteOffset = zeros(nSession,1);
sessions.nValidPixels = zeros(nSession,1);
sessions.nNeuronsPresent = zeros(nSession,1);
for j = 1:nSession
    m = double(sessions.offsetMap{j}); valid = isfinite(m)&isfinite(reference);
    sessions.meanAbsoluteOffset(j) = mean(abs(m(valid)-reference(valid)));
    sessions.nValidPixels(j) = nnz(valid);
    sessions.nNeuronsPresent(j) = nnz(sessions.ishere{j}==1);
end
sessions.offsetScore = sessions.meanAbsoluteOffset./sessions.scoreDivisor;
if useSessionInfo, indexName = 'sessionInfoRow'; else, indexName = 'opsSessionIndex'; end
sessions = sortrows(sessions,{'offsetScore','nTrials',indexName},{'ascend','descend','ascend'});
sessions.rank = (1:nSession)';
trackedNeurons = false(nNeuron,nSession); common = true(nNeuron,1);
trialSessionRank = nan(height(trials),1);
for j = 1:nSession
    common = common & (sessions.ishere{j}(:)==1);
    trackedNeurons(:,j) = common;
    trialSessionRank(inputSession==sessions.inputSessionIndex(j)) = j;
end
curve = table((1:nSession)',cumsum(sessions.nTrials),sum(trackedNeurons,1)', ...
    'VariableNames',{'nSessions','nTrials','nTrackedNeurons'});
tracking = struct('sourceFile',sources(1),'opsFile',string(opsFile),'presenceFile',presenceFile,'sessions',sessions, ...
    'referenceOffsetMap',reference,'referenceTrialCounts',denominator, ...
    'curve',curve,'trackedNeurons',trackedNeurons, ...
    'trialSessionRank',trialSessionRank,'uniqueTrialMask',uniqueTrialMask, ...
    'excludedSessions',excluded,'figure',[]);
tracking.sessionInfoFile = sessionInfoFile;
if useSessionInfo, tracking.opsFile = ""; end
if p.Results.Plot
    tracking.figure = figure('Color','w','Name','Tracking across selected sessions');
    layout = tiledlayout(tracking.figure,2,1,'TileSpacing','compact');
    ax = nexttile(layout);
    plot(ax,curve.nSessions,curve.nTrackedNeurons,'-o','LineWidth',1.5);
    xlabel(ax,'Sessions taken (lowest offset score first)');
    ylabel(ax,'Common tracked neurons'); grid(ax,'on');
    title(ax,'Cumulative tracking across selected sessions');
    ax = nexttile(layout);
    plot(ax,curve.nSessions,curve.nTrials,'-o','LineWidth',1.5);
    xlabel(ax,'Sessions taken (same ordering)'); ylabel(ax,'Unique selected trials'); grid(ax,'on');
    title(ax,'Trials retained');
end
end
