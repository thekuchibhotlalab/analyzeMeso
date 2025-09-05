function offsetMap = fn_estimateOffsetPatch(refStack, movingImage, Pix)
    % Registers a moving image to a fixed image using block-wise offsets.
    % Inputs:
    %   fixedImage - Fixed reference image
    %   movingImage - Moving image to align
    %   Pix - Block size (assumes square blocks, Pix x Pix)
    %   fn_align - Handle to function that calculates the z-offset between patches
    % Output:
    %   offsetMap - Smoothed offset map for the whole image

    % Get image size
    [imgHeight, imgWidth] = size(refStack);

    % Determine step size for overlapping blocks (1/4 of Pix)
    stepSize = floor(Pix / 4);

    % Initialize arrays to store offsets and counts
    offsetX = zeros(imgHeight, imgWidth);
    offsetY = zeros(imgHeight, imgWidth);
    countMatrix = zeros(imgHeight, imgWidth);  % To count contributions per pixel

    % Loop over blocks in the moving and fixed images
    for y = 1:stepSize:imgHeight - Pix + 1
        for x = 1:stepSize:imgWidth - Pix + 1
            % Extract corresponding blocks from fixed and moving images
            fixedBlock = refStack(y:y+Pix-1, x:x+Pix-1);
            movingBlock = movingImage(y:y+Pix-1, x:x+Pix-1);

            % Calculate the offset between the blocks using fn_align
            offset = fn_align(fixedBlock, movingBlock);  % Assume offset is [dy, dx]

            % Update the offset map with the calculated offset, weighted by count
            offsetX(y:y+Pix-1, x:x+Pix-1) = offsetX(y:y+Pix-1, x:x+Pix-1) + offset(2);
            offsetY(y:y+Pix-1, x:x+Pix-1) = offsetY(y:y+Pix-1, x:x+Pix-1) + offset(1);
            
            % Update count matrix for averaging
            countMatrix(y:y+Pix-1, x:x+Pix-1) = countMatrix(y:y+Pix-1, x:x+Pix-1) + 1;
        end
    end

    % Calculate the averaged offset map by dividing by the count matrix
    offsetX = offsetX ./ countMatrix;
    offsetY = offsetY ./ countMatrix;

    % Combine the offset components into a single offset map (optional)
    offsetMap = cat(3, offsetY, offsetX);  % offsetMap(:,:,1) for Y, offsetMap(:,:,2) for X

    % Optional: Smooth the offset map to create a uniform transformation
    offsetMap(:,:,1) = imgaussfilt(offsetMap(:,:,1), Pix/2);  % Smoothing on Y-offsets
    offsetMap(:,:,2) = imgaussfilt(offsetMap(:,:,2), Pix/2);  % Smoothing on X-offsets
end
