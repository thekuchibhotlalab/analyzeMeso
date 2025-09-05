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
        stackROI.refStackSel = loadRefstacksel(ops.refStackReconPath)/65536; 

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
    nNeuron = length(stackROI.coordRaw);
    refStackSel = stackROI.refStackSel;
    nBatch = stackROI.nBatch;
    nDepth = stackROI.nDepth;
    

    screenSize = get(0, 'ScreenSize');
    figSize = [screenSize(3)*0.05, screenSize(4)*0.05, screenSize(3)*0.9, screenSize(4)*0.9];
    fig = figure('Position', figSize, 'MenuBar', 'none', 'Name', 'ROI Tracker', ...
                 'NumberTitle', 'off', 'Resize', 'off');
    % Parameters
    
    nNeuronPerPlot = 10; roiImgSize = 20;
    
    
    % Example initialization
    margin = 0.005 * min(figSize(3:4));  % Margin between images


    % Create grid for images
    rows = nDepth;
    cols = min([nNeuronPerPlot nNeuron - stackROI.nNeuronDone]);
    roiTemp = updateRoiTemp(nBatch,stackROI,refStackSel,roiImgSize);
    copiedRedrawnCoord = [];
    axHandles = createGrid(fig, rows, cols, roiTemp, margin);

    if cols<=0; return; end 
    % Add Next button
    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Next', ...
              'Position', [figSize(3)-100, 20, 80, 40], ...
              'Callback',  @(src, event) nextBatch(src, event));

    % Nested Functions

    function stackROI=initiateStackROI(ops)
        roiPath = [ops.refStackReconPath filesep 'cellprofilerROI'];
        roiHandPath = [ops.refStackReconPath filesep 'cellprofilerROI_handdrawn'];
        [roi] = fn_dirFilefun(roiPath, @readTiffMask, '*.tiff');
        [roiHand] = fn_dirFilefun(roiHandPath, @readTiffMask, '*.tiff');

        stackROI.coordRaw = [cellfun(@(x)(x{1}),roi,'UniformOutput',false); ...
            cellfun(@(x)(x{1}),roiHand,'UniformOutput',false) ];
        stackROI.centroidRaw = [cellfun(@(x)(x{2}),roi,'UniformOutput',false); ...
            cellfun(@(x)(x{2}),roiHand,'UniformOutput',false) ];

        stackROI.roiHandFlag = [zeros(length(roi),1); ones(length(roiHand),1)];
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


    function img = loadRefstacksel(folder_path)
        % Get a list of all files in the folder
        files = dir([folder_path filesep '*.tiff']);
        
        % Extract the filenames
        filenames = {files.name};
        
        % Filter filenames that contain 'refImg' but do not contain '_'
        filtered_filenames = filenames(contains(filenames, 'refImg') & ~contains(filenames, '_'));
        img = {};
        for k = 1:length(filtered_filenames)
            img{k} = double(imread([folder_path filesep filtered_filenames{k}]));
        end 
        img = fn_cell2mat(img,3);
    end 

    function axHandles = createGrid(fig, rows, cols, roiTemp, margin)
        global imgPlot roiPlot rectPlot;
        % Create a grid of axes in the figure
        figPos = get(fig, 'Position');
        width = (figPos(3) - margin * (cols + 1)) / cols;
        height = (figPos(4) - margin * (rows + 1)) / rows;
        axHandles = cell(rows, cols);
    
        imgPlot = {}; 
        roiPlot = {};
        rectPlot = {};
        for r = 1:rows
            for c = 1:cols
                xPos = margin + (c-1) * (width + margin);
                yPos = margin + (rows-r) * (height + margin);
                ax = axes(fig, 'Position', [xPos / figPos(3), yPos / figPos(4), ...
                                            width / figPos(3), height / figPos(4)]);
                axHandles{r, c} = ax;
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

    function roiTemp = updateRoiTemp(nBatch,stackROI,refStackSel,roiImgSize)
        roiTemp = struct();
        roiTemp.ishere = ones(rows, cols);          
        roiTemp.isRedrawn = zeros(rows, cols);

        roiTemp.coord = cell(rows,cols);
        roiTemp.coordRedrawn = cell(rows,cols);
        roiTemp.refImg = cell(rows,cols);
        tic;
        for c = 1:cols
            neuronCount = c + nBatch * nNeuronPerPlot;
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
        end
        toc;
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
        h = drawfreehand('Parent', gca, 'Color', 'blue');
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
        nBatch = nBatch + 1; 
        saveCurrentBatch();
        % Load new data for the next batch (example data here)
        cols = min([nNeuronPerPlot nNeuron - stackROI.nNeuronDone]);
        if cols<=0; return; end 
        roiTemp = updateRoiTemp(nBatch,stackROI,refStackSel,roiImgSize);
        tic;
        for r = 1:rows
            for c = 1:cols

                tempROIplot = roiPlot{r,c}; delete(tempROIplot);
                hold(axHandles{r, c}, 'off');
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

    function saveCurrentBatch()
        % Save the current batch data and export the GUI view as a PDF
        tempUpdateIdx = stackROI.nNeuronDone+1:stackROI.nNeuronDone + cols;
        stackROI.nNeuronDone = stackROI.nNeuronDone + cols; 
        stackROI.nBatch = nBatch; 
        

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

        figure; imagesc(refStackSel(:,:,4),[0.2, 0.8]); colormap('gray');hold on; 
        for i = 1:cols            
            fill(roiTemp.coordRedrawn{4,i}(:,2),roiTemp.coordRedrawn{4,i}(:,1),'black','FaceColor','none','EdgeColor','red');
        end 

        save([datapath filesep 'stackROI.mat'],'stackROI');
        %pdfPath = [ops.roiTrackingPath filesep 'roiCheck']; mkdir(pdfPath);
        %print(fig,[pdfPath filesep 'temp.pdf'], '-dpdf', '-bestfit', '-r300');  % Save as high-res PDF
        %append_pdfs([pdfPath filesep 'roiTracking_' ops.mouseArea '.pdf'], [pdfPath filesep 'temp.pdf']);
    end
end
