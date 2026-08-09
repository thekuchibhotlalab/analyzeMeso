function step5_manualTracking(datapath)
    % Initialize variables
    global stackROI ops; 
    load([datapath filesep 'ops.mat'],'ops');
    ops.refStackReconPath = [ops.roiTrackingPath filesep 'refStackReconstruct'];
    if exist([datapath filesep 'stackROI.mat'], 'file') == 2
        tempLoad = load([datapath filesep 'stackROI.mat']);
        stackROI = tempLoad.stackROI;
        disp('ROI mat file exist, loading ROI. Starting at roi number ')
    else
        stackROI = initiateStackROI(ops);
        stackROI.refStackSel = loadRefstacksel(ops.refStackReconPath,ops.refStackSelLoc)/65536; 

        stackROI.nDepth = size(stackROI.refStackSel,3); 
        nNeuron = length(stackROI.coordRaw);
        stackROI.coord = stackROI.coordRaw; % Original ROIs
        stackROI.centroid = stackROI.centroidRaw; % Original ROIs
        stackROI.nNeuronDone = 0; 
        stackROI.coordRedrawn = {}; stackROI.centroidRedrawn = {}; 
        for i = 1:stackROI.nDepth; stackROI.coordRedrawn(i,:) = stackROI.coordRaw; end    % Redrawn ROIs
        for i = 1:stackROI.nDepth; stackROI.centroidRedrawn(i,:) = stackROI.centroidRaw; end      % Redrawn ROIs
        stackROI.ishere = ones(stackROI.nDepth, nNeuron);
        stackROI.isRedrawn = ones(stackROI.nDepth, nNeuron);
        stackROI.nBatch = 0; 

        save([datapath filesep 'stackROI.mat'],'stackROI');
        disp('ROI mat file does not exist. Creating roi mat file.')
    end
    stackROI.refStackSel = loadRefstacksel(ops.refStackReconPath,ops.refStackSelLoc)/65536;
    stackROI = syncStackROIDepths(stackROI);
    nNeuron = length(stackROI.coordRaw);
    if ~isfield(stackROI,'nNeuronDone') || isempty(stackROI.nNeuronDone)
        stackROI.nNeuronDone = 0;
    end
    stackROI.nNeuronDone = min(max(stackROI.nNeuronDone,0),nNeuron);
    save([datapath filesep 'stackROI.mat'],'stackROI');
    refStackSel = stackROI.refStackSel;
    nDepth = stackROI.nDepth;
    

    screenSize = getLargestMonitorPosition();
    figSize = [screenSize(1)+screenSize(3)*0.05, screenSize(2)+screenSize(4)*0.05, ...
               screenSize(3)*0.9, screenSize(4)*0.9];
    fig = figure('Units','pixels','Position', figSize, 'MenuBar', 'none', 'Name', 'ROI Tracker', ...
                 'NumberTitle', 'off', 'Resize', 'off');
    % Parameters
    
    nNeuronPerPlot = max(10,2*nDepth); roiImgSize = 20;
    fprintf('Loaded %d reconstructed depth images. Displaying %d ROI columns per batch.\n', ...
        nDepth, nNeuronPerPlot);
    
    
    % Example initialization
    margin = 0.005 * min(figSize(3:4));  % Margin between images


    % Create grid for images
    rows = nDepth;
    cols = min([nNeuronPerPlot nNeuron - stackROI.nNeuronDone]);
    if cols<=0; return; end
    roiTemp = updateRoiTemp(stackROI,refStackSel,roiImgSize);
    copiedRedrawnCoord = [];
    axHandles = createGrid(fig, rows, nNeuronPerPlot, cols, roiTemp, margin);
    % Add Next button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Next', ...
              'Position', [figSize(3)-100, 20, 80, 40], ...
              'Callback',  @(src, event) nextBatch(src, event));

    % Nested Functions

    function stackROI=initiateStackROI(ops)
        roiPath = [ops.refStackReconPath filesep 'cellprofilerROI'];
        roiHandPath = [ops.refStackReconPath filesep 'cellprofilerROI_handdrawn'];
        roiImageJ = [ops.refStackReconPath filesep 'ROISetFinal.zip'];
        if exist(roiPath,'dir') == 7
            disp('CellProfiler ROI detected!')
            [roi] = fn_dirFilefun(roiPath, @readTiffMask, '*.tiff');
            [roiHand] = fn_dirFilefun(roiHandPath, @readTiffMask, '*.tiff');
    
            stackROI.coordRaw = [cellfun(@(x)(x{1}),roi,'UniformOutput',false); ...
                cellfun(@(x)(x{1}),roiHand,'UniformOutput',false) ];
            stackROI.centroidRaw = [cellfun(@(x)(x{2}),roi,'UniformOutput',false); ...
                cellfun(@(x)(x{2}),roiHand,'UniformOutput',false) ];
    
            stackROI.roiHandFlag = [zeros(length(roi),1); ones(length(roiHand),1)];
        elseif exist(roiImageJ,'file') == 2
            disp('ImageJ ROI detected!')
            % Read the ZIP file containing ImageJ ROIs
            % ReadImageJROI typically returns a cell array of structures
            rois = ReadImageJROI(roiImageJ); 
            
            % Preallocate cell arrays
            numROIs = length(rois);
            stackROI.coordRaw = cell(numROIs, 1);
            stackROI.centroidRaw = cell(numROIs, 1);
            
            for i = 1:numROIs
                % Handle cell array vs struct array output depending on the specific version of ReadImageJROI you are using
                if iscell(rois)
                    currROI = rois{i};
                else
                    currROI = rois(i);
                end                
                % Extract coordinates. ImageJ stores them as [X, Y] (Col, Row). The rest of your script expects [Row, Col] (Y, X), so we swap them.
                if isfield(currROI, 'mnCoordinates') && ~isempty(currROI.mnCoordinates)
                    tempCoords = currROI.mnCoordinates;
                    % Swap X and Y to [Row, Col]
                    stackROI.coordRaw{i} = [tempCoords(:, 2), tempCoords(:, 1)];
                end
                % Calculate the centroid using your existing nested function
                if ~any(isnan(stackROI.coordRaw{i}(:)))
                    stackROI.centroidRaw{i} = round(getCentroid(stackROI.coordRaw{i}));
                else
                    stackROI.centroidRaw{i} = [NaN, NaN];
                end
            end
            % Since ImageJ ROIs don't have separate folders for auto vs handdrawn in this script, we set the handFlag array to all ones
            stackROI.roiHandFlag = ones(numROIs, 1);  
        end 


        function [boundaries,centroid]= readTiffMask(filename)
            mask = imread(filename);
            boundaries = bwboundaries(mask);
            boundaries = boundaries{1};
            centroid = round(getCentroid(boundaries));
        end 
        function centroid = getCentroid(contourCoords)
            % Validate the input
            if size(contourCoords, 2) ~= 2
                error('Input must be an Nx2 matrix of [row, column] coordinates.');
            end
            
            % Extract row (y) and column (x) coordinates
            rows = contourCoords(:, 1); % y-coordinates
            cols = contourCoords(:, 2); % x-coordinates
        
            % Compute the centroid
            centroid = [mean(rows), mean(cols)];
        end

    end 


    function img = loadRefstacksel(folder_path,refStackSelLoc)
        % Get a list of all files in the folder
        if nargin >= 2 && ~isempty(refStackSelLoc)
            filtered_filenames = arrayfun(@(x)(['refImg' num2str(x,'%02d') '.tiff']), ...
                refStackSelLoc(:)','UniformOutput',false);
        else
            files = dir([folder_path filesep '*.tiff']);
            filenames = {files.name};
            filtered_filenames = filenames(contains(filenames, 'refImg') & ~contains(filenames, '_'));
        end
        img = {};
        for k = 1:length(filtered_filenames)
            imgFile = [folder_path filesep filtered_filenames{k}];
            if exist(imgFile,'file') ~= 2
                error('Could not find reconstructed reference image: %s',imgFile);
            end
            img{k} = double(imread(imgFile));
        end 
        img = fn_cell2mat(img,3);
    end 

    function stackROI = syncStackROIDepths(stackROI)
        nDepthNew = size(stackROI.refStackSel,3);
        nNeuronLocal = length(stackROI.coordRaw);
        if ~isfield(stackROI,'nDepth') || stackROI.nDepth ~= nDepthNew
            fprintf('Updating stackROI depth count from %d to %d reconstructed images.\n', ...
                getFieldOrDefault(stackROI,'nDepth',0), nDepthNew);
        end

        coordRedrawnNew = cell(nDepthNew,nNeuronLocal);
        centroidRedrawnNew = cell(nDepthNew,nNeuronLocal);
        ishereNew = ones(nDepthNew,nNeuronLocal);
        isRedrawnNew = ones(nDepthNew,nNeuronLocal);

        for r = 1:nDepthNew
            coordRedrawnNew(r,:) = stackROI.coordRaw;
            centroidRedrawnNew(r,:) = stackROI.centroidRaw;
        end

        if isfield(stackROI,'coordRedrawn') && ~isempty(stackROI.coordRedrawn)
            rowsToCopy = min(nDepthNew,size(stackROI.coordRedrawn,1));
            colsToCopy = min(nNeuronLocal,size(stackROI.coordRedrawn,2));
            coordRedrawnNew(1:rowsToCopy,1:colsToCopy) = stackROI.coordRedrawn(1:rowsToCopy,1:colsToCopy);
        end
        if isfield(stackROI,'centroidRedrawn') && ~isempty(stackROI.centroidRedrawn)
            rowsToCopy = min(nDepthNew,size(stackROI.centroidRedrawn,1));
            colsToCopy = min(nNeuronLocal,size(stackROI.centroidRedrawn,2));
            centroidRedrawnNew(1:rowsToCopy,1:colsToCopy) = stackROI.centroidRedrawn(1:rowsToCopy,1:colsToCopy);
        end
        if isfield(stackROI,'ishere') && ~isempty(stackROI.ishere)
            rowsToCopy = min(nDepthNew,size(stackROI.ishere,1));
            colsToCopy = min(nNeuronLocal,size(stackROI.ishere,2));
            ishereNew(1:rowsToCopy,1:colsToCopy) = stackROI.ishere(1:rowsToCopy,1:colsToCopy);
        end
        if isfield(stackROI,'isRedrawn') && ~isempty(stackROI.isRedrawn)
            rowsToCopy = min(nDepthNew,size(stackROI.isRedrawn,1));
            colsToCopy = min(nNeuronLocal,size(stackROI.isRedrawn,2));
            isRedrawnNew(1:rowsToCopy,1:colsToCopy) = stackROI.isRedrawn(1:rowsToCopy,1:colsToCopy);
        end

        stackROI.nDepth = nDepthNew;
        stackROI.coordRedrawn = coordRedrawnNew;
        stackROI.centroidRedrawn = centroidRedrawnNew;
        stackROI.ishere = ishereNew;
        stackROI.isRedrawn = isRedrawnNew;
    end

    function value = getFieldOrDefault(s,fieldName,defaultValue)
        if isfield(s,fieldName)
            value = s.(fieldName);
        else
            value = defaultValue;
        end
    end

    function screenSize = getLargestMonitorPosition()
        try
            monitorPositions = get(0,'MonitorPositions');
        catch
            monitorPositions = get(0,'ScreenSize');
        end
        if isempty(monitorPositions) || size(monitorPositions,2) ~= 4
            monitorPositions = get(0,'ScreenSize');
        end
        [~,largestMonitorIdx] = max(monitorPositions(:,3).*monitorPositions(:,4));
        screenSize = monitorPositions(largestMonitorIdx,:);
        fprintf('ROI Tracker GUI using monitor %d of %d: [%d %d %d %d]\n', ...
            largestMonitorIdx,size(monitorPositions,1),screenSize);
    end

    function axHandles = createGrid(fig, rows, plotCols, activeCols, roiTemp, margin)
        global imgPlot roiPlot rectPlot;
        % Create a grid of axes in the figure
        figPos = get(fig, 'Position');
        width = (figPos(3) - margin * (plotCols + 1)) / plotCols;
        height = (figPos(4) - margin * (rows + 1)) / rows;
        axHandles = cell(rows, plotCols);
    
        imgPlot = {}; 
        roiPlot = {};
        rectPlot = {};

        for r = 1:rows
            for c = 1:plotCols
                xPos = margin + (c-1) * (width + margin);
                yPos = margin + (rows-r) * (height + margin);
                ax = axes(fig, 'Position', [xPos / figPos(3), yPos / figPos(4), ...
                                            width / figPos(3), height / figPos(4)]);
                axHandles{r, c} = ax;
                if c > activeCols
                    axis(ax,'off');
                    set(ax,'Visible','off');
                    continue;
                end
                imgPlot{r,c} = imagesc(ax, roiTemp.refImg{r, c}, [0.2, 0.8]);

                colormap(ax, gray);
                hold(ax, 'on');
                % Plot ROI, NOTE THAT IN FILL PLOT, X AND Y ARE REVERSED
                roiPlot{r,c} = fill(roiTemp.coord{r, c}(:,2), roiTemp.coord{r, c}( :,1),[0 0 0],'FaceColor', 'none', ...
                     'EdgeColor', 'red','LineWidth',0.8, 'Parent', ax);
                % Add green/red rectangle for ishere
                if roiTemp.ishere(r, c)==1
                    rectPlot{r,c} = rectangle('Position', [1, 1, size(roiTemp.refImg{r, c}, 2), size(roiTemp.refImg{r, c}, 1)], ...
                              'EdgeColor', 'green', 'LineWidth', 2, 'Parent', ax);
                elseif roiTemp.ishere(r, c)==0
                    rectPlot{r,c} = rectangle('Position', [1, 1, size(roiTemp.refImg{r, c}, 2), size(roiTemp.refImg{r, c}, 1)], ...
                              'EdgeColor', 'red', 'LineWidth', 2, 'Parent', ax);
                else
                    disp('Check ishere flag -- exist neither 1 or 0 index')
                end 
                axis off;
                % add interactive function
                set(imgPlot{r,c}, 'ButtonDownFcn', @(src, event)onImageClick(src, event, r, c));
                
            end
        end
    end 

    function roiTemp = updateRoiTemp(stackROI,refStackSel,roiImgSize)
        roiTemp = struct();
        roiTemp.ishere = ones(rows, cols);          
        roiTemp.isRedrawn = zeros(rows, cols);
        roiTemp.corr = nan(rows, cols);

        roiTemp.coord = cell(rows,cols);
        roiTemp.coordRedrawn = cell(rows,cols);
        roiTemp.refImg = cell(rows,cols);
        tic;
        for c = 1:cols
            neuronCount = stackROI.nNeuronDone + c;
            for r = 1:rows
                tempShiftX = (stackROI.centroidRaw{neuronCount}(1)); 
                tempShiftY = (stackROI.centroidRaw{neuronCount}(2)); 
                tempROISizeX = min([size(refStackSel,1)-round(tempShiftX)  round(tempShiftX)-1 roiImgSize]);
                tempROISizeY = min([size(refStackSel,2)-round(tempShiftY)  round(tempShiftY)-1 roiImgSize]);
                tempROISize = min([tempROISizeX,tempROISizeY]);

                selX = round(tempShiftX) - tempROISize : round(tempShiftX) + tempROISize;
                selY = round(tempShiftY) - tempROISize : round(tempShiftY) + tempROISize;
                
                roiTemp.coord{r,c} = stackROI.coordRaw{neuronCount};
                roiTemp.coord{r,c}(:,1) = roiTemp.coord{r,c}(:,1) - tempShiftX + tempROISize+1;
                roiTemp.coord{r,c}(:,2) = roiTemp.coord{r,c}(:,2) - tempShiftY + tempROISize+1;
                roiTemp.imgShiftX(r,c) = round(tempShiftX)-tempROISize-1; roiTemp.imgShiftY(r,c) = round(tempShiftY)-tempROISize-1;

                roiTemp.coordRedrawn{r,c} = roiTemp.coord{r,c};

                % Adjust for out-of-bounds indices and pad with NaNs
                patchSize = 2 * tempROISize + 1;
                patch = nan(patchSize, patchSize); % Initialize patch with NaNs
                
                % Valid indices within bounds
                validX = selX(selX > 0 & selX <= size(refStackSel, 1));
                validY = selY(selY > 0 & selY <= size(refStackSel, 2));
                
                % Corresponding indices in the patch
                patchX = find(selX > 0 & selX <= size(refStackSel, 1));
                patchY = find(selY > 0 & selY <= size(refStackSel, 2));
                
                % Insert valid data into the patch
                patch(patchX, patchY) = refStackSel(validX, validY, r);
                
                % Assign the patch to the structure
                roiTemp.refImg{r, c} = patch;

                allsum = nansum(patch(:));
                if isnan(allsum) || allsum==0; roiTemp.ishere(r,c) = 0;end 

                %roiTemp.refImg{r, c} = refStackSel(selX,selY,r);  % Replace with actual image data
            end
            tempPatch = roiTemp.refImg(:, c);
            refDepthIdx = round((rows+1)/2);
            tempPatchRef = tempPatch{refDepthIdx};
            corrMask = getRoiCorrelationMask(roiTemp.coord{refDepthIdx,c},size(tempPatchRef));
            for r = 1:rows
                tempCorr = maskedPearsonCorr(tempPatch{r},tempPatchRef,corrMask);
                roiTemp.corr(r,c) = tempCorr;
                roiTemp.ishere(r,c) = tempCorr>0.85; 
            end 

        end
        toc;
    end 

    function mask = getRoiCorrelationMask(coords,imgSize)
        mask = false(imgSize(1),imgSize(2));
        if isempty(coords) || any(isnan(coords(:)))
            return;
        end
        row = coords(:,1);
        col = coords(:,2);
        validCoord = row >= 1 & row <= imgSize(1) & col >= 1 & col <= imgSize(2);
        if sum(validCoord) < 3
            return;
        end
        mask = poly2mask(col(validCoord),row(validCoord),imgSize(1),imgSize(2));
        mask = conv2(double(mask),ones(5),'same') > 0;
    end

    function r = maskedPearsonCorr(img,refImg,mask)
        validPix = mask & isfinite(img) & isfinite(refImg) & img ~= 0 & refImg ~= 0;
        if sum(validPix(:)) < 5
            r = -Inf;
            return;
        end
        r = corr(img(validPix),refImg(validPix));
        if isnan(r)
            r = -Inf;
        end
    end 

    function onImageClick(~, ~,row, col)
        %persistent clickTimer
        clickType = get(gcf, 'SelectionType');
        persistent chk
        if isempty(chk)
              chk = 1;
              pause(0.2); %Add a delay to distinguish single click from a double click
              if chk == 1 & strcmp(clickType, 'normal')
                  chk = [];
                  fprintf('Single left-click detected: GUI location %d, %d\n', row, col);
                  roiTemp.ishere(row, col) = 1 - roiTemp.ishere(row, col);
                  updateDisplay(row, col);
              elseif chk == 1 & strcmp(clickType, 'alt')
                  fprintf('Single right-click detected: GUI location %d, %d\n', row, col);
                  pasteROI(row, col)
                  chk = [];
              end
        else
              chk = [];
              fprintf('Double left-click detected: GUI location %d, %d\n', row, col);
              redrawROI(row, col)
        end 
    end

    function updateDisplay(row, col)
        global rectPlot;
        % Update ROI contour and square color
        if roiTemp.ishere(row, col) == 0
            set(rectPlot{row,col},'EdgeColor','red');
        elseif roiTemp.isRedrawn(row, col) == 1
            set(rectPlot{row,col},'EdgeColor','blue');
        elseif roiTemp.ishere(row, col) == 1
            set(rectPlot{row,col},'EdgeColor','green');
        end
    end

    function redrawROI(row, col)
        global roiPlot;
        % Open new figure for ROI redraw
        redrawFig = figure('Name', sprintf('Redraw Panel: Cell (%d, %d)', row, col), ...
                           'NumberTitle', 'off');
        imagesc(roiTemp.refImg{row, col}, [0.2, 0.8]);
        colormap(gray);
        hold on;
        % Show existing ROI with lighter contour
        fill(roiTemp.coordRedrawn{row, col}(:,2), roiTemp.coordRedrawn{row, col}(:,1),matlabColors(1),'FaceColor', 'none', ...
             'EdgeColor', 'red', 'LineWidth', 2);
        h = drawfreehand('Parent', gca, 'Color', 'blue','Smoothing', 1, ...
            'Multiclick', false, ...
            'InteractionsAllowed', 'none');
        %wait(h);
        roiTemp.coordRedrawn{row, col} = h.Position(:,[2 1]);  % Update the redrawn ROI, first position is x (i.e. 900), second position is y (450)
        roiTemp.isRedrawn(row, col) = 1;            % Mark as redrawn
        copiedRedrawnCoord = roiTemp.coordRedrawn{row, col};
        close(redrawFig);
        tempROIplot = roiPlot{row,col};
        % Delete the fill object
        if isvalid(tempROIplot) % Check if the fill object is still valid
            delete(tempROIplot);
        end
        roiPlot{row,col} = fill(roiTemp.coordRedrawn{row, col}(:,2), roiTemp.coordRedrawn{row, col}(:,1),[0 0 0],'FaceColor', 'none', ...
             'EdgeColor', 'red','LineWidth',0.8, 'Parent', axHandles{row, col});
        updateDisplay( row, col);

    end

    function pasteROI(row, col)
        global roiPlot;
        % Apply the redrawn ROI to all images in the same column
        roiTemp.coordRedrawn{row, col} = copiedRedrawnCoord;
        roiTemp.isRedrawn(row, col) = 1;
        tempROIplot = roiPlot{row,col};
        % Delete the fill object
        if isvalid(tempROIplot) % Check if the fill object is still valid
            delete(tempROIplot);
        end
        roiPlot{row,col} = fill(roiTemp.coordRedrawn{row, col}(:,2), roiTemp.coordRedrawn{row, col}(:,1),[0 0 0],'FaceColor', 'none', ...
             'EdgeColor', 'red','LineWidth',0.8, 'Parent', axHandles{row, col});
        updateDisplay( row, col);
    end

    function nextBatch(~,~)
        global roiPlot imgPlot rectPlot;
        % Save current batch data and export to PDF
       
        % Clear and load the next batch
        saveCurrentBatch();
        % Load new data for the next batch (example data here)
        cols = min([nNeuronPerPlot nNeuron - stackROI.nNeuronDone]);
        if cols<=0; return; end 
        roiTemp = updateRoiTemp(stackROI,refStackSel,roiImgSize);
        tic;
        for r = 1:rows
            for c = 1:nNeuronPerPlot
                clearGridSlot(r,c);
                if c > cols
                    continue;
                end
                set(axHandles{r, c}, 'Visible', 'on');
                imgPlot{r,c} = imagesc(axHandles{r, c}, roiTemp.refImg{r, c}, [0.2, 0.8]);
    
                colormap(axHandles{r, c}, gray);
                hold(axHandles{r, c}, 'on');
                % Plot ROI
                roiPlot{r,c} = fill(roiTemp.coord{r, c}(:,2), roiTemp.coord{r, c}(:,1),[0 0 0],'FaceColor', 'none', ...
                     'EdgeColor', 'red','LineWidth',0.8, 'Parent', axHandles{r, c});
                
                % Add green/red rectangle for ishere
                if roiTemp.ishere(r,c)==1
                    rectPlot{r,c} = rectangle('Position', [1, 1, size(roiTemp.refImg{r, c}, 2), size(roiTemp.refImg{r, c}, 1)], ...
                              'EdgeColor', 'green', 'LineWidth', 2, 'Parent', axHandles{r, c});
                elseif roiTemp.ishere(r,c)==0
                     rectPlot{r,c} = rectangle('Position', [1, 1, size(roiTemp.refImg{r, c}, 2), size(roiTemp.refImg{r, c}, 1)], ...
                              'EdgeColor', 'red', 'LineWidth', 2, 'Parent', axHandles{r, c});
                else
                    disp('Check ishere flag -- exist neither 1 or 0 index');
                end
                axis(axHandles{r, c}, 'off'); 
                % add interactive function
                set(imgPlot{r,c}, 'ButtonDownFcn', @(src, event)onImageClick(src, event, r, c));
            end
        end
        toc;
    end

    function clearGridSlot(row,col)
        global roiPlot imgPlot rectPlot;
        ax = axHandles{row,col};
        cla(ax,'reset');
        axis(ax,'off');
        set(ax,'Visible','off');
        imgPlot{row,col} = [];
        roiPlot{row,col} = [];
        rectPlot{row,col} = [];
    end

    function saveCurrentBatch()
        % Save the current batch data and export the GUI view as a PDF
        tempUpdateIdx = stackROI.nNeuronDone+1:stackROI.nNeuronDone + cols;
        stackROI.nNeuronDone = stackROI.nNeuronDone + cols; 
        stackROI.nBatch = ceil(stackROI.nNeuronDone / nNeuronPerPlot); 
        

        for i = 1:size(roiTemp.coordRedrawn,1)
            for j =1:size(roiTemp.coordRedrawn,2)
                roiTemp.coordRedrawn{i,j}(:,1) = roiTemp.coordRedrawn{i,j}(:,1) + roiTemp.imgShiftX(i,j);
                roiTemp.coordRedrawn{i,j}(:,2) = roiTemp.coordRedrawn{i,j}(:,2) + roiTemp.imgShiftY(i,j);

            end
        end 
       
        stackROI.coordRedrawn(:,tempUpdateIdx) = roiTemp.coordRedrawn;     % Redrawn ROIs
        stackROI.ishere(:,tempUpdateIdx) = roiTemp.ishere;
        stackROI.isRedrawn(:,tempUpdateIdx) = roiTemp.isRedrawn;
        %figure; imagesc(refStackSel(:,:,2),[0.2, 0.8]); colormap('gray');hold on; fill(stackROI.coord{17}(:,1),stackROI.coord{17}(:,2),'black','FaceColor','none','EdgeColor','red');

        centerDepthIdx = ceil(nDepth/2);
        figure; imagesc(refStackSel(:,:,centerDepthIdx),[0.2, 0.8]); colormap('gray');hold on; 
        for i = 1:cols            
            fill(roiTemp.coordRedrawn{centerDepthIdx,i}(:,2),roiTemp.coordRedrawn{centerDepthIdx,i}(:,1),'black','FaceColor','none','EdgeColor','red');
        end 

        save([datapath filesep 'stackROI.mat'],'stackROI');
        %pdfPath = [ops.roiTrackingPath filesep 'roiCheck']; mkdir(pdfPath);
        %print(fig,[pdfPath filesep 'temp.pdf'], '-dpdf', '-bestfit', '-r300');  % Save as high-res PDF
        %append_pdfs([pdfPath filesep 'roiTracking_' ops.mouseArea '.pdf'], [pdfPath filesep 'temp.pdf']);
    end
end
