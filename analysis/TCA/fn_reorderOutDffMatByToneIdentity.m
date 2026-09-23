function [outDffMatReordered, reorderIdx, commonToneLabels] = fn_reorderOutDffMatByToneIdentity(outDffMat, toneLabels, nNeuron, commonToneLabels)
%FN_REORDEROUTDFFMATBYTONEIDENTITY Reorder stimulus/tone axis per animal.
%
%   outDffMat is neuron x time x stage x tone.
%   toneLabels is nAnimal x nTone, where each row describes the current
%   tone order for that animal in dim 4 of outDffMat.
%   nNeuron is a vector with the neuron count for each animal.
%
%   Example:
%       commonToneLabels = {'D','U','5.7','11.3'};
%       [outDffMatNorm, toneReorderIdx] = fn_reorderOutDffMatByToneIdentity( ...
%           outDffMatNorm, toneLabels, nNeuron, commonToneLabels);

if nargin < 4 || isempty(commonToneLabels)
    commonToneLabels = {'D','U','5.7','11.3'};
end

nNeuron = nNeuron(:)';
nAnimal = numel(nNeuron);
nTone = size(outDffMat, 4);

toneLabels = localLabelToString(toneLabels);
commonToneLabels = localLabelToString(commonToneLabels);
commonToneLabels = reshape(commonToneLabels, 1, []);

if size(toneLabels, 1) ~= nAnimal
    error('toneLabels should have one row per animal. Got %d rows for %d animals.', size(toneLabels, 1), nAnimal);
end

if size(toneLabels, 2) ~= nTone
    error('toneLabels should have one column per dim-4 tone. Got %d labels for dim-4 size %d.', size(toneLabels, 2), nTone);
end

if numel(commonToneLabels) ~= nTone
    error('commonToneLabels should have %d entries to match dim 4.', nTone);
end

if sum(nNeuron) ~= size(outDffMat, 1)
    error('sum(nNeuron)=%d does not match size(outDffMat,1)=%d.', sum(nNeuron), size(outDffMat, 1));
end

outDffMatReordered = outDffMat;
reorderIdx = nan(nAnimal, nTone);
neuronEnd = cumsum(nNeuron);
neuronStart = [1, neuronEnd(1:end-1) + 1];

for iAnimal = 1:nAnimal
    thisLabels = toneLabels(iAnimal, :);
    [foundFlag, thisOrder] = ismember(commonToneLabels, thisLabels);

    if ~all(foundFlag)
        missingLabels = strjoin(cellstr(commonToneLabels(~foundFlag)), ', ');
        error('Animal %d is missing tone label(s): %s.', iAnimal, missingLabels);
    end

    if numel(unique(thisOrder)) ~= nTone
        error('Animal %d has duplicated tone labels; cannot build a unique reorder.', iAnimal);
    end

    thisNeuronIdx = neuronStart(iAnimal):neuronEnd(iAnimal);
    outDffMatReordered(thisNeuronIdx, :, :, :) = outDffMat(thisNeuronIdx, :, :, thisOrder);
    reorderIdx(iAnimal, :) = thisOrder;

    fprintf('Animal %d tone reorder: [%s] -> [%s], dim4 idx [%s]\n', ...
        iAnimal, strjoin(cellstr(thisLabels), ', '), ...
        strjoin(cellstr(commonToneLabels), ', '), num2str(thisOrder));
end
end

function labels = localLabelToString(labels)
if iscell(labels)
    labelsOut = strings(size(labels));
    for iLabel = 1:numel(labels)
        thisLabel = labels{iLabel};
        if isnumeric(thisLabel)
            labelsOut(iLabel) = string(num2str(thisLabel));
        else
            labelsOut(iLabel) = string(thisLabel);
        end
    end
    labels = labelsOut;
else
    labels = string(labels);
end

labels = strtrim(labels);
end
