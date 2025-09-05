function [labels, Z] = fn_hierarchicalClustering(X, k, method, metric)
% Perform hierarchical clustering on neural data
%
% Inputs:
%   X      : [nNeurons x nFeatures] matrix
%   k      : number of clusters to form
%   method : linkage method (e.g., 'ward', 'average', 'single', 'complete') [default: 'ward']
%   metric : distance metric (e.g., 'euclidean', 'cosine', 'correlation') [default: 'euclidean']
%
% Outputs:
%   labels : cluster labels for each neuron
%   Z      : linkage matrix (for dendrogram plotting)

if nargin < 3, method = 'ward'; end
if nargin < 4, metric = 'euclidean'; end

% Step 1: Compute pairwise distances
D = pdist(X, metric);

% Step 2: Compute linkage
Z = linkage(D, method);

% Step 3: Assign clusters
labels = cluster(Z, 'maxclust', k);

% Optional: Plot dendrogram
figure;
dendrogram(Z, 0);
title(sprintf('Hierarchical Clustering (method: %s, k = %d)', method, k));
xlabel('Neuron Index');
ylabel('Distance');
end
