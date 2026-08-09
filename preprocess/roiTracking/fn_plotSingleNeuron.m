function [fig,selection] = fn_plotSingleNeuron(animalName,nCells,nSessions,varargin)
%FN_PLOTSINGLENEURON Show well-tracked neurons across a range of sessions.
%   FN_PLOTSINGLENEURON(ANIMALNAME) reads the animal parameter file, loads
%   stackROI_final_tracked.mat and alignedOps.mat, and plots the best three
%   tracked neurons across 15 sessions sampled over the depth-offset range.
%
%   ANIMALNAME can be an experiment ID such as 'zz153_PPC'. A mouse name
%   such as 'zz153' is also accepted when only one matching parameter file
%   exists. If it has multiple areas, supply the complete experiment ID.
%
%   FN_PLOTSINGLENEURON(ANIMALNAME,NCELLS,NSESSIONS) changes the defaults.
%
%   Name-value options:
%     'MaxAbsOffset' - largest reasonable absolute depth offset (default 10)
%     'CropRadius'   - half-width of each image crop in pixels (default 20)
%     'LineWidth'    - ROI-outline width (default 1.5)
%
%   SELECTION contains parameter/data paths, selected cell/session indices,
%   session offsets, tracking scores, ROI areas, and brightness scores used
%   to make the figure.

if nargin < 2 || isempty(nCells)
    nCells = 3;
end
if nargin < 3 || isempty(nSessions)
    nSessions = 15;
end

p = inputParser;
addParameter(p,'MaxAbsOffset',10,@(x) isnumeric(x) && isscalar(x) && x>0);
addParameter(p,'CropRadius',20,@(x) isnumeric(x) && isscalar(x) && x>=5);
addParameter(p,'LineWidth',1.5,@(x) isnumeric(x) && isscalar(x) && x>0);
parse(p,varargin{:});

validateattributes(nCells,{'numeric'},{'scalar','integer','positive'});
validateattributes(nSessions,{'numeric'},{'scalar','integer','positive'});

[myOps,paramFile] = loadAnimalParameters(animalName);
trackingFile = resolveFile(myOps,'trackingName','stackROI_final_tracked.mat');
alignedFile = resolveFile(myOps,'alignOpsPath','alignedOps.mat');

tracked = load(trackingFile);
aligned = load(alignedFile,'alignedOps');
if ~isfield(tracked,'roiFinal') || ~isfield(tracked,'ishereFinal')
    error('fn_plotSingleNeuron:MissingTrackingVariables', ...
        '%s must contain roiFinal and ishereFinal.',trackingFile);
end
if ~isfield(aligned,'alignedOps') || ~isfield(aligned.alignedOps,'suite2pImg')
    error('fn_plotSingleNeuron:MissingImages', ...
        '%s must contain alignedOps.suite2pImg.',alignedFile);
end

roiFinal = tracked.roiFinal;
ishereFinal = tracked.ishereFinal;
suite2pImg = aligned.alignedOps.suite2pImg;
nAvailableSessions = min([size(roiFinal,1),size(ishereFinal,1),size(suite2pImg,3)]);
nNeurons = min(size(roiFinal,2),size(ishereFinal,2));
if nAvailableSessions == 0 || nNeurons == 0
    error('fn_plotSingleNeuron:EmptyTracking','No tracked ROI data were found.');
end

sessionOffset = getSessionOffset(tracked,roiFinal,nAvailableSessions);
sessionIdx = selectSessions(sessionOffset,nSessions,p.Results.MaxAbsOffset);

validRoi = false(nAvailableSessions,nNeurons);
roiArea = nan(nAvailableSessions,nNeurons);
roiBrightness = nan(nAvailableSessions,nNeurons);
scoreSession = false(nAvailableSessions,1);
scoreSession(sessionIdx) = true;
for session = 1:nAvailableSessions
    for neuron = 1:nNeurons
        coord = roiFinal{session,neuron};
        validRoi(session,neuron) = isnumeric(coord) && size(coord,2)>=2 && ...
            size(coord,1)>=3 && all(isfinite(coord(:)));
        if validRoi(session,neuron) && scoreSession(session)
            roiArea(session,neuron) = polyarea(coord(:,2),coord(:,1));
            roiBrightness(session,neuron) = measureRoiBrightness( ...
                suite2pImg(:,:,session),coord);
        end
    end
end

