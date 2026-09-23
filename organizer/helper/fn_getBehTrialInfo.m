function [sessionInfoBeh,trialInfo] = fn_getBehTrialInfo(sessionInfo)
%GETBEHTRIALINFO Create session- and trial-level behavioral tables.
%
% [sessionInfoBeh,trialInfo] = getBehTrialInfo(sessionInfo)
%
% sessionInfoBeh contains every 2AFC session, including behavior-only
% sessions. It preserves the input table's row order and variables except
% for the neural trial arrays listed in sessionVariablesToRemove below.
% sessionRec is copied unchanged, so recorded sessions continue to map back
% to the original neural-session indexing used by Animal.
%
% trialInfo contains one row per trial. Session values are repeated for all
% trials in that session, every selected behSel variable becomes a regular
% table variable, and each wheel variable is stored as one nTime-by-1 trace
% per row. Sessions with an empty behSel remain in sessionInfoBeh and
% contribute zero rows to trialInfo.
%
% Edit the cell arrays in the configuration block to change the fields that
% are retained. An empty behaviorVariablesToKeep means keep every variable
% found in behSel.

% ------------------------- configuration -------------------------------
behaviorSessionTypes = {'2AFC'};

sessionVariablesToRemove = ...
    {'tuning','dffStim','dffChoice','dffReward'};

sessionVariablesForTrials = ...
    {'date','sessionName','ishere','sessionRec','day','taskLabel','dayLabel'};

behaviorVariablesToKeep = {}; % Empty means all behSel table variables.

trialTraceVariables = {'wheelStim','wheelChoice','wheelReward'};

derivedTrialVariables = {'trialInSession'};
% -----------------------------------------------------------------------

if ~istable(sessionInfo)
    error('getBehTrialInfo:InvalidInput','sessionInfo must be a MATLAB table.');
end

requiredSessionVariables = ...
    unique([{'sessionType','behSel'},sessionVariablesForTrials],'stable');
assertVariablesExist(sessionInfo,requiredSessionVariables,'sessionInfo');

sessionTypes = normalizeTextColumn(sessionInfo.sessionType);
normalizedBehaviorTypes = cellfun(@(value) lower(strtrim(value)), ...
    behaviorSessionTypes,'UniformOutput',false);
behaviorSessionFlag = ismember(cellstr(lower(strtrim(sessionTypes))), ...
    normalizedBehaviorTypes);
sessionInfoBeh = sessionInfo(behaviorSessionFlag,:);

variablesPresent = intersect(sessionVariablesToRemove, ...
    sessionInfoBeh.Properties.VariableNames,'stable');
sessionInfoBeh(:,variablesPresent) = [];

% Determine one stable behSel schema before creating trial chunks. This
% makes inconsistent session tables fail with a useful session-specific
% message rather than during table concatenation.
behaviorVariables = behaviorVariablesToKeep;
if isempty(behaviorVariables)
    for i = 1:height(sessionInfoBeh)
        behSel = getCellValue(sessionInfoBeh.behSel,i,'behSel');
        if ~isempty(behSel)
            if ~istable(behSel)
                error('getBehTrialInfo:InvalidBehSel', ...
                    'sessionInfoBeh row %d: behSel must be a table.',i);
            end
            behaviorVariables = behSel.Properties.VariableNames;
            break
        end
    end
end

duplicateVariables = intersect(sessionVariablesForTrials,behaviorVariables,'stable');
if ~isempty(duplicateVariables)
    error('getBehTrialInfo:DuplicateVariables', ...
        'Session and behSel variables overlap: %s.',strjoin(duplicateVariables,', '));
end
reservedVariables = [derivedTrialVariables,trialTraceVariables];
duplicateVariables = intersect([sessionVariablesForTrials,behaviorVariables], ...
    reservedVariables,'stable');
if ~isempty(duplicateVariables)
    error('getBehTrialInfo:DuplicateVariables', ...
        'Configured variables conflict with derived output variables: %s.', ...
        strjoin(duplicateVariables,', '));
