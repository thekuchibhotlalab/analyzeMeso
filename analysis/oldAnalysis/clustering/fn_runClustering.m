function clustering = fn_runClustering(selTrialType, varargin)
    p = inputParser;
    addParameter(p, 'projIdx', []);
    parse(p, varargin{:});
    
    % Data Preparation & NaN Handling

    selTrialCount = cellfun(@(x)(size(x,3)), selTrialType);
    selTrialType = cellfun(@(x)(nanmean(x,3)), selTrialType, 'UniformOutput', false);
    selTrialTypeFlat = cat(3, selTrialType{:}); 
    
    % Reshape to [Neurons x (Time*Conditions)]
    rawMatrix = selTrialTypeFlat(:, :, selTrialCount(:) > 5);
    rawMatrix = double(reshape(rawMatrix, size(rawMatrix, 1), []));
    
    % NaN Handling ---
    % Find neurons that have ANY NaN values in their feature vector
    % (UMAP/Hierarchical clustering cannot handle NaNs)
    nanMask = any(isnan(rawMatrix), 2); 
    validMask = ~nanMask; % Logic: Keep rows that are NOT NaN
    
    % Create the clean matrix for clustering
    outmatClean = rawMatrix(validMask, :);
    outmatClean = normalize(outmatClean, 2);
    % -------------------------

    %% Step 1.1 -- Clustering on Clean Data
    [reducedData_umap, ~, ~] = run_umap(outmatClean, ...
        'n_neighbors', 50, 'metric', 'euclidean', 'min_dist', 0.01, 'n_components', 3, 'n_epochs', 600);
    
    [k, ~] = fn_hierarchicalClusteringGetK(outmatClean, 2:10, 'ward', 'euclidean');
    [labelsClean, ~] = fn_hierarchicalClustering(outmatClean, k, 'ward', 'euclidean');
    
    %% Step 1.2 -- Map Labels Back
    % Use the helper function to expand labels back to the size of rawMatrix
    labelsTracked = fn_mapLabels(labelsClean, validMask);
    
    % Visualization logic using the clean subset
    clusterNum = max(labelsClean);
    totalPlot = clusterNum + 1; 
    figure; subplot(1, totalPlot, 1);
    for i = 1:clusterNum
        scatter3(reducedData_umap(labelsClean==i, 1), ...
                 reducedData_umap(labelsClean==i, 2), ...
                 reducedData_umap(labelsClean==i, 3), '.'); hold on;
    end 
    xlabel('Umap dim 1'); ylabel('Umap dim 2'); zlabel('Umap dim 3');
    title('Distribution of each neuron in Umap embedding')
    
    % Activity plotting (using rewarded stim 4)
    
    for i = 1:clusterNum
        subplot(1, totalPlot, 1+i);
        tempCount = 0;
        for j = [1 4 5 8]
            tempPlot = cat(3, selTrialType{:, j}); hold on; tempCount = tempCount+1;
            plot(squeeze(nanmean(nanmean(tempPlot(labelsClean==i, :, :), 1),3)),...
                'Color',multitaskColors(tempCount),'LineWidth',2); 
        end 
        title(['Cluster ' num2str(i)]);
        hold on; xline(20); legend({'stim1','stim2','stim3','stim4',''})
        xlabel('Frames aligned to choice'); ylabel('Avg. spk in cluster')
    end 
    
    % Store in ani object (mapping to global ishereAll indices)
    if ~isempty(p.Results.projIdx)
        % Project subset labels back to the global population
        clustering.labelAll = fn_mapLabels(labelsTracked, p.Results.projIdx);
    end 
    
    clustering.labelTracked = labelsTracked;
    clustering.proj         = reducedData_umap; % Note: this is only for valid neurons
    clustering.validMask    = validMask;

    % %% Step 2.0 -- Second Pass
    % if p.Results.secondCluster
    %     disp(['Refining cluster ' int2str(p.Results.secondClusterSelect) '...'])
    % 
    %     % 1. Identify which 'clean' neurons belong to the target cluster
    %     targetIdxInClean = (labelsClean == p.Results.secondClusterSelect);
    %     outmatSecondPass = outmatClean(targetIdxInClean, :);
    % 
    %     % 2. Run clustering on the sub-subset
    %     [reducedData_new, ~, ~] = run_umap(outmatSecondPass, ...
    %         'n_neighbors', 10, 'metric', 'euclidean', 'min_dist', 0.001, 'n_components', 3, 'n_epochs', 1200);
    % 
    %     [k_new, ~] = fn_hierarchicalClusteringGetK(outmatSecondPass, 2:10, 'ward', 'euclidean');
    %     [labelsNewClean, ~] = fn_hierarchicalClustering(outmatSecondPass, k_new, 'ward', 'euclidean');
    % 
    %     % 3. CREATE THE BRIDGE BACK TO ORIGINAL SIZE
    %     % Create a mask the size of the original TRACKED population (with NaNs)
    %     fullTargetMask = false(size(validMask));
    % 
    %     % Find the original positions of neurons that were valid (non-NaN)
    %     validIndices = find(validMask);
    % 
    %     % Of those valid positions, flag the ones that belong to our target cluster
    %     % This 're-inflates' the subset logic into the original index space
    %     fullTargetMask(validIndices(targetIdxInClean)) = true;
    % 
    %     % 4. Apply the labels back to the full size (N x 1)
    %     ani.analysis.secondClustering.labelTracked = fn_mapLabels(labelsNewClean, fullTargetMask);
    % 
    %     % 5. Map to Global Index (including non-tracked neurons)
    %     ishereIdx = find(ani.ops.ishereAll);
    %     tempLabelFlag2 = zeros(size(ani.ops.ishereAll));
    %     tempLabelFlag2(ishereIdx) = ani.analysis.secondClustering.labelTracked;
    %     ani.analysis.secondClustering.labelAll = tempLabelFlag2;
    % 
    %     % Store metadata
    %     ani.analysis.secondClustering.proj = reducedData_new;
    %     ani.analysis.secondClustering.parentCluster = p.Results.secondClusterSelect;
    % end
end