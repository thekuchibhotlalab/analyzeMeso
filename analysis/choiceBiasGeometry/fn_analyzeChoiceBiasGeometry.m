function [result,figures]=fn_analyzeChoiceBiasGeometry(allTrialsel,cfg,p)
%FN_ANALYZECHOICEBIASGEOMETRY Held-out choice-axis projections by task/animal.
% Input: cell array of fn_prepareNeuralData outputs, annotated BEFORE selection
% using fn_addChoiceBias. Uses actual action (1=L,2=R), including error trials.
[d,dp]=fn_choiceBiasGeometryConfig();
if nargin<2, cfg=struct(); end
if nargin<3, p=struct(); end
cfg=merge(cfg,d); p=merge(p,dp);
for name={'choiceFrame','choiceFrames','biasWindow','minTrialsPerAction','minBinTrialsPerAction','folds'}
    validateattributes(cfg.(name{1}),{'numeric'},{'scalar','integer','positive'});
end
assert(cfg.folds>=2&&cfg.minTrialsPerAction>=2,'choiceBias:Config','Need at least two folds and two trials per action.');
assert(cfg.ridge>0&&cfg.unbiasedThreshold<cfg.biasedThreshold,'choiceBias:Config','Use positive ridge and ordered bias thresholds.');
validateattributes(cfg.itiFrames,{'numeric'},{'vector','integer','positive','finite','nonempty'});
pre=reshape(cfg.itiFrames,1,[]); choice=cfg.choiceFrame+(-cfg.choiceFrames:-1);
assert(all(diff(pre)>0)&&all(pre<min(choice))&&all(choice>=1), ...
    'choiceBias:Window','ITI frames must be ordered and precede the pre-choice window.');
