function avgCorrcoeff = fn_fastRegStack(zstackCurr, zstackRef, depthDifference, reverseFlag)

nDepth = size(zstackCurr,3);
corrcoeffs = nan(1, nDepth); % depth 1-60

cropMargin = 20;

if ~exist('reverseFlag'); reverseFlag = false; end %#ok<EXIST>
% Loop through each of the 60 depths
if ~reverseFlag
    for frameIndex1 = 1:nDepth
        % Extract the current depth from day 1
        currentdepth1 = zstackRef(:, :, frameIndex1);
        
        % Extract the current depth from day 2
        frameIndex2 = frameIndex1 + depthDifference;
        if frameIndex2 >nDepth
            break;
        end
        currentdepth2 = zstackCurr(:, :, frameIndex2);
        
        %median filter denoising zstack
        currentdepthFiltered1 = medfilt2(currentdepth1,[3 3]);
        currentdepthFiltered2 = medfilt2(currentdepth2,[3 3]);
        %currentdepthFiltered1 = currentdepth1;
        %currentdepthFiltered2 = currentdepth2;
        
        %fast align
        concatenated2D = fn_fastAlign(cat(3,currentdepthFiltered1,currentdepthFiltered2));
        concatenated2D = concatenated2D(cropMargin+1:end-cropMargin,cropMargin+1:end-cropMargin,:);  

        %patchwarp_results = patchwarp_across_sessions(concatenated2D(:,:,1), concatenated2D(:,:,2), 'euclidean',...
        %        'affine', 6, 0.15, 0);
        %concatenated2D(:,:,2) = patchwarp_results.image2_warp2;
                 
        concatenated2D = reshape(concatenated2D, size(concatenated2D,1)*size(concatenated2D,2), 2);
        corrMatrix = corrcoef(concatenated2D, 'Rows', 'pairwise');  
        corrcoeff= corrMatrix(2, 1);
        % Store the correlation coefficient
        corrcoeffs(frameIndex1) = corrcoeff;
        
    end
else
    for frameIndex1 = nDepth:-1:1 % Loop backwards from 60 to 1
        % Extract the current depth from day 1
        currentdepth1 = zstackRef(:, :, frameIndex1);
        
        % Extract the current depth from day 2
        frameIndex2 = frameIndex1 - depthDifference;
        if frameIndex2 <1
            break;
        end
        currentdepth2 = zstackCurr(:, :, frameIndex2);
        
        %median filter denoising zstack
        currentdepthFiltered1 = medfilt2(currentdepth1,[3 3]);
        currentdepthFiltered2 = medfilt2(currentdepth2,[3 3]);
        %currentdepthFiltered1 = currentdepth1;
        %currentdepthFiltered2 = currentdepth2;
        %currentdepthFiltered1 = enhancedImage(currentdepth1,  [1 size(currentdepth1,1)],[1 size(currentdepth1,2)]);
        %currentdepthFiltered2 = enhancedImage(currentdepth2, [1 size(currentdepth2,1)],[1 size(currentdepth2,2)]);
        
       %fast align
        concatenated2D = fn_fastAlign(cat(3,currentdepthFiltered1,currentdepthFiltered2));
        concatenated2D = concatenated2D(cropMargin+1:end-cropMargin,cropMargin+1:end-cropMargin,:);        

        concatenated2D = reshape(concatenated2D, size(concatenated2D,1)*size(concatenated2D,2), 2);
        corrMatrix = corr(concatenated2D, 'Rows', 'pairwise');  
        corrcoeff= corrMatrix(2, 1);
        % Store the correlation coefficient
        corrcoeffs(frameIndex1) = corrcoeff;
    end
end
avgCorrcoeff = nanmean(corrcoeffs);


end