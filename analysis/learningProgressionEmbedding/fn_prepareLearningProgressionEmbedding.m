function [r,meanActivity]=fn_prepareLearningProgressionEmbedding(activity,conditions,cfg,trialInfo)
%FN_PREPARELEARNINGPROGRESSIONEMBEDDING Filter, order, reduce and bin any learning period.
% activity: condition x animal; each cell neuron x time x trial, dffStim.
% conditions: matching conditionName, stimulus, action, task, plus optional labels.
% trialInfo: matching tables with dayLabel and sourceTrialRow, in exact trial order.
d=fn_learningProgressionEmbeddingConfig();
if nargin<3||isempty(cfg), cfg=struct(); end
assert(isstruct(cfg)&&isscalar(cfg)&&isempty(setdiff(fieldnames(cfg),fieldnames(d))), ...
    'learningEmbedding:Config','Use options from fn_learningProgressionEmbeddingConfig.');
for f=fieldnames(d)', if ~isfield(cfg,f{1}), cfg.(f{1})=d.(f{1}); end; end
assert(nargin>=4&&iscell(activity)&&ismatrix(activity)&&~isempty(activity)&& ...
    iscell(trialInfo)&&isequal(size(activity),size(trialInfo)), ...
    'learningEmbedding:Input','Provide matching condition x animal activity and trialInfo cells.');
[nc,na]=size(activity);
assert(istable(conditions)&&height(conditions)==nc&& ...
    all(ismember({'conditionName','stimulus','action','task'},conditions.Properties.VariableNames)), ...
    'learningEmbedding:Conditions','Provide one conditionName/stimulus/action/task row per input condition.');
labels=conditions;
for f=labels.Properties.VariableNames
    value=string(labels.(f{1}));
    assert(iscolumn(value)&&all(~ismissing(value)&strlength(value)>0), ...
        'learningEmbedding:Conditions','Each condition column must contain nonempty scalar labels.');
    labels.(f{1})=value;
end
assert(numel(unique(labels.conditionName))==nc,'learningEmbedding:Conditions','Condition names must be unique.');
cfg.phaseOrder=uniqueText(cfg.phaseOrder,'phaseOrder');
cfg.learningPeriods=uniqueText(cfg.learningPeriods,'learningPeriods');
assert(all(ismember(cfg.learningPeriods,cfg.phaseOrder)),'learningEmbedding:Phases','learningPeriods must be in phaseOrder.');
cfg.groupBy=uniqueText(cfg.groupBy,'groupBy');
assert(all(ismember(cfg.groupBy,string(labels.Properties.VariableNames)))&&~any(cfg.groupBy=="conditionName"), ...
    'learningEmbedding:Groups','groupBy must name label columns other than conditionName.');
cfg.responsePeriods=uniqueText(cfg.responsePeriods,'responsePeriods');
assert(all(ismember(cfg.responsePeriods,["stimulus","reward"])), ...
    'learningEmbedding:Periods','Supported responsePeriods are stimulus and reward.');
cfg.normalization=validatestring(cfg.normalization,{'none','zscore'});
cfg.missingAnimal=validatestring(cfg.missingAnimal,{'exclude','error'});
validateattributes(cfg.nBins,{'numeric'},{'scalar','integer','>=',2,'finite'});
validateattributes(cfg.overlap,{'numeric'},{'scalar','>=',0,'<',1,'finite'});
validateattributes(cfg.minTrialsPerBin,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.runUMAP,{'logical'},{'scalar'});
for f={'stimulusOffsets','rewardOffsets'}
    validateattributes(cfg.(f{1}),{'numeric'},{'vector','nonempty','integer','positive','finite'});
end
if ~isempty(cfg.responseTypes), validateattributes(cfg.responseTypes,{'numeric'},{'vector','finite','real'}); end
selected=true(nc,1);
if ~isempty(cfg.trialTypes)
    cfg.trialTypes=uniqueText(cfg.trialTypes,'trialTypes');
    assert(all(ismember(cfg.trialTypes,labels.conditionName)),'learningEmbedding:Selection','Unknown trialTypes name.');
    selected=ismember(labels.conditionName,cfg.trialTypes);
