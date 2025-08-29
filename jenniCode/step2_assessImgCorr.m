function [corrMap,imgTracking, corrVal] = step2_assessImgCorr(imgMat,varargin)
global corrMethod;
p = inputParser();  p.KeepUnmatched = true;
addParameter(p, 'corrMethod', 'default', @(x) ischar(x) || isstring(x));
addParameter(p, 'medianFilterSize', [], @(x) isnumeric(x) );
addParameter(p, 'refIdx', [], @(x) isnumeric(x) );
parse(p, varargin{:});

% adjust the correlation method
corrMethod = p.Results.corrMethod; 
filterSize = p.Results.medianFilterSize; 
% do a median filtering of the image
if ~isempty(filterSize); imgMat = filterImage(imgMat,filterSize); end

% compute the correlation over the whole image
imgCrop = 20; 
img_flat = imgMat(imgCrop:end-imgCrop,imgCrop:end-imgCrop,:);
img_flat = reshape(img_flat,size(img_flat,1)*size(img_flat,2),[]);
corrVal = corr(img_flat);

% step 1 -- compute pixel wide correlation
Pix = 100;  refIdx = p.Results.refIdx; 
if isempty(refIdx); [~, refIdx] = max(sum(corrVal,1)); end
refImg = imgMat(:,:,refIdx); corrMap = nan(size(imgMat));
for i = 1:size(imgMat,3); corrMap(:,:,i) = fn_patchCorr(refImg, imgMat(:,:,i), Pix); end 


% step 2 -- plot the tracked and untracked part of the image
imgTracking.trackedImg = imgMat;
imgTracking.unTrackedImg = imgMat;
imgTracking.threshold  = 0.65; 
for i = 1:size(imgMat,3)
    tempHere = imgMat(:,:,i);
    flag = corrMap(:,:,i) < imgTracking.threshold;
    tempHere(flag) = nan; 
    imgTracking.trackedImg(:,:,i) = tempHere;

    tempNotHere = imgMat(:,:,i);
    tempNotHere(~flag) = nan; 
    imgTracking.unTrackedImg(:,:,i) = tempNotHere;
end 

end 

%% functions 
function img = filterImage(img,filterSize)

    for i = 1:size(img,3)
        img(:,:,i) = medfilt2(img(:,:,i),filterSize);
    end

end 


function [corrVal] = fn_patchCorr(refStack, testImg, Pix, excludeEdge)
    % Registers a moving image to a fixed image using block-wise offsets.
    % Inputs:
    %   refStack - Fixed reference image stack (imgHeight x imgWidth x nImg)
    %   testImg - Moving image to align (imgHeight x imgWidth)
    %   Pix - Block size (assumes square blocks, Pix x Pix)
    %   excludeEdge - Number of pixels to exclude from edges
    % Output:
    %   offsetMap - Smoothed offset map for the whole image, with edges padded with NaN
    if nargin == 3; excludeEdge = 0; end 
    % Get image size
    [imgHeight, imgWidth, nImg] = size(refStack);

    % Determine step size for overlapping blocks (1/4 of Pix)
    stepSize = floor(Pix / 4);

    % Initialize arrays to store offsets and counts
    corrVal = zeros(imgHeight, imgWidth);
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
            [corrVal,countMatrix] = patchFn(refStack,testImg,x,y,corrVal,countMatrix);
        end
    end

    % Add additional blocks to ensure last rows/columns are covered
    for y = validEndY - Pix + 1
        for x = validStartX:stepSize:validEndX - Pix + 1
           [corrVal,countMatrix] = patchFn(refStack,testImg,x,y,corrVal,countMatrix);

        end
    end

    for x = validEndX - Pix + 1
        for y = validStartY:stepSize:validEndY - Pix + 1
            [corrVal,countMatrix] = patchFn(refStack,testImg,x,y,corrVal,countMatrix);

        end
    end

     % Cover the bottom-right corner explicitly
    if validEndY - Pix + 1 > 0 && validEndX - Pix + 1 > 0
        y = validEndY - Pix + 1;
        x = validEndX - Pix + 1;
        [corrVal,countMatrix] = patchFn(refStack,testImg,x,y,corrVal,countMatrix);
    end

    % Average the offset map by dividing by the count matrix
    corrVal = corrVal ./ countMatrix;
    % Pad the excluded edges with NaN
    corrVal = nanEdge(corrVal);

    function mat = nanEdge(mat)
        mat(1:excludeEdge, :) = NaN;                     % Top edge
        mat(end-excludeEdge+1:end, :) = NaN;             % Bottom edge
        mat(:, 1:excludeEdge) = NaN;                     % Left edge
        mat(:, end-excludeEdge+1:end) = NaN;             % Right edge
    end 

    function [corrVal,countMatrix] = patchFn(refStack,testImg,x,y,corrVal,countMatrix)
        global corrMethod; 
        fixedBlock = refStack(y:y+Pix-1, x:x+Pix-1);
        movingBlock = testImg(y:y+Pix-1, x:x+Pix-1);
        alignedImg = fn_fastAlign(cat(3,fixedBlock,movingBlock));
        
        fixedBlock = alignedImg(:,:,1); movingBlock = alignedImg(:,:,2);
        switch corrMethod
            case 'gaussian'
                corrValtemp = fn_corrGaussian(fixedBlock,movingBlock);
            case 'default'
                corrValtemp = corr(fixedBlock(:),movingBlock(:));
        end 
        corrVal(y:y+Pix-1, x:x+Pix-1) = corrVal(y:y+Pix-1, x:x+Pix-1) + corrValtemp;   
        % Update count matrix for averaging
        countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;

    end

end

