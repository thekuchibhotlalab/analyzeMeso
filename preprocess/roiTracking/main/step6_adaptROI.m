function step6_adaptROI(datapath,Pix,stepSize)
if nargin < 2 || isempty(Pix); Pix = 40; end
if nargin < 3 || isempty(stepSize); stepSize = floor(Pix/2); end


% ROI that are tracked are adapted for each suite2p session image

opsLoad = load([datapath filesep 'ops.mat'],'ops','initial_transform_coord');
ops = opsLoad.ops;
if isfield(opsLoad,'initial_transform_coord')
    initial_transform_coord = opsLoad.initial_transform_coord;
elseif isfield(ops,'initial_transform_coord')
    initial_transform_coord = ops.initial_transform_coord;
else
    initial_transform_coord = [];
    warning('initial_transform_coord not found in ops.mat. Edge-FOV ishere correction will be skipped.');
end
load([datapath filesep 'alignedOps.mat' ],'alignedOps');
load([datapath filesep 'stackROI_final.mat' ],'stackROI');
lowSNRFlag = loadLowSNRFlag(datapath);
%if ~isfile([ops.roiTrackingPath filesep 'refStack' filesep 'refStackAligned.mat'])
%disp('refStack non-rigid alignment NOT detected -- OLD version -- loading refStack from TIFF')
refImg_roiReference = loadRefstacksel([datapath filesep 'roiTracking' filesep 'refStackReconstruct' ]);
%else
%    disp('refStack non-rigid alignment detected -- NEW version -- loading refStack from OPS FILE')
%    refImg_roiReference = ops.refStackAligned(:,:,ops.refStackSelLoc); 
%end 
% try this

[roiFinal, ishereFinal,alignIdx1Mean,alignIdx2Mean,roiShiftRowFinal,roiShiftColFinal,roiDepthFinal,roiDepthIdxFinal,roiDepthDiffFinal,roiFovValidFinal,roiFovFractionFinal,initialXYShiftFinal,roiFovExcludedCount,lowSNRExcludedCount] = projectROI(stackROI, alignedOps.suite2pImg, ops.offsetMap,refImg_roiReference, ops.refStackSelLoc,initial_transform_coord,lowSNRFlag,Pix,stepSize);
save([datapath filesep 'stackROI_final_tracked.mat'],'roiFinal', 'ishereFinal','alignIdx1Mean','alignIdx2Mean','roiShiftRowFinal','roiShiftColFinal','roiDepthFinal','roiDepthIdxFinal','roiDepthDiffFinal','roiFovValidFinal','roiFovFractionFinal','initialXYShiftFinal','roiFovExcludedCount','lowSNRExcludedCount','Pix','stepSize');
saveTopOffsetSessionPlots(ops.roiTrackingPath,alignedOps.suite2pImg,roiFinal,ishereFinal,initialXYShiftFinal,roiFovExcludedCount);
end 

