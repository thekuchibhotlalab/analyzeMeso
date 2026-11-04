function [selection,conditionDef]=fn_selectManualTrials(trialInfo,trialNumbers,conditionDef,idField,groupByCondition)
%FN_SELECTMANUALTRIALS Match table rows or explicit IDs, preserving source rows.
% A vector makes one ManualTrials group; cells correspond to cfg.conditionDef.
% groupByCondition instead splits a numeric pool by each stimulus/action pair.
% Explicit lists replace behavioral/RT filters. Session checks still follow.
if nargin<5, groupByCondition=false; end
assert(~groupByCondition||isnumeric(trialNumbers),'trialCuration:ManualTrialNumbers', ...
    'GroupManualTrialsByCondition requires a numeric trial-number pool, not cells.');
assert(all(ismember({'sessionRec','trialInSession'}, ...
    trialInfo.Properties.VariableNames)),'trialCuration:ManualTrialNumbers', ...
    'Manual selection requires sessionRec and trialInSession.');
ids=(1:height(trialInfo))';
if strlength(string(idField))>0
    assert(ismember(string(idField),string(trialInfo.Properties.VariableNames)), ...
        'trialCuration:ManualTrialNumbers','Trial ID column does not exist: %s.',idField);
    ids=trialInfo.(char(idField));
end
validateattributes(ids,{'numeric'},{'column','real','finite','integer','positive'});
assert(numel(unique(ids))==numel(ids),'trialCuration:ManualTrialNumbers', ...
    'The selected trial ID column must uniquely identify trials across sessions.');
if isnumeric(trialNumbers)
    if groupByCondition
        assert(all(ismember({'stimuli','action'},trialInfo.Properties.VariableNames)), ...
            'trialCuration:ManualTrialNumbers','Grouping requires trialInfo.stimuli and action.');
        trialNumbers=repmat({trialNumbers},numel(conditionDef),1);
    else
        conditionDef=fn_trialCondition("ManualTrials",[],[],[],[]);
        trialNumbers={trialNumbers};
    end
else
    assert(isvector(trialNumbers)&&numel(trialNumbers)==numel(conditionDef), ...
        'trialCuration:ManualTrialNumbers', ...
        'Supply one numeric trial-number vector per cfg.conditionDef entry.');
end
labels=string({conditionDef.name});
keys=matlab.lang.makeValidName(labels);
assert(all(~ismissing(labels)&strlength(strtrim(labels))>0)&& ...
    numel(unique(keys))==numel(keys),'trialCuration:ConditionLabel', ...
    'Condition labels must be nonempty and unique after field-name conversion.');
selection=repmat(struct(),numel(conditionDef),1);
for k=1:numel(conditionDef)
    requested=trialNumbers{k};
    assert(isnumeric(requested)&&(isempty(requested)||isvector(requested)), ...
        'trialCuration:ManualTrialNumbers','Trial numbers must be numeric vectors.');
    validateattributes(requested,{'numeric'},{'real','finite','integer','positive'});
    unknown=setdiff(requested(:),ids);
    assert(isempty(unknown),'trialCuration:UnknownTrialNumbers', ...
        'Trial numbers absent from trialInfo rows or the selected ID column: %s.',mat2str(unknown'));
    mask=ismember(ids,requested);
    d=conditionDef(k);
    if groupByCondition
        validateattributes(d.stimulus,{'numeric'},{'scalar','real','finite'});
        validateattributes(d.action,{'numeric'},{'scalar','real','finite'});
        mask=mask & trialInfo.stimuli==d.stimulus & trialInfo.action==d.action;
    end
    T=trialInfo(mask,:);
    T.sourceTrialRow=find(mask);
    selection(k).name=d.name;
    selection(k).displayName=d.name;
    if isfield(d,'displayName')&&~isempty(d.displayName)
        selection(k).displayName=d.displayName;
    end
    selection(k).definition=d;
    selection(k).maskBeforeRT=mask;
    selection(k).maskAfterRT=mask;
    selection(k).trialsBeforeRT=T;
    selection(k).trials=T;
    selection(k).nBeforeRT=height(T);
    selection(k).nAfterRT=height(T);
end
end
