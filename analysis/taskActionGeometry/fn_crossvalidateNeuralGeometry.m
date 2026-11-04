function [r,figures]=fn_crossvalidateNeuralGeometry(activity,T,cfg,p)
%FN_CROSSVALIDATENEURALGEOMETRY Whole-trial repeated CV and nested decoders.
validateattributes(cfg.cvFolds,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.cvRepeats,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.cvSeed,{'numeric'},{'scalar','integer','nonnegative'});
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity),'neuralGeometry:Input', ...
    'activity must be a condition x animal cell array.');
quiet=p; quiet.makePlot=false;
fitCfg=cfg; fitCfg.crossValidate=false; fitCfg.verbose=false;
[nc,na]=size(activity); excluded=false(na,1);
for a=1:na
    counts=cellfun(@(x)size(x,3),activity(:,a));
    if any(cellfun(@isempty,activity(:,a))) || any(counts<2*cfg.cvFolds)
        assert(~strcmp(cfg.missingAnimal,'error'),'neuralGeometry:CVTrials', ...
            'Animal column %d needs at least %d trials in every condition for held-out variance.',a,2*cfg.cvFolds);
        activity(:,a)={[]}; excluded(a)=true;
    end
end
% Full-data use is restricted to finite-neuron QC and descriptive raw PSTHs.
% This fit's weights are discarded; it never selects/orients a CV axis.
qc=fitCfg; qc.method='meanSquared'; qc.nAxes=1; qc.normalization='none';
r=fn_fitNeuralGeometry(activity,T,qc,quiet);
warningState=warning('off','neuralGeometry:Excluded');
restoreWarning=onCleanup(@()warning(warningState)); %#ok<NASGU>
originalNeurons=r.neurons;
for a=1:na
    rows=r.neurons.rowInAnimal(r.neurons.animalIndex==a);
    if isempty(rows), activity(:,a)={[]}; continue; end
    for c=1:nc, activity{c,a}=activity{c,a}(rows,:,:); end
