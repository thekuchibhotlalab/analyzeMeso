function [activity, trialTypeInfo, neuronInfo] = fn_loadTrackedNeuralActivity(sessionInfoFile, tracking, trials, phases, types, varargin)
%FN_LOADTRACKEDNEURALACTIVITY Load grouped neural trials from chosen sessions.
% [activity, trialTypeInfo, neuronInfo] = fn_loadTrackedNeuralActivity( ...
%     sessionInfoFile, tracking, trials, phases, types, 'NumSessions', k)
%
% sessionInfoFile: MAT file containing sessionInfo and its parsed activity
% (e.g. *_parsedTrial.mat). A sessionInfoBeh-only file has no neural activity.
% tracking: tracking struct, selected rows of tracking.sessions, or a vector
% of selected sessionRec identifiers. NumSessions takes the first k entries;
% default is all supplied sessions. Subset tracking.sessions for non-prefix
% choices. Other fields in tracking (including cached neuron masks) are unused.
% trials: one animal's selected trials table; existing RT filters are retained.
% phases: learning-period labels, in output order (e.g. ["T1E","T1M"]).
% types: table with label/stimulus/action, or label/predicate cells as in
% fn_selectNeuralTrials. Overlapping types may contain the same trials.
%
% Options:
% NumSessions     Number of supplied sessions to use (default Inf = all).
% ActivityField   Parsed activity field (default 'dffStim').
% FrameIndices    Frame indices to extract ([] = all; shorter traces get NaNs).
% NeuronSelection 'common' (default): ishere==1 in EVERY chosen session.
%                 'all': retain all neural rows, report the common mask.
%
% activity{s,t}: neurons x frames x trials (single precision).
% trialTypeInfo{s,t}: matching table; row r corresponds to activity{s,t}(:,:,r).
% Tables preserve input order and add inputTrialRow and neuralSessionRow.
% Repeated (sessionRec,trialInSession) pairs count once within each output cell.
% neuronInfo.neuronIDs: original sessionInfo neural rows in the output.
% neuronInfo.commonNeuronMask: mask over ALL original neural rows.
% neuronInfo.ishereBySession: raw flags, original neurons x chosen sessions.
% neuronInfo.sessionRec / sessionInfoRows: chosen identifiers and saved rows.
% The common mask uses every chosen session, even if a requested group is empty.
% Empty groups remain cells with zero trials. No files are modified.

p = inputParser;
addParameter(p,'NumSessions',Inf,@(x)isnumeric(x)&&isscalar(x)&& ...
    ((isfinite(x)&&x>=1&&x==fix(x))||x==Inf));
addParameter(p,'ActivityField','dffStim');
addParameter(p,'FrameIndices',[]);
addParameter(p,'NeuronSelection','common');
parse(p,varargin{:}); o = p.Results;
neuronSelection = validatestring(o.NeuronSelection,{'common','all'});
field = char(o.ActivityField);
if ~isempty(o.FrameIndices)
    validateattributes(o.FrameIndices,{'numeric'},{'vector','integer','positive','finite'});
end
assert(istable(trials)&&all(ismember({'sessionRec','trialInSession','dayLabel'}, ...
    trials.Properties.VariableNames)),'loadTrackedNeuralActivity:Trials', ...
    'trials must contain sessionRec, trialInSession and dayLabel.');
for key = {'animal','animalIndex','sourceFile'}
    if ismember(key{1},trials.Properties.VariableNames)&&~isempty(trials)
        assert(numel(unique(string(trials.(key{1}))))==1, ...
            'loadTrackedNeuralActivity:MixedAnimals','Provide trials from one animal/file only.');
    end
end
phases = string(phases); phases = phases(:);
assert(~isempty(phases)&&~any(ismissing(phases)|phases=="")&& ...
    numel(unique(phases))==numel(phases),'loadTrackedNeuralActivity:Phases', ...
    'Provide unique, nonempty learning phase labels.');
assert(istable(types)&&height(types)>0&&ismember('label',types.Properties.VariableNames), ...
    'loadTrackedNeuralActivity:Types','types must be a nonempty table with label.');
