function [imgBaselineAvg,imgPresDff] = fn_getToneActWF_SU(filename, roiOps)

%tiffPath = 'D:\labData\2pData_meso\zz129';
%fileName = 'zz128_AC_00001.tif';
%roiOps.nROI = 6;
%roiOps.ylen = 200;
%roiOps.roiPos = [1 2 3 4 5 6]

% tone ID
tone = [64001, 64000, 53817, 4000, 9514,...
           16000, 6727, 64002, 19027, 26909, 32000,...
           64003, 11314, 38055, 45255, 8000, 13454, 4757, 5657, 22627];

toneLabel = strsplit(int2str(round(tone)));
[~,toneindex] = sort(tone);
nPlanes = 1; nChan = roiOps.nChan; selChan = roiOps.selChan;
nTones = length(tone);
toneOnset = 18;
nTrials = 10;
nFramesPerTone = 100;
selFrameEachTone = 60; 

nFramesPerTrial = nFramesPerTone * nTones; % 850
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 17.1; % in the future, do not hard code this.

% process each trial
imgPres = cell(1,nTones);
imgBaseline = cell(1,nTones);
imgStack = TIFFStack(filename);
%refImg = imgStack(:,:,selChan:nChan:1000);
%refImg = fn_fastAlign(refImg);
for i = 1:nTrials
    disp(['Trial ' int2str(i)])
    for j = 1:nTones
        tempFrameStart = (i-1)*nFramesPerTrial + (j-1)*nFramesPerTone; 

        selFrame = [tempFrameStart+selChan, tempFrameStart+selFrameEachTone];
        %img = fn_readTiff(filename,selFrame);

        
        %img = permute(img,[2 1 3]);xpix = size(img,2); ypix = size(img,1); nFrame = size(img,3); 
        img = imgStack(:,:,selFrame(1):nChan:selFrame(2));

        [~, imgFOV] = fn_splitFOV(img, roiOps);
        %[~,T] = sbxalignxMat(imgFOV,1:size(imgFOV,3));
        %for k=1:size(imgFOV,3); imgFOV(:,:,k) = circshift(imgFOV(:,:,k),T(k,:)); end
        

        
        imgBaseline{j}{i} = mean(imgFOV(:,:,1:toneOnset-1),3);
        imgPres{j}{i} = mean(imgFOV(:,:,toneOnset+1:toneOnset+6),3);
        
    end 
end

% plot the figure
imgPresAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgPres,'UniformOutput',false),3);
imgBaselineAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgBaseline,'UniformOutput',false),3);

imgPresAvg = imgPresAvg(:,:,toneindex); imgBaselineAvg = imgBaselineAvg(:,:,toneindex);
imgBaselineAvgRep = repmat(nanmean(nanmean(imgBaselineAvg,1),2),[size(imgBaselineAvg,1) size(imgBaselineAvg,2) 1]); 
imgBaselineF = mean(imgBaselineAvg,3); 

% smooth the image first before computing dff
tempRatioXY = 1;
imgPresDff = zeros(size(imgPresAvg));
for i = 1:length(tone)
    K = (1/(200*200*tempRatioXY))*ones(200,200*tempRatioXY);
    imgPresAvgTemp = conv2(imgPresAvg(:,:,i),K,'same');
    imgBaselineAvgTemp = conv2(imgBaselineAvg(:,:,i),K,'same');
    imgPresDff(:,:,i) = (imgPresAvgTemp - imgBaselineAvgTemp) ./ max(imgBaselineAvgRep(:));
end 

% PLOT 1 -- Tone by Tone DFF map
figure; 
for i = 1:length(tone)
    subplot(4,5,i);
    tempImg = imgPresDff(:,:,i);
    imagesc((tempImg)); colormap gray; clim([-0.1 0.15]);
    title([int2str(round(tone(toneindex(i)))) ' Hz'])
end

% PLOT 2 -- Tonotopy Map of Besrt Frequency
imgPresDffAvgAllTone = nanmean(imgPresDff,3); dffLimit = 0.1; 
toneRespRegion = imgPresDffAvgAllTone>dffLimit; 
tempboundaries = bwboundaries(toneRespRegion);
[~,tonePeakIndex] = max(imgPresDff(:,:,1:17),[],3);
tonePeakIndex(~toneRespRegion) = nan;
figure; imagesc(tonePeakIndex); clim([1 17]);
a=colorbar; a.Label.String = 'tone ID'; title('tonotopic map by pixel')
xlabel('x axis pixel'); ylabel('y axis pixel')
hold on;
for i = 1:length(tempboundaries)
    plot(tempboundaries{i}(:,2),tempboundaries{i}(:,1),'r')
end 
% PLOT 3 -- Tonotopy Map of Best Frequency
imgBaselineTemp = nanmean(imgBaselineAvg,3);
figure; imagesc(imgBaselineTemp); hold on; colormap gray; clim([0 100])
for i = 1:length(tempboundaries)
    plot(tempboundaries{i}(:,2),tempboundaries{i}(:,1),'r')
end 
xlabel('x axis pixel'); ylabel('y axis pixel');
title('structure reference map')



end