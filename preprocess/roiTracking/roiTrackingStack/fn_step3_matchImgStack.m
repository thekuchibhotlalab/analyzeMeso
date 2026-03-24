function [offsetMap,offsetImg,offsetX,offsetY,tempMeanOffset] =...
        fn_step3_matchImgStack(filename_match,filename_stack,save2path)
%filename_match = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260212_2AFC_00001.mat'; 
%filename = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260125_stack_00001.mat'; 
load(filename_stack,'refStack','refStackMean');
load(filename_match,'matchImg','matchImgMean');

Pix = 100;

tempRefStack = refStack; offsetMap = {};offsetImg = {}; offsetX = {}; offsetY = {}; tempMeanOffset = []; 
for i = 1:length(matchImg)
    tic; disp(['ROI ' int2str(i)])
    for k = 1:size(tempRefStack,3)
        tempMatch = imboxfilt(matchImg{i},[3 3]);
        tempStack = imboxfilt(tempRefStack{i}(:,:,k),[3 3]);

        [tempAligned,tempShift] = fn_fastAlign(cat(3, tempMatch,tempStack),'center');
        tempRefStack{i}(:,:,k) = tempAligned(:,:,2);

    end 
    [offsetMap{i},offsetImg{i},offsetX{i},offsetY{i}] = fn_registerImg2Stack(tempRefStack{i}, tempMatch , Pix);
    tempMeanOffset(i) = nanmean(offsetMap{i}(:)) - 30;
    %figure; imagesc(offsetMap{i}-30); colormap redblue; clim([-5 5]); title(['ROI ' int2str(i) ', offset ' num2str(tempMeanOffset) ' um deeper'])
    toc;
end 

[filepath,tempname,~] = fileparts(filename_match); 
if ~exist('save2path'); save2path = filepath; end 
filename_save = [save2path filesep tempname '_offset.mat'];
save(filename_save,'offsetMap','offsetImg','offsetX','offsetY','tempMeanOffset');

end