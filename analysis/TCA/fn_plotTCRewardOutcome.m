function [fig,neuronTable,animalTables,plotData] = ...
    fn_plotTCRewardOutcome(M,nModel,nNeuron,componentToPlot,varargin)
%FN_PLOTTcrewardOutcome Plot reward outcome activity for one TCA component.
%   [FIG,NEURONTABLE,ANIMALTABLES,PLOTDATA] = FN_PLOTTcrewardOutcome(...)
%   assigns every neuron to the component with its largest neural loading,
%   records that component and weight, separates neurons using NNEURON, and
%   plots neurons assigned to COMPONENTTOPLOT from zz153_PPC and zz172_PPC1.
%
%   Required inputs
%     M               cell array of fitted TCA models, or one ktensor model
%     nModel          model index when M is a cell array; use [] otherwise
%     nNeuron         neuron counts for each concatenated animal
%     componentToPlot component whose exclusively assigned neurons to plot
%
%   Name-value inputs
%     'DataPath'      folder containing the trialType_frame20 files
%     'AnimalNames'   default {'zz153_PPC','zz172_PPC1'}
%     'AnimalIndices' positions of those animals in nNeuron; default [1 3]
%     'NeuronMap'     cell array mapping each animal's TCA-local rows back
%                     to rows in its trial file. A direct map is inferred
%                     when the two neuron counts match.
%     'TopN'          strongest exclusive neurons to retain; default Inf
%     'FrameRate'     default 15 Hz
%     'SmoothFrames'  default 3
%
%   The eight trial types are assumed to be:
%     T1: rewarded [1 4], unrewarded [2 3]
%     T2: rewarded [5 8], unrewarded [6 7]
%   Learning periods are combined as T1 [1 2 3 7] and T2 [4 5 6 7],
%   producing E, M, L, and interleaved columns. Choice threshold is frame 21.

thisDir = fileparts(mfilename('fullpath'));
p = inputParser;
addParameter(p,'DataPath',fullfile(thisDir,'sfn2025Plot'),@(x) ischar(x)||isstring(x));
addParameter(p,'AnimalNames',{'zz172_PPC1'},@iscell);
addParameter(p,'AnimalIndices',[4],@(x) isnumeric(x)&&isvector(x));
addParameter(p,'NeuronMap',{},@iscell);
addParameter(p,'TopN',Inf,@(x) isnumeric(x)&&isscalar(x)&&x>0);
addParameter(p,'FrameRate',15,@(x) isnumeric(x)&&isscalar(x)&&x>0);
addParameter(p,'SmoothFrames',3,@(x) isnumeric(x)&&isscalar(x)&&x>=1);
parse(p,varargin{:});

animalNames = p.Results.AnimalNames;
animalIndices = p.Results.AnimalIndices(:)';
if numel(animalNames) ~= numel(animalIndices)
    error('fn_plotTCRewardOutcome:AnimalInputMismatch', ...
        'AnimalNames and AnimalIndices must have the same length.');
end
if any(animalIndices<1 | animalIndices>numel(nNeuron))
    error('fn_plotTCRewardOutcome:InvalidAnimalIndex', ...
        'AnimalIndices must refer to entries in nNeuron.');
end

if iscell(M)
    if isempty(nModel) || nModel<1 || nModel>numel(M)
        error('fn_plotTCRewardOutcome:InvalidModelIndex', ...
            'Provide a valid nModel for the model cell array.');
    end
    model = M{nModel};
else
    model = M;
end
neuralLoading = model.U{1};
if componentToPlot<1 || componentToPlot>size(neuralLoading,2)
    error('fn_plotTCRewardOutcome:InvalidComponent', ...
        'componentToPlot must be between 1 and %d.',size(neuralLoading,2));
end

[neuronTable,animalTables] = fn_extractBestTCByAnimal(M,nModel,nNeuron);
bestComponent = neuronTable.BestComponent;
bestWeight = neuronTable.BestWeight;

