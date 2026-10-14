function [labels, k_opt] = fn_spectralClustering(X, maxK, method)
% Spectral clustering on neural data using similarity graph
% Inputs:
%   X       : [nNeurons x nFeatures] activity matrix
%   maxK    : (optional) max number of clusters to try (default = 10)
%   method  : (optional) 'eigengap' or 'silhouette' (default = 'eigengap')
%
% Outputs:
%   labels  : [nNeurons x 1] cluster assignments
%   k_opt   : optimal number of clusters selected

if nargin < 2, maxK = 10; end
if nargin < 3, method = 'silhouette'; end

n = size(X,1);

% Step 1: Build similarity matrix (RBF kernel)
sigma = mean(pdist(X));  % or choose fixed sigma
D = squareform(pdist(X));  % pairwise Euclidean distances
W = exp(-D.^2 / (2 * sigma^2));  % RBF kernel similarity

% Step 2: Build normalized Laplacian
Dmat = diag(sum(W,2));
L = Dmat - W;  % unnormalized Laplacian
Lsym = Dmat^(-1/2) * L * Dmat^(-1/2);  % symmetric normalized Laplacian

% Step 3: Eigen decomposition
[eigVecs, eigVals] = eig(Lsym);
eigVals = diag(eigVals);
[~, idx] = sort(eigVals);
eigVecs = eigVecs(:, idx);
eigVals = eigVals(idx);

% Step 4: Determine optimal number of clusters
if strcmpi(method, 'eigengap')
    gaps = diff(eigVals(1:maxK+1));
    [~, k_opt] = max(gaps);
    fprintf('Selected %d clusters by eigengap\n', k_opt);
elseif strcmpi(method, 'silhouette')
    sils = zeros(1, maxK);
    for k = 2:maxK
        V = eigVecs(:, 1:k);
        labels = kmeans(V, k, 'Replicates', 10, 'MaxIter', 1000);
        sils(k) = mean(silhouette(V, labels));
    end
    [~, k_opt] = max(sils);
    fprintf('Selected %d clusters by silhouette\n', k_opt);
else
    error('Unknown method: choose \"eigengap\" or \"silhouette\".');
end

% Step 5: Run k-means on eigenvectors
V = eigVecs(:, 1:k_opt);
labels = kmeans(V, k_opt, 'Replicates', 10, 'MaxIter', 1000);

% Optional: plot eigenvalue spectrum
figure;
subplot(1,2,1); plot(eigVals(1:maxK+1), 'o-'); xlabel('k'); ylabel('Eigenvalue');
title('Eigenvalue Spectrum');

subplot(1,2,2); gscatter(V(:,1), V(:,2), labels);
title(sprintf('Spectral Clustering (k = %d)', k_opt));
xlabel('1st Eigenvector'); ylabel('2nd Eigenvector');
end