present = ishereFinal(1:nAvailableSessions,1:nNeurons) == 1;
trackingScore = mean(present(sessionIdx,:) & validRoi(sessionIdx,:),1);
allSessionScore = mean(present & validRoi,1);
medianRoiArea = median(roiArea(sessionIdx,:),'omitnan');
medianBrightness = median(roiBrightness(sessionIdx,:),'omitnan');
areaScore = robustUnitScale(medianRoiArea);
brightnessScore = robustUnitScale(medianBrightness);
visualScore = 0.5*areaScore + 0.5*brightnessScore;
% Tracking reliability is primary; among similarly tracked cells, prefer a
% balance of large and bright ROIs so the examples are easy to see.
trackingBand = round(trackingScore(:)*10)/10;
[~,cellOrder] = sortrows( ...
    [-trackingBand,-visualScore(:),-brightnessScore(:),-areaScore(:), ...
    -trackingScore(:),-allSessionScore(:)],[1 2 3 4 5 6]);
cellIdx = cellOrder(1:min(nCells,nNeurons)).';

fig = figure('Color','w','Name',sprintf('%s: tracked neurons',myOps.ID), ...
    'NumberTitle','off');
set(fig,'Units','pixels');
figureWidth = max(700,54*numel(sessionIdx));
figureHeight = max(150,52*numel(cellIdx));
set(fig,'Position',[100 100 figureWidth figureHeight]);
panelGap = [0.003 0.003];

for row = 1:numel(cellIdx)
    neuron = cellIdx(row);
    for column = 1:numel(sessionIdx)
        session = sessionIdx(column);
        ax = subplot_tight(numel(cellIdx),numel(sessionIdx), ...
            (row-1)*numel(sessionIdx)+column,panelGap);
        coord = roiFinal{session,neuron};
        showRoiCrop(ax,suite2pImg(:,:,session),coord,p.Results.CropRadius, ...
            present(session,neuron),p.Results.LineWidth);

        if row == 1
            title(ax,sprintf('%d',session),'FontSize',7,'FontWeight','normal', ...
                'Units','normalized','Position',[0.5 0.98 0]);
        end
        if column == 1
            text(ax,-0.04,0.5,sprintf('%d',neuron),'Units','normalized', ...
                'HorizontalAlignment','right','VerticalAlignment','middle', ...
                'FontWeight','bold','FontSize',8, ...
                'Color',multitaskColors(mod(row-1,4)+1),'Clipping','off');
        end
    end
end

selection = struct();
selection.parameterFile = paramFile;
selection.trackingFile = trackingFile;
selection.alignedFile = alignedFile;
selection.cellIdx = cellIdx;
selection.sessionIdx = sessionIdx;
selection.sessionOffset = sessionOffset(sessionIdx);
selection.trackingScore = trackingScore(cellIdx);
selection.medianRoiArea = medianRoiArea(cellIdx);
selection.brightnessScore = medianBrightness(cellIdx);
selection.visualScore = visualScore(cellIdx);
end

function [myOps,paramFile] = loadAnimalParameters(animalName)
thisDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(thisDir));
paramDir = fullfile(repoRoot,'organizer','ops_param');
animalName = char(string(animalName));

exactFile = fullfile(paramDir,[animalName '_param.m']);
if isfile(exactFile)
    candidates = dir(exactFile);
else
    candidates = dir(fullfile(paramDir,[animalName '*_param.m']));
end
if isempty(candidates)
    error('fn_plotSingleNeuron:ParameterFileNotFound', ...
        'No parameter file matching %s was found in %s.',animalName,paramDir);
elseif numel(candidates) > 1
    names = strjoin({candidates.name},', ');
    error('fn_plotSingleNeuron:AmbiguousAnimal', ...
        'Multiple parameter files match %s: %s. Use the full experiment ID.', ...
        animalName,names);
end

paramFile = fullfile(candidates(1).folder,candidates(1).name);
myOps = struct();
run(paramFile);
if ~isfield(myOps,'ID')
    myOps.ID = animalName;
end
end

function filePath = resolveFile(myOps,fieldName,defaultName)
if strcmp(fieldName,'trackingName') && isfield(myOps,fieldName)
    filePath = myOps.(fieldName);
elseif isfield(myOps,fieldName)
    filePath = fullfile(myOps.(fieldName),defaultName);
elseif isfield(myOps,'TCpath')
    filePath = fullfile(myOps.TCpath,defaultName);
else
    error('fn_plotSingleNeuron:MissingPath', ...
        'The parameter file needs %s or TCpath.',fieldName);
end
if ~isfile(filePath) && isfield(myOps,'TCpath')
    fallback = fullfile(myOps.TCpath,defaultName);
    if isfile(fallback)
        filePath = fallback;
    end