function saveTopOffsetSessionPlots(roiTrackingPath,suite2pImg,roiFinal,ishereFinal,initialXYShiftFinal,roiFovExcludedCount)
    savingPath = [roiTrackingPath filesep 'adaptroi'];
    if ~exist(savingPath,'dir'); mkdir(savingPath); end

    offsetMag = hypot(initialXYShiftFinal(:,1),initialXYShiftFinal(:,2));
    validSession = ~isnan(offsetMag);
    if ~any(validSession)
        warning('No valid initial x-y shifts found. Skipping top-offset ROI summary figure.');
        return
    end

    [~,sortIdx] = sort(offsetMag,'descend','MissingPlacement','last');
    topSessionIdx = sortIdx(1:min(5,sum(validSession)));
    topSessionIdx = topSessionIdx(~isnan(offsetMag(topSessionIdx)));
    nPlot = length(topSessionIdx);
    if nPlot == 0
        warning('No valid sessions found for top-offset ROI summary figure.');
        return
    end

    fig = figure('Visible','off','Position',[100 100 1200 320*nPlot], ...
        'Name','Top initial x-y offset ROI summary','NumberTitle','off');
    tileObj = tiledlayout(fig,nPlot,1,'TileSpacing','compact','Padding','compact');
    title(tileObj,'Top sessions by initial x-y offset: accepted ROIs green, rejected ROIs red');

    for p = 1:nPlot
        sessionIdx = topSessionIdx(p);
        ax = nexttile(tileObj);
        bgImg = suite2pImg(:,:,sessionIdx);
        if isa(bgImg,'double') && max(bgImg(:)) <= 1
            imagesc(ax,bgImg,[0.2 0.8]);
        else
            imagesc(ax,bgImg,[double(prctile(bgImg(:),1)) double(prctile(bgImg(:),99))]);
        end
        colormap(ax,gray);
        axis(ax,'image');
        axis(ax,'off');
        hold(ax,'on');

        acceptedCount = 0;
        rejectedCount = 0;
        for n = 1:size(roiFinal,2)
            coords = roiFinal{sessionIdx,n};
            if isempty(coords) || any(isnan(coords(:)))
                continue
            end
            if ishereFinal(sessionIdx,n) == 1
                edgeColor = [0 1 0];
                lineWidth = 0.9;
                acceptedCount = acceptedCount + 1;
            else
                edgeColor = [1 0 0];
                lineWidth = 0.6;
                rejectedCount = rejectedCount + 1;
            end
            plot(ax,coords(:,2),coords(:,1),'Color',edgeColor,'LineWidth',lineWidth);
        end

        shiftText = sprintf('[row %.1f, col %.1f], |shift| %.1f px', ...
            initialXYShiftFinal(sessionIdx,1),initialXYShiftFinal(sessionIdx,2),offsetMag(sessionIdx));
        title(ax,sprintf('Session %d: %s | accepted %d, rejected %d, FOV-shift rejected %d', ...
            sessionIdx,shiftText,acceptedCount,rejectedCount,roiFovExcludedCount(sessionIdx)));
    end

    outFile = [savingPath filesep 'top5_initialXYOffset_ROIs.png'];
    try
        exportgraphics(fig,outFile,'Resolution',200);
    catch
        print(fig,outFile,'-dpng','-r200');
    end
    close(fig);
    fprintf('Saved top-offset ROI summary figure: %s\n',outFile);
end
%% old code
%matchedRoi = {}; roi = struct(); 
%stackROI.imageJ = ReadImageJROI('G:\rockfish\ziyi\zz153_PPC\meanImg\refStackAlignROI_reconstruct\roiMean.zip');
%[stackROI.maskRaw,stackROI.coordRaw,stackROI.centroidRaw] = convertROIcoord(stackROI.imageJ,stackROI.suite2pImg(:,:,1)); 
%roiRefImg = double(imread([datapath '\refStackAlignROI_reconstruct\refImg_mean.tiff' ]))/65536;

%for k = 1:size(stackROI.suite2pImg,3)
%    disp(k);
%    tempOffsetMap = matchedOffsetMap(:,:,k);
%    matchedRoi{k} = projectROI(roi, stackROI.refStackSelLoc, stackROI.suite2pImg(:,:,k), matchedOffsetMap(:,:,k),roiRefImg, Pix);
%end 

