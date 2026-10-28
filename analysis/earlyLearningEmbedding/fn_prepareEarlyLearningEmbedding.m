function [prepared,meanActivity]=fn_prepareEarlyLearningEmbedding(activity,conditions,cfg,trialInfo)
%FN_PREPAREEARLYLEARNINGEMBEDDING Reduce trials and form matched learning chunks.
% meanActivity: point x animal cells, each neuron x 1 (one chunk/event mean).
% A point is stimulus x responsePeriod x learningBin, NOT a single raw trial.
defaults=fn_earlyLearningEmbeddingConfig();
if nargin<3||isempty(cfg), cfg=struct(); end
assert(nargin>=4,'earlyEmbedding:TrialInfo','Provide aligned trialInfoNeural cells.');
assert(isstruct(cfg)&&isscalar(cfg),'earlyEmbedding:Config','Use a scalar config.');
assert(isempty(setdiff(fieldnames(cfg),fieldnames(defaults))), ...
    'earlyEmbedding:Config','Unknown configuration option.');
for name=fieldnames(defaults)'
    if ~isfield(cfg,name{1}), cfg.(name{1})=defaults.(name{1}); end
end
validateattributes(cfg.nBins,{'numeric'},{'scalar','integer','>=',2,'finite'});
validateattributes(cfg.overlap,{'numeric'},{'scalar','>=',0,'<',1,'finite'});
validateattributes(cfg.minTrialsPerBin,{'numeric'},{'scalar','integer','positive','finite'});
cfg.missingAnimal=validatestring(cfg.missingAnimal,{'exclude','error'});
% Reuse exactly the same event frames, reward filtering, phase order, and
% normalization as stimulus/reward alignment. Suppress its separate figures.
response=fn_analyzeStimRewardAlignment(activity,conditions,cfg.response,struct('makePlot',false),trialInfo);
cfg.response=response.cfg;
groups=response.byStimulus; [ns,na]=size(groups); K=cfg.nBins;
labels=response.cfg.animalLabels; stimuli=response.cfg.stimuli;
periods=["stimulus","reward"]; np=ns*2*K;
stimulus=zeros(np,1); responsePeriod=strings(np,1); learningBin=zeros(np,1);
conditionName=strings(np,1);
for s=1:ns
    for e=1:2
        ids=((s-1)*2+e-1)*K+(1:K);
        stimulus(ids)=stimuli(s); responsePeriod(ids)=periods(e); learningBin(ids)=(1:K)';
        conditionName(ids)="S"+stimuli(s)+"_"+periods(e)+"_bin"+compose('%02d',(1:K)');
    end
end
relativeProgress=(learningBin-1)/(K-1);
pointInfo=table((1:np)',conditionName,stimulus,responsePeriod,learningBin,relativeProgress, ...
    'VariableNames',{'pointIndex','conditionName','stimulus','responsePeriod','learningBin','relativeProgress'});
meanActivity=cell(np,na); blocks=cell(1,na); neurons=cell(1,na);
windows=cell(ns,na); trialMap=windows; validTrialCounts=windows;
trialCounts=zeros(ns,na); included=false(na,1); nNeurons=zeros(na,1);
nDroppedNeurons=zeros(na,1); reason=strings(na,1);
for a=1:na
    for s=1:ns
        trialCounts(s,a)=height(groups(s,a).trials);
        trialMap{s,a}=groups(s,a).trials;
    end
    nn=0; values=[];
    for s=1:ns
        B=groups(s,a); N=trialCounts(s,a);
        if N<K
            reason(a)=sprintf('S%g has %d rewarded trials; need at least %d for distinct chunks.',stimuli(s),N,K);
            break;
        end
        % Continuous windows cover [0,N], with step=(1-overlap)*width.
        % Round their edges once into 1-based inclusive trial ranges.
        denominator=1+(K-1)*(1-cfg.overlap);
        left=(0:K-1)'*(1-cfg.overlap)/denominator;
        firstTrial=round(N*left)+1;
        lastTrial=round(N*(left+1/denominator));
        count=lastTrial-firstTrial+1;
        if numel(unique(firstTrial))<K||any(count<cfg.minTrialsPerBin)
            reason(a)=sprintf('S%g has too few trials for %d windows with >=%d trials.', ...
                stimuli(s),K,cfg.minTrialsPerBin); break;
        end
        overlapWithPrevious=[NaN;max(0,lastTrial(1:end-1)-firstTrial(2:end)+1)./count(1:end-1)];
        phaseStart=B.trials.dayLabel(firstTrial); phaseEnd=B.trials.dayLabel(lastTrial);
        windows{s,a}=table((1:K)',firstTrial,lastTrial,count,overlapWithPrevious,phaseStart,phaseEnd, ...
            'VariableNames',{'learningBin','firstTrial','lastTrial','nTrials', ...
            'overlapWithPrevious','phaseStart','phaseEnd'});
        if s==1, nn=size(B.stimulusActivity,1); values=nan(nn,np); end
        assert(size(B.stimulusActivity,1)==nn,'earlyEmbedding:Neurons', ...
            'Use the same tracked neuron rows for every stimulus within an animal.');
        validTrialCounts{s,a}=zeros(nn,K);
        for b=1:K
            idx=firstTrial(b):lastTrial(b);
            S=B.stimulusActivity(:,idx); R=B.rewardActivity(:,idx);
            good=isfinite(S)&isfinite(R); n=sum(good,2);
            S(~good)=NaN; R(~good)=NaN;
            sm=mean(S,2,'omitnan'); rm=mean(R,2,'omitnan');
            sm(n<cfg.minTrialsPerBin)=NaN; rm(n<cfg.minTrialsPerBin)=NaN;
            values(:,(s-1)*2*K+b)=sm;
            values(:,(s-1)*2*K+K+b)=rm;
            validTrialCounts{s,a}(:,b)=n;
        end
    end
    if strlength(reason(a))==0
        valid=all(isfinite(values),2); nDroppedNeurons(a)=sum(~valid);
        nNeurons(a)=sum(valid);
        if ~any(valid), reason(a)="No neurons with finite responses in every stimulus/event/chunk.";
        else
            included(a)=true; blocks{a}=values(valid,:)';
            neurons{a}=table(repmat(a,sum(valid),1),repmat(labels(a),sum(valid),1),find(valid), ...
                'VariableNames',{'animalIndex','animalLabel','rowInAnimal'});
            % Preserve original input neuron rows; the shared embedding runner
            % drops exactly the same nonfinite rows and retains their identities.
            for q=1:np, meanActivity{q,a}=values(:,q); end
        end
    end
    assert(included(a)||~strcmp(cfg.missingAnimal,'error'),'earlyEmbedding:Animal', ...
        '%s: %s',labels(a),reason(a));
end
assert(any(included),'earlyEmbedding:Empty','No usable animals: %s',join(labels+": "+reason,'; '));
prepared=struct('cfg',cfg,'pointInfo',pointInfo,'populationVectors',cat(2,blocks{included}), ...
    'neurons',vertcat(neurons{included}),'trialCounts',trialCounts,'normalization',response.normalization);
prepared.animalAudit=table((1:na)',labels,included,nNeurons,nDroppedNeurons,reason, ...
    'VariableNames',{'animalIndex','animalLabel','included','nNeurons','nDroppedNeurons','reason'});
prepared.windows=windows; prepared.trialMap=trialMap; prepared.validTrialCounts=validTrialCounts;
prepared.estimation=['Unsupervised embedding of overlapping trial-chunk means. Animals concatenate as neural dimensions; ' ...
    'chunks align relative learning progress, not simultaneous trials or identical phase boundaries.'];
end
