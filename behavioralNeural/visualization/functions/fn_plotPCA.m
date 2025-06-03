function fn_plotPCA(dataCell)
[projData,explainedVar] = getPCA(dataCell);
nDays = length(dataCell);
for dayIdx = 1:nDays
    % Assuming `projData` is a cell array where each cell contains the projected data for that day
    % and `explainedVar` is a cell array of explained variances for each day
    plotPCAResults(projData{dayIdx}, explainedVar{dayIdx}, dayIdx);
end



end 

%% all functions

function [projData,explainedVar] = getPCA(dataCell)

% Assuming dataCell is your 1*n cell array containing neural data for each day
nDays = length(dataCell);
nComponents = 5;  % Number of principal components for projection

% To store results
projData = cell(1, nDays);  % Cell to store projections reshaped to nNeuron*time*trial
explainedVar = cell(1, nDays);  % Store variance explained for each day

for dayIdx = 1:nDays
    neuralData = dataCell{dayIdx};  % Retrieve data for current day
    [nNeurons, nTime, nTrials] = size(neuralData);
    
    % Step 1: Concatenate time and trial-type axes, handling NaNs
    reshapedData = reshape(neuralData, nNeurons, nTime * nTrials);  % nNeuron x (time * trials)
    reshapedData = fillmissing(reshapedData, 'constant', 0);  % Fill NaNs with zeros or other method

    % Step 2: Z-score normalization for each neuron
    reshapedData = reshapedData - repmat(nanmedian(reshapedData,2),[1 size(reshapedData,2)]);
    zScoredData = zscore(reshapedData, 0, 2);

    % Step 3: Apply smoothing (using a Gaussian or moving average filter)
    smoothedData = smoothdata(zScoredData, 2, 'gaussian', 5);  % Example smoothing with window size 5

    % Step 4: Perform PCA
    [coeff, score, ~, ~, explained] = pca(smoothedData');  % PCA on neurons' activity

    % Store variance explained for each day
    explainedVar{dayIdx} = explained;

    % Step 5: Project data onto PCs and reshape back to original dimensions
    projScore = score(:, 1:nComponents)';  % First nComponents components
    projData{dayIdx} = reshape(projScore, [nComponents, nTime, nTrials]);
end



end 


function plotPCAResults(projData, explainedVar, dayIdx)
    % Function to plot PCA results for a given day’s neural data
    % Inputs:
    %   projData - Projected data after PCA, reshaped as nComponents x Time x TrialType
    %   explainedVar - Variance explained by each principal component
    %   dayIdx - Index of the day (used for labeling the plot)

    % Number of principal components to plot
    nComponents = size(projData, 1);

    % Create a figure for the current day
    figure('Name', ['PCA Results for Day ' num2str(dayIdx)], 'NumberTitle', 'off');
    
    % Part 1: Variance Explained Plot (Top left corner, occupying 1/6 area)
    subplot(2, 6, 1);
    plot(explainedVar, '-o'); xlim([0 20])
    xlabel('Principal Component');
    ylabel('Variance Explained (%)');
    title(['Variance Explained for Day ' num2str(dayIdx)]);

    % Part 2: Trajectories of All Trial Types in PC1 vs. PC2 (Bottom left corner)
    subplot(2, 6, 7);
    hold on;
    colors = ['r', 'g', 'b', 'm'];  % Colors for 4 trial types
    for trialType = 1:size(projData, 3)
        if ~all(isnan(projData(:, :, trialType)), 'all')  % Skip if all entries are NaN
            plot(projData(1,:,trialType), projData(2,:,trialType), ...
                'Color', colors(trialType), 'DisplayName', ['Trial Type ' num2str(trialType)]);
        end
    end
    legend show;
    xlabel('PC1');
    ylabel('PC2');
    title('Trajectories in PC1-PC2 Space');

    % Part 3: Subplots for First 5 PCs - Comparison of Trial Types
    for pcIdx = 1:min(nComponents, 5)  % Ensure we only plot up to 5 PCs if available
        % Comparison for trial types 1 & 3
        subplot(2, 6, (pcIdx + 1));
        hold on;
        if size(projData, 3) >= 3  % Ensure there are at least 3 trial types
            if ~all(isnan(projData(pcIdx, :, 1)))  % Plot only if not all NaNs
                plot(projData(pcIdx, :, 1), 'r');  % Trial Type 1 in red
            end
            if ~all(isnan(projData(pcIdx, :, 3)))
                plot(projData(pcIdx, :, 3), 'b');  % Trial Type 3 in blue
            end
        end
        title(['PC' num2str(pcIdx) ': Trial Types 1 vs 3']);
        xlabel('Time');
        ylabel(['PC' num2str(pcIdx)]);
        
        % Comparison for trial types 2 & 4
        subplot(2, 6, pcIdx +7);
        hold on;
        if size(projData, 3) >= 4  % Ensure there are at least 4 trial types
            if ~all(isnan(projData(pcIdx, :, 2)))
                plot(projData(pcIdx, :, 2), 'g');  % Trial Type 2 in green
            end
            if ~all(isnan(projData(pcIdx, :, 4)))
                plot(projData(pcIdx, :, 4), 'm');  % Trial Type 4 in magenta
            end
        end
        title(['PC' num2str(pcIdx) ': Trial Types 2 vs 4']);
        xlabel('Time');
        ylabel(['PC' num2str(pcIdx)]);
    end
end