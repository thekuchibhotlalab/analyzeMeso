function [roiMovies, reconstructedFOV] = fn_splitFOV(movie, roiOps)
    % Get number of ROIs and image size
    [yTotal,xLen, nFrames] = size(movie);
    nROI = roiOps.nROI;
    yLen = roiOps.roiLen;
    
    if length(yLen) == 1; yLen = repmat(yLen,[1 nROI]); end 
    % Calculate the black strip width
    totalROIY = sum(yLen);
    blackStripWidth = (yTotal - totalROIY) / (nROI - 1);
    
    % Check if the computed black strip width is consistent
    if mod(yTotal - totalROIY, nROI - 1) ~= 0
        error('Inconsistent black strip width. Check ROI dimensions.');
    end
    
    % Split the movie into individual ROIs
    roiMovies = cell(1, nROI);
    yStart = 1;
    for i = 1:nROI
        yEnd = yStart + yLen(i) - 1;
        roiMovies{i} = movie(yStart:yEnd,:, :);
        yStart = yEnd + 1 + blackStripWidth; % Move to the next ROI, skipping the black strip
    end
    if isfield(roiOps,'roiPos')
        % Extract ROIs in specified positions
        roiGrid = roiOps.roiPos;
        [gridRows, gridCols] = size(roiGrid);
        
        % Ensure all selected ROIs have matching dimensions
        selectedROIs = cell(gridRows, gridCols);
        roiSizes = cell(gridRows, gridCols);
        for r = 1:gridRows
            for c = 1:gridCols
                idx = roiGrid(r, c);
                if idx > nROI || idx < 1
                    error('Invalid ROI index in roiPos.');
                end
                selectedROIs{r, c} = roiMovies{idx};
                roiSizes{r, c} = size(roiMovies{idx});
            end
        end
        
        % Check for consistent sizes in each dimension
        xSizes = cellfun(@(s) s(1), roiSizes);
        ySizes = cellfun(@(s) s(2), roiSizes);
        if numel(unique(xSizes(:))) > 1 || numel(unique(ySizes(:))) > 1
            error('Selected ROIs have inconsistent sizes, cannot concatenate.');
        end
        
        % Concatenate ROIs to form the reconstructed FOV
        reconstructedFOV = cell(gridRows, 1);
        for r = 1:gridRows
            reconstructedFOV{r} = cat(2, selectedROIs{r, :}); % Concatenate along x-dimension
        end
        reconstructedFOV = cat(1, reconstructedFOV{:}); % Concatenate along y-dimension
    else
        reconstructedFOV = [];
    end 
end
