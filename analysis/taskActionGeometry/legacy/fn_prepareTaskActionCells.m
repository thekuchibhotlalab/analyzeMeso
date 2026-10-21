function [data,opts]=fn_prepareTaskActionCells(activity,opts)
%FN_PREPARETASKACTIONCELLS Raw cells: rows T1L,T1R,T2L,T2R; columns animals.
% Entries are tracked-neuron x time x trial arrays. Counts may differ freely.
% All four entries within one animal must have identical neuron row identities.
if isvector(activity)&&numel(activity)==4, activity=reshape(activity,4,1); end
assert(ismatrix(activity)&&size(activity,1)==4,'taskGeometry:CellShape', ...
    'Provide 4 x nAnimal cells in order T1-left, T1-right, T2-left, T2-right.');
assert(isempty(opts.dayLabels)&&isempty(opts.conditionNames)&&isempty(opts.neuronIDs), ...
    'taskGeometry:CellFilters','Subset stages, conditions and tracked neurons BEFORE passing raw activity cells.');
if strcmp(opts.splitUnit,'auto'), opts.splitUnit='trial'; end
assert(strcmp(opts.splitUnit,'trial'),'taskGeometry:CellSplit', ...
    'Raw cells have no session identities. Use splitUnit=''trial'' or pass a curated structure.');
if isempty(opts.eventFrame), opts.eventFrame=31; end
validateattributes(opts.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
labels=string(opts.animalLabels(:)); nAnimal=size(activity,2);
if isempty(labels), labels="animal"+string((1:nAnimal)'); end
assert(numel(labels)==nAnimal&&numel(unique(labels))==nAnimal&&all(~ismissing(labels)&strlength(labels)>0), ...
    'taskGeometry:AnimalLabels','Provide one unique nonempty label per animal column.');
pop={}; neuronTables={}; droppedTables={}; excluded=strings(nAnimal,1);
counts=zeros(4,nAnimal); nTime=[]; offset=0; kept=false(nAnimal,1);
for a=1:nAnimal
    if any(cellfun(@isempty,activity(:,a)))
        excluded(a)="missing condition or no neurons"; continue;
    end
    for g=1:4
        validateattributes(activity{g,a},{'numeric'},{'real','nonempty'});
        assert(ndims(activity{g,a})<=3,'taskGeometry:CellShape','Entries must be neuron x time x trial.');
        counts(g,a)=size(activity{g,a},3);
    end
    if any(counts(:,a)<2*opts.minTrialsPerHalf)
        excluded(a)="too few trials for independent halves"; continue;
    end
    nNeuron=size(activity{1,a},1); nt=size(activity{1,a},2);
    for g=1:4
        assert(size(activity{g,a},1)==nNeuron&&size(activity{g,a},2)==nt, ...
            'taskGeometry:Shape','Neuron/time dimensions differ across conditions for %s.',labels(a));
    end
    if isempty(nTime), nTime=nt; end
    assert(nt==nTime,'taskGeometry:Shape','All animals must have matching time bins and alignment.');
    time=((1:nt)-opts.eventFrame)/opts.frameRate; frames=1:nt;
    if ~isempty(opts.timeWindow)
        validateattributes(opts.timeWindow,{'numeric'},{'numel',2,'finite','real','increasing'});
        frames=find(time>=opts.timeWindow(1)&time<=opts.timeWindow(2));
    end
    assert(~isempty(frames),'taskGeometry:Window','No frames within timeWindow.');
    X=cellfun(@(v)double(v(:,frames,:)),activity(:,a),'UniformOutput',false);
    X=cat(3,X{:}); finite=all(reshape(isfinite(X),nNeuron,[]),2);
    assert(opts.dropNonfiniteNeurons||all(finite),'taskGeometry:Nonfinite','Nonfinite activity for %s.',labels(a));
    globalIDs=offset+(1:nNeuron)'; offset=offset+nNeuron;
    rows=(1:nNeuron)';
    mapping=table(globalIDs,repmat(a,nNeuron,1),repmat(labels(a),nNeuron,1),rows, ...
        'VariableNames',{'neuronID','animalIndex','animalLabel','rowInAnimal'});
    droppedTables{end+1}=mapping(~finite,:); %#ok<AGROW>
    if ~any(finite), excluded(a)="no finite neurons in the selected window"; continue; end
    X=X(finite,:,:); if opts.averageTime, X=mean(X,2); end
    group=repelem((1:4)',counts(:,a));
    % Session identities are unknown, not fabricated from trial indices.
    trials=table(nan(numel(group),1),'VariableNames',{'sessionRec'});
    pop{end+1}=struct('X',X,'group',group,'trials',trials,'animalLabel',labels(a)); %#ok<AGROW>
    neuronTables{end+1}=mapping(finite,:); kept(a)=true; %#ok<AGROW>
end
assert(any(kept),'taskGeometry:Cells','No animals have four usable conditions with enough trials and finite neurons.');
for a=find(~kept)'
    warning('taskGeometry:ExcludedAnimal','Excluded %s: %s.',labels(a),excluded(a));
end
neurons=vertcat(neuronTables{:}); dropped=vertcat(droppedTables{:});
time=((frames)-opts.eventFrame)/opts.frameRate;
if opts.averageTime, time=mean(time); end
cellNames=["T1_L";"T1_R";"T2_L";"T2_R"];
data=struct('X',[],'animalData',{pop},'time',time,'frames',frames, ...
    'cellNames',cellNames,'neuronIDs',neurons.neuronID,'neurons',neurons, ...
    'droppedNeuronIDs',dropped.neuronID,'droppedNeurons',dropped, ...
    'isPseudoPopulation',sum(kept)>1,'animalLabels',labels(kept), ...
    'excludedAnimals',table(find(~kept),labels(~kept),excluded(~kept), ...
    'VariableNames',{'animalIndex','animalLabel','reason'}));
data.counts=table(cellNames,sum(counts(:,kept),2),nan(4,1), ...
    'VariableNames',{'cell','nTrials','nSessions'});
data.trialsPerAnimal=array2table(counts(:,kept)','VariableNames',cellstr(cellNames), ...
    'RowNames',cellstr(labels(kept)));
if opts.verbose
    disp(data.trialsPerAnimal);
    fprintf('Geometry: %d neurons from %d animals; independent trial halves within each animal.\n',height(neurons),sum(kept));
end
end
