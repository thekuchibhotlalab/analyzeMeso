function handles=fn_runStackAlign(handles)

    tic; 
    handles.meanImg = cell(1,handles.nROI);
    zstackCurr = tiffreadVolume( handles.currName,'PixelRegion', {[1 inf], [1 inf], [1 1 300]});
    disp('loading complete!');

    roiOps.nROI = handles.nROI;
    roiOps.roiLen = handles.roiLen;
    [roiMovies, ~] = fn_splitFOV(zstackCurr, roiOps);

    for i = 1:handles.nROI
        meanImgCurr = fn_fastAlignROI(roiMovies{i});
        handles.meanImg{i} = meanImgCurr; 
        fn_runStackAlignROI(meanImgCurr,handles.zstackRef{i});
        disp(['Loading ROI #' int2str(i) ' done!']);
    end    
    toc; disp('Alignment Done!')
end

function zstack_aligned = fn_fastAlignROI(zstack)
zstack_aligned = fn_fastAlign(zstack);
zstack_aligned = nanmean(zstack_aligned,3);
zstack_aligned = enhancedImage(zstack_aligned);
end

function fn_runStackAlignROI(meanImgCurr,zstackRef)
Pix = 100;
[offsetMap,~,~,~] = fn_registerImg2Stack(zstackRef, meanImgCurr, Pix);
offsetMap = offsetMap - handles.nDepth/2;
figure; subplot(1,2,1);
imagesc(offsetMap);
colormap redblue; clim([-handles.nDepth/2 handles.nDepth/2]);
subplot(1,2,2); hold on
histogram(offsetMap(:)); xlim([-handles.nDepth/2 handles.nDepth/2])
title(['Avg offset is: ' num2str(nanmean(offsetMap(:)),'%0.2f') ' um'])

%subplot(2,3,4);
%imagesc(meanImgCurr); colormap gray; 

%subplot(2,3,5); 
%imagesc(offsetImg); colormap gray; 


end

