%% try clustering 
% Example of generating activity where neurons are active in specific ranges
% Modify this to match your data if neurons are active in specific ranges
selFrame = 28:36; 
neuronActivity = []; clusterLabel = [];
for i = 1:16

    if i~=14 && i~=6
        [flagList, titleList] = fn_selectStim(data.selectedBehList{i},1);
        neuronActivity = cat(1,neuronActivity,[nanmean(data.dffStimList{i}(:,selFrame,flagList{1}),3),...
            nanmean(data.dffStimList{i}(:,selFrame,flagList{2}),3)]);
        clusterLabel = cat(1,clusterLabel, ones(size(data.dffStimList{i},1),1)*i);
    end 
end 


neuronActivity = smoothdata(neuronActivity,2,'movmean',3);
tempnanFlag = sum(isnan(neuronActivity),2)==size(neuronActivity,2);
neuronActivity(tempnanFlag,:) = []; clusterLabel(tempnanFlag) = []; 
neuronActivity(:,sum(isnan(neuronActivity),1)==size(neuronActivity,1)) = [];

[reducedData_umap, umapStruct, clusterStruct] = run_umap(neuronActivity,...
    'n_neighbors', 10,'metric','correlation', 'min_dist', 0.05, 'n_components', 3, 'n_epochs',600);
[reducedData_umap2, umapStruct2, clusterStruct2] = run_umap(neuronActivity,...
    'n_neighbors', 100,'metric','correlation', 'min_dist', 0.2, 'n_components', 3, 'n_epochs',200);
%% try dbscan clustering

distances = pdist(neuronActivity, 'correlation');

% Step 2: Perform DBSCAN clustering
minPts = 10;  % Minimum number of points
epsilon = 0.2;  % Epsilon value
clusterLabels = dbscan(neuronActivity, epsilon, minPts);


% Step 3: Assign cluster labels
figure; histogram(clusterLabels)
figure;
gscatter(reducedData_umap(:,1), reducedData_umap(:,2), clusterLabels);
title('DBSCAN Clustering');
xlabel('Feature 1');
ylabel('Feature 2');

%% try spectral clustering


sigma = 0.5;  % Standard deviation for the Gaussian kernel
similarityMatrix = exp(-pdist2(neuronActivity, neuronActivity,'correlation').^2 / (2 * sigma^2));

% Step 3: Compute the degree matrix and the unnormalized Laplacian
D = diag(sum(similarityMatrix, 2));  % Degree matrix
L = D - similarityMatrix;            % Unnormalized Laplacian

% Step 4: Compute the first k eigenvectors of the Laplacian (e.g., k = 2 for 2 clusters)
k = 4;  % Number of clusters
[eigVecs, eigVals] = eigs(L, k, 'smallestabs');  % Use 'smallestabs' for smallest eigenvalues

% Step 5: Normalize the eigenvectors row-wise (optional, depending on the approach)
Y = bsxfun(@rdivide, eigVecs, sqrt(sum(eigVecs.^2, 2)));

% Step 6: Perform k-means clustering on the rows of the normalized eigenvectors
clusterLabels = kmeans(Y, k);

% Step 7: Plot the clustering result
figure; histogram(clusterLabels)
figure;
gscatter(reducedData_umap(:,1), reducedData_umap(:,2), clusterLabels);
title('Spectral Clustering Result');
xlabel('Feature 1');
ylabel('Feature 2');
%%
figure;
scatter3(reducedData_umap(:,1), reducedData_umap(:,2),reducedData_umap(:,3),20,'filled','o');  % Use clusterIdx from hierarchical clustering
xlabel('UMAP Dimension 1');
ylabel('UMAP Dimension 2');
title('UMAP of Neuron Activity with Clustering');

figure; colors = jet; colors = colors(floor(linspace(1,size(colors,1),16)),:);
gscatter(reducedData_umap(:,2), reducedData_umap(:,1), clusterLabel,colors);  % Use clusterIdx from hierarchical clustering
xlabel('UMAP Dimension 1');
ylabel('UMAP Dimension 2');
title('UMAP of Neuron Activity with days in learning');