types.label = string(types.label);
custom = ismember('predicate',types.Properties.VariableNames);
assert(numel(unique(types.label))==height(types)&&~any(ismissing(types.label)|types.label=="")&& ...
    (custom||all(ismember({'stimulus','action'},types.Properties.VariableNames))), ...
    'loadTrackedNeuralActivity:Types','Provide unique type labels and stimulus/action or predicate.');
if isstruct(tracking)
    assert(isscalar(tracking)&&isfield(tracking,'sessions'), ...
        'loadTrackedNeuralActivity:Sessions','tracking must contain a sessions table.');
    selected = tracking.sessions;
else
    selected = tracking;
end
if isnumeric(selected), selected = table(selected(:),'VariableNames',{'sessionRec'}); end
assert(istable(selected)&&ismember('sessionRec',selected.Properties.VariableNames)&&height(selected)>0, ...
    'loadTrackedNeuralActivity:Sessions','Provide selected sessions with sessionRec identifiers.');
if isfinite(o.NumSessions)
    assert(o.NumSessions<=height(selected),'loadTrackedNeuralActivity:NumSessions', ...
        'NumSessions exceeds the number of supplied sessions.');
    selected = selected(1:o.NumSessions,:);
end
ids = selected.sessionRec;
validateattributes(ids,{'numeric'},{'column','integer','positive','finite'});
assert(numel(unique(ids))==numel(ids),'loadTrackedNeuralActivity:Sessions', ...
    'Selected sessionRec identifiers must be unique.');

% Only read the neural table, once. File names are independent of metadata
% sourceFile paths: *_trialInfo.mat and *_parsedTrial.mat are often separate.
d = load(char(sessionInfoFile),'sessionInfo');
assert(isfield(d,'sessionInfo')&&istable(d.sessionInfo), ...
    'loadTrackedNeuralActivity:SessionInfo', ...
    'File must contain sessionInfo with parsed neural activity, not just sessionInfoBeh.');
si = d.sessionInfo; clear d
assert(all(ismember({'sessionRec','ishere',field},si.Properties.VariableNames))&&iscell(si.(field)), ...
    'loadTrackedNeuralActivity:Field','sessionInfo needs sessionRec, ishere and parsed cell field %s.',field);
sessionRows = zeros(numel(ids),1); flags = cell(numel(ids),1);
for j = 1:numel(ids)
    row = find(si.sessionRec==ids(j));
    assert(numel(row)==1,'loadTrackedNeuralActivity:Mapping', ...
        'sessionRec %d matches %d sessionInfo rows.',ids(j),numel(row));
    sessionRows(j) = row;
    checkIdentity(selected(j,:),si(row,:));
    if iscell(si.ishere), h = si.ishere{row}; else, h = si.ishere(row,:); end
    assert((isnumeric(h)||islogical(h))&&isvector(h)&&~isempty(h), ...
        'loadTrackedNeuralActivity:Presence','sessionRec %d has no valid ishere vector.',ids(j));
    flags{j} = double(h(:));
end
nNeuron = numel(flags{1});
assert(all(cellfun(@numel,flags)==nNeuron),'loadTrackedNeuralActivity:Dimensions', ...
    'Chosen sessions have different neuron counts.');
ishereBySession = cat(2,flags{:});
common = all(ishereBySession==1,2);
if strcmp(neuronSelection,'common'), neuronIDs = find(common); else, neuronIDs = (1:nNeuron)'; end
neuronInfo = struct('neuronIDs',neuronIDs,'commonNeuronMask',common, ...
    'ishereBySession',ishereBySession,'sessionRec',ids,'sessionInfoRows',sessionRows, ...
    'neuronSelection',string(neuronSelection));

