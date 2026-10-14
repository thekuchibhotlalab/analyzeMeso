function byCondition = fn_organizeConditionData(neuralSelection)
%FN_ORGANIZECONDITIONDATA Easy condition-wise access for later analyses.
byCondition=struct();

for k=1:numel(neuralSelection)
    f=matlab.lang.makeValidName(char(neuralSelection(k).name));
    C=struct();
    C.displayName=neuralSelection(k).displayName;
    C.definition=neuralSelection(k).definition;
    C.trialInfo=neuralSelection(k).trialInfoNeural;
    C.droppedTrials=neuralSelection(k).droppedTrials;
    C.neuralRaw=neuralSelection(k).neuralRaw;
    C.neuralNorm=neuralSelection(k).neuralNorm;

    if isempty(C.neuralNorm)
        C.meanTC=[];
        C.populationMeanTC=[];
    else
        C.meanTC=mean(C.neuralNorm,3,'omitnan');
        C.populationMeanTC=mean(C.meanTC,1,'omitnan');
    end
    byCondition.(f)=C;
end
end
