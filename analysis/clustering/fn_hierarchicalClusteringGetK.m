function [bestK, allScores] = fn_hierarchicalClusteringGetK(X, kRange, method, metric)
% Find best number of clusters for hierarchical clustering using silhouette score
% Inputs:
%   X       : [n x m] data matrix
%   kRange  : vector of k values to evaluate (e.g., 2:10)
%   method  : linkage method (e.g., 'ward', 'average')
%   metric  : distance metric (e.g., 'euclidean', 'correlation')
%
% Outputs:
%   bestK       : optimal number of clusters based on max silhouette score
%   allScores   : silhouette scores for each k

if nargin < 3, method = 'ward'; end
if nargin < 4, metric = 'euclidean'; end

D = pdist(X, metric);
Z = linkage(D, method);

allScores = zeros(size(kRange));
for i = 1:length(kRange)
    k = kRange(i);
    labels = cluster(Z, 'maxclust', k);
    sil = silhouette(X, labels, metric);
    allScores(i) = mean(sil);
end

[~, idx] = max(allScores);
bestK = kRange(idx);

% Optional plot
figure;
plot(kRange, allScores, '-o');
xlabel('Number of Clusters (k)');
ylabel('Mean Silhouette Score');
title('Silhouette Analysis for Optimal k');

end
