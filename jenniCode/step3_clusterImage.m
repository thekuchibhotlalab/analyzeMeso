function labels = step3_clusterImage(imgStack, numClusters, method)
% clusterImages clusters a stack of images based on visual similarity.
%   labels = clusterImages(imgStack, numClusters, method)
%   - imgStack: [height × width × nImages] image stack
%   - numClusters: number of desired clusters
%   - method: clustering method: 'kmeans' (default), 'hierarchical', 'pca-kmeans'

    if nargin < 3
        method = 'kmeans';
    end
    % do a median filtering of the image
    filterSize = [3 3];
    imgStack = filterImage(imgStack,filterSize); 

    % compute the correlation over the whole image
    imgCrop = 20; 
    imgStack = imgStack(imgCrop:end-imgCrop,imgCrop:end-imgCrop,:);

    [h, w, n] = size(imgStack);
    data = zeros(n, h * w);

    % Preprocessing: normalize each image
    for i = 1:n
        img = double(imgStack(:,:,i));
        img = (img - min(img(:))) / (max(img(:)) - min(img(:)));  % normalize to [0,1]
        data(i, :) = img(:)';
    end

    switch lower(method)
        case 'kmeans'
            [labels, c] = kmeans(data, numClusters, 'Replicates', 5);

        case 'pca-kmeans'
            [coeff, score, latent, tsquared, explained, mu] = pca(data);
            dataReduced = score(:, 1:min(10, size(score,2)));
            [labels,c] = kmeans(dataReduced, numClusters, 'Replicates', 5);

        case 'hierarchical'
            dist = pdist(data, 'euclidean');
            tree = linkage(dist, 'ward');
            labels = cluster(tree, 'maxclust', numClusters);

        otherwise
            error('Unknown clustering method: %s', method);
    end

    % Optional: display grouped images
    figure; 
    for i = 1:4
        subplot(2,2,i); imagesc(mean(imgStack(:,:,labels==i),3)); colormap gray; title(['cluster ' int2str(i)])
    end
end

function img = filterImage(img,filterSize)

    for i = 1:size(img,3)
        img(:,:,i) = medfilt2(img(:,:,i),filterSize);
    end

end 