stageLabels = {'E','M','L','Interleaved'};
t1Periods = [1 2 3 7];
t2Periods = [4 5 6 7];
rewardTypes = {[1 4],[5 8]};
unrewardTypes = {[2 3],[6 7]};
rewarded = cell(2,4);
unrewarded = cell(2,4);
selected = cell(numel(animalNames),1);
trialMaps = p.Results.NeuronMap;
if isempty(trialMaps)
    trialMaps = cell(size(animalNames));
elseif numel(trialMaps) ~= numel(animalNames)
    error('fn_plotTCRewardOutcome:NeuronMapCount', ...
        'NeuronMap must contain one entry per requested animal.');
end

for requestedAnimal = 1:numel(animalNames)
    animalName = animalNames{requestedAnimal};
    animal = animalIndices(requestedAnimal);
    trialFile = fullfile(p.Results.DataPath,[animalName '_trialType_frame20.mat']);
    if ~isfile(trialFile)
        error('fn_plotTCRewardOutcome:TrialFileNotFound', ...
            'Could not find %s.',trialFile);
    end
    loaded = load(trialFile,'trialTypeInfo');
    hasChoiceData = isfield(loaded,'trialTypeInfo') && ...
        ((istable(loaded.trialTypeInfo) && ...
        ismember('dffChoice',loaded.trialTypeInfo.Properties.VariableNames)) || ...
        (isstruct(loaded.trialTypeInfo) && ...
        isfield(loaded.trialTypeInfo,'dffChoice')));
    if ~hasChoiceData
        error('fn_plotTCRewardOutcome:MissingChoiceData', ...
            '%s must contain trialTypeInfo.dffChoice.',trialFile);
    end
    choiceData = loaded.trialTypeInfo.dffChoice;
    nTrialFileNeuron = size(choiceData{1}{1},1);
    trialMap = resolveNeuronMap(trialMaps{requestedAnimal}, ...
        nNeuron(animal),nTrialFileNeuron,animalName);

    localTable = animalTables{animal};
    localTable.TrialFileNeuron = trialMap(:);
    localTable = localTable(localTable.BestComponent==componentToPlot,:);
    localTable = sortrows(localTable,'BestWeight','descend');
    if isfinite(p.Results.TopN)
        localTable = localTable(10:min(height(localTable),round(p.Results.TopN)),:);
    end
    selected{requestedAnimal} = localTable;
    if isempty(localTable)
        continue
    end
    trialNeuron = localTable.TrialFileNeuron;

    for stage = 1:4
        periods = [t1Periods(stage),t2Periods(stage)];
        for task = 1:2
            rewardedAnimal = averageStimuliAndTrials( ...
                choiceData{periods(task)},rewardTypes{task},trialNeuron);
            unrewardedAnimal = averageStimuliAndTrials( ...
                choiceData{periods(task)},unrewardTypes{task},trialNeuron);
            rewarded{task,stage} = [rewarded{task,stage};rewardedAnimal];
            unrewarded{task,stage} = [unrewarded{task,stage};unrewardedAnimal];
        end
    end
end

if all(cellfun(@isempty,rewarded),'all') && all(cellfun(@isempty,unrewarded),'all')
    error('fn_plotTCRewardOutcome:NoSelectedNeurons', ...
        'No requested-animal neuron was assigned to component %d.',componentToPlot);
end

nTime = findTimeLength(rewarded,unrewarded);
timeAxis = ((1:nTime)-21)/p.Results.FrameRate;
fig = figure('Color','w','Name',sprintf('TC %d reward outcome',componentToPlot), ...
    'NumberTitle','off');
