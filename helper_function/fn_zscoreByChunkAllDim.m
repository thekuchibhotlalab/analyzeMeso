function [zMat, mu, sigma] = fn_zscoreByChunkAllDim(mat, dim)
% fn_zscoreByChunkAllDim z-scores along one dimension while preserving all others.
%
%   zMat = fn_zscoreByChunkAllDim(mat, dim)
%
% Example:
%   If mat is neuron x time x period x trialType and dim = 2, this function
%   groups neuron/period/trialType together, z-scores each group across time,
%   and reshapes the output back to neuron x time x period x trialType.
%
% Optional outputs:
%   mu    - mean used for each chunk, reshaped for implicit expansion
%   sigma - std used for each chunk, reshaped for implicit expansion

if nargin < 2 || isempty(dim)
    dim = 1;
end

if dim < 1 || dim > ndims(mat)
    error('fn_zscoreByChunkAllDim:invalidDim', ...
        'dim must be between 1 and ndims(mat).');
end

matSize = size(mat);
nd = ndims(mat);

otherDims = setdiff(1:nd, dim, 'stable');
permOrder = [otherDims dim];

matPerm = permute(mat, permOrder);
mat2d = reshape(matPerm, [], matSize(dim));

mu2d = mean(mat2d, 2, 'omitnan');
sigma2d = std(mat2d, 0, 2, 'omitnan');
sigma2d(sigma2d == 0) = NaN;

z2d = (mat2d - mu2d) ./ sigma2d;

zPerm = reshape(z2d, size(matPerm));
zMat = ipermute(zPerm, permOrder);

if nargout > 1
    statPermSize = size(matPerm);
    statPermSize(end) = 1;

    mu = ipermute(reshape(mu2d, statPermSize), permOrder);
    sigma = ipermute(reshape(sigma2d, statPermSize), permOrder);
end
end