figure;
gscatter(reducedData_umap(:,2), reducedData_umap(:,1), clusterIdx);  % Use clusterIdx from hierarchical clustering
xlabel('UMAP Dimension 1');
ylabel('UMAP Dimension 2');
title('UMAP of Neuron Activity with Clustering');
%%

% Step 1: Calculate pairwise distances between neurons based on their temporal activity
distances = pdist(neuronActivity, 'correlation');  % You can choose other metrics like 'correlation'
% Step 2: Perform hierarchical clustering
Z = linkage(distances, 'average');  % You can choose 'single', 'complete', or 'average' linkage

% Step 3: Plot the dendrogram to visualize the clustering
figure;
dendrogram(Z);

% Step 4: Decide on the number of clusters and cut the dendrogram
numClusters = 4;  % Choose how many clusters you expect (modify if needed)
clusterIdx = cluster(Z, 'maxclust', numClusters);  % Assign each neuron to a cluster

% Step 5: Visualize the clustering results
figure;
gscatter(1:size(neuronActivity,1), neuronActivity(:, 15), clusterIdx);  % Example visualization at time point 15
xlabel('Neuron index');
ylabel('Activity at time point 15');
title('Neuron clustering based on temporal firing patterns');


figure; xaxisL = (selFrame-30)/15; xaxisL = xaxisL(2:end);
for i = 1:numClusters
    subplot(numClusters,2,(i-1)*2+1);
    imagesc(xaxisL,1:sum(clusterIdx==i),neuronActivity(clusterIdx==i,1:size(neuronActivity,2)/2)); clim([-0.06 0.06])
    hold on; xline(0,'Color',[0.4 0.4 0.4]); title(['PSTH stim=1, cluster=' int2str(i)]);
    subplot(numClusters,2,(i-1)*2+2)
    imagesc(xaxisL,1:sum(clusterIdx==i),neuronActivity(clusterIdx==i,size(neuronActivity,2)/2+1:end)); clim([-0.06 0.06])
    hold on; xline(0,'Color',[0.4 0.4 0.4]); title(['PSTH stim=2, cluster=' int2str(i)]);
end 

[~,sortIdx] = sort(clusterIdx,'ascend');

a = corr(neuronActivity(sortIdx,:)');
figure; imagesc(a)
clim([-0.5 1])


%% try the silhouette methods

maxClusters = 10;
avgSilhouette = zeros(1, maxClusters);

for k = 1:maxClusters
    clusterIdx = cluster(Z, 'maxclust', k);
    silhouetteVals = silhouette(neuronActivity, clusterIdx, 'correlation');
    avgSilhouette(k) = mean(silhouetteVals);
end

% Plot the silhouette analysis
figure;
plot(1:maxClusters, avgSilhouette(1:end), '-o');
xlabel('Number of clusters');
ylabel('Average Silhouette Score');
title('Silhouette Method');

%% do tsne visualization 
% Assuming 'neuronActivity' is the data matrix (neurons x time points) and 'clusterIdx' is the clustering result
% Step 1: Perform t-SNE on the neuron activity data
reducedData_tsne = tsne(neuronActivity, 'NumDimensions', 2, 'Perplexity', 100,'Distance','correlation');

% Step 2: Plot the t-SNE result with clustering
figure;
gscatter(reducedData_tsne(:,1), reducedData_tsne(:,2), clusterIdx);  % Use clusterIdx from hierarchical clustering
xlabel('t-SNE Dimension 1');
ylabel('t-SNE Dimension 2');
title('t-SNE of Neuron Activity with Clustering');

%% do umpa visualization


% Add UMAP folder to MATLAB path (if not already added)
% addpath('path_to_umap_folder');

% Step 1: Perform UMAP on the neuron activity data
[reducedData_umap, umapStruct, clusterStruct] = run_umap(neuronActivity,...
    'n_neighbors', 100,'metric','correlation', 'min_dist', 0.05, 'n_components', 3, 'n_epochs',600);

% Step 2: Plot the UMAP result with clustering
figure;
gscatter(reducedData_umap(:,2), reducedData_umap(:,1), clusterIdx);  % Use clusterIdx from hierarchical clustering
xlabel('UMAP Dimension 1');
ylabel('UMAP Dimension 2');
title('UMAP of Neuron Activity with Clustering');