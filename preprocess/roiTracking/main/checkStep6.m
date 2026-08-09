function checkStep6(rootPath, sessionsToPlot)
% PLOTSESSIONROIS Plots all ROIs for a given set of sessions on top of their aligned Suite2p images.
%
% Inputs:
%   rootPath        - String path to the animal directory (e.g., 'G:\rockfish\ziyi\zz170_AC1')
%   sessionsToPlot  - Array of session indices to plot (e.g., [1, 10, 20, 30])

    %% 1. Load the necessary data files
    opsPath = [rootPath filesep 'ops.mat'];
    alignedOpsPath = [rootPath filesep 'alignedOps.mat'];
    trackedRoiPath = [rootPath filesep 'stackROI_final_tracked.mat'];
    
    % Check if files exist
    if ~exist(alignedOpsPath, 'file')
        error('Could not find alignedOps.mat at %s', alignedOpsPath);
    end
    if ~exist(trackedRoiPath, 'file')
        error('Could not find stackROI_final_tracked.mat at %s', trackedRoiPath);
    end
    
    fprintf('Loading tracked ROIs and alignment operations...\n');
    load(opsPath, 'ops');
    load(alignedOpsPath, 'alignedOps');
    load(trackedRoiPath, 'roiFinal', 'ishereFinal');
    
    [nSessions, nNeurons] = size(roiFinal);
    
    %% 2. Loop over each requested session
    for s = sessionsToPlot
        if s > nSessions || s < 1
            warning('Session %d is out of bounds (Total sessions: %d). Skipping.', s, nSessions);
            continue;
        end
        
        % Try to extract the mean image for the session from alignedOps
        % Depending on your suite2p pipeline version, it's usually inside alignedOps(s).ops or alignedOps{s}.ops 
        bgImg = alignedOps.suite2pImg(:,:,s);
           
        %% 3. Generate the plot
        figure('Name', sprintf('Session %d - ROI Tracking Alignment', s), ...
                     'NumberTitle', 'off');
        s1 = subplot(1,2,1);      
        % Display background image with standard mesoscopic contrast scaling [0.2, 0.8]
        % normalized if double, or adjusted via raw intensity limits
        if isa(bgImg, 'double') && max(bgImg(:)) <= 1
            imagesc(s1,bgImg, [0.2, 0.8]);
        else
            imagesc(s1,bgImg, [double(min(bgImg(:))) * 1.2, double(max(bgImg(:))) * 0.8]);
        end
        colormap(s1, gray);
        hold on;
        axis image; % Maintain pixel aspect ratio
        
        s2 = subplot(1,2,2); 

        centerDepthIdx = ceil(numel(ops.refStackSelLoc)/2);
        imagesc(s2, ops.offsetMap(:,:,s)-ops.refStackSelLoc(centerDepthIdx)); colormap(s2,redblue); clim([-10 10]); hold on;

        %% 4. Overlap the ROI Contours
        greenCount = 0;
        redCount = 0;
        
        for n = 1:nNeurons
            coords = roiFinal{s, n};
            
            % Failsafe for empty or invalid ROIs
            if isempty(coords) || any(isnan(coords(:)))
                continue;
            end
            
            % Determine color based on presence flag
            if ishereFinal(s, n) == 1
                edgeColor = [0, 1, 0]; % Bright Green
                lineWidth = 1.0;
                greenCount = greenCount + 1;
            else
                edgeColor = [0, 0, 0]; % Bright Red
                lineWidth = 0.6;       % Slightly thinner for absent neurons
                redCount = redCount + 1;
            end
            
            % Draw the boundary outline. 
            % Based on step5 configuration: X data goes to column 1, Y data to column 2.
            plot(s1, coords(:, 2), coords(:, 1), 'Color', edgeColor, 'LineWidth', lineWidth);
            plot(s2, coords(:, 2), coords(:, 1), 'Color', edgeColor, 'LineWidth', lineWidth);
        end
        
        title(sprintf('Session %d | Present (Green): %d | Absent (blak): %d', s, greenCount, redCount));
        xlabel(s1, 'X (pixels)'); ylabel(s1,'Y (pixels)');
        xlabel(s2, 'X (pixels)'); ylabel(s2,'Y (pixels)');
        hold off;
        
    end
    fprintf('Plotting complete.\n');
end
