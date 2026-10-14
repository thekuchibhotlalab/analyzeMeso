function [activity, ishere] = fn_loadSelectedNeuralActivity(trialTypeInfo, files, varargin)
%FN_LOADSELECTEDNEURALACTIVITY Map selected tables back to parsed activity.
% [activity, ishere] = fn_loadSelectedNeuralActivity(trialTypeInfo,files,...)
% files must be in the same animal order used by fn_selectNeuralTrials.
% Both outputs have the SAME learning period x trial type x animal layout.
% activity{s,t,a}: NEURONS x FRAMES x TRIALS, in table-row order.
% size(activity{s,t,a},3) == height(trialTypeInfo{s,t,a}).
% ishere{s,t,a}: raw sessionInfo.ishere entries repeated in table-row order;
% empty cells when the source has no ishere column. No neuron masking occurs.
%
% ActivityField   Parsed field ('dffStim' by default).
% FrameIndices    Frames to extract ([]: all, pad shorter traces with NaN).
% MissingActivity 'nan' (default): behavior-only trials keep their position
%                 with NaN activity. 'error': stop on missing activity.
%
% Mapping uses date + sessionName when available, otherwise sessionRec.
% sessionRec is an identifier, NEVER assumed to equal the sessionInfo row.
% trialInSession indexes the third activity dimension. When behSel exists,
% RT/stimulus/action are checked to catch stale or incorrectly mapped tables.
% Loads sessionInfo once per animal and keeps every neural row unchanged
% (single precision). Empty trial tables require no neural-file load.

p = inputParser;
addParameter(p,'ActivityField','dffStim');
addParameter(p,'FrameIndices',[]);
addParameter(p,'MissingActivity','nan');
parse(p,varargin{:}); o = p.Results;
o.ActivityField = char(o.ActivityField);
o.MissingActivity = validatestring(o.MissingActivity,{'nan','error'});
if ~isempty(o.FrameIndices)
    validateattributes(o.FrameIndices,{'numeric'},{'vector','integer','positive','finite'});
end
assert(iscell(trialTypeInfo)&&ndims(trialTypeInfo)<=3, ...
    'loadSelectedNeuralActivity:Input','Expected a learning period x trial type x animal cell array.');
files = string(files); files = files(:);
assert(numel(files)==size(trialTypeInfo,3),'loadSelectedNeuralActivity:Files', ...
    'Provide one file per animal in the original animal order.');
