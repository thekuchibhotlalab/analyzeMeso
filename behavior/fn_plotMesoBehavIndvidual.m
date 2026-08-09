function [beh,summaryStatT1,summaryStatT2,summaryStatT1_interleave, ...
    summaryStatT2_interleave,block,blockType] = ...
    fn_plotMesoBehavIndvidual(mouse,datapath,plotFlag)
%FN_PLOTMESOBEHAVINDVIDUAL Load and optionally plot one animal's behavior.
%   DATAPATH may be either:
%     1) a folder containing <mouse>_beh.mat, or
%     2) a folder containing the raw <mouse>_*_2AFCsession*.mat files.
%
%   The returned BEH is always a table. Legacy numeric behavior matrices
%   are converted to the table layout expected by fn_selBehavByTrial.

if nargin < 3 || isempty(plotFlag)
    plotFlag = false;
end

tic;
beh = loadBehaviorTable(mouse,datapath);
fprintf('Loading beh done, t = %0.3f secs\n',toc);

% Plot the complete training history in one figure and retain session data.
[~,~,~,~,taskSession] = ...
    fn_selBehavByTrial(beh,'all','plot',plotFlag);

block = taskSession;
blockType = taskSession.blockTypes;

% Keep the original output meanings, but avoid making three extra figures.
[~,~,summaryStatT1] = fn_selBehavByTrial(beh,'task1','plot',false);
[~,~,summaryStatT2] = fn_selBehavByTrial(beh,'task2','plot',false);
[~,~,summaryStatT1_interleave,summaryStatT2_interleave] = ...
    fn_selBehavByTrial(beh,'interleave','plot',false);
end

function beh = loadBehaviorTable(mouse,datapath)
if isfile(datapath)
    behaviorFile = datapath;
else
    behaviorFile = fullfile(datapath,[mouse '_beh.mat']);
end

if isfile(behaviorFile)
    loaded = load(behaviorFile,'beh');
    if ~isfield(loaded,'beh')
        error('fn_plotMesoBehavIndvidual:MissingBeh', ...
            'File %s does not contain a variable named beh.',behaviorFile);
    end
    beh = loaded.beh;
else
    ops.mouse = mouse;
    ops.datapath = datapath;
    beh = fn_loadBehav(ops);
end

if isnumeric(beh)
    variableNames = {'date','day','session','trialNum','stimulus','action', ...
        'responseType','stimulusTime','responseTime','stimulusFrame', ...
        'responseFrame','rewardFrame','context'};
    if size(beh,2) < numel(variableNames)
        error('fn_plotMesoBehavIndvidual:InvalidBehaviorMatrix', ...
            'Behavior matrix has %d columns; at least %d are required.', ...
            size(beh,2),numel(variableNames));
    end
    beh = array2table(beh(:,1:numel(variableNames)), ...
        'VariableNames',variableNames);
elseif ~istable(beh)
    error('fn_plotMesoBehavIndvidual:InvalidBehaviorType', ...
        'beh must be a numeric matrix or table.');
end

requiredVariables = {'date','day','session','stimulus','action', ...
    'responseType','stimulusTime','responseTime'};
missingVariables = setdiff(requiredVariables,beh.Properties.VariableNames);
if ~isempty(missingVariables)
    error('fn_plotMesoBehavIndvidual:MissingVariables', ...
        'Behavior table is missing: %s.',strjoin(missingVariables,', '));
end
end
