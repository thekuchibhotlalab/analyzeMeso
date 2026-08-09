function sessionInfo = fn_encodeTrainingLabels(sessionInfo)
%FN_ENCODETRAININGLABELS Add task accuracy and training-period labels.
%
% Adds per-session:
%   T1acc, T2acc, T1nTrial, T2nTrial, taskLabel, dayLabel
%
% taskLabel is one of {'T1','T2','Int',''}.
% dayLabel is one of {'T1E','T1M','T1L','T2E','T2M','T2L','Int',''}.
% dayLabel is assigned per date, so all task sessions on the same day share
% the same dayLabel.

nSession = height(sessionInfo);
sessionInfo.T1acc = nan(nSession,1);
sessionInfo.T2acc = nan(nSession,1);
sessionInfo.T1nTrial = zeros(nSession,1);
sessionInfo.T2nTrial = zeros(nSession,1);
sessionInfo.taskLabel = repmat({''},nSession,1);
sessionInfo.dayLabel = repmat({''},nSession,1);

if ~ismember('behSel',sessionInfo.Properties.VariableNames)
    return
end
if ~ismember('sessionType',sessionInfo.Properties.VariableNames)
    return
end

for i = 1:nSession
    behSel = getTableCell(sessionInfo.behSel,i);
    sessionType = getTableCell(sessionInfo.sessionType,i);
    if isempty(behSel) || ~isBehaviorSession(sessionType)
        continue
    end

    if ~istable(behSel)
        continue
    end
    if ~all(ismember({'stimuli','action','correct','miss'},behSel.Properties.VariableNames))
        continue
    end

    t1Trial = behSel.stimuli == 1 | behSel.stimuli == 2;
    t2Trial = behSel.stimuli == 3 | behSel.stimuli == 4;

    sessionInfo.T1nTrial(i) = sum(t1Trial);
    sessionInfo.T2nTrial(i) = sum(t2Trial);
    if any(t1Trial)
        [~, sessionInfo.T1acc(i)] = fn_getAccBias(behSel.stimuli(t1Trial), behSel.correct(t1Trial),  behSel.miss(t1Trial));
    end
    if any(t2Trial)
        [~, sessionInfo.T2acc(i)] = fn_getAccBias(behSel.stimuli(t2Trial), behSel.correct(t2Trial),  behSel.miss(t2Trial));
    end

    nTaskTrial = sessionInfo.T1nTrial(i) + sessionInfo.T2nTrial(i);
    if nTaskTrial == 0
        continue
    end

    t1Frac = sessionInfo.T1nTrial(i) / nTaskTrial;
    t2Frac = sessionInfo.T2nTrial(i) / nTaskTrial;
    if t1Frac >= 0.65
        sessionInfo.taskLabel{i} = 'T1';
    elseif t2Frac >= 0.65
        sessionInfo.taskLabel{i} = 'T2';
    else
        sessionInfo.taskLabel{i} = 'Int';
    end
end

sessionInfo.dayLabel = assignDayLabels(sessionInfo);
end

function tf = isBehaviorSession(sessionType)
sessionType = charValue(sessionType);
sessionType = lower(strtrim(sessionType));
tf = ~isempty(sessionType) && ...
    ~any(strcmp(sessionType,{'baseline','pt','puretone','puretone','exptone','tone'}));
end

function dayLabel = assignDayLabels(sessionInfo)
nSession = height(sessionInfo);
dayLabel = repmat({''},nSession,1);

taskSession = ~cellfun(@isempty,sessionInfo.taskLabel);
if ~any(taskSession) || ~ismember('date',sessionInfo.Properties.VariableNames)
    return
end

taskDays = unique(sessionInfo.date(taskSession),'stable');
nDay = length(taskDays);
dayTaskLabel = repmat({''},nDay,1);
dayAcc = nan(nDay,1);