end
if ~isfile(filePath)
    error('fn_plotSingleNeuron:DataFileNotFound','Could not find %s.',filePath);
end
end

function sessionOffset = getSessionOffset(tracked,roiFinal,nSessions)
if isfield(tracked,'roiDepthDiffFinal')
    depthDiff = tracked.roiDepthDiffFinal(1:nSessions,:);
    sessionOffset = median(depthDiff,2,'omitnan');
elseif isfield(tracked,'initialXYShiftFinal')
    xy = tracked.initialXYShiftFinal(1:nSessions,1:2);
    sessionOffset = hypot(xy(:,1),xy(:,2));
else
    % Older tracking files do not save offsets. Estimate the session-wide
    % x-y displacement from the median centroid of all valid tracked ROIs.
    sessionCentroid = nan(nSessions,2);
    for session = 1:nSessions
        centroids = nan(size(roiFinal,2),2);
        for neuron = 1:size(roiFinal,2)
            coord = roiFinal{session,neuron};
            if isnumeric(coord) && size(coord,2)>=2 && all(isfinite(coord(:)))
                centroids(neuron,:) = mean(coord(:,1:2),1);
            end
        end
        sessionCentroid(session,:) = median(centroids,1,'omitnan');
    end
    referenceCentroid = median(sessionCentroid,1,'omitnan');
    displacement = sessionCentroid-referenceCentroid;
    sessionOffset = hypot(displacement(:,1),displacement(:,2));
end
sessionOffset = sessionOffset(:);
end

function sessionIdx = selectSessions(offset,nRequested,maxAbsOffset)
valid = find(isfinite(offset) & abs(offset)<=maxAbsOffset);
if isempty(valid)
    valid = find(isfinite(offset));
end
if isempty(valid)
    valid = (1:numel(offset)).';
end

[~,order] = sort(offset(valid));
ranked = valid(order);
nSelect = min(nRequested,numel(ranked));
positions = unique(round(linspace(1,numel(ranked),nSelect)),'stable');
sessionIdx = sort(ranked(positions)).';
end

function showRoiCrop(ax,img,coord,radius,isPresent,lineWidth)
imagesc(ax,img);
colormap(ax,gray);
axis(ax,'image','off');
hold(ax,'on');

if isempty(coord) || size(coord,2)<2 || any(~isfinite(coord(:)))
    return
end
row = mean(coord(:,1));
column = mean(coord(:,2));
xlim(ax,[column-radius column+radius]);
ylim(ax,[row-radius row+radius]);

if isPresent
    edgeColor = [0 1 0];
else
    edgeColor = [0.85 0.20 0.20];
end
plot(ax,[coord(:,2);coord(1,2)],[coord(:,1);coord(1,1)], ...
    'Color',edgeColor,'LineWidth',lineWidth);
end

function score = measureRoiBrightness(img,coord)
% Contrast of the ROI interior relative to a local annular background.
padding = 8;
rowRange = max(1,floor(min(coord(:,1)))-padding): ...
    min(size(img,1),ceil(max(coord(:,1)))+padding);
colRange = max(1,floor(min(coord(:,2)))-padding): ...
    min(size(img,2),ceil(max(coord(:,2)))+padding);
localCoord = [coord(:,1)-rowRange(1)+1,coord(:,2)-colRange(1)+1];
localImg = img(rowRange,colRange);
roiMask = poly2mask(localCoord(:,2),localCoord(:,1), ...
    size(localImg,1),size(localImg,2));
if ~any(roiMask(:))
    score = nan;
    return
end

outerMask = imdilate(roiMask,strel('disk',6,0));
innerMask = imdilate(roiMask,strel('disk',2,0));
backgroundMask = outerMask & ~innerMask;
inside = double(localImg(roiMask));
background = double(localImg(backgroundMask));
if isempty(background)
    score = mean(inside,'omitnan');
    return
end
backgroundSpread = std(background,0,'omitnan');
score = (mean(inside,'omitnan')-median(background,'omitnan')) / ...
    max(backgroundSpread,eps);
end

function scaled = robustUnitScale(values)
values = values(:);
finiteValues = sort(values(isfinite(values)));
scaled = zeros(size(values));
if isempty(finiteValues)
    return
end
low = finiteValues(max(1,round(0.05*numel(finiteValues))));
high = finiteValues(max(1,round(0.95*numel(finiteValues))));
scaled = (values-low)/max(high-low,eps);
scaled = min(max(scaled,0),1);
scaled(~isfinite(scaled)) = 0;
end
