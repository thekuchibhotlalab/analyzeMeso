function [curated,plan]=fn_prepareLearningChoiceData(trialInfo,sessionInfoBeh,neuralSource,selectionCfg,cfg)
%FN_PREPARELEARNINGCHOICEDATA One tracking selection across the entire timeline.
plan=fn_learningTrialWindows(trialInfo,cfg);
definitions=[];
for stimulus=1:4
    for action=1:2
        d=fn_trialCondition("S"+stimulus+"_A"+action,cfg.dayLabels,[],stimulus,action);
        definitions=[definitions;d]; %#ok<AGROW>
    end
end
selectionCfg.conditionDef=definitions;
selectionCfg.loadNeural=false; selectionCfg.saveFile='';
% Apply the usual RT/correct/miss filters first, then restrict to the timeline.
selected=fn_selectTrialsByCondition(trialInfo,definitions,selectionCfg);
lists=cell(numel(selected),1);
for k=1:numel(selected)
    lists{k}=intersect(selected(k).trials.sourceTrialRow,plan.eligibleRows,'stable');
end
% Explicit lists retain those already-applied filters; ranking is performed ONCE.
curated=fn_prepareTrialData(trialInfo,sessionInfoBeh,selectionCfg,'TrialNumbers',lists);
curated=fn_prepareNeuralData(curated,neuralSource);
curated.learningPlan=plan;
assert(isfield(curated.tracking,'selectedNeuronMask')&&any(curated.tracking.selectedNeuronMask), ...
    'learningAxes:Tracking','No common tracked neurons. Adjust session selection before analysis.');
end
