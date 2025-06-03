%% Method 1 -- load data, using unaligned and suite2p images
clear;
datapath = 'G:\rockfish\ziyi\zz153_AC\meanImg\';
refpath = [datapath '\refStack\zz153_20240604_stack1_parsed.h5'];
saveAlignment(datapath,refpath);

datapath = 'G:\rockfish\ziyi\zz153_PPC\meanImg\';
refpath = [datapath '\refStack\zz153_20240604_stack1_parsed.h5'];
saveAlignment(datapath, refpath);

%% Method 1 -- check the alignment of image of whole image
datapath = 'G:\rockfish\ziyi\zz153_PPC\meanImg\';
resultName = {'sessionAlignment_suite2p_crop0','sessionAlignment_suite2p_crop50','sessionAlignment_suite2p_crop100'};
for i = 1:length(resultName)
    results{i} = load([datapath filesep resultName{i}]);
end 
offset = cellfun(@(x)(x.offset),results,'UniFormOutput', false);offset = fn_cell2mat(offset,1);

offsetVar = var(offset,0,2); [~,bestAlign] = min(offsetVar);
midLine = median(offset(bestAlign,:));

figure; hold on; 
for i = 1:size(offset,1); plot((1:size(offset,2))+0.2*(i-1), offset(i,:) - midLine,'.'); end 
yline(0,'Color',[0.8 0.8 0.8]); yline(5,'Color',[0.8 0.8 0.8]); yline(-5,'Color',[0.8 0.8 0.8])




%% Method 2 -- register the imaging sessions with the ref stack 
clear; 
datapath = 'G:\rockfish\ziyi\zz153_PPC\meanImg\';
refpath = [datapath '\refStack\zz153_20240604_stack1_parsed.h5'];

