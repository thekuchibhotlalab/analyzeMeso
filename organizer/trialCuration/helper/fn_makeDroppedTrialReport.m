function report = fn_makeDroppedTrialReport(neuralSelection)
%FN_MAKEDROPPEDTRIALREPORT Preserve all selected trials excluded from neural use.
parts={};

for k=1:numel(neuralSelection)
    T=neuralSelection(k).droppedTrials;
    if isempty(T), continue; end

    T.Condition=repmat(string(neuralSelection(k).name),height(T),1);

    keep={'Condition','date','sessionName','sessionRec','trialInSession', ...
        'sourceTrialRow','taskLabel','dayLabel','stimuli','action','RT','dropReason'};
    keep=intersect(keep,T.Properties.VariableNames,'stable');
    parts{end+1,1}=T(:,keep); %#ok<AGROW>
end

if isempty(parts), report=table(); else, report=vertcat(parts{:}); end
end
