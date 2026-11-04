function [curated,figures] = fn_prepareTrialData(trialInfo,sessionInfoBeh,cfg,varargin)
%FN_PREPARETRIALDATA Select trials and sessions using lightweight metadata.
% First output contains data/configuration only; second output holds figures.
% figures.tracking and figures.rt are empty when their plots are not created.
% Inputs are tables or *_trialInfo.mat and *_sessionInfoBeh.mat filenames.
% Default: no parsedTrial.mat load. Inspect tracking.curve, then use
% fn_chooseTrackedSessions and fn_prepareNeuralData when ready for neural activity.
% For the old in-memory sessionInfo workflow, set cfg.loadNeural=true.
% 'MakePlot',false: display RT and session/neuron tradeoff plots when true.
% This argument is independent of fn_prepareNeuralData's ShowPlots option.
% Plotting is controlled by function arguments, not cfg.makePlots.
% 'TrialNumbers',ids: explicitly select trialInfo row numbers instead
% of behavioral/RT filters. Vector -> one ManualTrials condition; cell array ->
% one list per cfg.conditionDef (labels retained). Session/tracking cfg applies.
% 'TrialNumberField','': use row numbers; set a column name to match IDs instead.
% 'GroupManualTrialsByCondition',true: split a numeric manual pool by the
% stimulus/action pairs in cfg.conditionDef; day/task/RT filters remain bypassed.
if nargin<3 || isempty(cfg), cfg=fn_defaultTrialSelectionConfig(); end
p=inputParser;
addParameter(p,'MakePlot',false,@(x)islogical(x)&&isscalar(x));
addParameter(p,'TrialNumbers',[],@(x)isnumeric(x)||iscell(x));
addParameter(p,'GroupManualTrialsByCondition',false,@(x)islogical(x)&&isscalar(x));
addParameter(p,'TrialNumberField','',@(x)ischar(x)||(isstring(x)&&isscalar(x)));
parse(p,varargin{:});
manualTrials=~any(strcmp('TrialNumbers',p.UsingDefaults));
makePlot=p.Results.MakePlot;
defaults=fn_defaultTrialSelectionConfig();
names=fieldnames(defaults);
for i=1:numel(names)
    if ~isfield(cfg,names{i}), cfg.(names{i})=defaults.(names{i}); end
end
% The object supplies its ID. Direct file calls can infer it from canonical names.
if strlength(string(cfg.animalID))==0
    sources={trialInfo,cfg.sessionInfoFile};
    for i=1:numel(sources)
        source=sources{i};
        if (ischar(source)||isstring(source)) && isscalar(string(source))
            [~,stem]=fileparts(char(source));
            token=regexp(stem,'^(.+)_parsedTrial(?:_trialInfo|_sessionInfoBeh)?$','tokens','once');
            if ~isempty(token), cfg.animalID=string(token{1}); break; end
        end
    end
end
trialInfo=fn_loadTrialTable(trialInfo,'trialInfo');
metadata=fn_loadTrialTable(sessionInfoBeh,'sessionInfoBeh');
if isempty(cfg.conditionDef)
    cfg.conditionDef=defaults.conditionDef;
end
conditionDef=cfg.conditionDef;
% Lookahead preserves minimum quotas, then scores every remaining session.
if strcmpi(cfg.trackingMethod,'lookahead'), cfg.matchRemaining=false; end
if manualTrials
    [selection,conditionDef]=fn_selectManualTrials(trialInfo,p.Results.TrialNumbers, ...
        conditionDef,p.Results.TrialNumberField,p.Results.GroupManualTrialsByCondition);
    cfg.conditionDef=conditionDef;
else
    selection=fn_selectTrialsByCondition(trialInfo,conditionDef,cfg);
end
[selection,tracking]=fn_rankTrialSessions(selection,metadata,cfg,makePlot);

curated=struct();
curated.cfg=cfg;
curated.trialPlotOptions=p.Results;
if strlength(string(cfg.animalID))>0, curated.animalID=string(cfg.animalID); end
curated.conditionDef=conditionDef;
curated.selectionAllSessions=selection;
curated.tracking=tracking;
curated.neuralLoaded=false;
curated.neuralSelection=[];
curated.byCondition=struct();
curated.qc=table(); % Neural QC is available only after extraction.
curated.sessionAudit=table();
curated.droppedTrialReport=table();
curated.trackedNeuronQC=struct();
curated=fn_chooseTrackedSessions(curated);
figures=struct('tracking',[],'rt',[]);
if isfield(curated.tracking,'figure')
    figures.tracking=curated.tracking.figure;
    curated.tracking=rmfield(curated.tracking,'figure');
end
if cfg.verbose
    decision=curated.tracking.sessionCountSelection;
    if decision.method~="fixed"
        fprintf('Session count (%s): %d of %d; minimum prefix %d (%s).\n', ...
            decision.method,decision.selectedCount,decision.availableSessions, ...
            decision.minimumSessions,decision.reason);
    end
    fprintf('\nTrial selection using metadata (neural activity not loaded):\n');
    disp(curated.selectionQC);
end
if makePlot
    figures.rt=fn_plotRTQC(curated.selection,cfg);
end
if cfg.loadNeural
    source=cfg.sessionInfoFile;
    if isempty(source) && ismember(cfg.neuralField,metadata.Properties.VariableNames)
        source=metadata; % Backward-compatible full sessionInfo table input.
    end
    curated=fn_prepareNeuralData(curated,source);
elseif ~isempty(cfg.saveFile)
    save(cfg.saveFile,'curated','-v7.3');
end
end
