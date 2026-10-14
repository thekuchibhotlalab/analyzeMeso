function fn_getSessionMeanImgTif(tiffPath,fileName, savePath)
%% load the recording


%tiffPath = 'C:\Users\zzhu34\Documents\tempdata\zstackTest_sage';
%fileName = 'zz142_baseline_103023_00001.tif'; 


frame = [1 80]; % only load the green channel till 1000 frames
recording = tiffreadVolume([tiffPath filesep fileName],'PixelRegion', {[1 inf], [1 inf], frame});
%%
%figure; imagesc(mean(recording,3)); colormap gray; caxis([1 2000]); colorbar;

AC_bound = 512; PPC_bound = 640;
recording_AC = recording(1:AC_bound,:,:);
recording_PPC = recording(PPC_bound:end,:,:);

%figure; subplot(2,1,1); imagesc(mean(recording_AC,3)); colormap gray; caxis([1 2000]); colorbar;
%subplot(2,1,2); imagesc(mean(recording_PPC,3)); colormap gray; caxis([1 2000]); colorbar;

%% align the frames 
recording_AC_aligned = nan(size(recording_AC));
recording_PPC_aligned = nan(size(recording_PPC));

[~,transform_coordAC] = sbxalignxMat(recording_AC,1:size(recording_AC,3));
for j=1:size(recording_AC,3); recording_AC_aligned(:,:,j) = circshift(recording_AC(:,:,j),transform_coordAC(j,:)); end
[~,transform_coordPPC] = sbxalignxMat(recording_PPC,1:size(recording_PPC,3));
for j=1:size(recording_PPC,3); recording_PPC_aligned(:,:,j) = circshift(recording_PPC(:,:,j),transform_coordPPC(j,:)); end

%% save the mean image back to tiff files
meanAC = mean(recording_AC_aligned,3); 
meanPPC = mean(recording_PPC_aligned,3); 
figure; subplot(2,1,1); imagesc(meanAC); colormap gray; caxis([1 2000]); colorbar;
subplot(2,1,2); imagesc(meanPPC); colormap gray; caxis([1 2000]); colorbar;

save([savePath filesep fileName(1:end-10) '_AC.mat'],'meanAC','transform_coordAC')
save([savePath filesep fileName(1:end-10) '_PPC.mat'],'meanPPC','transform_coordPPC')

end