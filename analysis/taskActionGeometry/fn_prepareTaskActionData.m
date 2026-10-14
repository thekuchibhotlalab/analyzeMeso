function [data,opts]=fn_prepareTaskActionData(curated,opts)
%FN_PREPARETASKACTIONDATA Accept raw 4 x animal cells or a curated structure.
defaults=fn_taskActionGeometryConfig();
if nargin<2||isempty(opts), opts=defaults; end
for f=fieldnames(defaults)'
    if ~isfield(opts,f{1}), opts.(f{1})=defaults.(f{1}); end
end
opts.taskDefinition=validatestring(opts.taskDefinition,{'stimulusSet','context'});
opts.normalization=validatestring(opts.normalization,{'zscore','rms','none'});
opts.splitUnit=validatestring(opts.splitUnit,{'auto','session','trial'});
opts.noiseMetric=validatestring(opts.noiseMetric,{'diagonal','shrinkage','identity'});
for f={'nComponents','nSplits','minTrialsPerHalf'}
    validateattributes(opts.(f{1}),{'numeric'},{'scalar','integer','positive','finite'});
end
validateattributes(opts.frameRate,{'numeric'},{'scalar','positive','finite'});
validateattributes(opts.noiseRidge,{'numeric'},{'scalar','positive','finite'});
validateattributes(opts.noiseShrinkage,{'numeric'},{'scalar','>=',0,'<=',1});
if iscell(curated)
    [data,opts]=fn_prepareTaskActionCells(curated,opts);
    return;
end
if strcmp(opts.splitUnit,'auto'), opts.splitUnit='session'; end
assert(isfield(curated,'neuralLoaded')&&curated.neuralLoaded, ...
    'taskGeometry:NeuralData','First call a.fn_prepareNeuralData(curated).');
assert(isfield(curated,'tracking')&&isfield(curated.tracking,'selectedNeuronIDs'), ...
    'taskGeometry:Tracking','Tracked neuron identities are required for cross-session geometry.');
ids=curated.tracking.selectedNeuronIDs(:);
if ~isempty(opts.neuronIDs)
    assert(all(ismember(opts.neuronIDs,ids)), 'taskGeometry:Tracking', ...
        'neuronIDs must be tracked across the selected sessions.');
    ids=opts.neuronIDs(:);
end
assert(~isempty(ids)&&numel(unique(ids))==numel(ids),'taskGeometry:Tracking', ...
    'Provide at least one unique neuron tracked across the selected sessions.');
items=curated.neuralSelection;
names=string({items.name}); wanted=string(opts.conditionNames);
assert(all(ismember(wanted,names)),'taskGeometry:Conditions','Unknown conditionNames.');
chunks={}; tables={}; nTime=[];
for k=1:numel(items)
    if ~isempty(wanted)&&~ismember(names(k),wanted), continue; end
    X=items(k).neuralRaw; T=items(k).trialInfoNeural;
    if isempty(X)||isempty(T), continue; end
    assert(size(X,3)==height(T),'taskGeometry:Mapping','Neural trials and table rows disagree.');
    if isempty(nTime), nTime=size(X,2); end
    assert(size(X,2)==nTime&&max(ids)<=size(X,1),'taskGeometry:Shape','Neural dimensions disagree across conditions.');
    if ~isempty(opts.dayLabels)
        keep=ismember(lower(strtrim(string(T.dayLabel))),lower(string(opts.dayLabels)));
        T=T(keep,:); X=X(:,:,keep);
    end
    if isempty(T), continue; end
    T.geometrySourceCondition=repmat(names(k),height(T),1);
    chunks{end+1}=X(ids,:,:); tables{end+1}=T; %#ok<AGROW>
end
assert(~isempty(chunks),'taskGeometry:Empty','No trials remain in this condition/period subset.');
X=cat(3,chunks{:}); T=vertcat(tables{:});
assert(all(ismember({'sessionRec','trialInSession','stimuli','action'},T.Properties.VariableNames)), ...
    'taskGeometry:Metadata','Trial identities, stimuli and action are required.');
[~,keep]=unique([T.sessionRec,T.trialInSession],'rows','stable');
duplicateCount=height(T)-numel(keep); T=T(keep,:); X=X(:,:,keep);
task=zeros(height(T),1);
if strcmp(opts.taskDefinition,'stimulusSet')
    task(ismember(T.stimuli,[1 2]))=1; task(ismember(T.stimuli,[3 4]))=2;
else
    assert(ismember('taskLabel',T.Properties.VariableNames),'taskGeometry:Metadata','Context analysis requires taskLabel.');
    labels=upper(strtrim(string(T.taskLabel)));
    task(labels=="T1")=1; task(labels=="T2")=2;
end
keep=task>0&ismember(T.action,[1 2]);
excludedLabelCount=sum(~keep); task=task(keep); T=T(keep,:); X=X(:,:,keep);
group=2*(task-1)+double(T.action);
if isempty(opts.eventFrame), opts.eventFrame=curated.cfg.alignedEventFrame; end
time=((1:nTime)-opts.eventFrame)/opts.frameRate;
frames=1:nTime;
if ~isempty(opts.timeWindow)
    validateattributes(opts.timeWindow,{'numeric'},{'numel',2,'finite','real'});
    assert(opts.timeWindow(1)<=opts.timeWindow(2),'taskGeometry:Window','timeWindow must be increasing.');
    frames=find(time>=opts.timeWindow(1)&time<=opts.timeWindow(2));
end
assert(~isempty(frames),'taskGeometry:Window','No frames within timeWindow.');
time=time(frames); X=double(X(:,frames,:));
finite=all(reshape(isfinite(X),numel(ids),[]),2);
assert(opts.dropNonfiniteNeurons||all(finite),'taskGeometry:Nonfinite', ...
    'Nonfinite samples: shorten timeWindow or enable dropNonfiniteNeurons.');
droppedIDs=ids(~finite); ids=ids(finite); X=X(finite,:,:);
assert(~isempty(ids),'taskGeometry:Nonfinite','No finite tracked neurons remain; inspect the time window.');
if opts.averageTime, X=mean(X,2); time=mean(time); end
counts=accumarray(group,1,[4 1]);
assert(all(counts>=2*opts.minTrialsPerHalf),'taskGeometry:Cells', ...
    'All four task/action cells need >=%d trials; counts are [%s].', ...
    2*opts.minTrialsPerHalf,num2str(counts'));
sessions=zeros(4,1);
for g=1:4, sessions(g)=numel(unique(T.sessionRec(group==g))); end
data=struct('X',X,'trials',T,'group',group,'neuronIDs',ids, ...
    'droppedNeuronIDs',droppedIDs,'duplicateTrialCount',duplicateCount, ...
    'excludedLabelCount',excludedLabelCount,'time',time,'frames',frames, ...
    'cellNames',["T1_L";"T1_R";"T2_L";"T2_R"], ...
    'counts',table(["T1_L";"T1_R";"T2_L";"T2_R"],counts,sessions, ...
    'VariableNames',{'cell','nTrials','nSessions'}));
if opts.verbose
    disp(data.counts);
    fprintf('Geometry: %d neurons, %d samples/trial, %d unique trials; %d nonfinite neurons removed.\n', ...
        size(X,1),size(X,2),size(X,3),numel(droppedIDs));
end
end
