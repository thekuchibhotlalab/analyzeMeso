function step4_saveMeanImg4ROI(datapath)
load([datapath filesep 'ops.mat'],'ops','initial_transform_coord');
load([datapath filesep 'alignedOps.mat' ],'alignedOps');
matchedOffsetMap = loadMat([ops.roiTrackingPath '\offsetEvaluation']);
ops.suite2pRefImg = alignedOps.suite2pImg(:,:,ops.refIdx); % which session of suite2p is used as suite2p reference
offsetMap = cellfun(@(x)(x.offsetMap),matchedOffsetMap,'UniformOutput',false);
offsetMap = fn_cell2mat(offsetMap,3);
ops.offsetMap = offsetMap;
avgOffset = squeeze(nanmean(nanmean(offsetMap,1),2));
selMean = round(mean(avgOffset));
ops.refStackSelLoc = selMean-15:5:selMean+15;
ops.refStackSelLocMeanIdx = 3:5;
refStack = ops.refStackAligned;
for k = 1:size(ops.refStack,3)
   [tempAligned,tempShift] = fn_fastAlign(cat(3, ops.suite2pRefImg,refStack(:,:,k)),'center');
   ops.refStackAligned(:,:,k) = tempAligned(:,:,2);
   ops.refStackAlignedT(k,:) = tempShift(2,:);
end 
reconstructImageSave(ops,alignedOps);
save([datapath filesep 'ops.mat' ],'ops','initial_transform_coord');
end

function reconstructImageSave(ops,alignedOps)
    savingPath = [ops.roiTrackingPath '\refStackReconstruct\'];
    mkdir(savingPath);
    refStack = ops.refStackAligned;
    suite2pImg = alignedOps.suite2pImg;
    matchedOffsetMap = ops.offsetMap;
    Pix = 100;
    tic;
    refStackSelLoc = ops.refStackSelLoc; %[28 33 38 43 48 53];
    refStackMeanIdx = ops.refStackSelLocMeanIdx; %2:4;
    offsetImg = {};
    for i= 1:length(refStackSelLoc)
        [offsetImg{i}] = reconstructImage(suite2pImg, refStack, matchedOffsetMap, refStackSelLoc(i),Pix);
        t = toc; disp(['depth ' int2str(i) ', time = ' num2str(t) ' sec'])
        % revise this line (buld a new function) so that we take the average of the image patches (after alignment to z-position), not just select one 
        fn_saveTiff(offsetImg{i},['refImg' num2str(refStackSelLoc(i),'%02d') '.tiff'], savingPath);
       
    end 
    tempMeanImg = fn_cell2mat(offsetImg,3);
    meanImg = nanmean(tempMeanImg(:,:,refStackMeanIdx),3);
    fn_saveTiff(meanImg,'refImg_mean.tiff', savingPath);

    %% --- REVISIONS BETWEEN LINES 52-62 ---
    % 1. Reconstruct image matching the dynamic offset map of the reference imaging session
    fprintf('Reconstructing refImg_refIdx matching offset map for reference session %d...\n', ops.refIdx);
    refImg_refIdx = reconstructImageFromMap(suite2pImg, refStack, matchedOffsetMap, ops.refIdx, Pix);
    fn_saveTiff(refImg_refIdx, 'refImg_refIdx.tiff', savingPath);

    % 2. Save the suite2p enhanced image at the reference session index
    refImg_refIdx_suite2p = suite2pImg(:, :, ops.refIdx);
    fn_saveTiff(refImg_refIdx_suite2p, 'refImg_refIdx_suite2p.tiff', savingPath);
    %% -------------------------------------
end 

function [offsetImg] = reconstructImage(suite2pImg, tempRefImg, offsetMap, refPosition, Pix,excludeEdge)
    if nargin == 5; excludeEdge = 10; end 
    % Get image size
    [imgHeight, imgWidth, nImg] = size(tempRefImg);
    % Determine step size for overlapping blocks (1/4 of Pix)
    stepSize = floor(Pix / 4);
    % Initialize arrays to store offsets and counts
    offsetImg = zeros(imgHeight, imgWidth);
    countMatrix = zeros(imgHeight, imgWidth);  % To count contributions per pixel
    % Define valid ranges excluding edges
    validStartY = excludeEdge + 1;
    validEndY = imgHeight - excludeEdge;
    validStartX = excludeEdge + 1;
    validEndX = imgWidth - excludeEdge;
    % Loop over blocks
    for y = validStartY:stepSize:validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
            % Extract corresponding blocks from fixed and moving images
            tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1,patchOffsetFlag); 
            tempPatch = fn_fastAlign(tempPatch,'refImg',tempRefImg(y:y+Pix-1, x:x+Pix-1,refPosition));
            % Calculate the offset between the blocks using fn_align
            
            alignedPatch = nanmean(tempPatch,3);
            % Update the offset map with the calculated offset, weighted by count
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
            
            % Update count matrix for averaging
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
        end
    end
    % Add additional blocks to ensure last rows/columns are covered
    for y = validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
            % Extract corresponding blocks from fixed and moving images
            tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1,patchOffsetFlag); 
            tempPatch = fn_fastAlign(tempPatch,'refImg',tempRefImg(y:y+Pix-1, x:x+Pix-1,refPosition));
            % Calculate the offset between the blocks using fn_align
            
            alignedPatch = nanmean(tempPatch,3);
            % Update the offset map with the calculated offset, weighted by count
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
            
            % Update count matrix for averaging
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
        end
    end
    for x = validEndX - Pix + 1
        for y = validStartY:stepSize:validEndY - Pix + 1
             patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
            % Extract corresponding blocks from fixed and moving images
            tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1,patchOffsetFlag); 
            tempPatch = fn_fastAlign(tempPatch,'refImg',tempRefImg(y:y+Pix-1, x:x+Pix-1,refPosition));
            % Calculate the offset between the blocks using fn_align
            
            alignedPatch = nanmean(tempPatch,3);
            % Update the offset map with the calculated offset, weighted by count
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
            
            % Update count matrix for averaging
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
        end
    end
     % Cover the bottom-right corner explicitly
    if validEndY - Pix + 1 > 0 && validEndX - Pix + 1 > 0
         patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
            % Extract corresponding blocks from fixed and moving images
            tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1,patchOffsetFlag); 
            tempPatch = fn_fastAlign(tempPatch,'refImg',tempRefImg(y:y+Pix-1, x:x+Pix-1,refPosition));
            % Calculate the offset between the blocks using fn_align
            
            alignedPatch = nanmean(tempPatch,3);
            % Update the offset map with the calculated offset, weighted by count
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
            
            % Update count matrix for averaging
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
    end
    offsetImg = offsetImg ./ countMatrix;
