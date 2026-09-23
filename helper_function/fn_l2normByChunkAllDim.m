function [normMat, l2norm] = fn_l2normByChunkAllDim(mat, dim)
% fn_l2normByChunkAllDim L2-normalizes along one dimension while preserving all others.
%
%   normMat = fn_l2normByChunkAllDim(mat, dim)
%
% Example:
%   If mat is neuron x time x period x trialType and dim = 2, this function
%   groups neuron/period/trialType together, L2-normalizes each group across
%   time, and reshapes the output back to neuron x time x period x trialType.
%
% Optional output:
%   l2norm - sqrt(sum(mat.^2)) used for each chunk, reshaped for implicit expansion

if nargin < 2 || isempty(dim)
    dim = 1;
end

if dim < 1 || dim > ndims(mat)
    error('fn_l2normByChunkAllDim:invalidDim', ...
        'dim must be between 1 and ndims(mat).');
end

matSize = size(mat);
nd = ndims(mat);

otherDims = setdiff(1:nd, dim, 'stable');
permOrder = [otherDims dim];

matPerm = permute(mat, permOrder);
mat2d = reshape(matPerm, [], matSize(dim));

l2norm2d = sqrt(sum(mat2d.^2, 1, 'omitnan'));
l2norm2d(l2norm2d == 0) = NaN;

norm2d = mat2d ./ repmat(l2norm2d, [size(mat2d,1) 1]);

normPerm = reshape(norm2d, size(matPerm));
normMat = ipermute(normPerm, permOrder);

if nargout > 1
    statPermSize = size(matPerm);
    statPermSize(end) = 1;
    l2norm = ipermute(reshape(l2norm2d, statPermSize), permOrder);
end
end
