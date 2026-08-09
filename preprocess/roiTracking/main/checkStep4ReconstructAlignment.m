function checkStep4ReconstructAlignment(datapath,Pix,stepSize)
% Check whether the reconstructed ROI reference image is aligned to Suite2p.
% Positive shift values are the row/column shift applied to the reconstructed
% reference image to align it to the Suite2p reference session image.

if nargin < 2 || isempty(Pix); Pix = 40; end
if nargin < 3 || isempty(stepSize); stepSize = floor(Pix/2); end

load([datapath filesep 'ops.mat'],'ops');
load([datapath filesep 'alignedOps.mat'],'alignedOps');

refPath = [ops.roiTrackingPath filesep 'refStackReconstruct' filesep 'refImg_refIdx.tiff'];
if ~exist(refPath,'file')
    error('Could not find %s. Run step4_saveMeanImg4ROI first.',refPath);
end

suite2pRef = alignedOps.suite2pImg(:,:,ops.refIdx);
refImg = double(imread(refPath));
if max(refImg(:)) > 1
    refImg = refImg ./ 65536;
end

[globalAligned,globalShift] = fn_fastAlign(cat(3,suite2pRef,refImg),'center');
[shiftRow,shiftCol,corrMap,centerRow,centerCol] = localShiftMap(suite2pRef,globalAligned(:,:,2),Pix,stepSize);

figure('Name','Step 4 reconstruction vs Suite2p reference','NumberTitle','off');
subplot(2,2,1);
imagesc(suite2pRef); axis image off; colormap gray;
title(sprintf('Suite2p ref session %d',ops.refIdx));

subplot(2,2,2);
imagesc(globalAligned(:,:,2)); axis image off; colormap gray;
title(sprintf('Reconstructed refIdx, global shift [%0.1f %0.1f]',globalShift(2,1),globalShift(2,2)));

subplot(2,2,3);
imagesc(suite2pRef - globalAligned(:,:,2)); axis image off; colormap redblue;
title('Suite2p - reconstructed');

subplot(2,2,4);
imagesc(suite2pRef); axis image off; colormap gray; hold on;
quiver(centerCol,centerRow,shiftCol,shiftRow,0,'r','LineWidth',1);
title(sprintf('Local shifts, median abs = %0.2f px',median(abs([shiftRow(:); shiftCol(:)]),'omitnan')));

figure('Name','Step 4 local alignment diagnostics','NumberTitle','off');
subplot(1,3,1); imagesc(shiftRow); axis image; colorbar; title('Row shift');
subplot(1,3,2); imagesc(shiftCol); axis image; colorbar; title('Column shift');
subplot(1,3,3); imagesc(corrMap); axis image; colorbar; title('Local correlation');

end

function [shiftRow,shiftCol,corrMap,centerRow,centerCol] = localShiftMap(fixedImg,movingImg,Pix,stepSize)
excludeEdge = 10;
[imgHeight,imgWidth] = size(fixedImg);
rowStarts = getBlockStarts(excludeEdge+1,imgHeight-excludeEdge,Pix,stepSize);
colStarts = getBlockStarts(excludeEdge+1,imgWidth-excludeEdge,Pix,stepSize);

shiftRow = nan(length(rowStarts),length(colStarts));
shiftCol = nan(length(rowStarts),length(colStarts));
corrMap = nan(length(rowStarts),length(colStarts));
centerRow = nan(length(rowStarts),length(colStarts));
centerCol = nan(length(rowStarts),length(colStarts));

for r = 1:length(rowStarts)
    for c = 1:length(colStarts)
        rowIdx = rowStarts(r):rowStarts(r)+Pix-1;
        colIdx = colStarts(c):colStarts(c)+Pix-1;
        fixedBlock = fixedImg(rowIdx,colIdx);
        movingBlock = movingImg(rowIdx,colIdx);
        try
            [alignedBlock,localShift] = fn_fastAlign(cat(3,fixedBlock,movingBlock),'center');
            shiftRow(r,c) = localShift(2,1);
            shiftCol(r,c) = localShift(2,2);
            movingAlignedBlock = alignedBlock(:,:,2);
            tempCorr = corr([fixedBlock(:), movingAlignedBlock(:)],'rows','complete');
            corrMap(r,c) = tempCorr(1,2);
        catch
            shiftRow(r,c) = nan;
            shiftCol(r,c) = nan;
            corrMap(r,c) = nan;
        end
        centerRow(r,c) = mean(rowIdx);
        centerCol(r,c) = mean(colIdx);
    end
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
