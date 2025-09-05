function step4_saveMeanImg4ROI(datapath)

load([datapath filesep 'ops.mat'],'ops');
load([datapath filesep 'alignedOps.mat' ],'alignedOps');

matchedOffsetMap = loadMat([ops.roiTrackingPath '\offsetEvaluation']);
% After this, save the image to draw roi

refpath = [ops.roiTrackingPath filesep 'refStack' ];
refName = dir([refpath filesep '*.h5']);  refName = refName(1).name;
ops.refStackPath = [refpath filesep refName];
ops.refStack = loadRef(ops.refStackPath);

ops.suite2pRefImg = alignedOps.suite2pImg(:,:,ops.refIdx); % which session of suite2p is used as suite2p reference

offsetMap = cellfun(@(x)(x.offsetMap),matchedOffsetMap,'UniformOutput',false);
offsetMap = fn_cell2mat(offsetMap,3);
ops.offsetMap = offsetMap;
avgOffset = squeeze(nanmean(nanmean(offsetMap,1),2));
selMean = round(mean(avgOffset));

ops.refStackSelLoc = selMean-15:5:selMean+15;
ops.refStackSelLocMeanIdx = 3:5;

ops.refStackAligned = ops.refStack;
for k = 1:size(ops.refStack,3)
    [tempAligned,tempShift] = fn_fastAlign(cat(3, ops.suite2pRefImg,ops.refStack(:,:,k)),'center');
    ops.refStackAligned(:,:,k) = tempAligned(:,:,2);
    ops.refStackAlignedT(k,:) = tempShift(2,:);
end 

reconstructImageSave(ops,alignedOps);

save([datapath filesep 'ops.mat' ],'ops');

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

function [meanStack_enhanced,meanStack] = loadRef(refname)
    if strcmp(refname(end-1:end),'h5')
        refStack = double(h5read(refname, '/data', [1 1 1], [Inf Inf Inf]));
    else; disp('FILENAME IS NOT h5, check'); end
    
    framePerPlane = 20;
    refStack = reshape(refStack,size(refStack,1),size(refStack,2),framePerPlane,[]);
    meanStack = nan(size(refStack,1),size(refStack,2),size(refStack,3));
    meanStack_enhanced = nan(size(refStack,1),size(refStack,2),size(refStack,3));
    for i = 1:size(refStack,4)
        tempStack = fn_fastAlign(refStack(:,:,:,i));
        meanStack(:,:,i) = imboxfilt(nanmean(tempStack,3),[3 3]);
        meanStack_enhanced(:,:,i) = enhancedImage(meanStack(:,:,i),6);
    end 
    meanStack = fn_fastAlign(meanStack,'center');
    meanStack_enhanced = fn_fastAlign(meanStack_enhanced,'center');
end 