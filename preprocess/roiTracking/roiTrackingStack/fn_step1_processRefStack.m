function fn_step1_processRefStack(filename)

tic;
roiOps.nROI = 2;
roiOps.yLen = [676 676];
stackOps.nSlice = 60; 
stackOps.nFrame = 60; 
%filename = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260125_stack_00001.tif'; 
%filename = 'G:\ziyi\mesoData\zz179\0120\zz179_20260120_stack_00001.tif'; 
[filepath,tempname,~] = fileparts(filename);filename_save = [filepath filesep tempname '.mat'];
[refStack, refStackMean] = loadRef(filename,roiOps, stackOps);
save(filename_save,'refStack','refStackMean');
toc;

end 

function [meanStack_enhanced,meanStack] = loadRef(refname, roiOps, stackOps)
    
    refstack = TIFFStack(refname);

    [roiMovies, ~] = fn_splitFOV(refstack, roiOps);
    meanStack = {}; meanStack_enhanced = {};
    for i = 1:length(roiMovies)
        tempStack = roiMovies{i};
        tempStack = reshape(tempStack,size(tempStack,1),size(tempStack,2),stackOps.nFrame,stackOps.nSlice);
        meanStack_temp = nan(size(tempStack,1),size(tempStack,2),size(tempStack,4));
        meanStack_enhanced_temp = nan(size(tempStack,1),size(tempStack,2),size(tempStack,4));
        for j = 1:size(tempStack,4)
            temp = fn_fastAlign(tempStack(:,:,:,j));
            meanStack_temp(:,:,j) = imboxfilt(nanmean(temp,3),[3 3]);
            meanStack_enhanced_temp(:,:,j) = enhancedImage(meanStack_temp(:,:,j),6);
        end 
        meanStack{i} = fn_fastAlign(meanStack_temp,'center');
        meanStack_enhanced{i} = fn_fastAlign(meanStack_enhanced_temp,'center');

    end 

end 