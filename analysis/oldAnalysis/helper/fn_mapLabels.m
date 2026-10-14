function labelsFull = fn_mapLabels(labelsSub, mask, defaultValue)
% FN_EXPANDLABELS Maps labels from a subset back to the original population size.
%
% USAGE:
%   labelsFull = fn_expandLabels(labelsSub, mask, 0)
%
% INPUTS:
%   labelsSub    - Vector of labels (size: [sum(mask) x 1])
%   mask         - Logical mask used to subset the data (size: [TotalNeurons x 1])
%   defaultValue - Value to assign to neurons that were masked out (default: 0)

    if nargin < 3, defaultValue = nan; end

    % Initialize the full-sized vector
    labelsFull = ones(size(mask)) * defaultValue;
    
    % Map the sub-labels into the indices where the mask was true
    labelsFull(mask) = labelsSub;
end