for i = 1:nDay
    selDay = sessionInfo.date == taskDays(i) & taskSession;
    behDay = concatBehSel(sessionInfo.behSel(selDay));
    if isempty(behDay)
        continue
    end

    t1Trial = behDay.stimuli == 1 | behDay.stimuli == 2;
    t2Trial = behDay.stimuli == 3 | behDay.stimuli == 4;
    nT1Trial = sum(t1Trial);
    nT2Trial = sum(t2Trial);
    nTaskTrial = nT1Trial + nT2Trial;
    if nTaskTrial == 0
        continue
    end

    t1Frac = nT1Trial / nTaskTrial;
    t2Frac = nT2Trial / nTaskTrial;
    if t1Frac >= 0.65
        dayTaskLabel{i} = 'T1';
        [~, dayAcc(i)] = fn_getAccBias(behDay.stimuli(t1Trial), behDay.correct(t1Trial), behDay.miss(t1Trial));
    elseif t2Frac >= 0.65
        dayTaskLabel{i} = 'T2';
        [~, dayAcc(i)] = fn_getAccBias(behDay.stimuli(t2Trial), behDay.correct(t2Trial), behDay.miss(t2Trial));
    else
        dayTaskLabel{i} = 'Int';
    end
end

dayLabelByDay = repmat({''},nDay,1);
dayLabelByDay(strcmp(dayTaskLabel,'Int')) = {'Int'};
dayLabelByDay = assignSingleTaskDayLabels(taskDays,dayTaskLabel,dayAcc,dayLabelByDay,'T1');
dayLabelByDay = assignSingleTaskDayLabels(taskDays,dayTaskLabel,dayAcc,dayLabelByDay,'T2');

for i = 1:nDay
    if isempty(dayLabelByDay{i})
        continue
    end
    selDay = sessionInfo.date == taskDays(i) & taskSession;
    dayLabel(selDay) = dayLabelByDay(i);
end
end

function dayLabelByDay = assignSingleTaskDayLabels(taskDays,dayTaskLabel,dayAcc,dayLabelByDay,taskName)
dayIdx = find(strcmp(dayTaskLabel,taskName));
if isempty(dayIdx)
    return
end

singleTaskDays = taskDays(dayIdx);
earlyDays = singleTaskDays(1:min(2,length(singleTaskDays)));
lateDays = singleTaskDays(max(1,length(singleTaskDays)-1):end);

for ii = 1:length(dayIdx)
    idx = dayIdx(ii);
    acc = dayAcc(idx);

    if ismember(taskDays(idx),earlyDays)
        period = 'E';
    elseif ismember(taskDays(idx),lateDays)
        period = 'L';
    elseif isnan(acc) || acc < 0.65
        period = 'E';
    elseif acc < 0.8
        period = 'M';
    else
        period = 'L';
    end

    dayLabelByDay{idx} = [taskName period];
end
dayLabelByDay = enforceMonotonicTaskPeriod(dayLabelByDay,dayIdx,taskName);
end

function dayLabelByDay = enforceMonotonicTaskPeriod(dayLabelByDay,dayIdx,taskName)
maxLevel = 1;
periodList = {'E','M','L'};
for ii = 1:length(dayIdx)
    idx = dayIdx(ii);
    if isempty(dayLabelByDay{idx})
        continue
    end
    period = dayLabelByDay{idx}(end);
    level = find(strcmp(period,periodList),1,'first');
    if isempty(level)
        continue
    end
    maxLevel = max(maxLevel,level);
    dayLabelByDay{idx} = [taskName periodList{maxLevel}];
end
end

function value = getTableCell(column,rowIdx)
if iscell(column)
    value = column{rowIdx};
else
    value = column(rowIdx);
end
end

function value = charValue(value)
if iscell(value)
    if isempty(value)
        value = '';
    else
        value = value{1};
    end
end
if isstring(value)
    value = char(value);
elseif iscategorical(value)
    value = char(value);
end
end

function behDay = concatBehSel(behCell)
behDay = table();
for i = 1:length(behCell)
    behSel = getTableCell(behCell,i);
    if isempty(behSel) || ~istable(behSel)
        continue
    end
    if ~all(ismember({'stimuli','correct','miss'},behSel.Properties.VariableNames))
        continue
    end
    behDay = [behDay; behSel];
end
end
