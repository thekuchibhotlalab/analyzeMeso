function [neuronTable,animalTables] = fn_extractBestTCByAnimal(M,nModel,nNeuron)
%FN_EXTRACTBESTTCBYANIMAL Assign neurons to their strongest TCA component.
%   [NEURONTABLE,ANIMALTABLES] = FN_EXTRACTBESTTCBYANIMAL(M,NMODEL,NNEURON)
%   identifies the maximum neural loading in M.U{1} for every neuron and
%   separates the resulting table using the concatenated animal counts in
%   NNEURON. M can be a cell array of models or one fitted ktensor.

if iscell(M)
    if isempty(nModel) || nModel<1 || nModel>numel(M)
        error('fn_extractBestTCByAnimal:InvalidModelIndex', ...
            'Provide a valid nModel for the model cell array.');
    end
    model = M{nModel};
else
    model = M;
end
neuralLoading = model.U{1};
if sum(nNeuron) ~= size(neuralLoading,1)
    error('fn_extractBestTCByAnimal:NeuronCountMismatch', ...
        'sum(nNeuron) is %d, but the model contains %d neurons.', ...
        sum(nNeuron),size(neuralLoading,1));
end

[bestWeight,bestComponent] = max(neuralLoading,[],2);
animalEnd = cumsum(nNeuron(:));
animalStart = [1;animalEnd(1:end-1)+1];
animalIndex = zeros(sum(nNeuron),1);
animalNeuron = zeros(sum(nNeuron),1);
for animal = 1:numel(nNeuron)
    rows = animalStart(animal):animalEnd(animal);
    animalIndex(rows) = animal;
    animalNeuron(rows) = (1:nNeuron(animal))';
end

neuronTable = table((1:sum(nNeuron))',animalIndex,animalNeuron, ...
    bestComponent,bestWeight,'VariableNames', ...
    {'GlobalNeuron','AnimalIndex','AnimalNeuron','BestComponent','BestWeight'});
animalTables = cell(numel(nNeuron),1);
for animal = 1:numel(nNeuron)
    animalTables{animal} = neuronTable(neuronTable.AnimalIndex==animal,:);
end
end
