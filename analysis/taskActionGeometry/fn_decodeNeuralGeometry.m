function d=fn_decodeNeuralGeometry(train,test,T,cfg,model,stream)
%FN_DECODENEURALGEOMETRY Real-trial single-neuron LDA; no population decoder.
% Choice fits/scores frames -3:-1 before choice. Task uses the selected window.
% The per-time threshold diagnostic is also fitted using training trials only.
validateattributes(cfg.decoderInnerFolds,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.decoderTopFractions,{'numeric'},{'vector','positive','<=',1});
assert(cfg.decoderWindowFrames==3,'neuralGeometry:DecoderWindow', ...
    'Choice decoding uses exactly three frames before threshold; decoderWindowFrames must be 3.');
fractions=unique(cfg.decoderTopFractions(:))';
nf=numel(model.variables); n=height(model.neurons); nt=numel(model.time);
np=numel(fractions); [nc,na]=size(train);
if isempty(cfg.time)
    a=find(~cellfun(@isempty,train(1,:)),1);
    fullTime=((1:size(train{1,a},2))-cfg.eventFrame)/cfg.frameRate;
else
    fullTime=reshape(cfg.time,1,[]);
end
[ok,frames]=ismember(model.time,fullTime); assert(all(ok));
windows=repmat({1:nt},1,nf);
for f=1:nf
    if ~strcmpi(model.variables(f),cfg.decoderChoiceVariable), continue; end
    % Time zero must be the actual choice threshold (use dffChoice input).
    [distance,zero]=min(abs(fullTime));
    assert(distance<1e-8 && zero>=4,'neuralGeometry:ChoiceAlignment', ...
        'Choice decoding requires choice-aligned time zero and three preceding frames. Use dffChoice.');
    original=zero+(-3:-1);
    assert(max(abs(fullTime(original)-[-.2 -2/15 -1/15]))<1e-8, ...
        'neuralGeometry:ChoiceAlignment', ...
        'The three pre-choice frames must be at -200, -133.33, -66.67 ms (15 Hz); check cfg.time/frameRate.');
    [found,win]=ismember(original,frames);
    assert(all(found),'neuralGeometry:DecoderWindow', ...
        'cfg.timeWindow must include all three pre-choice frames (-200 ms to strictly before zero).');
    windows{f}=win;
end
for a=1:na
    for c=1:nc
        if isempty(train{c,a}), continue; end
        train{c,a}=double(train{c,a}(:,frames,:)); test{c,a}=double(test{c,a}(:,frames,:));
    end
end
J=cfg.decoderInnerFolds; innerFold=cell(nc,na);
for a=1:na
    for c=1:nc
        if isempty(train{c,a}), continue; end
        N=size(train{c,a},3);
        assert(N>=J&&N-ceil(N/J)>=2,'neuralGeometry:InnerTrials','Insufficient training trials for inner folds.');
        order=randperm(stream,N); z=zeros(N,1); z(order)=mod(0:N-1,J)+1; innerFold{c,a}=z;
    end
end
validation=zeros(n,nt,nf);
for j=1:J
    tr=train; va=train;
    for a=1:na
        for c=1:nc
            if isempty(train{c,a}), continue; end
            keep=innerFold{c,a}~=j;
            tr{c,a}=train{c,a}(:,:,keep); va{c,a}=train{c,a}(:,:,~keep);
        end
    end
    m=singleModel(tr,T,cfg,model,windows);
    validation=validation+singleAccuracy(va,T,m,model,false)/J;
end
m=singleModel(train,T,cfg,model,windows);
singleTest=singleAccuracy(test,T,m,model,false);
timeTest=singleAccuracy(test,T,m,model,true);
d=struct('fractions',fractions,'variables',model.variables,'validFactor',m.valid, ...
    'singleTime',nan(np,nt,nf),'neuronTime',singleTest,'neuronSummary',nan(n,nf), ...
    'timeResolvedNeuronTime',timeTest,'timeResolvedNeuronSummary',nan(n,nf), ...
    'windowStart',cellfun(@(x)x(1),windows),'windowEnd',cellfun(@(x)x(end),windows), ...
    'windowTime',{cellfun(@(x)model.time(x),windows,'UniformOutput',false)}, ...
    'nSelected',ceil(n*fractions),'ranking',nan(n,nf),'trainingSingleAccuracy',validation, ...
    'singleWeights',m.w,'singleThreshold',m.mid,'timeResolvedWeights',m.wTime, ...
    'timeResolvedThreshold',m.midTime,'normalizationOffset',m.offset, ...
    'normalizationScale',m.scale,'innerAssignments',{innerFold});
d.sourceTrial=cell(nc,na);
for c=1:nc
    for a=1:na
        if ~isempty(test{c,a}), d.sourceTrial{c,a}=(1:size(test{c,a},3))'; end
    end
