%% labelLowSNR
% Manually label low-SNR regions in a 3-D mean image stack.
%
% Expected input:
%   meanImg: Y x X x nSession matrix already loaded in the workspace.
%
% Output:
%   lowSNRFlag: Y x X x nSession logical matrix.
%       1 means low SNR / bad region.
%
% Edit the section below, then run this script.

%% User settings
% If meanImg is already loaded in the workspace, leave meanImgFile empty.
% Otherwise, set this to a .mat file containing meanImgVarName.
meanImgFile = '';
meanImgVarName = 'meanImg';

% Each cell is [firstSession lastSession].
% Example:
% sessionGroups = {[1 10],[11 40],[41 100]};
sessionGroups = {[1 52],[53 140],[141 166]};

% The image shown for each group is the average of that session range.
% Options: 'mean', 'median', or 'first'
displayMode = 'mean';

% Output file. If empty, save next to meanImgFile when meanImgFile is set;
% otherwise save in the current folder.
saveFile = '';

%% Load mean image stack if needed
if ~exist('meanImg','var')
    if isempty(meanImgFile)
        error('meanImg is not in the workspace. Load it first, or set meanImgFile in this script.');
    end

    loadedData = load(meanImgFile,meanImgVarName);
    if ~isfield(loadedData,meanImgVarName)
        error('Could not find variable "%s" in %s.',meanImgVarName,meanImgFile);
    end
    meanImg = loadedData.(meanImgVarName);
end

if ndims(meanImg) ~= 3
    error('meanImg should be a 3-D matrix: Y x X x nSession.');
end

[imgHeight,imgWidth,nSession] = size(meanImg);
lowSNRFlag = false(imgHeight,imgWidth,nSession);

if isempty(saveFile)
    if ~isempty(meanImgFile)
        [savePath,saveName] = fileparts(meanImgFile);
        saveFile = fullfile(savePath,[saveName '_lowSNRFlag.mat']);
    else
        saveFile = fullfile(pwd,'lowSNRFlag.mat');
    end
end

fprintf('meanImg size: %d x %d x %d sessions\n',imgHeight,imgWidth,nSession);
fprintf('Saving lowSNRFlag to:\n%s\n',saveFile);

%% Draw one or more low-SNR masks for each session group
for groupIdx = 1:numel(sessionGroups)
    groupRange = sessionGroups{groupIdx};
    if numel(groupRange) ~= 2
        error('sessionGroups{%d} should be [firstSession lastSession].',groupIdx);
    end

    firstSession = max(1,round(groupRange(1)));
    lastSession = min(nSession,round(groupRange(2)));
    if lastSession < firstSession
        warning('Skipping group %d because the range is invalid after clipping: [%d %d].', ...
            groupIdx,firstSession,lastSession);
        continue
    end

    sessionIdx = firstSession:lastSession;
    displayImg = getDisplayImage(meanImg,sessionIdx,displayMode);

    figure('Name',sprintf('Low SNR group %d: sessions %d-%d', ...
        groupIdx,firstSession,lastSession),'Color','w');
    imagesc(displayImg);
    axis image off
    colormap gray
    colorbar
    title(sprintf('Draw low-SNR region(s): group %d, sessions %d-%d', ...
        groupIdx,firstSession,lastSession));

    groupMask = false(imgHeight,imgWidth);
    keepDrawing = true;
    drawCount = 0;

    while keepDrawing
        drawCount = drawCount + 1;
        fprintf('Group %d, sessions %d-%d: draw low-SNR region %d, then double-click/finish the ROI.\n', ...
            groupIdx,firstSession,lastSession,drawCount);

        roi = drawfreehand(gca,'Color','r','LineWidth',1.5);
        if isempty(roi) || ~isvalid(roi)
            keepDrawing = false;
            continue
        end

        tempMask = createMask(roi);
        groupMask = groupMask | tempMask;

        hold on
        contour(groupMask,[0.5 0.5],'r','LineWidth',1);

        choice = questdlg('Add another low-SNR region for this session group?', ...
            'Continue drawing?', ...
            'Yes','No','No');
        keepDrawing = strcmp(choice,'Yes');
    end

    lowSNRFlag(:,:,sessionIdx) = repmat(groupMask,1,1,numel(sessionIdx));
    fprintf('Group %d done: labelled %d pixels for sessions %d-%d.\n', ...
        groupIdx,nnz(groupMask),firstSession,lastSession);
end

%% Save result
save(saveFile,'lowSNRFlag','sessionGroups','displayMode','meanImgVarName','-v7.3');
fprintf('Saved lowSNRFlag: %d x %d x %d\n',size(lowSNRFlag,1),size(lowSNRFlag,2),size(lowSNRFlag,3));

%% Local helper
function displayImg = getDisplayImage(meanImg,sessionIdx,displayMode)
switch lower(displayMode)
    case 'mean'
        displayImg = nanmean(meanImg(:,:,sessionIdx),3);
    case 'median'
        displayImg = nanmedian(meanImg(:,:,sessionIdx),3);
    case 'first'
        displayImg = meanImg(:,:,sessionIdx(1));
    otherwise
        error('Unknown displayMode: %s. Use mean, median, or first.',displayMode);
end
end