%end 
%% functions 
function [roiFinal, ishereFinal,alignIdx1Mean,alignIdx2Mean,roiShiftRowFinal,roiShiftColFinal,roiDepthFinal,roiDepthIdxFinal,roiDepthDiffFinal,roiFovValidFinal,roiFovFractionFinal,initialXYShiftFinal,roiFovExcludedCount,lowSNRExcludedCount] = projectROI(stackROI, suite2pImg, offsetMap,refImg_roiReference,refStackSelLoc,initial_transform_coord,lowSNRFlag,Pix,stepSize)
    excludeEdge = 10;
    roiShiftRadius = Pix;
    maxGlobalShift = 5;
    maxLocalShift = 6;
    depthTolerance = 2;
    minRoiFovFraction = 0.5;
    % Get image size
    [imgHeight, imgWidth, nImg] = size(suite2pImg);
    lowSNRFlag = validateLowSNRFlag(lowSNRFlag,imgHeight,imgWidth,nImg);

    % take note of which ROI is here
    roiFinal = cell(nImg,length(stackROI.coord));
    ishereFinal = nan(nImg,length(stackROI.coord));
    roiShiftRowFinal = nan(nImg,length(stackROI.coord));
    roiShiftColFinal = nan(nImg,length(stackROI.coord));
    roiDepthFinal = nan(nImg,length(stackROI.coord));
    roiDepthIdxFinal = nan(nImg,length(stackROI.coord));
    roiDepthDiffFinal = nan(nImg,length(stackROI.coord));
    roiFovValidFinal = nan(nImg,length(stackROI.coord));
    roiFovFractionFinal = nan(nImg,length(stackROI.coord));
    initialXYShiftFinal = nan(nImg,2);
    roiFovExcludedCount = nan(1,nImg);
    lowSNRExcludedCount = nan(1,nImg);
    alignIdx1Mean = nan(1,nImg); alignIdx2Mean = nan(1,nImg);
    for i = 1:nImg
        tic;
        initialXYShift = getInitialXYShift(initial_transform_coord,i,nImg);
        initialXYShiftFinal(i,:) = initialXYShift;

        [roiMatched,ishereMatched,alignIdx1Mean(i),alignIdx2Mean(i),roiShiftRow,roiShiftCol,roiDepth,roiDepthIdx,roiDepthDiff,roiFovValid,roiFovFraction,lowSNRRejected] = matchImg(suite2pImg(:,:,i),offsetMap(:,:,i),refImg_roiReference,refStackSelLoc,stackROI,initialXYShift,i);
        roiFinal(i,:) = roiMatched;
        ishereFinal(i,:) = ishereMatched;
        roiShiftRowFinal(i,:) = roiShiftRow;
        roiShiftColFinal(i,:) = roiShiftCol;
        roiDepthFinal(i,:) = roiDepth;
        roiDepthIdxFinal(i,:) = roiDepthIdx;
        roiDepthDiffFinal(i,:) = roiDepthDiff;
        roiFovValidFinal(i,:) = roiFovValid;
        roiFovFractionFinal(i,:) = roiFovFraction;
        roiFovExcludedCount(i) = sum(roiFovValid == 0);
        lowSNRExcludedCount(i) = sum(lowSNRRejected == 1);
        fprintf('Session%d: %d neurons inferred absent due to initial x-y FOV shift.\n', ...
            i, roiFovExcludedCount(i));
        fprintf('Session%d: %d neurons inferred absent due to low-SNR flag.\n', ...
            i, lowSNRExcludedCount(i));
        t = toc; disp(['Session' int2str(i) ', time elapsed = ' num2str(t)])
    end 
    function [roiMatched,ishereMatched,alignIdx1Mean,alignIdx2Mean,roiShiftRow,roiShiftCol,roiDepth,roiDepthIdx,roiDepthDiff,roiFovValid,roiFovFraction,lowSNRRejected] = matchImg(suite2pImg,offsetMap,refImg_roiReference,refStackSelLoc,stackROI,initialXYShift,sessionIdx)

        nRoi = size(stackROI.ishere,2); nDepth = length(refStackSelLoc);
        % Define valid ranges excluding edges
        validStartRow = excludeEdge + 1;
        validEndRow = imgHeight - excludeEdge;
        validStartCol = excludeEdge + 1;
        validEndCol =  imgWidth - excludeEdge;
        rowStarts = getBlockStarts(validStartRow,validEndRow,Pix,stepSize);
        colStarts = getBlockStarts(validStartCol,validEndCol,Pix,stepSize);

        % first do a rough alignment that shifts the stack towards suite2p
        refImg_aligned = refImg_roiReference/65536;
        alignIdx1 = cell(nDepth,1);
        for a = 1:nDepth
            tempSuite2pImg = suite2pImg; tempSuite2pImg(refImg_aligned(:,:,a)==0) = 0;
            [tempref, alignIdx1{a}] = fn_fastAlign(cat(3,tempSuite2pImg,refImg_aligned(:,:,a)),'center');
            if abs(alignIdx1{a}(2,1)) > maxGlobalShift || abs(alignIdx1{a}(2,2)) > maxGlobalShift
                fprintf(['Session %d: global shift rejected at depth index %d ' ...
                    '(refStackSelLoc %.2f): row %.2f, col %.2f, maxGlobalShift %.2f px.\n'], ...
                    sessionIdx,a,refStackSelLoc(a),alignIdx1{a}(2,1),alignIdx1{a}(2,2),maxGlobalShift);
                alignIdx1{a}(2,1) = 0; alignIdx1{a}(2,2) = 0;
            else
                refImg_aligned(:,:,a) = tempref(:,:,2);
            end 
            
        end
        roiCoordShift1 = cell(nDepth,nRoi); roiCenterShift1 = cell(nDepth,nRoi);
        for a = 1:nDepth
            for b = 1:nRoi
                if isempty(stackROI.coordRedrawn{a,b}) || isempty(stackROI.centroidRedrawn{a,b})
                    continue
                end
                roiCoordShift1{a,b} = [stackROI.coordRedrawn{a,b}(:,1) + alignIdx1{a}(2,1),  stackROI.coordRedrawn{a,b}(:,2) + alignIdx1{a}(2,2)];
                roiCenterShift1{a,b} = [stackROI.centroidRedrawn{a,b}(1) + alignIdx1{a}(2,1),  stackROI.centroidRedrawn{a,b}(2) + alignIdx1{a}(2,2)];
            end 
        end 

        roiMatched = cell(1,nRoi);
        ishereMatched = nan(1,nRoi);
        roiShiftRow = nan(1,nRoi);
        roiShiftCol = nan(1,nRoi);
        roiDepth = nan(1,nRoi);
        roiDepthIdx = nan(1,nRoi);
        roiDepthDiff = nan(1,nRoi);
        roiFovValid = nan(1,nRoi);
        roiFovFraction = nan(1,nRoi);
        lowSNRRejected = zeros(1,nRoi);

        offsetMapForDepth = fillOffsetEdges(offsetMap);
        [shiftSamples,alignIdx2Abs] = estimateShiftField();
        alignIdx1Mean = fn_cell2mat(alignIdx1,3); alignIdx1Mean = alignIdx1Mean(2,:,:);
        alignIdx1Mean = nanmean(abs(alignIdx1Mean(:)));
        alignIdx2Mean = nanmean(alignIdx2Abs);

        for b = 1:nRoi
            [selDepth,minDepthDiff] = selectDepthForRoi(b);
            roiDepthIdx(b) = selDepth;
            if ~isnan(selDepth)
                roiDepth(b) = refStackSelLoc(selDepth);
            end
            roiDepthDiff(b) = minDepthDiff;

            if isnan(selDepth) || isempty(roiCoordShift1{selDepth,b})
                continue
            end

            roiCenter = roiCenterShift1{selDepth,b};
            [dRow,dCol] = selectRoiShift(roiCenter,selDepth,shiftSamples);
            roiShiftRow(b) = dRow;
            roiShiftCol(b) = dCol;

            roiMatched{b} = [roiCoordShift1{selDepth,b}(:,1) + dRow,...
                roiCoordShift1{selDepth,b}(:,2) + dCol];
            ishereMatched(b) = stackROI.ishere(selDepth,b);
            if minDepthDiff > depthTolerance
                ishereMatched(b) = nan;
            end

            [isValidFov,inFovFraction] = roiWithinInitialShiftFov(roiMatched{b},initialXYShift);
            roiFovValid(b) = isValidFov;
            roiFovFraction(b) = inFovFraction;
            if isValidFov == 0
                ishereMatched(b) = 0;
            end

            if roiCentroidInLowSNR(roiMatched{b},sessionIdx)
                ishereMatched(b) = 0;
                lowSNRRejected(b) = 1;
            end
        end

        function [shiftSamples,alignIdx2Abs] = estimateShiftField()
            shiftSamples = nan(length(rowStarts)*length(colStarts),6);
            alignIdx2Abs = nan(length(rowStarts)*length(colStarts),1);
            sampleCount = 0;
            for rowStart = rowStarts
                for colStart = colStarts
                    rowIdx = rowStart:rowStart+Pix-1;
                    colIdx = colStart:colStart+Pix-1;
                    tempOffset = offsetMapForDepth(rowIdx, colIdx);
                    tempOffset = nanMedian(tempOffset(:));
                    if isnan(tempOffset)
                        continue
                    end

                    [minDepthDiff,selDepth] = min(abs(refStackSelLoc - tempOffset));
                    fixedBlock = suite2pImg(rowIdx, colIdx);
                    movingBlock = refImg_aligned(rowIdx, colIdx, selDepth);
                    try
                        [~,alignIdx2] = fn_fastAlign(cat(3,fixedBlock,movingBlock),'center');
                        localShift = alignIdx2(2,:);
                    catch
                        localShift = [nan nan];
                    end

                    if any(abs(localShift) > maxLocalShift)
                        fprintf(['Session %d: local shift rejected at patch row %d:%d, col %d:%d, ' ...
                            'depth index %d (refStackSelLoc %.2f, offset %.2f, depth diff %.2f): ' ...
                            'row %.2f, col %.2f, maxLocalShift %.2f px.\n'], ...
                            sessionIdx,rowIdx(1),rowIdx(end),colIdx(1),colIdx(end), ...
                            selDepth,refStackSelLoc(selDepth),tempOffset,minDepthDiff, ...
                            localShift(1),localShift(2),maxLocalShift);
                        localShift = [nan nan];
                    end

                    if any(isnan(localShift))
                        continue
                    end

                    sampleCount = sampleCount + 1;
                    shiftSamples(sampleCount,:) = [mean(rowIdx), mean(colIdx), selDepth, localShift(1), localShift(2), minDepthDiff];
                    alignIdx2Abs(sampleCount) = nanmean(abs(localShift));
                end
            end
            shiftSamples = shiftSamples(1:sampleCount,:);
            alignIdx2Abs = alignIdx2Abs(1:sampleCount);
        end

        function [selDepth,minDepthDiff] = selectDepthForRoi(roiIdx)
            centerAllDepth = cellRowsToMat(roiCenterShift1(:,roiIdx));
            if isempty(centerAllDepth)
                selDepth = nan;
                minDepthDiff = nan;
                return
            end
            centerRow = round(nanMedian(centerAllDepth(:,1)));
            centerCol = round(nanMedian(centerAllDepth(:,2)));
            if isnan(centerRow) || isnan(centerCol)
                selDepth = nan;
                minDepthDiff = nan;
                return
            end
            centerRow = min(max(centerRow,1),imgHeight);
            centerCol = min(max(centerCol,1),imgWidth);
            roiDepthRadius = max(5,round(Pix/4));
            rowIdx = max(1,centerRow-roiDepthRadius):min(imgHeight,centerRow+roiDepthRadius);
            colIdx = max(1,centerCol-roiDepthRadius):min(imgWidth,centerCol+roiDepthRadius);
            tempOffset = offsetMapForDepth(rowIdx,colIdx);
            tempOffset = nanMedian(tempOffset(:));
            if isnan(tempOffset)
                selDepth = nan;
                minDepthDiff = nan;
                return
            end
            [minDepthDiff,selDepth] = min(abs(refStackSelLoc - tempOffset));
        end

        function [dRow,dCol] = selectRoiShift(roiCenter,selDepth,shiftSamples)
            if isempty(shiftSamples)
                dRow = 0; dCol = 0;
                return
            end
            dist = hypot(shiftSamples(:,1)-roiCenter(1),shiftSamples(:,2)-roiCenter(2));
            sampleDepth = shiftSamples(:,3);
            sameDepth = sampleDepth == selDepth;
            goodDepth = shiftSamples(:,6) <= depthTolerance;
            useIdx = sameDepth & goodDepth & dist <= roiShiftRadius;
            if sum(useIdx) < 3
                useIdx = sameDepth & dist <= roiShiftRadius*2;
            end
            if sum(useIdx) < 3 && any(sameDepth)
                useIdx = false(size(dist));
                sameDepthIdx = find(sameDepth);
                [~,sortIdx] = sort(dist(sameDepthIdx),'ascend');
                useIdx(sameDepthIdx(sortIdx(1:min(5,length(sortIdx))))) = true;
            end
            if sum(useIdx) < 1
                useIdx = false(size(dist));
                [~,sortIdx] = sort(dist,'ascend');
                useIdx(sortIdx(1:min(5,length(sortIdx)))) = true;
            end

            dRow = nanMedian(shiftSamples(useIdx,4));
            dCol = nanMedian(shiftSamples(useIdx,5));
            if isnan(dRow); dRow = 0; end
            if isnan(dCol); dCol = 0; end
            if abs(dRow) > maxLocalShift || abs(dCol) > maxLocalShift
                dRow = 0; dCol = 0;
            end
        end

        function starts = getBlockStarts(validStart,validEnd,blockSize,blockStep)
            lastStart = validEnd - blockSize + 1;
            if lastStart < validStart
                starts = validStart;
            else
                starts = validStart:blockStep:lastStart;
                starts = unique([starts lastStart]);
            end
        end

        function matOut = fillOffsetEdges(matIn)
            matOut = matIn;
            if any(isnan(matOut(:)))
                try
                    matOut = fillmissing(matOut,'nearest',1);
                    matOut = fillmissing(matOut,'nearest',2);
                catch
                    warning('fillmissing is unavailable. Using raw offset map; edge depth estimates may be less stable.');
                end
            end
        end

        function matOut = cellRowsToMat(cellIn)
            goodCell = ~cellfun(@isempty,cellIn);
            if any(goodCell)
                matOut = cell2mat(cellIn(goodCell));
            else
                matOut = [];
            end
        end

        function out = nanMedian(values)
            values = values(~isnan(values));
            if isempty(values)
                out = nan;
            else
                out = median(values);
            end
        end 

        function [isValidFov,inFovFraction] = roiWithinInitialShiftFov(roiCoords,initialXYShift)
            % initialXYShift is the [row, col] shift used in circshift to
            % align the raw session image into reference-session coordinates.
            % For aligned pixel (r,c), the raw source is (r-shiftRow,c-shiftCol).
            % Therefore valid aligned rows are 1+shiftRow : imgHeight+shiftRow.
            if isempty(initialXYShift) || any(isnan(initialXYShift))
                isValidFov = 1;
                inFovFraction = 1;
                return
            end

            shiftRow = initialXYShift(1);
            shiftCol = initialXYShift(2);
            validRowStart = max(1,1 + shiftRow);
            validRowEnd = min(imgHeight,imgHeight + shiftRow);
            validColStart = max(1,1 + shiftCol);
            validColEnd = min(imgWidth,imgWidth + shiftCol);

            if validRowStart > validRowEnd || validColStart > validColEnd
                isValidFov = 0;
                inFovFraction = 0;
                return
            end

            roiRows = roiCoords(:,1);
            roiCols = roiCoords(:,2);
            roiInFov = roiRows >= validRowStart & roiRows <= validRowEnd & ...
                roiCols >= validColStart & roiCols <= validColEnd;
            inFovFraction = mean(roiInFov);

            roiCenter = [mean(roiRows), mean(roiCols)];
            centerInFov = roiCenter(1) >= validRowStart && roiCenter(1) <= validRowEnd && ...
                roiCenter(2) >= validColStart && roiCenter(2) <= validColEnd;
            isValidFov = centerInFov && inFovFraction >= minRoiFovFraction;
        end

        function inLowSNR = roiCentroidInLowSNR(roiCoords,sessionIdx)
            inLowSNR = false;
            if isempty(lowSNRFlag) || sessionIdx > size(lowSNRFlag,3)
                return
            end
            if isempty(roiCoords) || size(roiCoords,2) < 2 || any(isnan(roiCoords(:)))
                return
            end

            centerRow = round(mean(roiCoords(:,1)));
            centerCol = round(mean(roiCoords(:,2)));
            if centerRow < 1 || centerRow > imgHeight || centerCol < 1 || centerCol > imgWidth
                return
            end

            inLowSNR = lowSNRFlag(centerRow,centerCol,sessionIdx) > 0;
        end
    end

    function lowSNRFlag = validateLowSNRFlag(lowSNRFlag,imgHeight,imgWidth,nImg)
        if isempty(lowSNRFlag)
            return
        end
        if ndims(lowSNRFlag) ~= 3
            warning('lowSNRFlag should be Y x X x nSession. Ignoring lowSNRFlag because it is not 3-D.');
            lowSNRFlag = [];
            return
        end
        if size(lowSNRFlag,1) ~= imgHeight || size(lowSNRFlag,2) ~= imgWidth
            warning(['lowSNRFlag spatial size is %d x %d, but suite2pImg is %d x %d. ' ...
                'Ignoring lowSNRFlag.'], ...
                size(lowSNRFlag,1),size(lowSNRFlag,2),imgHeight,imgWidth);
            lowSNRFlag = [];
            return
        end
        if size(lowSNRFlag,3) < nImg
            warning(['lowSNRFlag has %d sessions, but suite2pImg has %d sessions. ' ...
                'Low-SNR rejection will only apply to the available sessions.'], ...
                size(lowSNRFlag,3),nImg);
        end
        lowSNRFlag = logical(lowSNRFlag);
    end

    function initialXYShift = getInitialXYShift(initial_transform_coord,sessionIdx,nSession)
        if isempty(initial_transform_coord)
            initialXYShift = [nan nan];
            return
        end

        if iscell(initial_transform_coord)
            initialXYShift = initial_transform_coord{sessionIdx};
        elseif size(initial_transform_coord,1) == nSession && size(initial_transform_coord,2) >= 2
            initialXYShift = initial_transform_coord(sessionIdx,1:2);
        elseif size(initial_transform_coord,2) == nSession && size(initial_transform_coord,1) >= 2
            initialXYShift = initial_transform_coord(1:2,sessionIdx)';
        else
            warning('initial_transform_coord size does not match session count. Edge-FOV correction skipped for session %d.',sessionIdx);
            initialXYShift = [nan nan];
            return
        end

        initialXYShift = double(initialXYShift(1:2));
        initialXYShift = initialXYShift(:)';
    end