end 

%% --- NEW HELPER: RECONSTRUCT IMAGE MATCHING ARBITRARY MAP TOPOGRAPHY ---
function [offsetImg] = reconstructImageFromMap(suite2pImg, tempRefImg, offsetMap, refSessionIdx, Pix, excludeEdge)
    if nargin == 5; excludeEdge = 10; end 
    [imgHeight, imgWidth, ~] = size(tempRefImg);
    stepSize = floor(Pix / 4);

    offsetImg = zeros(imgHeight, imgWidth);
    countMatrix = zeros(imgHeight, imgWidth); 

    validStartY = excludeEdge + 1;
    validEndY = imgHeight - excludeEdge;
    validStartX = excludeEdge + 1;
    validEndX = imgWidth - excludeEdge;

    % Extract the specific 2D topographical offset matrix for the reference day
    refSessionOffsetMap = offsetMap(:, :, refSessionIdx);

    % Loop over tile blocks
    for y = validStartY:stepSize:validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            % Dynamically resolve the corresponding Z-plane mapping for this block
            refPosition = round(nanmean(nanmean(refSessionOffsetMap(y:y+Pix-1, x:x+Pix-1))));
            
            if ~isnan(refPosition) && refPosition >= 1 && refPosition <= size(tempRefImg,3)
                patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
                if ~isempty(patchOffsetFlag)
                    tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1, patchOffsetFlag); 
                    tempPatch = fn_fastAlign(tempPatch, 'refImg', tempRefImg(y:y+Pix-1, x:x+Pix-1, refPosition));
                    alignedPatch = nanmean(tempPatch, 3);
                    offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
                    countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
                end
            end
        end
    end

    % Cover boundary constraints (Last Rows)
    for y = validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            refPosition = round(nanmean(nanmean(refSessionOffsetMap(y:y+Pix-1, x:x+Pix-1))));
            
            if ~isnan(refPosition) && refPosition >= 1 && refPosition <= size(tempRefImg,3)
                patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
                if ~isempty(patchOffsetFlag)
                    tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1, patchOffsetFlag); 
                    tempPatch = fn_fastAlign(tempPatch, 'refImg', tempRefImg(y:y+Pix-1, x:x+Pix-1, refPosition));
                    alignedPatch = nanmean(tempPatch, 3);
                    offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
                    countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
                end
            end
        end
    end

    % Cover boundary constraints (Last Columns)
    for x = validEndX - Pix + 1
        for y = validStartY:stepSize:validEndY - Pix + 1
            patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
            refPosition = round(nanmean(nanmean(refSessionOffsetMap(y:y+Pix-1, x:x+Pix-1))));
            
            if ~isnan(refPosition) && refPosition >= 1 && refPosition <= size(tempRefImg,3)
                patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
                if ~isempty(patchOffsetFlag)
                    tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1, patchOffsetFlag); 
                    tempPatch = fn_fastAlign(tempPatch, 'refImg', tempRefImg(y:y+Pix-1, x:x+Pix-1, refPosition));
                    alignedPatch = nanmean(tempPatch, 3);
                    offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
                    countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
                end
            end
        end
    end

    % Cover bottom-right corner explicitly
    if validEndY - Pix + 1 > 0 && validEndX - Pix + 1 > 0
        patchOffset = squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)); 
        refPosition = round(nanmean(nanmean(refSessionOffsetMap(y:y+Pix-1, x:x+Pix-1))));
        
        if ~isnan(refPosition) && refPosition >= 1 && refPosition <= size(tempRefImg,3)
            patchOffsetFlag = find(patchOffset >= refPosition-2 & patchOffset <= refPosition+2); 
            if ~isempty(patchOffsetFlag)
                tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1, patchOffsetFlag); 
                tempPatch = fn_fastAlign(tempPatch, 'refImg', tempRefImg(y:y+Pix-1, x:x+Pix-1, refPosition));
                alignedPatch = nanmean(tempPatch, 3);
                offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedPatch;
                countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
            end
        end
    end
    offsetImg = offsetImg ./ countMatrix;
end 

function output = loadMat(datapath,fieldStr,concatFlag, normalizeFlag)
    if ~exist('fieldStr'); fieldStr = '';end 
    if ~exist('concatFlag'); concatFlag = false;end 
    if ~exist('normalizeFlag'); normalizeFlag = true;end 
    output = fn_dirFilefun(datapath, @load, '*.mat');
    if ~isempty(fieldStr); output = cellfun(@(x)(x.(fieldStr)),output,'UniformOutput',false); end 
    if strcmp(fieldStr,'meanImg')
        output = fn_cell2mat(output,3);
        if normalizeFlag && max(output(:))>1; output = output./prctile(output(:),99.8); end 
    end 
end