end

trialChunks = cell(height(sessionInfoBeh),1);
for i = 1:height(sessionInfoBeh)
    behSel = getCellValue(sessionInfoBeh.behSel,i,'behSel');
    if isempty(behSel)
        trialChunks{i} = table();
        continue
    end
    if ~istable(behSel)
        error('getBehTrialInfo:InvalidBehSel', ...
            'sessionInfoBeh row %d: behSel must be a table.',i);
    end
    assertVariablesExist(behSel,behaviorVariables, ...
        sprintf('behSel in sessionInfoBeh row %d',i));

    nTrial = height(behSel);
    repeatedRows = repmat(i,nTrial,1);
    sessionPart = sessionInfoBeh(repeatedRows,sessionVariablesForTrials);
    behaviorPart = behSel(:,behaviorVariables);
    trialPart = [sessionPart behaviorPart];
    trialPart.trialInSession = (1:nTrial)';

    for j = 1:numel(trialTraceVariables)
        variableName = trialTraceVariables{j};
        traces = cell(nTrial,1);
        if ismember(variableName,sessionInfoBeh.Properties.VariableNames)
            sessionTraces = getCellValue(sessionInfoBeh.(variableName),i,variableName);
            if ~isempty(sessionTraces)
                if ~isnumeric(sessionTraces) || ~ismatrix(sessionTraces)
                    error('getBehTrialInfo:InvalidTrace', ...
                        'sessionInfoBeh row %d: %s must be an nTime-by-nTrial numeric matrix.', ...
                        i,variableName);
                end
                if size(sessionTraces,2) ~= nTrial
                    error('getBehTrialInfo:TrialCountMismatch', ...
                        ['sessionInfoBeh row %d: behSel has %d trials, but %s ' ...
                         'has %d columns.'], ...
                        i,nTrial,variableName,size(sessionTraces,2));
                end
                traces = mat2cell(sessionTraces,size(sessionTraces,1),ones(1,nTrial))';
            end
        end
        trialPart.(variableName) = traces;
    end
    trialChunks{i} = trialPart;
end

nonemptyChunk = find(~cellfun(@isempty,trialChunks),1,'first');
if isempty(nonemptyChunk)
    % With no trials, behSel has no discoverable dynamic schema. Still
    % return a useful zero-row table containing every configured field.
    trialInfo = sessionInfoBeh([],sessionVariablesForTrials);
    trialInfo.trialInSession = zeros(0,1);
    for j = 1:numel(trialTraceVariables)
        trialInfo.(trialTraceVariables{j}) = cell(0,1);
    end
else
    template = trialChunks{nonemptyChunk}([],:);
    for i = 1:numel(trialChunks)
        if isempty(trialChunks{i}); trialChunks{i} = template; end
    end
    trialInfo = vertcat(trialChunks{:});
end
end

function assertVariablesExist(inputTable,variableNames,tableName)
missingVariables = setdiff(variableNames,inputTable.Properties.VariableNames,'stable');
if ~isempty(missingVariables)
    error('getBehTrialInfo:MissingVariables', ...
        '%s is missing required variables: %s.', ...
        tableName,strjoin(missingVariables,', '));
end
end

function values = normalizeTextColumn(values)
if iscell(values)
    try
        values = string(values);
    catch
        error('getBehTrialInfo:InvalidSessionType', ...
            'sessionType must contain text values.');
    end
elseif iscategorical(values) || ischar(values)
    values = string(values);
elseif ~isstring(values)
    error('getBehTrialInfo:InvalidSessionType', ...
        'sessionType must be a cell array of text, string, char, or categorical.');
end
values = values(:);
end

function value = getCellValue(column,rowIndex,variableName)
if ~iscell(column)
    error('getBehTrialInfo:InvalidContainer', ...
        'sessionInfo.%s must be a cell array with one value per session.', ...
        variableName);
end
value = column{rowIndex};
end
