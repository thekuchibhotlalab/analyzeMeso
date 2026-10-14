function qc = fn_makeTrialCountQCTable(neuralSelection,cfg)
%FN_MAKETRIALCOUNTQCTABLE Main condition-level trial availability summary.
n=numel(neuralSelection);

Condition=strings(n,1); DisplayName=strings(n,1);
NBeforeRT=zeros(n,1); NAfterRT=zeros(n,1); NNeural=zeros(n,1);
NBehaviorOnly=zeros(n,1); NMissingNeural=zeros(n,1);
NBadTracking=zeros(n,1); NInvalidTrialIndex=zeros(n,1);
NAfterSessionSelection=zeros(n,1);

for k=1:n
    Condition(k)=neuralSelection(k).name;
    DisplayName(k)=neuralSelection(k).displayName;
    NBeforeRT(k)=neuralSelection(k).nBeforeRT;
    NAfterRT(k)=neuralSelection(k).nAfterRT;
    NAfterSessionSelection(k)=height(neuralSelection(k).trials);
    NNeural(k)=neuralSelection(k).nNeuralTrials;
    NBehaviorOnly(k)=neuralSelection(k).nBehaviorOnly;
    NMissingNeural(k)=neuralSelection(k).nMissingNeural;
    NBadTracking(k)=neuralSelection(k).nBadTracking;
    NInvalidTrialIndex(k)=neuralSelection(k).nInvalidTrialIndex;
end

EnoughAfterRT=NAfterRT>=cfg.minTrials;
EnoughNeural=NNeural>=cfg.minTrials;

qc=table(Condition,DisplayName,NBeforeRT,NAfterRT,NAfterSessionSelection,NNeural, ...
    NBehaviorOnly,NMissingNeural,NBadTracking,NInvalidTrialIndex, ...
    EnoughAfterRT,EnoughNeural);
end
