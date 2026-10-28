function b = fn_binStimulusProgression(activity,conditions,trialInfo,cfg,timeBins,animalLabels,normalization)
%FN_BINSTIMULUSPROGRESSION Equal-count bins per animal/stimulus after phase concatenation.
% Uses every supplied trial, independent of nProgressionTrials. Stores only
% population means and provenance, not the neural arrays. Outcomes are pooled.
if nargin<7, normalization=struct('method','none'); end
nb=cfg.nStimulusBins; nt=numel(timeBins);
% Crop before grouping to avoid an additional full-time copy of neural data.
for k=1:numel(activity)
    if ~isempty(activity{k}), activity{k}=activity{k}(:,timeBins,:); end
end
[activity,definitions,trialMap]=fn_groupTrialProgression( ...
    activity,conditions,trialInfo,'stimulus',cfg.phaseOrder);
[ns,na]=size(activity);
b=struct('nBins',nb,'conditions',definitions,'animalLabels',animalLabels, ...
    'meanPsth',nan(nt,nb,ns,na),'trialCounts',zeros(ns,na), ...
    'binCounts',zeros(nb,ns,na),'nNeurons',zeros(ns,na), ...
    'nDroppedNeurons',zeros(ns,na),'status',repmat("no trials",ns,na));
b.trialMap=trialMap; b.binRanges=cell(ns,na); b.neuronRows=cell(ns,na);
for s=1:ns
    for a=1:na
        X=activity{s,a}; if isempty(X), continue; end
        if ~strcmp(normalization.method,'none')
            X=(double(X)-normalization.offset{a})./normalization.scale{a};
        end
        nr=size(X,3); b.trialCounts(s,a)=nr;
        % Every trial occurs once. Bin sizes differ by at most one; N<nb
        % produces explicitly empty bins rather than duplicating trials.
        edges=floor((0:nb)*nr/nb); counts=diff(edges)';
        first=edges(1:end-1)'+1; last=edges(2:end)';
        first(counts==0)=NaN; last(counts==0)=NaN;
        b.binCounts(:,s,a)=counts;
        b.binRanges{s,a}=table((1:nb)',first,last,counts, ...
            'VariableNames',{'bin','firstTrial','lastTrial','nTrials'});
        valid=all(reshape(isfinite(X),size(X,1),[]),2);
        assert(cfg.dropNonfiniteNeurons||all(valid),'trialProgression:Nonfinite', ...
            'Nonfinite activity in full-sequence stimulus bins.');
        b.neuronRows{s,a}=find(valid); b.nNeurons(s,a)=sum(valid);
        b.nDroppedNeurons(s,a)=sum(~valid);
        if ~any(valid), b.status(s,a)="no finite neurons"; continue; end
        for j=1:nb
            if counts(j)==0, continue; end
            trialMean=mean(double(X(valid,:,first(j):last(j))),3);
            b.meanPsth(:,j,s,a)=mean(trialMean,1)';
        end
        b.status(s,a)="computed";
        if nr<nb, b.status(s,a)="computed with empty bins"; end
    end
end
end