end 

function lowSNRFlag = loadLowSNRFlag(datapath)
    lowSNRFlag = [];
    candidateFiles = { ...
        [datapath filesep 'lowSNRFlag.mat'], ...
        [datapath filesep 'lowSNRflag.mat'], ...
        [datapath filesep 'roiTracking' filesep 'lowSNRFlag.mat'], ...
        [datapath filesep 'roiTracking' filesep 'lowSNRflag.mat']};

    lowSNRFile = '';
    for i = 1:numel(candidateFiles)
        if isfile(candidateFiles{i})
            lowSNRFile = candidateFiles{i};
            break
        end
    end

    if isempty(lowSNRFile)
        fprintf('No lowSNRFlag.mat detected. Skipping low-SNR ROI rejection.\n');
        return
    end

    loadedLowSNR = load(lowSNRFile);
    if isfield(loadedLowSNR,'lowSNRFlag')
        lowSNRFlag = loadedLowSNR.lowSNRFlag;
    elseif isfield(loadedLowSNR,'lowSNRflag')
        lowSNRFlag = loadedLowSNR.lowSNRflag;
    else
        warning('Found %s, but it does not contain lowSNRFlag or lowSNRflag. Skipping low-SNR ROI rejection.',lowSNRFile);
        return
    end

    fprintf('Loaded low-SNR mask: %s\n',lowSNRFile);
end


 function img = loadRefstacksel(folder_path)
    % Get a list of all files in the folder
    files = dir([folder_path filesep '*.tiff']);
    
    % Extract the filenames
    filenames = {files.name};
    
    % Filter filenames that contain 'refImg' but do not contain '_'
    filtered_filenames = filenames(contains(filenames, 'refImg') & ~contains(filenames, '_'));
    img = cell(1,length(filtered_filenames));
    for k = 1:length(filtered_filenames)
        img{k} = double(imread([folder_path filesep filtered_filenames{k}]));
    end 
    img = fn_cell2mat(img,3);
end 