end
for f=1:nf
    if ~m.valid(f), continue; end
    win=windows{f};
    d.neuronSummary(:,f)=mean(singleTest(:,win,f),2);
    d.timeResolvedNeuronSummary(:,f)=mean(timeTest(:,win,f),2);
    [~,order]=sort(mean(validation(:,win,f),2),'descend'); d.ranking(:,f)=order;
    for q=1:np
        chosen=order(1:d.nSelected(q));
        d.singleTime(q,:,f)=mean(singleTest(chosen,:,f),1);
    end
end
d.criterion='Equal priors: level 2 if w_j*(x_j-(mu1_j+mu2_j)/2)>0; ties score 0.5.';
d.rankingRule='Inner-training CV ranks neurons for top-group time courses. Individual-cell plot sorts held-out mean accuracy for display only.';
d.windowRule='Choice: fit and average frame accuracies strictly at offsets -3:-1 (15 Hz, time zero = choice). Other factors: whole selected window.';
d.diagnostic='timeResolvedNeuronTime/Summary refits each time-bin threshold on training trials; contrasts with the fixed-window threshold to reveal temporal-baseline dilution.';
end

function m=singleModel(X,T,cfg,model,windows)
n=height(model.neurons); nf=numel(model.variables); [nc,na]=size(X); nt=numel(model.time);
m.offset=zeros(n,1); m.scale=ones(n,1); timeMean=zeros(n,nt,nc); timeVar=timeMean;
for a=1:na
    ix=find(model.neurons.animalIndex==a); if isempty(ix), continue; end
    sums=zeros(numel(ix),1); squares=sums; N=0;
    for c=1:nc
        z=reshape(X{c,a},numel(ix),[]); sums=sums+sum(z,2); squares=squares+sum(z.^2,2); N=N+size(z,2);
    end
    switch cfg.normalization
        case 'zscore'
            m.offset(ix)=sums/N; m.scale(ix)=sqrt(max(0,(squares-sums.^2/N)/(N-1)));
        case 'rms'
            m.scale(ix)=sqrt(squares/N);
    end
    m.scale(m.scale==0)=1;
    for c=1:nc
        X{c,a}=(X{c,a}-m.offset(ix))./m.scale(ix);
        timeMean(ix,:,c)=mean(X{c,a},3); timeVar(ix,:,c)=var(X{c,a},1,3);
    end
end
m.w=zeros(n,nf); m.mid=m.w; m.valid=false(1,nf);
m.wTime=zeros(n,nt,nf); m.midTime=m.wTime;
for f=1:nf
    levels=model.factors(f).levels; if numel(levels)~=2, continue; end
    g=string(T.(model.variables(f))); win=windows{f};
    M=reshape(mean(timeMean(:,win,:),2),n,nc);
    % Total variance pools both within-trial time changes and across-trial noise.
    V=reshape(mean(timeVar(:,win,:)+(timeMean(:,win,:)-reshape(M,n,1,nc)).^2,2),n,nc);
    mu=zeros(n,2); noise=zeros(n,1); muTime=zeros(n,nt,2); noiseTime=zeros(n,nt);
    for l=1:2
        rows=find(g==levels(l)); mu(:,l)=mean(M(:,rows),2);
        noise=noise+mean(V(:,rows)+(M(:,rows)-mu(:,l)).^2,2)/2;
        muTime(:,:,l)=mean(timeMean(:,:,rows),3);
        noiseTime=noiseTime+mean(timeVar(:,:,rows)+(timeMean(:,:,rows)-muTime(:,:,l)).^2,3)/2;
    end
    base=mean(noise); if base<=0, base=1; end
    m.w(:,f)=(mu(:,2)-mu(:,1))./(noise+cfg.ridge*base);
    m.mid(:,f)=mean(mu,2); m.valid(f)=true;
    baseTime=mean(noiseTime,1); baseTime(baseTime<=0)=1;
    m.wTime(:,:,f)=(muTime(:,:,2)-muTime(:,:,1))./(noiseTime+cfg.ridge*baseTime);
    m.midTime(:,:,f)=mean(muTime,3);
end
end

function acc=singleAccuracy(X,T,m,model,timeSpecific)
[nc,na]=size(X); n=height(model.neurons); nt=numel(model.time); nf=numel(model.variables);
acc=zeros(n,nt,nf);
for f=1:nf
    if ~m.valid(f), acc(:,:,f)=NaN; continue; end
    levels=model.factors(f).levels; g=string(T.(model.variables(f)));
    for a=1:na
        ix=find(model.neurons.animalIndex==a); if isempty(ix), continue; end
        if timeSpecific
            mid=m.midTime(ix,:,f); w=m.wTime(ix,:,f);
        else
            mid=m.mid(ix,f); w=m.w(ix,f);
        end
        for c=1:nc
            z=(X{c,a}-m.offset(ix))./m.scale(ix);
            margin=(z-mid).*w;
            if g(c)~=levels(2), margin=-margin; end
            correct=double(margin>0)+0.5*double(margin==0);
            acc(ix,:,f)=acc(ix,:,f)+mean(correct,3)/(2*sum(g==g(c)));
        end
    end
end
end
