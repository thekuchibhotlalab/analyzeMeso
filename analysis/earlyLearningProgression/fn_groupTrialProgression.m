function [grouped,conditions,trialMap] = fn_groupTrialProgression(activity,definitions,trialInfo,groupBy,phaseOrder)
%FN_GROUPTRIALPROGRESSION Pool stimuli by phase and actual trial outcome.
% trialInfo{condition,animal} must match activity's third dimension exactly.
% sourceTrialRow restores chronological order within each animal. Overlapping
% selections are rejected, so one trial cannot silently contribute twice.
if nargin<4, groupBy='phaseOutcome'; end
if nargin<5, phaseOrder=[]; end
groupBy=validatestring(groupBy,{'phaseOutcome','outcome','stimulus'});
assert(iscell(trialInfo)&&isequal(size(trialInfo),size(activity)), ...
    'trialProgression:TrialInfo','Provide trialInfo cells matching activity, using trialInfoNeural.');
[nc,na]=size(activity); phases=strings(0,1); maps=cell(1,na); arrays=cell(1,na);
% Include configured phases even when every trial of a phase is absent.
for field={'dayLabels','dayLabel'}
    if ismember(field{1},definitions.Properties.VariableNames)
        values=definitions.(field{1});
        for c=1:nc
            if iscell(values), value=values{c}; else, value=values(c,:); end
            phases=[phases;string(value(:))]; %#ok<AGROW>
        end
        break;
    end
end
phases=unique(phases(~ismissing(phases)&strlength(phases)>0),'stable');
for a=1:na
    blocks=cell(nc,1); rows=cell(nc,1);
    for c=1:nc
        X=activity{c,a}; if isempty(X), continue; end
        T=trialInfo{c,a};
        assert(istable(T)&&height(T)==size(X,3)&& ...
            all(ismember({'dayLabel','responseType','sourceTrialRow'},T.Properties.VariableNames)), ...
            'trialProgression:TrialInfo', ...
            'Cell (%d,%d): trialInfoNeural must match neural trials and contain dayLabel, responseType, sourceTrialRow.',c,a);
        phase=string(T.dayLabel); outcome=T.responseType; source=T.sourceTrialRow;
        assert(iscolumn(phase)&&all(~ismissing(phase)&strlength(phase)>0)&& ...
            isnumeric(outcome)&&iscolumn(outcome)&&all(ismember(outcome,[-1 1 2])), ...
            'trialProgression:Outcome','Use dayLabel and responseType 1 (rewarded), -1 (incorrect), or 2 (probe).');
        validateattributes(source,{'numeric'},{'column','integer','positive','finite'});
        rows{c}=table(repmat(c,height(T),1),(1:height(T))',double(source),phase,outcome, ...
            'VariableNames',{'sourceCondition','sourceTrial','sourceTrialRow','dayLabel','responseType'});
        if strcmp(groupBy,'stimulus')
            if ismember('stimuli',T.Properties.VariableNames)
                stimulus=T.stimuli;
            elseif ismember('stimulus',T.Properties.VariableNames)
                stimulus=T.stimulus;
            elseif ismember('stimulus',definitions.Properties.VariableNames)
                value=definitions.stimulus(c,:); if iscell(value), value=value{1}; end
                assert(isnumeric(value)&&isscalar(value),'trialProgression:Stimulus', ...
                    'Each condition must have one stimulus, or provide per-trial stimuli metadata.');
                stimulus=repmat(value,height(T),1);
            else
                error('trialProgression:Stimulus', ...
                    'Provide trialInfoNeural.stimuli (or stimulus), or a scalar stimulus per condition. Set cfg.nStimulusBins=0 to skip this view.');
            end
            validateattributes(stimulus,{'numeric'},{'column','numel',height(T),'real','finite'});
            rows{c}.stimulus=stimulus;
        end
        blocks{c}=X;
        phases=unique([phases;phase],'stable');
    end
    present=~cellfun(@isempty,rows);
    if ~any(present), continue; end
    maps{a}=vertcat(rows{present}); arrays{a}=cat(3,blocks{present});
    assert(numel(unique(maps{a}.sourceTrialRow))==height(maps{a}), ...
        'trialProgression:DuplicateTrial','Animal %d has overlapping sourceTrialRow values across input conditions.',a);
end
assert(~isempty(phases),'trialProgression:Empty','No phases found in definitions or nonempty activity.');
outcomes=["rewarded";"incorrect";"probe"]; codes=[1;-1;2];
if ismember(groupBy,{'outcome','stimulus'})
    if isempty(phaseOrder), phaseOrder=phases; end
    phaseOrder=string(phaseOrder(:));
    assert(all(~ismissing(phaseOrder)&strlength(phaseOrder)>0)&&numel(unique(phaseOrder))==numel(phaseOrder), ...
        'trialProgression:PhaseOrder','phaseOrder must contain unique nonempty phase labels.');
    if strcmp(groupBy,'stimulus')
        allRows=vertcat(maps{~cellfun(@isempty,maps)}); stimulus=unique(allRows.stimulus);
        dayLabel=repmat(join(phaseOrder," -> "),numel(stimulus),1);
        conditionName="S"+string(stimulus);
    else
        dayLabel=repmat(join(phaseOrder," -> "),3,1);
        outcome=outcomes; responseType=codes; conditionName=outcomes;
    end
else
    dayLabel=reshape(repelem(phases,3),[],1); outcome=repmat(outcomes,numel(phases),1);
    responseType=repmat(codes,numel(phases),1); conditionName=dayLabel+"_"+outcome;
end
if strcmp(groupBy,'stimulus')
    conditions=table(conditionName,dayLabel,stimulus);
else
    conditions=table(conditionName,dayLabel,outcome,responseType);
end
grouped=cell(height(conditions),na); trialMap=cell(size(grouped));
for a=1:na
    if isempty(maps{a}), continue; end
    if ismember(groupBy,{'outcome','stimulus'})
        [known,phaseRank]=ismember(maps{a}.dayLabel,phaseOrder);
        assert(all(known),'trialProgression:PhaseOrder', ...
            'phaseOrder must include every observed phase; missing: %s.',join(unique(maps{a}.dayLabel(~known)),', '));
    end
    for g=1:height(conditions)
        if ismember(groupBy,{'outcome','stimulus'})
            if strcmp(groupBy,'stimulus'), keep=find(maps{a}.stimulus==stimulus(g));
            else, keep=find(maps{a}.responseType==responseType(g)); end
            [~,order]=sortrows([phaseRank(keep),maps{a}.sourceTrialRow(keep)],[1 2]);
        else
            keep=find(maps{a}.dayLabel==dayLabel(g)&maps{a}.responseType==responseType(g));
            [~,order]=sort(maps{a}.sourceTrialRow(keep));
        end
        keep=keep(order);
        trialMap{g,a}=maps{a}(keep,:);
        if ~isempty(keep), grouped{g,a}=arrays{a}(:,:,keep); end
    end
end
end