end
r.animalAudit.reason(excluded)="empty condition or fewer than 2*cvFolds trials";
stream=RandStream('mt19937ar','Seed',cfg.cvSeed);
decoderStream=RandStream('mt19937ar','Seed',mod(cfg.cvSeed+1,2^32));
R=cfg.cvRepeats; F=cfg.cvFolds; S=R*F;
assignments=cell(nc,na); splits=cell(S,1); models=cell(S,1); decoder=cell(S,1);
for rep=1:R
    for a=1:na
        for c=1:nc
            if isempty(activity{c,a}), continue; end
            N=size(activity{c,a},3); order=randperm(stream,N);
            fold=zeros(N,1); fold(order)=mod(0:N-1,F)+1;
            assignments{c,a}(:,rep)=fold;
        end
    end
    for fold=1:F
        s=(rep-1)*F+fold; train=activity; test=activity;
        for a=1:na
            for c=1:nc
                if isempty(activity{c,a}), continue; end
                mask=assignments{c,a}(:,rep)==fold;
                train{c,a}=activity{c,a}(:,:,~mask); test{c,a}=activity{c,a}(:,:,mask);
            end
        end
        model=fn_fitNeuralGeometry(train,T,fitCfg,quiet);
        % Binary axes point toward level 2; sign alignment uses training only.
        for f=1:numel(model.factors)
            ids=model.factors(f).axisIndices;
            if numel(model.factors(f).levels)==2
                delta=diff(model.factors(f).pooledLevelMeans,1,2);
                sg=sign(model.weights(:,ids)'*delta); sg(sg==0)=1;
                model.weights(:,ids)=model.weights(:,ids).*sg';
                model.factors(f).weights=model.weights(:,ids);
            elseif s>1
                [ok,j]=ismember(model.axisLabels,models{1}.axisLabels);
                for k=find(ok)'
                    if model.weights(:,k)'*models{1}.weights(:,j(k))<0
                        model.weights(:,k)=-model.weights(:,k);
                    end
                end
                model.factors(f).weights=model.weights(:,ids);
            end
        end
        model.weightsRaw=model.weights./model.normalization.scale;
        held=fn_fitNeuralGeometry(test,T,fitCfg,quiet,model);
        splits{s}=struct('projection',held.projection,'variance',held.variance,'factors',held.factors);
        models{s}=struct('weights',model.weights,'weightsRaw',model.weightsRaw, ...
            'normalization',model.normalization,'axisInfo',model.axisInfo,'axisLabels',model.axisLabels);
        if cfg.decode
            decoder{s}=fn_decodeNeuralGeometry(train,test,T,fitCfg,model,decoderStream);
            % Record every real held-out trial in original input coordinates.
            for c=1:nc
                for a=1:na
                    if isempty(activity{c,a}), continue; end
                    source=find(assignments{c,a}(:,rep)==fold);
                    decoder{s}.sourceTrial{c,a}=source(decoder{s}.sourceTrial{c,a});
                end
            end
        end
        if cfg.verbose, fprintf('Geometry CV: repeat %d/%d, fold %d/%d complete.\n',rep,R,fold,F); end
    end
end
% Only ranks estimable in every split are reported; never substitute a fit
% from the full dataset when a training split has no residual signal.
labels=models{1}.axisLabels;
for s=2:S, labels=intersect(labels,models{s}.axisLabels,'stable'); end
assert(~isempty(labels),'neuralGeometry:CVSignal','No axis was estimable in every training fold.');
W=zeros(height(r.neurons),numel(labels),S); rawW=W;
for s=1:S
    [~,ix]=ismember(labels,models{s}.axisLabels);
    models{s}.weights=models{s}.weights(:,ix); models{s}.weightsRaw=models{s}.weightsRaw(:,ix);
    models{s}.axisInfo=models{s}.axisInfo(ix,:); models{s}.axisLabels=labels;
    W(:,:,s)=models{s}.weights; raw=models{s}.weightsRaw;
    rawW(:,:,s)=raw./sqrt(sum(raw.^2,1));
    splits{s}=subsetSplit(splits{s},ix);
end
[r.projection,r.crossValidation.projectionSEM]=averageStruct(cellfun(@(x)x.projection,splits,'UniformOutput',false),F,R);
[r.variance,r.crossValidation.varianceSEM]=averageStruct(cellfun(@(x)x.variance,splits,'UniformOutput',false),F,R);
r.factors=splits{1}.factors;
for f=1:numel(r.factors)
    [r.factors(f),se]=averageStruct(cellfun(@(x)x.factors(f),splits,'UniformOutput',false),F,R);
    r.crossValidation.factorSEM(f)=se;
end
% Store arithmetic mean directions AND unit versions in a common raw space.
r.meanWeights=mean(rawW,3);
r.weights=r.meanWeights./sqrt(sum(r.meanWeights.^2,1)); r.weightsRaw=r.weights;
r.projectionOffset=zeros(numel(labels),1);
r.normalization=struct('method','per-training-fold; mean directions in raw neuron coordinates', ...
    'offset',zeros(height(r.neurons),1),'scale',ones(height(r.neurons),1));
r.axisInfo=models{1}.axisInfo; r.axisLabels=labels;
for f=1:numel(r.factors)
    ids=r.factors(f).axisIndices; r.factors(f).weights=r.weights(:,ids);
    r.axisInfo.fitObjective(ids)=r.factors(f).objective;
end
r.neurons=originalNeurons; r.cfg=cfg;
r.estimation='Held-out whole trials; equal split averages; SEM across repeat means (partition variability, not independent subjects).';
r.projection.conditionSEM=r.crossValidation.projectionSEM.conditionMean;
r.projection.conditionSD=r.projection.conditionSEM*sqrt(R);
r.projection.errorEstimation=r.estimation;
r.crossValidation.enabled=true; r.crossValidation.nFolds=F; r.crossValidation.nRepeats=R;
r.crossValidation.assignments=assignments; r.crossValidation.models=models;
r.crossValidation.splits=splits; r.crossValidation.weightsBySplit=W;
r.crossValidation.rawUnitWeightsBySplit=rawW;
r.crossValidation.repeat=repelem((1:R)',F); r.crossValidation.fold=repmat((1:F)',R,1);
r.crossValidation.note='Mean directions are descriptive and not refitted/evaluated on all trials. Averaging can destroy within-factor orthogonality. Metrics use individual training axes.';
cs=r.weights'*r.weights; cs=max(-1,min(1,cs));
r.similarity=struct('cosine',cs,'angleDegrees',acosd(abs(cs)),'metric','Unit-normalized mean raw-coordinate directions');
if cfg.decode
    r.decoding.splits=decoder;
    [r.decoding.mean,r.decoding.sem]=averageStruct(decoder,F,R);
    r.decoding.note='Real-trial single-neuron balanced accuracy. Fixed pre-choice frames; no population decoder or pseudo-trials. Display sorting by held-out accuracy is descriptive, not independent neuron selection.';
    N=height(r.neurons); nf=numel(r.variables); ranks=nan(N,nf);
    r.decoding.displayOrder=nan(N,nf);
    for f=1:nf
        [~,order]=sort(r.decoding.mean.neuronSummary(:,f),'descend');
        r.decoding.displayOrder(:,f)=order; ranks(order,f)=(1:N)';
    end
    info=repmat(r.neurons,nf,1); info.neuronIndex=repmat((1:N)',nf,1);
    info.variable=repelem(r.variables,N);
    info.accuracy=r.decoding.mean.neuronSummary(:);
    info.sem=r.decoding.sem.neuronSummary(:); info.displayRank=ranks(:);
    info.timeResolvedAccuracy=r.decoding.mean.timeResolvedNeuronSummary(:);
    info.timeResolvedSEM=r.decoding.sem.timeResolvedNeuronSummary(:);
    r.decoding.neuronTable=info;
end
[figures,r.plotFiles]=fn_plotNeuralGeometry(r,p);
end

function x=subsetSplit(x,ix)
K=size(x.projection.conditionMean,1);
for section=["projection","variance"]
    z=x.(section);
    for key=string(fieldnames(z))'
        value=z.(key);
        if isnumeric(value)&&startsWith(key,'population'), continue; end
        if isnumeric(value)&&~contains(key,'PopulationVariance')&&size(value,1)==K
            sub=repmat({':'},1,ndims(value)); sub{1}=ix; z.(key)=value(sub{:});
        end
    end
    x.(section)=z;
end
for f=1:numel(x.factors)
    z=x.factors(f); wanted=find(ismember(ix,z.axisIndices));
    old=z.axisIndices; [~,local]=ismember(ix(wanted),old);
    for key=["weights","marginalProjection","separationEnergy","separationCaptureByTime","separationCapture","cumulativeSeparationCapture","objective"]
        v=z.(key); sub=repmat({':'},1,ndims(v));
        if key=="weights", sub{2}=local; else, sub{1}=local; end
        z.(key)=v(sub{:});
    end
    z.axisIndices=reshape(wanted,1,[]); z.nAxes=numel(wanted); x.factors(f)=z;
end
end

function [m,se]=averageStruct(values,F,R)
% Each repeat aggregates all folds before estimating partition-to-partition SEM.
m=values{1}; se=struct();
for key=string(fieldnames(m))'
    v=m.(key);
    if ~isnumeric(v)||isempty(v), continue; end
    sz=size(v); flat=cellfun(@(x)x.(key)(:),values,'UniformOutput',false);
    if ~all(cellfun(@numel,flat)==numel(v)), continue; end
    samples=cat(2,flat{:}); repeats=reshape(mean(reshape(samples,[],F,R),2,'omitnan'),[],R);
    m.(key)=reshape(mean(repeats,2,'omitnan'),sz);
    se.(key)=reshape(std(repeats,0,2,'omitnan')/sqrt(R),sz);
end
end