plotAxes = gobjects(2,4);
taskColors = [multitaskColors('task1');multitaskColors('task2')];
for task = 1:2
    for stage = 1:4
        plotAxes(task,stage) = subplot_tight(2,4,(task-1)*4+stage,[0.035 0.025]);
        hold on;
        rewardMat = smoothdata(rewarded{task,stage},2,'movmean',p.Results.SmoothFrames);
        unrewardMat = smoothdata(unrewarded{task,stage},2,'movmean',p.Results.SmoothFrames);
        if ~isempty(rewardMat)
            fn_plotMeanErrorbar(timeAxis,rewardMat,taskColors(task,:), ...
                taskColors(task,:),{'LineWidth',2.5,'LineStyle','-'}, ...
                {'FaceAlpha',0.25});
        end
        if ~isempty(unrewardMat)
            unrewardColor = 0.45*taskColors(task,:) + 0.55*[0.55 0.55 0.55];
            fn_plotMeanErrorbar(timeAxis,unrewardMat,unrewardColor, ...
                unrewardColor,{'LineWidth',2.5,'LineStyle','--'}, ...
                {'FaceAlpha',0.18});
        end
        xline(0,'k-','HandleVisibility','off');
        title(stageLabels{stage});
        if stage==1
            ylabel(sprintf('T%d activity',task));
        end
        if task==1
            xticklabels([]);
        else
            xlabel('Time from choice threshold (s)');
        end
        box off;
    end
end

allYLim = nan(numel(plotAxes),2);
for axisIdx = 1:numel(plotAxes)
    allYLim(axisIdx,:) = ylim(plotAxes(axisIdx));
end
sharedYLim = [min(allYLim(:,1)) max(allYLim(:,2))];
if diff(sharedYLim)==0
    sharedYLim = sharedYLim+[-0.5 0.5];
end
linkaxes(plotAxes(:),'xy');
set(plotAxes,'XLim',[timeAxis(1) timeAxis(end)],'YLim',sharedYLim);

nSelected = sum(cellfun(@height,selected));
sgtitle(sprintf(['TC %d exclusive neurons from zz153 + zz172 PPC1 ' ...
    '(n=%d; solid=rewarded, dashed=unrewarded)'],componentToPlot,nSelected));

plotData = struct('rewarded',{rewarded},'unrewarded',{unrewarded}, ...
    'selectedTables',{selected},'timeAxis',timeAxis, ...
    'bestComponent',bestComponent,'bestWeight',bestWeight);
end

function trialMap = resolveNeuronMap(providedMap,nTcaNeuron,nTrialFileNeuron,animalName)
if ~isempty(providedMap)
    trialMap = providedMap(:);
    if numel(trialMap) ~= nTcaNeuron || any(trialMap<1) || ...
            any(trialMap>nTrialFileNeuron) || numel(unique(trialMap))~=numel(trialMap)
        error('fn_plotTCRewardOutcome:InvalidNeuronMap', ...
            'NeuronMap for %s must contain %d unique valid trial-file rows.', ...
            animalName,nTcaNeuron);
    end
elseif nTcaNeuron==nTrialFileNeuron
    trialMap = (1:nTcaNeuron)';
else
    error('fn_plotTCRewardOutcome:NeuronMapRequired', ...
        ['%s has %d TCA neurons but %d neurons in its trial file. Supply ' ...
        '''NeuronMap'' with the original trial-file row for every TCA-local neuron.'], ...
        animalName,nTcaNeuron,nTrialFileNeuron);
end
end

function neuronMean = averageStimuliAndTrials(periodData,trialTypes,neuronIdx)
trialData = cell(1,numel(trialTypes));
for trialType = 1:numel(trialTypes)
    data = periodData{trialTypes(trialType)};
    trialData{trialType} = data(neuronIdx,:,:);
end
trialData = cat(3,trialData{:});
neuronMean = mean(trialData,3,'omitnan');
end

function nTime = findTimeLength(rewarded,unrewarded)
allData = [rewarded(:);unrewarded(:)];
firstData = find(~cellfun(@isempty,allData),1);
if isempty(firstData)
    error('fn_plotTCRewardOutcome:EmptyTrialData','No trial activity was available.');
end
nTime = size(allData{firstData},2);
end
