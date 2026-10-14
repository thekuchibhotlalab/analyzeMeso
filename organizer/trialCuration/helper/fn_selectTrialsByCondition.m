function selection = fn_selectTrialsByCondition(trialInfo,conditionDef,cfg)
%FN_SELECTTRIALSBYCONDITION Behavioral selection only.
% Accepts any number of definitions; preserves sourceTrialRow for provenance.

required={'sessionRec','trialInSession','taskLabel','dayLabel','stimuli','action','RT'};
missing=setdiff(required,trialInfo.Properties.VariableNames);
if ~isempty(missing)
    error('trialInfo missing: %s',strjoin(missing,', '));
end

dayLabel = lower(strtrim(string(trialInfo.dayLabel)));
taskLabel = lower(strtrim(string(trialInfo.taskLabel)));

selection = repmat(struct(),numel(conditionDef),1);
labels=string({conditionDef.name});
assert(all(~ismissing(labels)&strlength(strtrim(labels))>0), ...
    'trialCuration:ConditionLabel','Condition labels must be nonempty.');
keys=matlab.lang.makeValidName(labels);
assert(numel(unique(keys))==numel(keys),'trialCuration:ConditionLabel', ...
    'Condition labels must remain unique after MATLAB field-name conversion.');

for k=1:numel(conditionDef)
    d=conditionDef(k);

    mask=ismember(dayLabel,lower(strtrim(d.dayLabels)));

    if ~isempty(d.taskLabels)
        mask = mask & ismember(taskLabel,lower(strtrim(d.taskLabels)));
    end

    mask = mask & trialInfo.stimuli==d.stimulus & trialInfo.action==d.action;

    if isfield(d,'responseTypes') && ~isempty(d.responseTypes)
        assert(ismember('responseType',trialInfo.Properties.VariableNames), ...
            'trialCuration:MissingResponseType', ...
            'Condition %s requires trialInfo.responseType to separate rewarded and probe trials.',d.name);
        mask = mask & ismember(trialInfo.responseType,d.responseTypes);
    end

    if cfg.requireCorrect
        mask = mask & logical(trialInfo.correct);
    end
    if cfg.excludeMiss
        mask = mask & ~logical(trialInfo.miss);
    end

    maskBeforeRT=mask;
    rowsBefore=find(maskBeforeRT);
    Tbefore=trialInfo(maskBeforeRT,:);
    Tbefore.sourceTrialRow=rowsBefore;

    if cfg.useRTFilter
        rtOK=isfinite(trialInfo.RT) & trialInfo.RT>=cfg.RTRange(1) & trialInfo.RT<=cfg.RTRange(2);
        mask=mask & rtOK;
    end

    rowsAfter=find(mask);
    Tafter=trialInfo(mask,:);
    Tafter.sourceTrialRow=rowsAfter;

    selection(k).name=d.name;
    selection(k).displayName=d.name;
    % Accept previously saved definitions that supplied a separate display label.
    if isfield(d,'displayName') && ~isempty(d.displayName)
        selection(k).displayName=d.displayName;
    end
    selection(k).definition=d;
    selection(k).maskBeforeRT=maskBeforeRT;
    selection(k).maskAfterRT=mask;
    selection(k).trialsBeforeRT=Tbefore;
    selection(k).trials=Tafter;
    selection(k).nBeforeRT=height(Tbefore);
    selection(k).nAfterRT=height(Tafter);

    if cfg.verbose
        fprintf('%2d. %-24s | before RT = %4d | after RT = %4d\n', ...
            k,char(d.name),height(Tbefore),height(Tafter));
    end
end
end
