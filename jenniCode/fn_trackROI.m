function fn_trackROI()
    f = figure('Name','Track ROIs Over Stack','NumberTitle','off','Position',[100 100 900 700]);
    ax = axes('Units','pixels','Position',[100 100 700 500]);
    title(ax, 'Load an image stack to begin.', 'FontSize', 12, 'Color', 'b');
    colormap gray;

    imgStack = [];
    nImgs = 0;
    currentImg = 1;
    currentROI = 1;
    roi_results = {};  % {img}{roi}
    rois = {};         % handles for current ROI drawing
    ishere = [];       % logical matrix: ROI presence (nImgs x nROIs)
    isredrawn = [];
    corrMap = [];      % stores correlation map of the stack, if exists
    prelabelThre = 0.6;

    uicontrol('Style','pushbutton','String','<','Position',[30 330 40 40], 'FontSize',12,...
              'Callback',@prevImg);
    uicontrol('Style','pushbutton','String','>','Position',[830 330 40 40], 'FontSize',12,...
              'Callback',@nextImg);
    uicontrol('Style','pushbutton','String','Load Images','Position',[100 30 100 30],...
              'Callback',@loadImages);
    uicontrol('Style','pushbutton','String','Load ROI','Position',[220 30 100 30],...
              'Callback',@loadROI);
    uicontrol('Style','pushbutton','String','Redraw','Position',[340 30 100 30],...
              'Callback',@redraw);
    uicontrol('Style','pushbutton','String','Next ROI','Position',[460 30 100 30],...
              'Callback',@nextROI);
    uicontrol('Style','pushbutton','String','Reject','Position',[580 30 100 30],...
              'Callback',@rejectROI);
    uicontrol('Style','pushbutton','String','Save','Position',[700 30 100 30],...
              'Callback',@saveProgress);

    function loadImages(~,~)
        [file, path] = uigetfile({'*.mat;*.tif','Image Stack (*.mat, *.tif)'}, 'Select Image Stack');
        if isequal(file, 0), return; end
        [~,~,ext] = fileparts(file);
        if strcmp(ext, '.mat')
            s = load(fullfile(path, file));
            imgStack = s.imgStack;
            if isfield(s,'corrMap') 
                corrMap = s.corrMap; 
            else
                corrMap = []; disp('No Image Correlation detected');
            end 
        else
            info = imfinfo(fullfile(path, file));
            nImgs = numel(info);
            imgStack = zeros(info(1).Height, info(1).Width, nImgs);
            for i = 1:nImgs
                imgStack(:,:,i) = imread(fullfile(path, file), i);
            end
        end
        nImgs = size(imgStack, 3);
        currentImg = 1;
        currentROI = 1;
        updateDisplay();
    end

    function loadROI(~,~)
        [file, path] = uigetfile('*.mat', 'Select ROI File');
        if isequal(file, 0), return; end
        s = load(fullfile(path, file));
        if isfield(s, 'roi_results')
            r = s.roi_results;
            if isempty(imgStack)
                warndlg('Please load the image stack before loading ROIs.');
                return;
            end
            if isvector(r) || size(r,1) == 1
                roi_results = repmat(r, nImgs, 1);
            else
                roi_results = r;
            end
            [nr, nc] = size(roi_results);
            if ~isfield(s, 'ishere')
                disp('Initializing ishere tracking matrix')
                if ~isempty(corrMap)
                    disp('corrMap found; doing pre-labelling')
                    ishere = createPrelabel(corrMap,roi_results,prelabelThre);
                else
                    ishere = ones(nr, nc);
                end 
                isredrawn = zeros(nr, nc);
            else
                ishere = s.ishere;
                isredrawn = s.isredrawn;
            end
            if isfield(s, 'currentROI')
                currentROI = s.currentROI;
            else
                currentROI = 1;
            end
            updateDisplay();
        else
            warndlg('Selected file does not contain "roi_results".');
        end
    end

    function redraw(~,~)
        clearROIs();
        title(ax, sprintf('Redraw ROI #%d on Image %d', currentROI, currentImg), 'FontSize', 12, 'Color', 'b');
        h = drawfreehand('Color','r');
        if isempty(h.Position)
            delete(h);
            return;
        end
        mask = createMask(h);
        [B, ~] = bwboundaries(mask, 'noholes');
        contour = B{1};
        deleteExistingOverlay();
        plot(ax, contour(:,2), contour(:,1), 'g', 'LineWidth', 2);
        rois{1} = h;
        roi_results{currentImg, currentROI}.Mask =  mask;
        roi_results{currentImg, currentROI}.Contour =  contour;
        ishere(currentImg, currentROI) = 1;
        isredrawn(currentImg, currentROI) = 1;
        title(ax, sprintf('Saved ROI #%d for Image %d', currentROI, currentImg), 'FontSize', 12);
    end

    function rejectROI(~,~)
        if ishere(currentImg, currentROI) == 1
            ishere(currentImg, currentROI) = 0;
        elseif ishere(currentImg, currentROI) == 0
            ishere(currentImg, currentROI) = 1;
        end 
        updateDisplay();
    end

    function saveProgress(~,~)
        [file, path] = uiputfile('roi_progress.mat', 'Save Tracking Progress');
        if isequal(file, 0), return; end
        roi_results = roi_results; %#ok<NASGU>
        ishere = ishere; %#ok<NASGU>
        currentROI = currentROI; %#ok<NASGU>
        save(fullfile(path, file), 'roi_results', 'ishere', 'currentROI','isredrawn');
        msgbox('Progress saved.');
    end

    function nextROI(~,~)
        currentROI = currentROI + 1;
        updateDisplay();
    end

    function prevImg(~,~)
        if currentImg > 1
            currentImg = currentImg - 1;
            updateDisplay();
        end
    end

    function nextImg(~,~)
        if currentImg < nImgs
            currentImg = currentImg + 1;
            updateDisplay();
        end
    end

    function updateDisplay()
        cla(ax);
        if isempty(imgStack), return; end
        imagesc(ax, imgStack(:,:,currentImg));
        clim(ax, [prctile(imgStack(:), 0.5), prctile(imgStack(:), 99.5)]);
        colormap(ax, gray);
        hold(ax, 'on');
        set(ax, 'FontSize', 8);
        title(ax, sprintf('Image %d / %d - ROI #%d', currentImg, nImgs, currentROI), 'FontSize', 12);
        clearROIs();
        if ~isempty(roi_results) && currentImg <= size(roi_results,1) && currentROI <= size(roi_results,2)
            r = roi_results{currentImg, currentROI};
            if ~isempty(r)
                color = 'g';
                if ~isempty(ishere) && ishere(currentImg, currentROI) == 0
                    color = 'r';
                end
                plot(ax, r.Contour(:,2), r.Contour(:,1), color, 'LineWidth', 2);
                h = drawfreehand('Position', r.Contour, 'Color', color);
                set(h, 'Visible', 'off');
                rois{1} = h;
            end
        end
    end

    function deleteExistingOverlay()
        ch = get(ax, 'Children');
        for i = 1:length(ch)
            if strcmp(ch(i).Type, 'line') && (strcmp(ch(i).Color, [0 1 0]) || strcmp(ch(i).Color, [1 0 0]))
                delete(ch(i));
            end
        end
    end

    function clearROIs()
        if ~isempty(rois)
            for i = 1:length(rois)
                if isvalid(rois{i})
                    delete(rois{i});
                end
            end
        end
        rois = {};
    end

    function ishere = createPrelabel(corrMap,roi_results,prelabelThre)
        [nImg, nroi] = size(roi_results);
        ishere = zeros(nImg,nroi);
        for i = 1:nroi
            for j = 1:nImg
                tempCent = round(roi_results{j,i}.Centroid);
                tempCorr = corrMap(tempCent(1),tempCent(2),j);
                ishere(j,i) = tempCorr >= prelabelThre;
            end
        end 

    end 

end
