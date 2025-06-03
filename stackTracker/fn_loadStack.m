function handles = fn_loadStack(handles)

    handles.nROI = str2double(handles.nROItext);
    handles.roiLen = cellfun(@str2double,strsplit(handles.roiLenText,',')); 
    handles.zstackRef = cell(1,handles.nROI);
    
    nFramesPerDepth = 20; 
    tic; 
    zstackRef = tiffreadVolume( handles.refName,'PixelRegion', {[1 inf], [1 inf], [1 1 Inf]});
    disp('Loading tiff complete!'); 
    nDepth = size(zstackRef,3)/nFramesPerDepth; handles.nDepth = nDepth;
    
    roiOps.nROI = handles.nROI;
    roiOps.roiLen = handles.roiLen;
    [roiMovies, ~] = fn_splitFOV(zstackRef, roiOps);
    for i = 1:handles.nROI
        handles.zstackRef{i} = fn_fastAlignROIStack(roiMovies{i},nFramesPerDepth,nDepth);
        disp(['Loading ROI #' int2str(i) ' done!']); 
    end 
    toc;
end

function zstack_aligned = fn_fastAlignROIStack(zstack,nFramesPerDepth,nDepth)

zstack = reshape(zstack,[size(zstack,1) size(zstack,2) nFramesPerDepth nDepth]);
zstack_aligned = fn_fastAlignStack(zstack);
for i = 1:size(zstack_aligned,3); zstack_aligned(:,:,i) = enhancedImage(zstack_aligned(:,:,i)); end 
zstack_aligned = fn_fastAlign(zstack_aligned,'center');


end