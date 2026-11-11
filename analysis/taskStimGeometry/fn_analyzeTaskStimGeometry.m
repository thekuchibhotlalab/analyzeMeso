function [result,figures]=fn_analyzeTaskStimGeometry(activity,conditions,cfg,plotCfg,trialInfo)
%FN_ANALYZETASKSTIMGEOMETRY Binary LDA on one reduced response per neuron/trial.
% activity: condition x animal cells, neuron x time x trial, stimulus aligned.
% conditions: conditionName, stimulus (plot color), and three or six binary columns.
% Empty comparison labels exclude that condition from THAT axis fit only.
% Keep ALL animal columns and labels: animals with any empty activity cell
% are skipped automatically (default missingAnimal='exclude').
% trialInfo: optional matching tables; required for reward timing. Original
% cell trial indices and supplied metadata are retained in pseudo-trial maps.
[defaults,~]=fn_taskStimGeometryConfig();
if nargin<3, cfg=struct(); end
if nargin<4, plotCfg=struct(); end
cfg=options(cfg,defaults);
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity),'taskStim:Input', ...
    'Use a nonempty condition x animal activity cell array.');
[nc,na]=size(activity);
if nargin<5||isempty(trialInfo), trialInfo=cell(nc,na); end
assert(iscell(trialInfo)&&isequal(size(trialInfo),size(activity)), ...
    'taskStim:TrialInfo','trialInfo must have the same cell dimensions as activity.');
cfg.period=validatestring(cfg.period,{'stimulus','reward'});
cfg.normalization=validatestring(cfg.normalization,{'none','zscore'});
cfg.covariance=validatestring(cfg.covariance,{'withinAnimal','diagonal'});
cfg.missingAnimal=validatestring(cfg.missingAnimal,{'exclude','error'});
assert(strcmpi(cfg.neuralField,'dffStim'),'taskStim:Alignment','Input must be stimulus-aligned dffStim.');
validateattributes(cfg.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.ridge,{'numeric'},{'scalar','positive','finite'});
validateattributes(cfg.minTrials,{'numeric'},{'scalar','integer','>=',2,'finite'});
validateattributes(cfg.seed,{'numeric'},{'scalar','integer','nonnegative','finite','<=',2^32-1});
for field={'stimulusOffsets','rewardOffsets'}
    validateattributes(cfg.(field{1}),{'numeric'},{'vector','integer','positive','finite','nonempty'});
end
if ~isempty(cfg.nPseudoTrials)
    validateattributes(cfg.nPseudoTrials,{'numeric'},{'scalar','integer','positive','finite'});
end
cfg.comparisons=string(cfg.comparisons(:));
nf=numel(cfg.comparisons);
assert(ismember(nf,[3 6])&&numel(unique(cfg.comparisons))==nf, ...
    'taskStim:Conditions','Specify three or six distinct comparison columns.');
required=["conditionName";"stimulus";cfg.comparisons];
assert(istable(conditions)&&height(conditions)==nc&& ...
    all(ismember(required,string(conditions.Properties.VariableNames))), ...
    'taskStim:Conditions','Provide conditionName, stimulus and all configured binary comparison columns.');
names=string(conditions.conditionName); stimuli=string(conditions.stimulus);
assert(iscolumn(names)&&iscolumn(stimuli)&&numel(unique(names))==nc&& ...
    all(~ismissing(names)&strlength(names)>0&~ismissing(stimuli)&strlength(stimuli)>0), ...
    'taskStim:Conditions','Use unique condition names and one nonempty stimulus label per row.');
groups=zeros(nc,nf); levels=cell(nf,1);
for f=1:nf
    labels=string(conditions.(cfg.comparisons(f)));
    assert(iscolumn(labels),'taskStim:Conditions','Comparison labels must be columns.');
    used=~ismissing(labels)&strlength(labels)>0;
    levels{f}=unique(labels(used),'stable');
    assert(numel(levels{f})==2,'taskStim:Conditions','%s must have exactly two nonempty levels.',cfg.comparisons(f));
    [~,groups(used,f)]=ismember(labels(used),levels{f});
end
if isempty(cfg.animalLabels), cfg.animalLabels="Animal "+string(1:na); end
cfg.animalLabels=string(cfg.animalLabels(:));
assert(numel(cfg.animalLabels)==na&&all(~ismissing(cfg.animalLabels)&strlength(cfg.animalLabels)>0), ...
    'taskStim:Animals', ...
    ['Received %d animal labels for %d input columns. Keep the original activity, metadata, ' ...
    'and label columns; empty animals are excluded automatically. Use animalLabels=[] for automatic labels.'], ...
    numel(cfg.animalLabels),na);
[X,maps,neurons,audit,normInfo,counts]=reduce(activity,trialInfo,cfg,names);
for a=find(~audit.included)'
    fprintf('Task/stim geometry: skipping %s (input column %d): %s\n', ...
        cfg.animalLabels(a),a,audit.reason(a));
