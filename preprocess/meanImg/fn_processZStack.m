function fn_processZStack(tiffPath,fileName, savePath)

%% load the stack
%tiffPath = 'C:\Users\zzhu34\Documents\tempdata\zstackTest_sage';
%fileName = 'zz142_stack_102923_00001.tif'; 
frame = [1 1 Inf];
zstack = tiffreadVolume([tiffPath filesep fileName],'PixelRegion', {[1 inf], [1 inf], frame});
if size(zstack,3)>600;zstack = zstack(:,:,1:2:end); end
%% display AC and PPC
AC_bound = 526; PPC_bound = 649;

recording_AC = zstack(1:AC_bound,:,:);
recording_PPC = zstack(PPC_bound:end,:,:);

figure; subplot(2,1,1); imagesc(mean(recording_AC,3)); colormap gray; caxis([1 2000]); colorbar;
subplot(2,1,2); imagesc(mean(recording_PPC,3)); colormap gray; caxis([1 2000]); colorbar;
%% separate the depth
nDepth = 60; nFramesPerDepth = 10; 
try
    recording_AC = reshape(recording_AC,[size(recording_AC,1) size(recording_AC,2) nFramesPerDepth nDepth]);
    recording_PPC = reshape(recording_PPC,[size(recording_PPC,1) size(recording_PPC,2) nFramesPerDepth nDepth]);
catch
    disp([fileName ' seems to have more than 600 frames acquired! Try doing 1200 frames'])
    recording_AC = reshape(recording_AC,[size(recording_AC,1) size(recording_AC,2) nFramesPerDepth 20]);
    recording_PPC = reshape(recording_PPC,[size(recording_PPC,1) size(recording_PPC,2) nFramesPerDepth 20]);
end

recording_AC_aligned = nan(size(recording_AC));
recording_PPC_aligned = nan(size(recording_PPC));
for i = 1:size(recording_AC,4)
    [~,transform_coordAC] = sbxalignxMat(recording_AC(:,:,:,i),1:size(recording_AC,3));
    for j=1:size(recording_AC,3); recording_AC_aligned(:,:,j,i) = circshift(recording_AC(:,:,j,i),transform_coordAC(j,:)); end
end
for i = 1:size(recording_PPC,4)
    [~,transform_coordPPC] = sbxalignxMat(recording_PPC(:,:,:,i),1:size(recording_PPC,3));
    for j=1:size(recording_PPC,3); recording_PPC_aligned(:,:,j,i) = circshift(recording_PPC(:,:,j,i),transform_coordPPC(j,:)); end
end

recording_AC_aligned = squeeze(mean(recording_AC_aligned,3));
recording_PPC_aligned = squeeze(mean(recording_PPC_aligned,3));
%% SAVE the data

save([savePath filesep fileName(1:end-10) '_AC.mat'],'recording_AC_aligned','transform_coordAC')
save([savePath filesep fileName(1:end-10) '_PPC.mat'],'recording_PPC_aligned','transform_coordPPC')
end






