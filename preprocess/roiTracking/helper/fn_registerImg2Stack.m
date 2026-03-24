function [offsetMap,offsetImg,offsetX,offsetY] = fn_registerImg2Stack(refStack, testImg, Pix, excludeEdge)
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
        [offsetTemp, alignedImg, corrMetric, shift] = fn_align(fixedBlock,movingBlock);
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