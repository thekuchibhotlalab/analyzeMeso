function sessionMatchingGUI()
    % REGISTRATIONTOOL - GUI for matching images to reference stacks.
    % This version loads data immediately upon file selection.
    % Ensure fn_fastAlign and fn_registerImg2Stack are in your MATLAB path.

    % Create the main figure window
    fig = uifigure('Name', 'Image Stack Registration Tool', 'Position', [100 100 550 250]);
    
    % Use a grid layout for clean alignment
    grid = uigridlayout(fig, [4, 2]);
    grid.RowHeight = {40, 40, 60, '1x'};
    grid.ColumnWidth = {150, '1x'};

    % State variables to store paths and loaded data
    appData = struct(...
        'stackPath', '', ...
        'matchPath', '', ...
        'refStack', [], ...
        'refStackMean', [], ...
        'matchImg', [], ...
        'matchImgMean', [] ...
    );

    % --- Row 1: Reference Stack Selection ---
    btnStack = uibutton(grid, 'Text', 'Load Ref Stack', ...
        'ButtonPushedFcn', @(btn,event) selectStack());
    txtStack = uieditfield(grid, 'text', 'Value', 'No file selected...', 'Editable', 'off');

    % --- Row 2: Match Image Selection ---
    btnMatch = uibutton(grid, 'Text', 'Load Match Image', ...
        'ButtonPushedFcn', @(btn,event) selectMatch());
    txtMatch = uieditfield(grid, 'text', 'Value', 'No file selected...', 'Editable', 'off');

    % --- Row 3: Run Button ---
    btnRun = uibutton(grid, 'Text', 'RUN MATCHING', ...
        'BackgroundColor', [0.8 1.0 0.8], 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(btn,event) runProcess());
    btnRun.Layout.Column = [1 2]; % Span both columns

    % --- Row 4: Status / Feedback ---
    lblStatus = uilabel(grid, 'Text', 'Status: Ready', 'VerticalAlignment', 'top');
    lblStatus.Layout.Column = [1 2];

    % --- Callback: Select and Load Reference Stack ---
    function selectStack()
        [file, path] = uigetfile('*.mat', 'Select Reference Stack File');
        if ischar(file)
            fullPath = fullfile(path, file);
            updateStatus(['Loading ' file '...']);
            drawnow;
            
            try
                % Load specific variables immediately
                vars = load(fullPath, 'refStack', 'refStackMean');
                
                % Store in appData
                appData.stackPath = fullPath;
                appData.refStack = vars.refStack;
                appData.refStackMean = vars.refStackMean;
                
                txtStack.Value = file;
                updateStatus(['Loaded Stack: ' file]);
            catch ME
                uialert(fig, ['Failed to load stack variables: ' ME.message], 'Load Error');
                updateStatus('Error loading stack.');
            end
        end
    end

    % --- Callback: Select and Load Match Image ---
    function selectMatch()
        [file, path] = uigetfile('*.mat', 'Select Image to Match');
        if ischar(file)
            fullPath = fullfile(path, file);
            updateStatus(['Loading ' file '...']);
            drawnow;
            
            try
                % Load specific variables immediately
                vars = load(fullPath, 'matchImg', 'matchImgMean');
                
                % Store in appData
                appData.matchPath = fullPath;
                appData.matchImg = vars.matchImg;
                appData.matchImgMean = vars.matchImgMean;
                
                txtMatch.Value = file;
                updateStatus(['Loaded Match Image: ' file]);
            catch ME
                uialert(fig, ['Failed to load match variables: ' ME.message], 'Load Error');
                updateStatus('Error loading match image.');
            end
        end
    end

    % --- Callback: Run the logic ---
    function runProcess()
        % Check if data is actually loaded in memory
        if isempty(appData.refStack) || isempty(appData.matchImg)
            uialert(fig, 'Please load both the Reference Stack and the Match Image first.', 'Data Missing');
            return;
        end

        % Disable button during processing
        btnRun.Enable = 'off';
        updateStatus('Processing... (Check Command Window for progress)');
        drawnow;

        try
            % Use pre-loaded variables from appData
            matchImg = appData.matchImg;
            tempRefStack = appData.refStack; % We'll modify this local copy
            
            % Setup output variables
            Pix = 100;
            offsetMap = cell(1, length(matchImg));
            offsetImg = cell(1, length(matchImg));
            offsetX = cell(1, length(matchImg));
            offsetY = cell(1, length(matchImg));
            tempMeanOffset = zeros(1, length(matchImg));

            % 2. Process Loop (Original Logic)
            for i = 1:length(matchImg)
                fprintf('Processing ROI %d/%d...\n', i, length(matchImg));
                
                for k = 1:size(tempRefStack{i}, 3)
                    tempMatch = imboxfilt(matchImg{i}, [3 3]);
                    tempStack = imboxfilt(tempRefStack{i}(:,:,k), [3 3]);
                    
                    % Note: fn_fastAlign and fn_registerImg2Stack must be in path
                    [tempAligned, ~] = fn_fastAlign(cat(3, tempMatch, tempStack), 'center');
                    tempRefStack{i}(:,:,k) = tempAligned(:,:,2);
                end 
                
                [offsetMap{i}, offsetImg{i}, offsetX{i}, offsetY{i}] = ...
                    fn_registerImg2Stack(tempRefStack{i}, tempMatch, Pix);
                
                tempMeanOffset(i) = nanmean(offsetMap{i}(:)) - 30;
                figure; imagesc(offsetMap{i}-30); colormap redblue; clim([-5 5]); 
                title(['ROI ' int2str(i) ', offset ' num2str(tempMeanOffset(i)) ' um deeper'])

            end 

            % 3. Save Output
            [filepath, tempname, ~] = fileparts(appData.matchPath); 
            filename_save = fullfile(filepath, [tempname '_offset.mat']);
            
            save(filename_save, 'offsetMap', 'offsetImg', 'offsetX', 'offsetY', 'tempMeanOffset');
            
            updateStatus(['Success! Saved: ' tempname '_offset.mat']);
            fprintf('Process complete. File saved to %s\n', filename_save);

        catch ME
            updateStatus('Error occurred during processing.');
            uialert(fig, ['An error occurred: ' ME.message], 'Processing Error');
            fprintf('Error: %s\n', ME.getReport());
        end

        btnRun.Enable = 'on';
    end

    function updateStatus(msg)
        lblStatus.Text = ['Status: ' msg];
    end
end