inputRows = find(ismember(trials.sessionRec,ids));
b = trials(inputRows,:);
validateattributes(b.trialInSession,{'numeric'},{'column','integer','positive','finite'});
[~,first] = unique([b.sessionRec b.trialInSession],'rows','stable');
b = b(first,:); inputRows = inputRows(first);
[~,chosenIndex] = ismember(b.sessionRec,ids);
b.inputTrialRow = inputRows;
b.neuralSessionRow = sessionRows(chosenIndex);
trialTypeInfo = cell(numel(phases),height(types));
for t = 1:height(types)
    if custom
        keepType = types.predicate{t}(b);
        assert(islogical(keepType)&&numel(keepType)==height(b), ...
            'loadTrackedNeuralActivity:Predicate','Predicate must return one logical per trial.');
        keepType = keepType(:);
    else
        if ismember('stimuli',b.Properties.VariableNames), stimulus = b.stimuli;
        else
            assert(ismember('stimulus',b.Properties.VariableNames), ...
                'loadTrackedNeuralActivity:Types','trials needs stimuli or stimulus.');
            stimulus = b.stimulus;
        end
        assert(ismember('action',b.Properties.VariableNames), ...
            'loadTrackedNeuralActivity:Types','trials needs action.');
        keepType = stimulus==types.stimulus(t)&b.action==types.action(t);
    end
    for s = 1:numel(phases)
        part = b(keepType & string(b.dayLabel)==phases(s),:);
        part.trialType = repmat(types.label(t),height(part),1);
        trialTypeInfo{s,t} = part;
    end
end

groupedTrials = vertcat(trialTypeInfo{:});
usedRows = unique(groupedTrials.neuralSessionRow);
clear groupedTrials
nFrame = numel(o.FrameIndices);
for row = usedRows'
    x = si.(field){row};
    assert(isnumeric(x)&&isreal(x)&&~isempty(x)&&ndims(x)<=3, ...
        'loadTrackedNeuralActivity:MissingActivity','sessionInfo row %d has no valid %s activity.',row,field);
    assert(size(x,1)==nNeuron,'loadTrackedNeuralActivity:Dimensions', ...
        'Neural row count does not match ishere in sessionInfo row %d.',row);
    if isempty(o.FrameIndices), nFrame = max(nFrame,size(x,2));
    else
        assert(all(o.FrameIndices<=size(x,2)),'loadTrackedNeuralActivity:Frames', ...
            'Requested frame indices exceed activity in sessionInfo row %d.',row);
    end
end
activity = cell(size(trialTypeInfo));
for c = 1:numel(trialTypeInfo)
    part = trialTypeInfo{c};
    z = nan(numel(neuronIDs),nFrame,height(part),'single');
    for row = unique(part.neuralSessionRow)'
        dest = find(part.neuralSessionRow==row);
        checkIdentity(part(dest,:),si(row,:));
        original = part.trialInSession(dest);
        x = si.(field){row};
        assert(all(original<=size(x,3)),'loadTrackedNeuralActivity:TrialIndex', ...
            'trialInSession exceeds activity trials in sessionInfo row %d.',row);
        if ismember('behSel',si.Properties.VariableNames)&&~isempty(si.behSel{row})
            beh = si.behSel{row};
            assert(all(original<=height(beh)),'loadTrackedNeuralActivity:TrialIndex', ...
                'trialInSession exceeds behSel rows in sessionInfo row %d.',row);
            for key = {'RT','stimuli','stimulus','action','stimulusFrame'}
                name = key{1};
                if ismember(name,part.Properties.VariableNames)&&ismember(name,beh.Properties.VariableNames)
                    assert(isequaln(part.(name)(dest,:),beh.(name)(original,:)), ...
                        'loadTrackedNeuralActivity:StaleTrials', ...
                        'Selected %s disagrees with behSel in sessionInfo row %d.',name,row);
                end
            end
        end
        frames = o.FrameIndices;
        if isempty(frames), frames = 1:size(x,2); end
        if ~isempty(neuronIDs)
            z(:,1:numel(frames),dest) = single(x(neuronIDs,frames,original));
        end
    end
    activity{c} = z;
end
end

function checkIdentity(rows, session)
for key = {'date','sessionName','dayLabel'}
    name = key{1};
    if ismember(name,rows.Properties.VariableNames)&&ismember(name,session.Properties.VariableNames)
        assert(all(string(rows.(name))==string(session.(name))), ...
            'loadTrackedNeuralActivity:Identity', ...
            'The %s values disagree for sessionRec %d.',name,session.sessionRec);
    end
end
end