end
n=height(neurons); M=zeros(n,nc); blocks=cell(nc,na); indices=cell(na,1);
for a=1:na
    ix=find(neurons.animalIndex==a); indices{a}=ix;
    if isempty(ix), continue; end
    for c=1:nc
        Z=X{c,a}; M(ix,c)=mean(Z,2); Z=Z-mean(Z,2);
        if strcmp(cfg.covariance,'diagonal'), blocks{c,a}=sum(Z.^2,2)/(size(Z,2)-1);
        else, blocks{c,a}=(Z*Z')/(size(Z,2)-1); end
    end
end
W=nan(n,nf); thresholds=nan(1,nf); fits=struct([]);
for f=1:nf
    g=groups(:,f); mu=zeros(n,2); alpha=zeros(nc,1);
    for l=1:2
        mu(:,l)=mean(M(:,g==l),2); alpha(g==l)=1/(2*sum(g==l));
    end
    selected=find(g>0);
    % Mixture covariance includes cross-animal CONDITION-mean differences.
    % Only trial noise between separate animals is assumed independent.
    D=zeros(n,numel(selected));
    for j=1:numel(selected)
        c=selected(j); D(:,j)=sqrt(alpha(c))*(M(:,c)-mu(:,g(c)));
    end
    B=cell(na,1); diagonal=zeros(n,1);
    for a=1:na
        ix=indices{a}; if isempty(ix), continue; end
        B{a}=zeros(size(blocks{selected(1),a}));
        for c=selected', B{a}=B{a}+alpha(c)*blocks{c,a}; end
        if strcmp(cfg.covariance,'diagonal'), diagonal(ix)=B{a};
        else, diagonal(ix)=diag(B{a}); end
    end
    base=mean(diagonal+sum(D.^2,2)); if base<=0, base=1; end
    lambda=cfg.ridge*base; delta=mu(:,2)-mu(:,1);
    % Woodbury solve for blockdiag(within-condition noise)+D*D'+ridge*I.
    inverse=zeros(n,1+size(D,2)); rhs=[delta D];
    for a=1:na
        ix=indices{a}; if isempty(ix), continue; end
        if strcmp(cfg.covariance,'diagonal'), inverse(ix,:)=rhs(ix,:)./(B{a}+lambda);
        else, inverse(ix,:)=(B{a}+lambda*eye(numel(ix)))\rhs(ix,:); end
    end
    v=inverse(:,1); U=inverse(:,2:end);
    w=v-U*((eye(size(D,2))+D'*U)\(D'*v));
    valid=norm(delta)>1e-12*max(1,norm(mu,'fro'))&&norm(w)>0;
    if valid
        W(:,f)=w/norm(w); thresholds(f)=W(:,f)'*mean(mu,2);
    end
    fits(f).name=cfg.comparisons(f); fits(f).levels=levels{f};
    fits(f).conditionIndices=selected; fits(f).classMeans=mu;
    fits(f).regularization=lambda; fits(f).valid=valid;
end
result=struct('cfg',cfg,'conditions',conditions,'neurons',neurons, ...
    'animalAudit',audit,'normalization',normInfo,'trialCounts',counts, ...
    'weights',W,'thresholds',thresholds,'fits',fits,'conditionMeans',M);
result.axisInfo=table(cfg.comparisons,string(cellfun(@(x)x(1),levels)), ...
    string(cellfun(@(x)x(2),levels)),thresholds',reshape([fits.valid],[],1), ...
    'VariableNames',{'comparison','negativeClass','positiveClass','threshold','valid'});
result.reducedActivity=X; result.trialMap=maps;
result.includedAnimalIndices=find(audit.included);
result.includedAnimalLabels=cfg.animalLabels(audit.included);
result.weightsRaw=W./normInfo.scale;
result.thresholdsRaw=thresholds+(W'*(normInfo.offset./normInfo.scale))';
result.cosine=W'*W;
result.cosine(result.cosine>1)=1; result.cosine(result.cosine< -1)=-1;
result.angleDegrees=acosd(result.cosine); % Oriented angles: 0 parallel, 90 orthogonal, 180 opposite.
result.estimation='In-sample regularized LDA; equal classes and equal conditions within each class. Not cross-validated.';
result.assumption='Pooled neurons; cross-animal within-condition trial noise is independent. Plotted multi-animal points are pseudo-trials.';
result.projection=fn_projectTaskStimTrials(X,maps,W,thresholds,indices,cfg,nc,na);
[figures,result.plotFiles]=fn_plotTaskStimGeometry(result,plotCfg);
end

function [X,maps,neurons,audit,info,counts]=reduce(activity,trialInfo,cfg,conditionNames)
[nc,na]=size(activity); X=cell(nc,na); maps=X; counts=zeros(nc,na);
neurons=table(); included=false(na,1); nNeurons=zeros(na,1); dropped=zeros(na,1); reason=strings(na,1);
info=struct('method',cfg.normalization,'offset',[],'scale',[], ...
    'scope','All reduced response trials across supplied conditions per neuron, before fitting.');
for a=1:na
    % Exclude the entire animal BEFORE reading its metadata or other cells.
    % Retain original input-column indices in outputs for unambiguous mapping.
    emptyConditions=cellfun(@isempty,activity(:,a));
    if any(emptyConditions)
        reason(a)="Empty activity for: "+strjoin(conditionNames(emptyConditions),", ");
        if strcmp(cfg.missingAnimal,'error')
            error('taskStim:Animal','Animal %s (column %d): %s',cfg.animalLabels(a),a,reason(a));
        end
        continue;
    end
    nn=[];
    for c=1:nc
        A=activity{c,a}; if isempty(A), continue; end
        validateattributes(A,{'numeric'},{'real','nonempty'});
        assert(ndims(A)<=3,'taskStim:Input','Use neuron x time x trial arrays.');
        if isempty(nn), nn=size(A,1); end
        assert(size(A,1)==nn,'taskStim:Neurons','Match tracked neuron rows across conditions in animal %d.',a);
        nt=size(A,3); T=trialInfo{c,a};
        if isempty(T), T=table((1:nt)','VariableNames',{'inputTrial'}); end
        assert(istable(T),'taskStim:TrialInfo', ...
            'Metadata for %s / %s (cell %d,%d) must be a table.',conditionNames(c),cfg.animalLabels(a),c,a);
        assert(height(T)==nt,'taskStim:TrialInfo', ...
            ['%s / %s (cell %d,%d): activity has %d trials but metadata has %d rows. ' ...
            'Select both from the same neuralSelection entry; check intNames against conditions.conditionName.'], ...
            conditionNames(c),cfg.animalLabels(a),c,a,nt,height(T));
        if strcmp(cfg.period,'stimulus')
            centers=repmat(cfg.eventFrame,nt,1); offsets=cfg.stimulusOffsets;
        else
            fields={cfg.stimulusFrameField,cfg.choiceFrameField};
            assert(all(ismember(fields,T.Properties.VariableNames)),'taskStim:TrialInfo', ...
                'Reward period needs stimulusFrame and responseFrame (or configured field names).');
            s=T.(fields{1}); q=T.(fields{2});
            validateattributes(s,{'numeric'},{'column','numel',nt,'real'});
            validateattributes(q,{'numeric'},{'column','numel',nt,'real'});
            centers=cfg.eventFrame+double(q)-double(s); offsets=cfg.rewardOffsets;
            centers(~isfinite(s)|~isfinite(q)|mod(s,1)~=0|mod(q,1)~=0|q<s)=NaN;
        end
        Z=nan(nn,nt); valid=false(nt,1);
        for j=1:nt
            frames=centers(j)+offsets;
            valid(j)=all(isfinite(frames)&mod(frames,1)==0&frames>=1&frames<=size(A,2));
            if valid(j), Z(:,j)=mean(double(A(:,frames,j)),2); end
        end
        X{c,a}=Z(:,valid); counts(c,a)=sum(valid);
        maps{c,a}=struct('sourceTrial',find(valid),'metadata',T(valid,:), ...
            'invalidWindowTrials',find(~valid));
    end
    if any(counts(:,a)<cfg.minTrials)
        reason(a)="At least one condition has fewer than minTrials valid event windows.";
    else
        allX=cat(2,X{:,a}); keep=all(isfinite(allX),2); dropped(a)=sum(~keep);
        if ~any(keep), reason(a)="No neuron has finite responses across all retained trials.";
        else
            z=allX(keep,:); mu=zeros(sum(keep),1); scale=ones(sum(keep),1);
            if strcmp(cfg.normalization,'zscore')
                mu=mean(z,2); scale=std(z,0,2); scale(scale==0)=1;
            end
            for c=1:nc, X{c,a}=(X{c,a}(keep,:)-mu)./scale; end
            included(a)=true; nNeurons(a)=sum(keep);
            rows=find(keep); labels=repmat(cfg.animalLabels(a),numel(rows),1);
            neurons=[neurons;table(repmat(a,numel(rows),1),labels,rows, ...
                'VariableNames',{'animalIndex','animalLabel','rowInAnimal'})]; %#ok<AGROW>
            info.offset=[info.offset;mu]; info.scale=[info.scale;scale]; %#ok<AGROW>
        end
    end
    if ~included(a)
        X(:,a)={[]};
        if strcmp(cfg.missingAnimal,'error'), error('taskStim:Animal','Animal %d: %s',a,reason(a)); end
    end
end
assert(any(included),'taskStim:Empty','No animal has usable data for all conditions.');
audit=table((1:na)',cfg.animalLabels,included,nNeurons,dropped,reason, ...
    'VariableNames',{'animalIndex','animalLabel','included','nNeurons','nDroppedNeurons','reason'});
end

function cfg=options(cfg,defaults)
assert(isstruct(cfg)&&isscalar(cfg)&&isempty(setdiff(fieldnames(cfg),fieldnames(defaults))), ...
    'taskStim:Config','Use supported fields from fn_taskStimGeometryConfig.');
for name=fieldnames(defaults)'
    if ~isfield(cfg,name{1}), cfg.(name{1})=defaults.(name{1}); end
end
end

