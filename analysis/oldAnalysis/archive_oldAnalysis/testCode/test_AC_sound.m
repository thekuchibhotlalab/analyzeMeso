clear;
imgRaw = double(tiffreadVolume('AC\AC_sound_011723_00001.tif'));
%%
img = imgRaw(:,:,1:2:end);
%%

meanImg = mean(img,3);
meanImg = meanImg ./ prctile(meanImg(:),90);
figure; imagesc(meanImg)
colormap gray
%%
roiPix = 512;betPix = 50;nFrames = size(img,3);
xlen = 1024; ylen = 512*3; 
roiPos = {[1 512;1 512],[1 512;513 1024],[1 512;1025 ylen],[513 1024;1 512],[513 1024;513 1024],[513 1024;1025 ylen]};

imgFOV = zeros(xlen,ylen,nFrames);

for i = 1:length(roiPos)
    startLoc = (i-1)*(roiPix+betPix)+1;
    imgFOV(roiPos{i}(1,1):roiPos{i}(1,2),roiPos{i}(2,1):roiPos{i}(2,2),:) = img(startLoc:startLoc+roiPix-1,:,:);

end
%%
meanImgFOV = mean(imgFOV,3);
meanImgFOV = meanImgFOV ./ prctile(meanImgFOV(:),90);
figure; imagesc(meanImgFOV)
colormap gray

%% get sound evoked response
soundFrames = []; baselineFrames = [];  soundOn = (50:50:450); soundFrame = 25;
for i = 1:length(soundOn)
    soundFrames = [soundFrames soundOn(i)+1:soundOn(i)+soundFrame];
    baselineFrames = [baselineFrames soundOn(i)-10:soundOn(i)-1];
end

soundEvokedFOV = mean(imgFOV(:,:,soundFrames),3);
baselineEvokedFOV = mean(imgFOV(:,:,baselineFrames),3); 
soundEvokedFOV = (soundEvokedFOV - baselineEvokedFOV); 
%%
K = (1/1600)*ones(40);
soundEvokedFOVSmooth = conv2(soundEvokedFOV,K,'same');
figure;subplot(2,1,1);imagesc(meanImgFOV); colormap gray; 
title('FOV near auditory cortex')
subplot(2,1,2);
imagesc(soundEvokedFOVSmooth); caxis([-10 10]);colormap gray;
title('Auditory evoked response')