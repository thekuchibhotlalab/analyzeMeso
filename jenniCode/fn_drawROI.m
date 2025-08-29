function fn_drawROI(img)
    f = figure('Name','Multi-ROI Tool','NumberTitle','off','Position',[100 100 800 600]);
    imagesc(img); clim([prctile(img(:),0.5) prctile(img(:),99.5)]); hold on;
    colormap gray;
    set(gca, 'FontSize', 8); % Reduce tick label font size

    rois = {};  
    results = {};  

    % Buttons
    uicontrol('Style','pushbutton','String','Add ROI','Position',[20 20 80 30],...
              'Callback',@drawNewROI);
    uicontrol('Style','pushbutton','String','Remove ROI','Position',[120 20 80 30],...
              'Callback',@startRemovingROI);
    uicontrol('Style','pushbutton','String','Finish','Position',[220 20 80 30],...
              'Callback',@finishAndSave);
    uicontrol('Style','pushbutton','String','Save','Position',[320 20 80 30],...
              'Callback',@saveToFile);
    uicontrol('Style','pushbutton','String','Load','Position',[420 20 80 30],...
              'Callback',@loadFromFile);
    uicontrol('Style','pushbutton','String','Launch Tracker','Position',[520 20 100 30],...
              'Callback',@launchTracker);

    function drawNewROI(~, ~)
        title('Draw ROI with cursor', 'FontSize', 12, 'Color', 'b');
        drawnow;
        h = drawfreehand('Color', 'r');
        title('');
        if isempty(h.Position)
            delete(h);
            return;
        end
        mask = createMask(h);
        stats = regionprops(mask, 'Centroid');
        centroid = stats.Centroid;
        [B, ~] = bwboundaries(mask, 'noholes');
        contour = B{1};

        plot(contour(:,2), contour(:,1), 'g', 'LineWidth', 2);
        plot(centroid(1), centroid(2), 'bo', 'MarkerSize', 10, 'LineWidth', 2);

        rois{end+1} = h;
        results{end+1} = struct('Mask', mask, 'Contour', contour, 'Centroid', centroid);
    end

    function startRemovingROI(~, ~)
        title('Click on an ROI to remove it');
        [x, y] = ginput(1);
        minDist = inf; idx = -1;
        for i = 1:length(results)
            c = results{i}.Centroid;
            dist = norm([x - c(1), y - c(2)]);
            if dist < minDist
                minDist = dist;
                idx = i;
            end
        end
        if idx > 0 && minDist < 20
            delete(rois{idx});
            rois(idx) = [];
            results(idx) = [];
            redrawAll();
        end
        title('');
    end

    function redrawAll()
        cla;
        imagesc(img); clim([prctile(img(:),0.5) prctile(img(:),99.5)]); hold on;
        colormap gray;
        for i = 1:length(results)
            plot(results{i}.Contour(:,2), results{i}.Contour(:,1), 'g', 'LineWidth', 2);
            plot(results{i}.Centroid(1), results{i}.Centroid(2), 'bo', 'MarkerSize', 10, 'LineWidth', 2);
        end
    end

    function finishAndSave(~, ~)
        assignin('base','roi_results',results);
        disp('ROI data saved to variable "roi_results" in the base workspace.');
        close(gcf);
    end

    function saveToFile(~, ~)
        [file, path] = uiputfile('roi_results.mat', 'Save ROI Results');
        if isequal(file, 0)
            return;
        end
        fullFile = fullfile(path, file);
        if exist(fullFile, 'file')
            answer = questdlg('File already exists. Overwrite?', ...
                              'Confirm Overwrite', 'Yes', 'No', 'No');
            if ~strcmp(answer, 'Yes')
                return;
            end
        end
        roi_results = results; %#ok<NASGU>
        save(fullFile, 'roi_results');
        disp(['Saved to ', fullFile]);
    end

    function loadFromFile(~, ~)
        [file, path] = uigetfile('*.mat', 'Select ROI File');
        if isequal(file, 0)
            return;
        end
        s = load(fullfile(path, file));
        if isfield(s, 'roi_results')
            results = s.roi_results;
        elseif isfield(s, 'roi')
            results = s.roi;
        else
            warndlg('File does not contain "roi_results" or "roi" variable.');
            return;
        end

        for i = 1:length(rois)
            delete(rois{i});
        end
        rois = {};
        redrawAll();

        for i = 1:length(results)
            h = drawfreehand('Position', results{i}.Contour, 'Color', 'r');
            set(h, 'Visible', 'off');
            rois{end+1} = h;
        end
        disp('ROIs loaded and displayed.');
    end

    function launchTracker(~, ~)
        %[file, path] = uiputfile('roi_results.mat', 'Save ROI and Launch Tracker');
        %if isequal(file, 0), return; end
        %roi_results = results; %#ok<NASGU>
        %save(fullfile(path, file), 'roi_results');
        %uiwait(msgbox('Select the image stack to track ROIs.', 'Next Step'));
        fn_trackROI();
    end
end
