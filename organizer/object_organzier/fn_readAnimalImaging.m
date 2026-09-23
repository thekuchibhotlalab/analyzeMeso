function [data,selection] = fn_readAnimalImaging(ani,varargin)
%FN_READANIMALIMAGING Explicit session/frame/trial queries against Animal HDF5.
% Select sessions by exactly one of SessionRows, SessionID, ImagingSessionIdx.
% A single session returns an array; several sessions return a column cell.
% Session reads: frames x neurons. Trial reads: neurons x time x trials.
% NeuronIDs are the original tracked column indices (same indexing as ishere).
% WindowFrames contains inclusive [first last] offsets from the alignment event.
% Missing events and frames outside the recording are returned as NaNs.
% Trials use current behSel row indices; selection.trialIDs retains source IDs.
p = inputParser;
addParameter(p,'SessionRows',[]);
addParameter(p,'SessionID',[]);
addParameter(p,'ImagingSessionIdx',[]);
addParameter(p,'Trials',[]);
addParameter(p,'Frames',[]);
addParameter(p,'NeuronIDs',[]);
addParameter(p,'Align','stim');
addParameter(p,'WindowFrames',[-30 69]);
addParameter(p,'Signal',ani.actType);
addParameter(p,'Normalize',isfield(ani.ops,'normSpk') && ani.ops.normSpk);
parse(p,varargin{:}); opts = p.Results;
selectors = {'SessionRows','SessionID','ImagingSessionIdx'};
supplied = ~ismember(selectors,p.UsingDefaults);
if sum(supplied) ~= 1
    error('Animal:SessionSelection','Specify exactly one of SessionRows, SessionID, or ImagingSessionIdx.');
end
if ~isfile(ani.databasePath)
    error('Animal:MissingDatabase','Create the database with Animal(id) before reading imaging.');
end
if supplied(1)
    rows = opts.SessionRows;
    if islogical(rows)
        if numel(rows) ~= height(ani.sessionInfo)
            error('Animal:SessionSelection','SessionRows logical mask must match sessionInfo height.');
        end
        rows = find(rows);
    end
    if ~isempty(rows)
        validateattributes(rows,{'numeric'},{'vector','integer','positive','finite','<=',height(ani.sessionInfo)});
    end
elseif supplied(2)
    [found,rows] = ismember(string(opts.SessionID),ani.sessionInfo.sessionID);
    if ~all(found(:)); error('Animal:SessionSelection','Unknown SessionID.'); end
else
    requested = opts.ImagingSessionIdx;
    if ~isempty(requested); validateattributes(requested,{'numeric'},{'vector','positive','integer','finite'}); end
    [found,rows] = ismember(requested,ani.sessionInfo.imagingSessionIdx);
    if ~all(found(:)); error('Animal:SessionSelection','Unknown ImagingSessionIdx.'); end
end
rows = rows(:);
signal = validatestring(opts.Signal,{'spk','dff'});
signals = strsplit(h5readatt(ani.databasePath,'/','signals'),',');
if ~ismember(signal,signals); error('Animal:MissingSignal','Database has no %s signal.',signal); end
trialQuery = ~ismember('Trials',p.UsingDefaults);
if trialQuery && ~ismember('Frames',p.UsingDefaults)
    error('Animal:QueryOptions','Frames and Trials cannot be combined.');
end
window = opts.WindowFrames;
validateattributes(window,{'numeric'},{'vector','numel',2,'integer','finite'});
if window(2) < window(1); error('Animal:QueryOptions','WindowFrames must be increasing.'); end
align = validatestring(opts.Align,{'stim','choice','reward'});
data = cell(numel(rows),1); selection = cell(numel(rows),1);
for k = 1:numel(rows)
    row = rows(k); info = ani.sessionInfo(row,:);
    if ~info.hasRecording
        error('Animal:NoRecording','Session row %d is behavior-only.',row);
    end
    neurons = opts.NeuronIDs;
    if ismember('NeuronIDs',p.UsingDefaults); neurons = 1:info.nNeurons; end
    if islogical(neurons)
        if numel(neurons) ~= info.nNeurons; error('Animal:NeuronSelection','Neuron mask has the wrong length.'); end
        neurons = find(neurons);
    end
    if ~isempty(neurons)
        validateattributes(neurons,{'numeric'},{'vector','integer','positive','finite','<=',info.nNeurons});
    end
    selection{k} = struct('sessionRow',row,'sessionID',info.sessionID, ...
        'imagingSessionIdx',info.imagingSessionIdx,'neuronIDs',neurons, ...
        'excludedFromAnalysis',info.excludeNeuralAnalysis,'trialIDs',[]);
    if trialQuery
        behavior = info.behSel{1}; trials = opts.Trials;
        if iscell(trials)
            if numel(trials) ~= numel(rows); error('Animal:TrialSelection','Provide one trial vector per selected session.'); end
            trials = trials{k};
        end
        if islogical(trials)
            if numel(trials) ~= height(behavior); error('Animal:TrialSelection','Trial mask has the wrong length.'); end
            trials = find(trials);
        end
        if ~isempty(trials)
            validateattributes(trials,{'numeric'},{'vector','integer','positive','finite','<=',height(behavior)});
        end
        eventFields = struct('stim','stimulusFrame','choice','responseFrame','reward','rewardFrame');
        if isempty(trials)
            events = zeros(0,1);
        else
            events = behavior.(eventFields.(align))(trials);
            events(events <= 0 | events ~= fix(events)) = NaN;
            selection{k}.trialIDs = behavior.trialID(trials);
        end
        frames = (window(1):window(2))' + events(:)';
        selection{k}.frames = frames;
        values = readFrames(frames(:),neurons,info);
        data{k} = permute(reshape(values,[size(frames) numel(neurons)]),[3 1 2]);
    else
        frames = opts.Frames;
        if ismember('Frames',p.UsingDefaults); frames = 1:info.nFrames; end
        if ~isempty(frames)
            validateattributes(frames,{'numeric'},{'vector','integer','positive','finite','<=',info.nFrames});
        end
        selection{k}.frames = frames;
        data{k} = readFrames(frames,neurons,info);
    end
end
if numel(rows) == 1; data = data{1}; selection = selection{1}; end

    function values = readFrames(frames,neurons,info)
        values = nan(numel(frames),numel(neurons),'single');
        rawFrames = info.nFrames - info.neuralPaddingFrames;
        valid = isfinite(frames) & frames >= 1 & frames <= rawFrames;
        if any(valid(:)) && ~isempty(neurons)
            values(valid(:),:) = AnimalH5.readSignal(ani.databasePath, ...
                info.imagingSessionIdx,signal,frames(valid),neurons,opts.Normalize);
        end
    end
end