end
assert(isstruct(cfg.select)&&isscalar(cfg.select),'learningEmbedding:Selection','select must be a scalar structure.');
for f=fieldnames(cfg.select)'
    assert(ismember(f{1},labels.Properties.VariableNames),'learningEmbedding:Selection','Unknown filter column %s.',f{1});
    allowed=uniqueText(cfg.select.(f{1}),f{1});
    assert(all(ismember(allowed,labels.(f{1}))),'learningEmbedding:Selection','Unknown label in filter %s.',f{1});
    selected=selected&ismember(labels.(f{1}),allowed);
end
assert(any(selected),'learningEmbedding:Selection','No condition rows satisfy the filters.');
% Group IDs are stable in input order. No string-concatenation keys/collisions.
[~,~,sortedGroup]=unique(labels(selected,cellstr(cfg.groupBy)),'rows');
ids=unique(sortedGroup,'stable'); groupID=zeros(nc,1); rows=find(selected);
for g=1:numel(ids), groupID(rows(sortedGroup==ids(g)))=g; end
ng=numel(ids); groupLabels=table((1:ng)','VariableNames',{'groupIndex'});
for f=labels.Properties.VariableNames
    if strcmp(f{1},'conditionName'), continue; end
    column=strings(ng,1);
    for g=1:ng
        values=unique(labels.(f{1})(groupID==g),'stable');
        if numel(values)==1, column(g)=values; else, column(g)="mixed"; end
    end
    assert(~ismember(f{1},{'groupIndex','groupName','pointIndex','responsePeriod','learningBin','relativeProgress'}), ...
        'learningEmbedding:Conditions','Reserved label column %s.',f{1});
    groupLabels.(f{1})=column;
end
groupName=strings(ng,1);
for g=1:ng
    groupName(g)=join(string(groupLabels{g,cellstr(cfg.groupBy)}),' / ');
end
groupLabels.groupName=groupName;
if isempty(cfg.animalLabels), cfg.animalLabels="Animal "+string(1:na); end
cfg.animalLabels=string(cfg.animalLabels(:));
assert(numel(cfg.animalLabels)==na&&all(~ismissing(cfg.animalLabels)&strlength(cfg.animalLabels)>0), ...
    'learningEmbedding:Animals','Keep one animal label per original input column, including animals with empty cells.');
K=cfg.nBins; ne=numel(cfg.responsePeriods); np=ng*ne*K;
gi=repelem((1:ng)',ne*K); pointInfo=groupLabels(gi,:);
pointInfo.pointIndex=(1:np)'; pointInfo.conditionName="point_"+string((1:np)');
pointInfo.responsePeriod=repmat(repelem(cfg.responsePeriods,K,1),ng,1);
pointInfo.learningBin=repmat((1:K)',ng*ne,1);
pointInfo.relativeProgress=(pointInfo.learningBin-1)/(K-1);
meanActivity=cell(np,na); trialMap=cell(ng,na); windows=trialMap; validTrialCounts=trialMap;
trialCounts=zeros(ng,na); selectedCounts=zeros(nc,na); sourceMetadata=cell(nc,na);
blocks=cell(na,1); neurons=blocks; included=false(na,1); nNeurons=zeros(na,1); dropped=nNeurons; reason=strings(na,1);
normalization=struct('method',cfg.normalization,'offset',{cell(na,1)},'scale',{cell(na,1)}, ...
    'scope','Selected, paired-finite reduced responses across all groups and chosen response periods; before overlapping bins.');
for a=1:na
    Z=cell(nc,1); maps=Z; nn=[];
    for c=find(selected)'
        A=activity{c,a}; if isempty(A), continue; end
        T=trialInfo{c,a};
        assert(istable(T)&&height(T)==size(A,3)&& ...
            all(ismember({'dayLabel','sourceTrialRow'},T.Properties.VariableNames)), ...
            'learningEmbedding:TrialInfo','%s / %s: match activity trials and provide dayLabel/sourceTrialRow.',labels.conditionName(c),cfg.animalLabels(a));
        phase=string(T.dayLabel); keep=ismember(phase,cfg.learningPeriods);
        if ~isempty(cfg.responseTypes)
            assert(ismember('responseType',T.Properties.VariableNames),'learningEmbedding:TrialInfo','responseTypes filter needs responseType metadata.');
            keep=keep&ismember(T.responseType,cfg.responseTypes);
        end
        source=find(keep); if isempty(source), continue; end
        validateattributes(A,{'numeric'},{'real','nonempty'});
        assert(ndims(A)<=3,'learningEmbedding:Activity','Use neuron x time x trial arrays.');
        if isempty(nn), nn=size(A,1); end
        assert(size(A,1)==nn,'learningEmbedding:Neurons','Keep identical neuron rows across selected conditions of %s.',cfg.animalLabels(a));
        T=T(keep,:); N=height(T); selectedCounts(c,a)=N; sourceMetadata{c,a}=T;
        validateattributes(T.sourceTrialRow,{'numeric'},{'column','integer','positive','finite'});
        [~,phaseRank]=ismember(string(T.dayLabel),cfg.phaseOrder);
        values=nan(nn,N,ne); validWindow=false(N,ne);
        for e=1:ne
            switch cfg.responsePeriods(e)
                case "stimulus"
                    centers=repmat(cfg.eventFrame,N,1); offsets=cfg.stimulusOffsets;
                case "reward"
                    fields={cfg.stimulusFrameField,cfg.choiceFrameField};
                    assert(all(ismember(fields,T.Properties.VariableNames)),'learningEmbedding:Timing','Reward needs stimulus/choice frame metadata.');
                    s=T.(fields{1}); q=T.(fields{2});
                    validateattributes(s,{'numeric'},{'column','real','numel',N});
                    validateattributes(q,{'numeric'},{'column','real','numel',N});
                    centers=cfg.eventFrame+double(q)-double(s); offsets=cfg.rewardOffsets;
                    centers(~isfinite(s)|~isfinite(q)|mod(s,1)~=0|mod(q,1)~=0|q<s)=NaN;
            end
            for j=1:N
                frames=centers(j)+offsets;
                validWindow(j,e)=all(isfinite(frames)&frames>=1&frames<=size(A,2)&mod(frames,1)==0);
                if validWindow(j,e), values(:,j,e)=mean(double(A(:,frames,source(j))),2); end
            end
        end
        % Both periods use the same finite trials for each neuron when compared.
        paired=all(isfinite(values),3);
        for e=1:ne, v=values(:,:,e); v(~paired)=NaN; values(:,:,e)=v; end
        Z{c}=values;
        maps{c}=table(repmat(c,N,1),source,(1:N)',T.sourceTrialRow,string(T.dayLabel),phaseRank,validWindow, ...
            'VariableNames',{'sourceCondition','sourceTrial','metadataRow','sourceTrialRow','dayLabel','phaseRank','validWindow'});
    end
    nonempty=find(~cellfun(@isempty,maps));
    if isempty(nonempty), reason(a)="No trials in the selected phases/conditions.";
    else
        allMap=vertcat(maps{nonempty});
        assert(numel(unique(allMap.sourceTrialRow))==height(allMap),'learningEmbedding:DuplicateTrial', ...
            '%s has duplicate sourceTrialRow values across selected conditions. Supply each physical trial once.',cfg.animalLabels(a));
        allZ=cat(2,Z{nonempty}); mu=zeros(nn,1); scale=ones(nn,1);
        if strcmp(cfg.normalization,'zscore')
            samples=reshape(allZ,nn,[]); mu=mean(samples,2,'omitnan'); scale=std(samples,0,2,'omitnan'); scale(scale==0)=1;
        end
        normalization.offset{a}=mu; normalization.scale{a}=scale;
        values=nan(nn,np);
        for g=1:ng
            cs=find(groupID==g&~cellfun(@isempty,maps));
            if isempty(cs), reason(a)="No trials for group "+groupName(g); break; end
            M=vertcat(maps{cs}); V=cat(2,Z{cs});
            [~,order]=sortrows([M.phaseRank M.sourceTrialRow],[1 2]); M=M(order,:); V=V(:,order,:);
            N=height(M); trialCounts(g,a)=N; trialMap{g,a}=M;
            denominator=1+(K-1)*(1-cfg.overlap);
            left=(0:K-1)'*(1-cfg.overlap)/denominator;
            first=round(N*left)+1; last=round(N*(left+1/denominator)); count=last-first+1;
            if N<K||numel(unique(first))<K||any(count<cfg.minTrialsPerBin)
                reason(a)=sprintf('%s: %d trials cannot supply %d bins with >=%d trials.',groupName(g),N,K,cfg.minTrialsPerBin); break;
            end
            overlapWithPrevious=[NaN;max(0,last(1:end-1)-first(2:end)+1)./count(1:end-1)];
            phaseCounts=zeros(K,numel(cfg.phaseOrder));
            for b=1:K
                for ph=1:numel(cfg.phaseOrder), phaseCounts(b,ph)=sum(M.phaseRank(first(b):last(b))==ph); end
            end
            windows{g,a}=table((1:K)',first,last,count,overlapWithPrevious,M.dayLabel(first),M.dayLabel(last),phaseCounts, ...
                'VariableNames',{'learningBin','firstTrial','lastTrial','nTrials','overlapWithPrevious','phaseStart','phaseEnd','phaseCounts'});
            V=(V-mu)./scale; validTrialCounts{g,a}=zeros(nn,K);
            for b=1:K
                ix=first(b):last(b); good=all(isfinite(V(:,ix,:)),3); n=sum(good,2);
                validTrialCounts{g,a}(:,b)=n;
                for e=1:ne
                    v=mean(V(:,ix,e),2,'omitnan'); v(n<cfg.minTrialsPerBin)=NaN;
                    values(:,(g-1)*ne*K+(e-1)*K+b)=v;
                end
            end
        end
        if reason(a)==""
            valid=all(isfinite(values),2); dropped(a)=sum(~valid); nNeurons(a)=sum(valid);
            if ~any(valid), reason(a)="No neurons finite across all bins/groups/periods.";
            else
                included(a)=true; blocks{a}=values(valid,:)';
                neurons{a}=table(repmat(a,sum(valid),1),repmat(cfg.animalLabels(a),sum(valid),1),find(valid), ...
                    'VariableNames',{'animalIndex','animalLabel','rowInAnimal'});
                for q=1:np, meanActivity{q,a}=values(:,q); end
            end
        end
    end
    if ~included(a)
        assert(~strcmp(cfg.missingAnimal,'error'),'learningEmbedding:Animal','%s: %s',cfg.animalLabels(a),reason(a));
        fprintf('Learning embedding: skipping %s: %s\n',cfg.animalLabels(a),reason(a));
    end
end
assert(any(included),'learningEmbedding:Empty','No animal can supply the selected progression groups/bins.');
r=struct('cfg',cfg,'conditions',conditions,'selectedConditionMask',selected,'groupLabels',groupLabels, ...
    'pointInfo',pointInfo,'populationVectors',cat(2,blocks{included}),'neurons',vertcat(neurons{included}), ...
    'normalization',normalization,'trialCounts',trialCounts,'selectedTrialCounts',selectedCounts);
r.windows=windows; r.trialMap=trialMap; r.sourceMetadata=sourceMetadata; r.validTrialCounts=validTrialCounts;
r.animalAudit=table((1:na)',cfg.animalLabels,included,nNeurons,dropped,reason, ...
    'VariableNames',{'animalIndex','animalLabel','included','nNeurons','nDroppedNeurons','reason'});
r.estimation='One point per group x response period x learning bin. Animals concatenate as neural features; bins match relative progress, not simultaneous trials or common phase boundaries.';
end

function x=uniqueText(x,name)
x=string(x(:));
assert(~isempty(x)&&all(~ismissing(x)&strlength(x)>0)&&numel(unique(x))==numel(x), ...
    'learningEmbedding:Config','%s must contain unique nonempty labels.',name);
end