unalignedImg = loadMat([datapath filesep '\sessionImg\']);
refStack = loadRef(refpath);
tempRefStack = refStack; 

savingPath = [datapath filesep 'offsetEvaluation'];
mkdir(savingPath);
Pix = 100;tic;
for i= 1:size(suite2pImg,3)
    for k = 1:size(refStack,3)
        [tempAligned,tempShift] = fn_fastAlign(cat(3, suite2pImg(:,:,i),tempRefStack(:,:,k)),'center');
        tempRefStack(:,:,k) = tempAligned(:,:,2);
    end 
    [offsetMap,offsetImg,offsetX,offsetY] = registerImageWithBlocksMap(tempRefStack, suite2pImg(:,:,i), Pix);
    t = toc; disp(['day ' int2str(i) ', time = ' num2str(t) ' sec'])
    save([savingPath filesep 'session_' int2str(i) '.mat'],'offsetMap','offsetImg','offsetX','offsetY');
end 


%% Method 2 -- check offset map inference


matchedImgCmp = cat(3,zeros(size(matchedImg)),zeros(size(matchedImg)));
matchedImgCmp(:,:,1:2:end) = matchedImg;  matchedImgCmp(:,:,2:2:end) = suite2pImg/5000;

%% Method 2 -- comparison with method 1, load offset 

datapath = 'G:\rockfish\ziyi\zz153_PPC\meanImg\';
resultName = {'sessionAlignment_suite2p_crop0','sessionAlignment_suite2p_crop50','sessionAlignment_suite2p_crop100'};
for i = 1:length(resultName)
    results{i} = load([datapath filesep resultName{i}]);
end 
offset = cellfun(@(x)(x.offset),results,'UniFormOutput', false);offset = fn_cell2mat(offset,1);

offsetVar = var(offset,0,2); [~,bestAlign] = min(offsetVar);
midLine = median(offset(bestAlign,:));

%% Method 2 -- load the ROI 

roi = ReadImageJROI('G:\rockfish\ziyi\zz153_PPC\meanImg\refStackAlignROI\roi38.zip');
figure; imagesc(alignedImg(:,:,143)); colormap gray; hold on;
for k = 1:length(roi) % number of neurons in this plane
    tempMask = roipoly(zeros(size(alignedImg,1),size(alignedImg,2)),roi{k}.mnCoordinates(:,2),...
        roi{k}.mnCoordinates(:,1));   
    roisMask{k} = logical(tempMask);
    roisCoord{k} = roi{k}.mnCoordinates;
    fill(roisCoord{k}(:,1),roisCoord{k}(:,2),matlabColors(1),'FaceColor','none','LineWidth',2);
end
%% Method 2 -- use reconstruction to ge the reference image
%offsetAvg = squeeze(nanmean(nanmean(matchedOffsetMap(:,:,:),1),2));
%% Method 2 -- MAIN SCRIPT HERE
clear; 

% load the alignment data

%matchedImg = loadMat('G:\rockfish\ziyi\zz153_PPC\meanImg\offsetEvaluation\','offsetImg');
matchedOffsetMap = loadMat('G:\rockfish\ziyi\zz153_PPC\archive_alignByDay\meanImg\refStack\offsetEvaluation');
% After this, save the image to draw roi
stackROI = struct(); 

stackROI.datapath = 'G:\rockfish\ziyi\zz153_PPC\meanImg\';
[stackROI.refStack,~] = loadRef('G:\rockfish\ziyi\zz153_PPC\meanImg\refStack\zz153_20240604_stack1_parsed.h5');
stackROI.suite2pImg = loadSuite2p([datapath filesep '\registeredImg_simpleElastix']) ;

stackROI.suite2pRefIdx = 75; % which session of suite2p is used as suite2p reference
stackROI.suite2pRefImg = stackROI.suite2pImg(:,:,stackROI.suite2pRefIdx); % which session of suite2p is used as suite2p reference
stackROI.refStackSelLoc = [28 33 38 43 48 53];
stackROI.refStackMeanIdx = 2:4;

stackROI.refStackAligned = stackROI.refStack;
for k = 1:size(refStack,3)
    [tempAligned,tempShift] = fn_fastAlign(cat(3, stackROI.suite2pRefImg,refStack(:,:,k)),'center');
    stackROI.refStackAligned(:,:,k) = tempAligned(:,:,2);
    stackROI.refStackAlignedT(k,:) = tempShift(2,:);
end 
%%
reconstructImageSave(stackROI);
% Here put in another GUI for roi tracking confirmation

% ROI that are tracked are adapted for each suite2p session image

matchedRoi = {}; roi = struct(); 
stackROI.imageJ = ReadImageJROI('G:\rockfish\ziyi\zz153_PPC\meanImg\refStackAlignROI_reconstruct\roiMean.zip');
[stackROI.maskRaw,stackROI.coordRaw,stackROI.centroidRaw] = convertROIcoord(stackROI.imageJ,stackROI.suite2pImg(:,:,1)); 
roiRefImg = double(imread([datapath '\refStackAlignROI_reconstruct\refImg_mean.tiff' ]))/65536;

for k = 1:size(stackROI.suite2pImg,3)
    disp(k);
    tempOffsetMap = matchedOffsetMap(:,:,k);
    matchedRoi{k} = projectROI(roi, stackROI.refStackSelLoc, stackROI.suite2pImg(:,:,k), matchedOffsetMap(:,:,k),roiRefImg, Pix);
end 

% finally visualize a whole FOV is wnated (optional)
%selDay = 10; 
%plotProjectedROI(suite2pImg(:,:,selDay),matchedRoi{selDay}); 

%% Method 2 -- use reconstruction to 
offsetAvg = squeeze(nanmean(nanmean(matchedOffsetMap(:,:,:),1),2));

savingPath = datapath;
refIdx = 75;
refImg = suite2pImg(:,:,refIdx)/5000;
Pix = 100;tic;
refStackSelLoc = [33 38 43 48];
offsetImg = {};
for k = 1:size(suite2pImg,3)
    [tempAligned,tempShift] = fn_fastAlign(cat(3, refImg,suite2pImg(:,:,k)),'center');
    suite2pImg(:,:,k) = tempAligned(:,:,2);

end 
for k = 1:size(refStack,3)
    [tempAligned,tempShift] = fn_fastAlign(cat(3, refImg,refStack(:,:,k)),'center');
    refStack(:,:,k) = tempAligned(:,:,2);
end 

%% visualize the result of roi porjection
matchedRoi = {}; roi = struct(); 
roi.imageJ = ReadImageJROI('G:\rockfish\ziyi\zz153_PPC\meanImg\refStackAlignROI_reconstruct\roiMean.zip');
[roi.mask,roi.coord,roi.centroid] = convertROIcoord(roi.imageJ,suite2pImg(:,:,1)); 
roiRefImg = double(imread([datapath '\refStackAlignROI_reconstruct\refImg_mean.tiff' ]))/65536;

for k = 1:size(suite2pImg,3)
    disp(k);
    tempOffsetMap = stackROI.offsetMap(:,:,k);
    matchedRoi{k} = projectROI(roi, stackROI.refStackSelLoc, stackROI.suite2pImg(:,:,k), stackROI.offsetMap(:,:,k),roiRefImg, 100);
end 
%%
selDay = 150; 
plotProjectedROI(stackROI.suite2pImg(:,:,selDay),matchedRoi{selDay}); 

%% Method 2 -- 
savingPath = [datapath filesep 'refStackAlignROI'];
save([savingPath filesep 'refStack.mat'],'refStack');

refIdx = 75; stackIdx= 38; 
refImg = suite2pImg(:,:,refIdx)/5000;
tic;


[tempAligned,tempShift] = fn_fastAlign(cat(3, refImg,refStack(:,:,stackIdx)),'center');
for i = 1:size(refStack,3)
    refStack(:,:,i) =  circshift(refStack(:,:,i),tempShift(2,:));
end 

save([savingPath filesep 'refStack_aligned.mat'],'refStack')
refStackSelLoc = [33 38 43];
for i= 1:length(refStackSelLoc)

    fn_saveTiff(refStack(:,:,refStackSelLoc(i)),['refImg' int2str(refStackSelLoc(i)) '.tiff'], savingPath);

end 



%% 
offsetAvg = squeeze(nanmean(nanmean(matchedOffsetMap(:,:,:),1),2));
figure; plot(offsetAvg-median(offsetAvg),'.'); hold on; plot(offset(3,:)-median(offsetAvg),'.');
figure; plot(offsetAvg,'.');
%% all functions
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

function output = loadSuite2p(suite2ppath)
    suite2ppath = [suite2ppath filesep '\suite2p\plane0'];
    load([suite2ppath filesep 'Fall.mat'],'ops','ops_matlab'); if ~exist('ops'); ops = ops_matlab; end
    
    fileID = fopen([suite2ppath filesep 'data.bin'],'r'); % open binary file 
    output = fread(fileID,inf,'*int16');
    output = double(reshape(output,ops.Lx,ops.Ly,[]));
    output = permute(output, [2, 1, 3]); %output = output(:,:,1:2:end);
    output = output/5000;
end 


function saveAlignment(datapath, refpath)

    unalignedImg = loadMat([datapath filesep '\sessionImg\']);
    suite2pImg = loadSuite2p([datapath filesep '\registeredImg_simpleElastix']) ;
    
    refStack = loadRef(refpath); %[datapath '\refStack\zz159_20240707_stack1_parsed.h5']); 

    overallCrop = [0 50 100];
    for j = 1:length(overallCrop)
        [offset,alignedImg_matched,corrMetric] = align(unalignedImg,refStack,overallCrop(j));
        save([datapath filesep 'sessionAlignment_raw_crop' int2str(overallCrop(j)) '.mat'],'unalignedImg','alignedImg_matched','corrMetric','offset')
        [offset,alignedImg_matched,corrMetric] = align(suite2pImg,refStack,overallCrop(j));
        save([datapath filesep 'sessionAlignment_suite2p_crop' int2str(overallCrop(j)) '.mat'],'suite2pImg','alignedImg_matched','corrMetric','offset')
    end 
end 
function [offset,alignedImg_matched,corrMetric] = align(testImg,refStack,overallCrop)
    if nargin==2; overallCrop = 0; end 
    offset = []; alignedImg = {};corrMetric = {};
    for i = 1:size(testImg,3)
        tempRefStack = refStack; 
        for k = 1:size(refStack,3)
                       
            [tempAligned,tempShift] = fn_fastAlign(cat(3, testImg(:,:,i),tempRefStack(:,:,k)),'center');
            tempRefStack(:,:,k) = tempAligned(:,:,2);
        end 
        tic; [offset(i),alignedImg{i},corrMetric{i}] = registerImageWithBlocks(tempRefStack, testImg(:,:,i),overallCrop); t=toc;
        disp(['day ' int2str(i) ', time = ' num2str(t) ' sec'])
    end 

    size1 = min(cellfun(@(x)(size(x,1)),alignedImg));
    size2 = min(cellfun(@(x)(size(x,2)),alignedImg));
    alignedImg_matched = nan(size1,size2,length(alignedImg));
    for i = 1:length(alignedImg)
        tempCut =  (size(alignedImg{i},1) - size1)/2;
        alignedImg_matched(:,:,i) = alignedImg{i}(tempCut+1:end-tempCut,tempCut+1:end-tempCut);
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

function [offset,alignedImg,corrMetric] = registerImageWithBlocks(fixedImage, movingImage,overallCrop)
    [offset,alignedImg, corrMetric ] = fn_align(fixedImage(overallCrop+1:end-overallCrop,overallCrop+1:end-overallCrop,:),...
        movingImage(overallCrop+1:end-overallCrop,overallCrop+1:end-overallCrop));
end 

function [offsetMap,offsetImg,offsetX,offsetY] = registerImageWithBlocksMap(refStack, testImg, Pix, excludeEdge)
    % Registers a moving image to a fixed image using block-wise offsets.
    % Inputs:
    %   refStack - Fixed reference image stack (imgHeight x imgWidth x nImg)
    %   testImg - Moving image to align (imgHeight x imgWidth)
    %   Pix - Block size (assumes square blocks, Pix x Pix)
    %   excludeEdge - Number of pixels to exclude from edges
    % Output:
    %   offsetMap - Smoothed offset map for the whole image, with edges padded with NaN
    if nargin == 3; excludeEdge = 10; end 
    % Get image size
    [imgHeight, imgWidth, nImg] = size(refStack);

    % Determine step size for overlapping blocks (1/4 of Pix)
    stepSize = floor(Pix / 4);

    % Initialize arrays to store offsets and counts
    offset = zeros(imgHeight, imgWidth);
    offsetImg = zeros(imgHeight, imgWidth);
    offsetX = zeros(imgHeight, imgWidth);
    offsetY = zeros(imgHeight, imgWidth);
    countMatrix = zeros(imgHeight, imgWidth);  % To count contributions per pixel

    % Define valid ranges excluding edges
    validStartY = excludeEdge + 1;
    validEndY = imgHeight - excludeEdge;
    validStartX = excludeEdge + 1;
    validEndX = imgWidth - excludeEdge;

    % Loop over blocks
    for y = validStartY:stepSize:validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            % Extract corresponding blocks from fixed and moving images
            fixedBlock = refStack(y:y+Pix-1, x:x+Pix-1, :);
            movingBlock = testImg(y:y+Pix-1, x:x+Pix-1);

            % Calculate the offset between the blocks using fn_align
            
            [offsetTemp, alignedImg, corrMetric, shift] = fn_align(fixedBlock, movingBlock);  % Assume offset is [dy, dx]
            
            % Update the offset map with the calculated offset, weighted by count
            offset(y:y+Pix-1, x:x+Pix-1) = offset(y:y+Pix-1, x:x+Pix-1) + offsetTemp;
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedImg;
            offsetX(y:y+Pix-1, x:x+Pix-1) = offsetX(y:y+Pix-1, x:x+Pix-1) + shift(1);
            offsetY(y:y+Pix-1, x:x+Pix-1) = offsetY(y:y+Pix-1, x:x+Pix-1) + shift(2);
            
            % Update count matrix for averaging
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
        end
    end

    % Add additional blocks to ensure last rows/columns are covered
    for y = validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            fixedBlock = refStack(y:y+Pix-1, x:x+Pix-1, :);
            movingBlock = testImg(y:y+Pix-1, x:x+Pix-1);
            [offsetTemp, alignedImg, corrMetric, shift] = fn_align(fixedBlock, movingBlock);
            offset(y:y+Pix-1, x:x+Pix-1) = offset(y:y+Pix-1, x:x+Pix-1) + offsetTemp;
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedImg;
            offsetX(y:y+Pix-1, x:x+Pix-1) = offsetX(y:y+Pix-1, x:x+Pix-1) + shift(1);
            offsetY(y:y+Pix-1, x:x+Pix-1) = offsetY(y:y+Pix-1, x:x+Pix-1) + shift(2);
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;

        end
    end

    for x = validEndX - Pix + 1
        for y = validStartY:stepSize:validEndY - Pix + 1
            fixedBlock = refStack(y:y+Pix-1, x:x+Pix-1, :);
            movingBlock = testImg(y:y+Pix-1, x:x+Pix-1);
            [offsetTemp, alignedImg, corrMetric, shift] = fn_align(fixedBlock,movingBlock);
            offset(y:y+Pix-1, x:x+Pix-1) = offset(y:y+Pix-1, x:x+Pix-1) + offsetTemp;
            offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedImg;
            offsetX(y:y+Pix-1, x:x+Pix-1) = offsetX(y:y+Pix-1, x:x+Pix-1) + shift(1);
            offsetY(y:y+Pix-1, x:x+Pix-1) = offsetY(y:y+Pix-1, x:x+Pix-1) + shift(2);
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;

        end
    end

     % Cover the bottom-right corner explicitly
    if validEndY - Pix + 1 > 0 && validEndX - Pix + 1 > 0
        y = validEndY - Pix + 1;
        x = validEndX - Pix + 1;
        fixedBlock = refStack(y:y+Pix-1, x:x+Pix-1, :);
        movingBlock = testImg(y:y+Pix-1, x:x+Pix-1);
        [offsetTemp, alignedImg, corrMetric, shift] = fn_align(movingBlock, fixedBlock);
        offset(y:y+Pix-1, x:x+Pix-1) = offset(y:y+Pix-1, x:x+Pix-1) + offsetTemp;
        offsetImg(y:y+Pix-1, x:x+Pix-1) = offsetImg(y:y+Pix-1, x:x+Pix-1) + alignedImg;
        offsetX(y:y+Pix-1, x:x+Pix-1) = offsetX(y:y+Pix-1, x:x+Pix-1) + shift(1);
        offsetY(y:y+Pix-1, x:x+Pix-1) = offsetY(y:y+Pix-1, x:x+Pix-1) + shift(2);

        countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
    end

    % Average the offset map by dividing by the count matrix
    offset = offset ./ countMatrix;
    offsetImg = offsetImg ./ countMatrix;
    offsetX = offsetX ./ countMatrix;
    offsetY = offsetY ./ countMatrix;

    % Pad the excluded edges with NaN
    offsetMap = nanEdge(offset);

    function mat = nanEdge(mat)
        mat(1:excludeEdge, :) = NaN;                     % Top edge
        mat(end-excludeEdge+1:end, :) = NaN;             % Bottom edge
        mat(:, 1:excludeEdge) = NaN;                     % Left edge
        mat(:, end-excludeEdge+1:end) = NaN;             % Right edge
    end 
end



function [offset,alignedImg, corrMetric, outShift ]= fn_align(fixedBlock,movingBlock)

    corrMetric = nan(size(fixedBlock,3),1);
    alignedImg = {}; shift = {};
    for i = 1:size(fixedBlock,3)
        temp = fixedBlock(:,:,i); tempAligned = cat(3,movingBlock,temp);
        [tempAligned,tempShift] = fn_fastAlign(tempAligned,'center');
        alignedImg{i} = tempAligned(:,:,2) ; shift{i} = tempShift; 
        tempCrop = max(abs(tempShift),[],1);
        tempAligned = tempAligned(tempCrop+1:end-tempCrop,tempCrop+1:end-tempCrop,:);
        %tempAligned(:,:,2) = fn_fastAlignTwoImgPatchwarp(tempAligned(:,:,1),tempAligned(:,:,2));
        a = reshape(tempAligned,size(tempAligned,1)*size(tempAligned,2),[]);
        d = corr(a); corrMetric(i) = d(end,1);
    end 
    midIdx = floor(size(fixedBlock,3)/2);
    [tempIdx, tempVal] = fn_findLongestAsymptote(smoothdata(corrMetric,'movmean',3),0.006);
    if mod(length(tempIdx),2) == 1; offset = median(tempIdx); 
    elseif tempVal(2)>tempVal(1); offset = ceil(median(tempIdx)); 
    else offset = floor(median(tempIdx)); end
    try
        alignedImg = alignedImg{int16((offset))};
        outShift = shift{int16(offset)}(2,:); 
    catch
        disp('?');
    end
end 

function [matchedRoi] = projectROI(roi, offsetRange, suite2pImg, offsetMap,refStack, Pix, excludeEdge)
    if nargin == 6; excludeEdge = 10; end 
    % Get image size
    [imgHeight, imgWidth, nImg] = size(suite2pImg);

    % Determine step size for overlapping blocks (1/4 of Pix)
    stepSize = Pix ;
    roiImgSize = 20; 
    % Define valid ranges excluding edges
    validStartY = excludeEdge + 1;
    validEndY = imgHeight - excludeEdge;
    validStartX = excludeEdge + 1;
    validEndX = imgWidth - excludeEdge;

    % take note of which ROI is here
    matchedRoi = roi;
    matchedRoi.ishere = zeros(1,length(roi.coord));
    roiCenter = fn_cell2mat(roi.centroid,1);
    
    % Loop over blocks
    for y = validStartY:stepSize:validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
            patchOffset = (squeeze(nanmean(nanmean(offsetMap(y:y+Pix-1, x:x+Pix-1, :),1),2)));
            roiPathFlag = find(roiCenter(:,1) >= x & roiCenter(:,1) <= x+Pix-1 & roiCenter(:,2) >= y & roiCenter(:,2) <= y+Pix-1);

            % get the patch images and align if needed
            tempPatch = suite2pImg(y:y+Pix-1, x:x+Pix-1); 
            %tempPatchRef = refStack(y:y+Pix-1, x:x+Pix-1,round(patchOffset));
            tempPatchRef = refStack(y:y+Pix-1, x:x+Pix-1);
            noiseEst = fspecial('laplacian',0.2);  % Example high-pass filter (edge detection)
            highFreqImg = imfilter(double(tempPatch), noiseEst, 'replicate');
        
            % Measure the noise level as the standard deviation of the high-pass image
            %noiseEst = std(highFreqImg(:)); noiseThreshold = 0.14; 
            %if noiseEst>noiseThreshold; disp('noise too high'); end 
            
            if patchOffset >= min(offsetRange)-2 && patchOffset <= max(offsetRange)+2 
                matchedRoi.ishere(roiPathFlag) = 1; 
                % Update the roi coordinates     
                for k = 1:length(roiPathFlag)
                    selX = round(matchedRoi.centroid{k}(1)) - roiImgSize : round(matchedRoi.centroid{k}(1)) + roiImgSize;
                    selY = round(matchedRoi.centroid{k}(2)) - roiImgSize : round(matchedRoi.centroid{k}(2)) + roiImgSize;
                    tempRef = refStack(selX,selY); tempSuite2p = suite2pImg(selX,selY);
                    try
                        [tempAligned,tempCoord] = fn_fastAlign(cat(3,tempRef,tempSuite2p),'refImg',tempRef);
                    catch
                        tempCoord = zeros(2,2);
                    end 
                    matchedRoi.coord{roiPathFlag(k)}(:,1) = matchedRoi.coord{roiPathFlag(k)}(:,1)-tempCoord(2,1);
                    matchedRoi.coord{roiPathFlag(k)}(:,2) = matchedRoi.coord{roiPathFlag(k)}(:,2)-tempCoord(2,2);
                end 
            end 
        end
    end
end 

function [roisMask,roisCoord,roisCentroid] = convertROIcoord(roi,alignedImg)
    roisMask = cell(roi);roisCoord = cell(roi);roisCentroid = cell(roi);
    for k = 1:length(roi) % number of neurons in this plane
    tempMask = roipoly(zeros(size(alignedImg,1),size(alignedImg,2)),roi{k}.mnCoordinates(:,2),...
        roi{k}.mnCoordinates(:,1));   
    roisMask{k} = logical(tempMask);
    roisCoord{k} = roi{k}.mnCoordinates;
    [x,y] = centroid(polyshape(roisCoord{k}(:,1),roisCoord{k}(:,2)));
    roisCentroid{k} = [x,y];

    end 
end

function plotProjectedROI(img, roi)

figure; imagesc(img); colormap gray; hold on; 
for k = 1:length(roi.coord) % number of neurons in this plane
    if logical(roi.ishere(k))
        fill(roi.coord{k}(:,1),roi.coord{k}(:,2),matlabColors(1),'FaceColor','none','LineWidth',2);
    end 
end
end 

function reconstructImageSave(stackROI)
    savingPath = [datapath '\refStackAlignROI_reconstruct\'];
    
    refStack = stackROI.refStackAligned;
    suite2pImg = stackROI.suite2pImg;
    matchedOffsetMap = stackROI.matchedOffsetMap;

    Pix = 100;
    tic;
    refStackSelLoc = roi.refStackSelLoc; %[28 33 38 43 48 53];
    refStackMeanIdx = roi.refStackMeanIdx; %2:4;
    offsetImg = {};

    for i= 1:length(refStackSelLoc)
        [offsetImg{i}] = reconstructImage(suite2pImg, refStack, matchedOffsetMap, refStackSelLoc(i),Pix);
        t = toc; disp(['day ' int2str(i) ', time = ' num2str(t) ' sec'])
        % revise this line (buld a new function) so that we take the average of the image patches (after alignment to z-position), not just select one 
        fn_saveTiff(offsetImg{i},['refImg' int2str(refStackSelLoc(i)) '.tiff'], savingPath);
       
    end 
    tempMeanImg = fn_cell2mat(offsetImg,3);
    meanImg = nanmean(tempMeanImg(:,:,refStackMeanIdx),3);
    fn_saveTiff(meanImg,'refImg_mean.tiff', savingPath);

    refStackSel = refStack(:,:,refStackSelLoc); 
    save([savingPath 'refStack_aligned.mat'],'refStackSel','refStack','refStackSelLoc');

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

