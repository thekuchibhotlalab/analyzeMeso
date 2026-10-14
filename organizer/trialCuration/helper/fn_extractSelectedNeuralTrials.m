function neuralSelection = fn_extractSelectedNeuralTrials(sessionInfo,selection,cfg)
%FN_EXTRACTSELECTEDNEURALTRIALS Map selected trials to aligned neural arrays.
%
% All dropped-trial tables now have the SAME variables before vertcat.
% Every dropped trial always contains:
%   - sessionInfoRow  (NaN if no neural session exists)
%   - dropReason
%
% Mapping:
%   trialInfo.sessionRec      -> sessionInfo.sessionRec
%   trialInfo.trialInSession -> neural array third dimension

required={'sessionRec',cfg.neuralField};
if cfg.requireGoodTracking
    required{end+1}='goodTracking';
end

missing=setdiff(required,sessionInfo.Properties.VariableNames);
if ~isempty(missing)
    error('sessionInfo missing: %s',strjoin(missing,', '));
end

neuralSelection=selection;

for k=1:numel(selection)

    trials=selection(k).trials;

    chunks={};
    kept={};
    dropped={};
    usedRows=[];

    nBehaviorOnly=0;
    nMissing=0;
    nBadTracking=0;
    nBadIdx=0;

    if isempty(trials)
        neuralSelection(k).neuralRaw=[];
        neuralSelection(k).trialInfoNeural=trials;

        emptyDrop=trials;
        emptyDrop.sessionInfoRow=zeros(0,1);
        emptyDrop.dropReason=strings(0,1);

        neuralSelection(k).droppedTrials=emptyDrop;
        neuralSelection(k).nNeuralTrials=0;
        neuralSelection(k).nBehaviorOnly=0;
        neuralSelection(k).nMissingNeural=0;
        neuralSelection(k).nBadTracking=0;
        neuralSelection(k).nInvalidTrialIndex=0;
        neuralSelection(k).sessionRowsUsed=[];
        continue;
    end

    recList=unique(trials.sessionRec,'stable');

    for rr=1:numel(recList)

        rec=recList(rr);
        trialRows=find(trials.sessionRec==rec | (isnan(trials.sessionRec)&isnan(rec)));

        if ~isfinite(rec) || rec<=0
            nBehaviorOnly=nBehaviorOnly+numel(trialRows);
            temp=trials(trialRows,:);
            temp.sessionInfoRow=nan(height(temp),1);
            temp.dropReason=repmat("behaviorOnly",height(temp),1);
            dropped{end+1,1}=temp; %#ok<AGROW>
            continue;
        end

        sessionRows=find(sessionInfo.sessionRec==rec);

        if isempty(sessionRows)
            nMissing=nMissing+numel(trialRows);
            temp=trials(trialRows,:);
            temp.sessionInfoRow=nan(height(temp),1);
            temp.dropReason=repmat("sessionRecNotFound",height(temp),1);
            dropped{end+1,1}=temp; %#ok<AGROW>
            continue;
        end

        if numel(sessionRows)>1 && ismember('sessionType',sessionInfo.Properties.VariableNames)
            st=string(sessionInfo.sessionType(sessionRows));
            sessionRows=sessionRows(strcmpi(strtrim(st),'2AFC'));
        end

        if numel(sessionRows)~=1
            error('sessionRec=%g maps to %d candidate neural sessions.', ...
                rec,numel(sessionRows));
        end

        s=sessionRows(1);

        % Metadata and neural files may have different row orders.
        for name={'date','sessionName','dayLabel'}
            field=name{1};
            if ismember(field,trials.Properties.VariableNames)&& ...
                    ismember(field,sessionInfo.Properties.VariableNames)
                assert(all(strcmpi(strtrim(string(trials.(field)(trialRows,:))), ...
                    strtrim(string(sessionInfo.(field)(s,:)))),'all'), ...
                    'trialCuration:Identity','%s disagrees for neural sessionRec=%g.',field,rec);
            end
        end

        if cfg.requireGoodTracking && ismember('goodTracking',sessionInfo.Properties.VariableNames)
            good=sessionInfo.goodTracking(s);
            if iscell(good), good=good{1}; end

            if isempty(good) || ~isscalar(good) || ~isfinite(good) || good~=1
                nBadTracking=nBadTracking+numel(trialRows);
                temp=trials(trialRows,:);
                temp.sessionInfoRow=repmat(s,height(temp),1);
                temp.dropReason=repmat("badTracking",height(temp),1);
                dropped{end+1,1}=temp; %#ok<AGROW>
                continue;
            end
        end

        col=sessionInfo.(cfg.neuralField);
        X=col{s};

        if isempty(X)
            nMissing=nMissing+numel(trialRows);
            temp=trials(trialRows,:);
            temp.sessionInfoRow=repmat(s,height(temp),1);
            temp.dropReason=repmat("emptyNeuralArray",height(temp),1);
            dropped{end+1,1}=temp; %#ok<AGROW>
            continue;
        end

        if ~isnumeric(X)||ndims(X)>3
            error('%s row %d is not neurons x time x trials.',cfg.neuralField,s);
        end

        idx=double(trials.trialInSession(trialRows));
        valid=isfinite(idx) & idx>=1 & idx<=size(X,3) & idx==round(idx);

        if any(~valid)
            nBadIdx=nBadIdx+sum(~valid);
            temp=trials(trialRows(~valid),:);
            temp.sessionInfoRow=repmat(s,height(temp),1);
            temp.dropReason=repmat("invalidTrialIndex",height(temp),1);
            dropped{end+1,1}=temp; %#ok<AGROW>
        end

        if ~any(valid), continue; end

        validRows=trialRows(valid);
        validIdx=idx(valid);

        chunks{end+1,1}=X(:,:,validIdx); %#ok<AGROW>

        temp=trials(validRows,:);
        temp.sessionInfoRow=repmat(s,height(temp),1);
        kept{end+1,1}=temp; %#ok<AGROW>
        usedRows(end+1,1)=s; %#ok<AGROW>
    end

    Xall=fn_catChunks(chunks);

    if isempty(kept)
        keptT=trials([],:);
        keptT.sessionInfoRow=zeros(0,1);
    else
        keptT=vertcat(kept{:});
    end

    if isempty(dropped)
        dropT=trials([],:);
        dropT.sessionInfoRow=zeros(0,1);
        dropT.dropReason=strings(0,1);
    else
        dropT=vertcat(dropped{:});
    end

    neuralSelection(k).neuralRaw=Xall;
    neuralSelection(k).trialInfoNeural=keptT;
    neuralSelection(k).droppedTrials=dropT;
    neuralSelection(k).nNeuralTrials=height(keptT);
    neuralSelection(k).nBehaviorOnly=nBehaviorOnly;
    neuralSelection(k).nMissingNeural=nMissing;
    neuralSelection(k).nBadTracking=nBadTracking;
    neuralSelection(k).nInvalidTrialIndex=nBadIdx;
    neuralSelection(k).sessionRowsUsed=unique(usedRows,'stable');

    if cfg.verbose
        fprintf(['    %-24s | neural=%4d | behaviorOnly=%3d | ' ...
                 'missing=%3d | badTrack=%3d | badIdx=%3d\n'], ...
            char(selection(k).name),height(keptT), ...
            nBehaviorOnly,nMissing,nBadTracking,nBadIdx);
    end
end
end

function Xall=fn_catChunks(chunks)
if isempty(chunks), Xall=[]; return; end

nNeuron=size(chunks{1},1);
maxTime=max(cellfun(@(x)size(x,2),chunks));
nTrial=sum(cellfun(@(x)size(x,3),chunks));

Xall=nan(nNeuron,maxTime,nTrial,'single');
cursor=1;

for i=1:numel(chunks)
    X=chunks{i};
    if size(X,1)~=nNeuron
        error('Neuron dimension differs across sessions.');
    end
    nt=size(X,3);
    Xall(:,1:size(X,2),cursor:cursor+nt-1)=single(X);
    cursor=cursor+nt;
end
end