assert(iscell(allTrialsel)&&~isempty(allTrialsel),'choiceBias:Input','Use a cell array of neural selections.');
stream=RandStream('mt19937ar','Seed',cfg.seed); entries=struct([]); bins=table(); audit=table();
for a=1:numel(allTrialsel)
    S=allTrialsel{a}; assert(strcmpi(S.cfg.neuralField,'dffChoice'),'choiceBias:Alignment','Load dffChoice.');
    if isfield(S.cfg,'alignedEventFrame')
        assert(S.cfg.alignedEventFrame==cfg.choiceFrame, ...
            'choiceBias:Alignment','Configured event frames do not match loaded alignment.');
    end
    label=string(S.animalID); T=table(); chunks={};
    for c=1:numel(S.neuralSelection)
        Q=S.neuralSelection(c); if isempty(Q.neuralRaw), continue; end
        M=Q.trialInfoNeural;
        required={'choiceBias','choiceBiasTask','choiceBiasBlock','choiceBiasBlockValue','choiceBiasBlockN','action','sourceTrialRow','dayLabel'};
        assert(all(ismember(required,M.Properties.VariableNames)),'choiceBias:Metadata','Annotate full trialInfo with fn_addChoiceBias before loading neural trials.');
        use=strcmpi(string(M.dayLabel),'Int')&ismember(M.action,[1 2]);
        mask=S.tracking.selectedNeuronMask;
        assert(numel(mask)==size(Q.neuralRaw,1),'choiceBias:Neurons','Neuron mask must match neuralRaw rows.');
        chunks{end+1}=Q.neuralRaw(mask,:,use); T=[T;M(use,:)]; %#ok<AGROW>
    end
    if isempty(T), continue; end
    X=cat(3,chunks{:}); clear chunks
    assert(size(X,2)>=cfg.choiceFrame,'choiceBias:Alignment','dffChoice must contain the configured choice-onset frame.');
    [~,uniqueRows]=unique(T.sourceTrialRow,'stable'); T=T(uniqueRows,:); X=X(:,:,uniqueRows);
    for task=1:2
        ids=find(T.choiceBiasTask==task); M=T(ids,:); A=double(X(:,:,ids));
        nn=size(A,1); nInput=height(M);
        % A shared finite-neuron set across the two analysis windows.
        keep=all(isfinite(A(:,[pre choice],:)),[2 3]); A=A(keep,:,:);
        L=M.action==1; nL=sum(L); nR=sum(~L); status="included";
        if ~any(keep), status="No finite tracked neurons";
        elseif min(nL,nR)<cfg.minTrialsPerAction, status="Too few L or R trials"; end
        audit=[audit;table(a,label,task,nInput,nL,nR,nn,sum(keep),status, ...
            'VariableNames',{'animalIndex','animal','task','nTrials','nLeft','nRight','nTracked','nFinite','status'})]; %#ok<AGROW>
        if status~="included", continue; end
        C=reshape(mean(A(:,choice,:),2),size(A,1),[])';
        folds=min(cfg.folds,min(nL,nR)); fold=zeros(nInput,1);
        for side=[false true]
            ii=find(L==side); ii=ii(randperm(stream,numel(ii)));
            fold(ii)=mod(0:numel(ii)-1,folds)+1;
        end
        projection=nan(nInput,size(A,2)); models=cell(folds,1);
        for f=1:folds
            train=fold~=f; test=find(fold==f); model=lda(C(train,:),L(train),cfg.ridge);
            models{f}=model;
            for j=test'
                Z=(A(:,:,j)'-model.offset)./model.scale;
                projection(j,:)=((Z*model.weight)/model.noiseSD)';
            end
        end
        e=struct('animalIndex',a,'animal',label,'task',task,'trialInfo',M, ...
            'trackedRowIndices',find(S.tracking.selectedNeuronMask),'finiteNeuronMask',keep, ...
            'fold',fold,'foldModels',{models},'fullModel',lda(C,L,cfg.ridge), ...
            'projection',projection,'preProjection',mean(projection(:,pre),2), ...
            'choiceProjection',mean(projection(:,choice),2));
        if isempty(entries), entries=e; else, entries(end+1)=e; end %#ok<AGROW>
        for b=unique(M.choiceBiasBlock(isfinite(M.choiceBiasBlock)))'
            in=M.choiceBiasBlock==b; left=in&L; right=in&~L;
            bv=unique(M.choiceBiasBlockValue(in)); bv=bv(isfinite(bv));
            if numel(bv)~=1||any(M.choiceBiasBlockN(in)~=cfg.biasWindow)|| ...
                    min(sum(left),sum(right))<cfg.minBinTrialsPerAction, continue; end
            preSep=mean(e.preProjection(left))-mean(e.preProjection(right));
            choiceSep=mean(e.choiceProjection(left))-mean(e.choiceProjection(right));
            bins=[bins;table(a,label,task,b,bv,abs(bv),sum(left),sum(right),preSep,choiceSep, ...
                'VariableNames',{'animalIndex','animal','task','block','bias','absBias','nLeft','nRight','preSeparation','choiceSeparation'})]; %#ok<AGROW>
        end
    end
end
assert(~isempty(entries),'choiceBias:Empty','No animal/task has sufficient valid trials of both actions.');
result=struct('cfg',cfg,'entries',entries,'bins',bins,'animalAudit',audit, ...
    'preFrameIndices',pre,'choiceFrameIndices',choice, ...
    'interpretation','Cross-validated choice LDA; positive toward L; units of training within-class projection SD. Bins are descriptive repeated observations.');
result.regression=regressions(bins,cfg);
[figures,result.plotFiles]=fn_plotChoiceBiasGeometry(result,p);
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    save(fullfile(p.savePath,[p.prefix '.mat']),'result','-v7.3');
end
end
function m=lda(X,L,ridge)
mu=mean(X,1); scale=std(X,0,1); scale(scale==0)=1; Z=(X-mu)./scale;
a=mean(Z(L,:),1); b=mean(Z(~L,:),1);
V=.5*cov(Z(L,:),0)+.5*cov(Z(~L,:),0); base=trace(V)/size(V,1); if base<=0, base=1; end
w=(V+ridge*base*eye(size(V)))\(a-b)';
if norm(w)<=eps, w=zeros(size(w)); else, w=w/norm(w); end
z=Z*w; noise=sqrt(.5*var(z(L))+.5*var(z(~L))); if noise<=eps, noise=1; end
m=struct('weight',w,'offset',mu,'scale',scale,'noiseSD',noise);
end
function R=regressions(B,cfg)
R=struct([]); if isempty(B), return; end
fields={'preSeparation','choiceSeparation'};
for task=1:2
    for period=1:2
        T=B(B.task==task,:); x=T.bias; if cfg.biasMagnitude, x=abs(x); end
        y=T.(fields{period}); slope=NaN; intercept=NaN; rho=NaN;
        if numel(x)>=3
            % Animal fixed intercepts: do not infer a trend from between-animal offsets.
            group=findgroups(T.animalIndex); xc=x; yc=y;
            for k=unique(group)', ix=group==k; xc(ix)=x(ix)-mean(x(ix)); yc(ix)=y(ix)-mean(y(ix)); end
            if sum(xc.^2)>eps
                slope=(xc'*yc)/(xc'*xc); intercept=mean(y)-slope*mean(x);
                if sum(yc.^2)>eps, rho=(xc'*yc)/sqrt(sum(xc.^2)*sum(yc.^2)); end
            end
        end
        row=struct('task',task,'period',fields{period},'nBins',height(T), ...
            'nAnimals',numel(unique(T.animalIndex)),'slope',slope,'intercept',intercept, ...
            'withinAnimalR',rho,'note','Descriptive animal-adjusted slope; no IID bin-level p-value.');
        if isempty(R), R=row; else, R(end+1)=row; end %#ok<AGROW>
    end
end
end
function out=merge(in,d)
assert(isstruct(in)&&isscalar(in)&&isempty(setdiff(fieldnames(in),fieldnames(d))),'choiceBias:Config','Unknown configuration field.');
out=d; for key=fieldnames(in)', out.(key{1})=in.(key{1}); end
end