activity = cell(size(trialTypeInfo)); ishere = cell(size(trialTypeInfo));
nGroups = size(trialTypeInfo,1)*size(trialTypeInfo,2);
for a = 1:numel(files)
    cells = (a-1)*nGroups+(1:nGroups);
    for c = cells
        assert(istable(trialTypeInfo{c}),'loadSelectedNeuralActivity:Input', ...
            'Each input cell must contain a table.');
        activity{c} = zeros(0,numel(o.FrameIndices),0,'single');
        ishere{c} = cell(0,1);
    end
    if all(cellfun(@isempty,trialTypeInfo(cells))), continue; end
    [ok,info] = fileattrib(char(files(a)));
    assert(ok,'loadSelectedNeuralActivity:File','Cannot access %s.',files(a));
    canonical = string(info.Name);
    for c = cells
        b = trialTypeInfo{c}; if isempty(b), continue; end
        assert(all(ismember({'sourceFile','animalIndex','trialInSession'},b.Properties.VariableNames)), ...
            'loadSelectedNeuralActivity:Columns','Use tables returned by fn_selectNeuralTrials.');
        assert(all(strcmpi(string(b.sourceFile),canonical))&&all(b.animalIndex==a), ...
            'loadSelectedNeuralActivity:Source','Table source does not match animal file %d.',a);
    end
    d = load(char(files(a)),'sessionInfo');
    assert(isfield(d,'sessionInfo')&&istable(d.sessionInfo), ...
        'loadSelectedNeuralActivity:Table','%s lacks a sessionInfo table.',files(a));
    si = d.sessionInfo; clear d
    assert(ismember(o.ActivityField,si.Properties.VariableNames)&&iscell(si.(o.ActivityField)), ...
        'loadSelectedNeuralActivity:Field','sessionInfo lacks parsed cell field %s.',o.ActivityField);
    mapped = cell(numel(cells),1); selectedSessions = [];
    for j = 1:numel(cells)
        b = trialTypeInfo{cells(j)};
        if isempty(b), continue; end
        rows = zeros(height(b),1);
        validateattributes(b.trialInSession,{'numeric'},{'column','integer','positive','finite'});
        for k = 1:height(b)
            if all(ismember({'date','sessionName'},b.Properties.VariableNames))&& ...
                    all(ismember({'date','sessionName'},si.Properties.VariableNames))
                hit = find(si.date==b.date(k)&string(si.sessionName)==string(b.sessionName(k)));
            elseif ismember('sessionRec',b.Properties.VariableNames)&&ismember('sessionRec',si.Properties.VariableNames)
                hit = find(si.sessionRec==b.sessionRec(k));
            else
                error('loadSelectedNeuralActivity:Keys','Need date/sessionName or sessionRec in both tables.');
            end
            assert(numel(hit)==1,'loadSelectedNeuralActivity:Mapping', ...
                'Animal %d, selected row %d has %d matching sessions.',a,k,numel(hit));
            rows(k) = hit;
        end
        mapped{j} = rows; selectedSessions = [selectedSessions;rows]; %#ok<AGROW>
    end
    nNeuron = 0; nFrame = numel(o.FrameIndices);
    for row = unique(selectedSessions)'
        x = si.(o.ActivityField){row};
        if isempty(x), continue; end
        assert(isnumeric(x)&&isreal(x)&&ndims(x)<=3, ...
            'loadSelectedNeuralActivity:Dimensions','Parsed activity must be neurons x frames x trials.');
        if nNeuron==0, nNeuron = size(x,1); end
        assert(nNeuron==size(x,1),'loadSelectedNeuralActivity:Dimensions', ...
            'Activity row count differs between selected sessions.');
        if isempty(o.FrameIndices), nFrame = max(nFrame,size(x,2));
        else
            assert(all(o.FrameIndices<=size(x,2)),'loadSelectedNeuralActivity:Frames', ...
                'Session %d does not contain all requested frames.',row);
        end
    end
    % If all selected trials are behavior-only, infer row/time dimensions
    % from any parsed recording in this animal, without selecting its trials.
    if nNeuron==0
        ref = find(~cellfun(@isempty,si.(o.ActivityField)),1);
        if ~isempty(ref)
            nNeuron = size(si.(o.ActivityField){ref},1);
            if isempty(o.FrameIndices), nFrame = size(si.(o.ActivityField){ref},2); end
        end
    end
    for j = 1:numel(cells)
        c = cells(j); b = trialTypeInfo{c}; rows = mapped{j};
        activity{c} = nan(nNeuron,nFrame,height(b),'single');
        ishere{c} = cell(height(b),1);
        for row = unique(rows)'
            dest = find(rows==row); original = b.trialInSession(dest);
            if ismember('ishere',si.Properties.VariableNames)
                if iscell(si.ishere), value = si.ishere{row}; else, value = si.ishere(row,:); end
                ishere{c}(dest) = repmat({value},numel(dest),1);
            end
            if ismember('behSel',si.Properties.VariableNames)&&~isempty(si.behSel{row})
                beh = si.behSel{row};
                assert(all(original<=height(beh)),'loadSelectedNeuralActivity:TrialIndex', ...
                    'trialInSession exceeds behSel rows in session %d.',row);
                for name = {'RT','stimuli','stimulus','action','stimulusFrame'}
                    key = name{1};
                    if ismember(key,b.Properties.VariableNames)&&ismember(key,beh.Properties.VariableNames)
                        assert(isequaln(b.(key)(dest,:),beh.(key)(original,:)), ...
                            'loadSelectedNeuralActivity:StaleTrials', ...
                            'Selected %s does not match behSel in session %d.',key,row);
                    end
                end
            end
            x = si.(o.ActivityField){row};
            if isempty(x)
                assert(strcmp(o.MissingActivity,'nan'),'loadSelectedNeuralActivity:MissingActivity', ...
                    'Session %d has no %s activity.',row,o.ActivityField);
                continue
            end
            assert(all(original<=size(x,3)),'loadSelectedNeuralActivity:TrialIndex', ...
                'trialInSession exceeds parsed activity trials in session %d.',row);
            frames = o.FrameIndices;
            if isempty(frames), frames = 1:size(x,2); end
            activity{c}(:,1:numel(frames),dest) = single(x(:,frames,original));
        end
    end
    clear si x
end
end

