function [imgBaselineAvg,imgPresDff] = fn_getToneActWF(filename, roiOps)

%tiffPath = 'D:\labData\2pData_meso\zz129';
%fileName = 'zz128_AC_00001.tif';
%roiOps.nROI = 6;
%roiOps.ylen = 200;
%roiOps.roiPos = [1 2 3 4 5 6]

% tone ID
tone = [45254.834 8000 13454.34264 4756.82846 5656.854249,...
    22627.417 64000 53817.37058 4000 9513.65692,...
    16000 6727.171322 19027.31384 26908.6852 32000,...
    11313.7085 38054.62768];

toneLabel = strsplit(int2str(round(tone)));
toneindex = [9;4;5;12;2;10;16;3;11;13;6;14;15;17;1;8;7];
nPlanes = 1; nChan = 1; selChan = 1;
nTones = length(tone);
toneOnset = 8;
nTrials = 10;
nFramesPerTone = 40 / nPlanes * nChan; % 50
nFramesPerTonePerChan = 40 / nPlanes;
nFramesPerTrial = nFramesPerTone * nTones; % 850
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 17.1; % in the future, do not hard code this.

% process each trial
imgPres = cell(1,nTones);
imgBaseline = cell(1,nTones);
imgStack = TIFFStack(filename);

for i = 1:nTrials
    disp(['Trial ' int2str(i)])
    tempFrameStart = (i-1)*nFramesPerTrial; 

    selFrame = [tempFrameStart+1, tempFrameStart+nFramesPerTrial];
    img = imgStack(:,:,selFrame(1):selFrame(2));
    %img = fn_readTiff(filename,selFrame);
    %img = permute(img,[2 1 3]);xpix = size(img,2); ypix = size(img,1); nFrame = size(img,3); 

    [~, imgFOV] = fn_splitFOV(img, roiOps);
    %[~,T] = sbxalignxMat(imgFOV,1:size(imgFOV,3));
    %for k=1:size(imgFOV,3); imgFOV(:,:,k) = circshift(imgFOV(:,:,k),T(k,:)); end
    

    tempIdx = 0:nFramesPerTonePerChan:size(imgFOV,3)-1;
    for j = 1:nTones
        imgBaseline{j}{i} = mean(imgFOV(:,:,(tempIdx(j)+1):(tempIdx(j)+toneOnset-1)),3);
        imgPres{j}{i} = mean(imgFOV(:,:,(tempIdx(j)+toneOnset+1):(tempIdx(j)+toneOnset+6)),3);
    end
end

% plot the figure
imgPresAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgPres,'UniformOutput',false),3);
imgBaselineAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgBaseline,'UniformOutput',false),3);

imgPresAvg = imgPresAvg(:,:,toneindex); imgBaselineAvg = imgBaselineAvg(:,:,toneindex);
imgBaselineAvgRep = repmat(nanmean(nanmean(imgBaselineAvg,1),2),[size(imgBaselineAvg,1) size(imgBaselineAvg,2) 1]); 
imgBaselineF = mean(imgBaselineAvg,3); 

% smooth the image first before computing dff
tempRatioXY = 11; pixelAvg = 6;
imgPresDff = zeros(size(imgPresAvg));
for i = 1:length(tone)
    K = (1/(pixelAvg*pixelAvg*tempRatioXY))*ones(pixelAvg,pixelAvg*tempRatioXY);
    imgPresAvgTemp = conv2(imgPresAvg(:,:,i),K,'same');
    imgBaselineAvgTemp = conv2(imgBaselineAvg(:,:,i),K,'same');
    imgPresDff(:,:,i) = (imgPresAvgTemp - imgBaselineAvgTemp) ./ max(imgBaselineAvgRep(:));
end 

% PLOT 1 -- Tone by Tone DFF map
figure; 
for i = 1:length(tone)
    subplot(3,6,i);
    tempImg = imgPresDff(:,:,i);
    imagesc((tempImg)); colormap gray; clim([-0.5 1]);
    title([int2str(round(tone(toneindex(i)))) ' Hz'])
end

% PLOT 2 -- Tonotopy Map of Besrt Frequency
imgPresDffAvgAllTone = nanmean(imgPresDff,3); dffLimit = 0.005; 
toneRespRegion = imgPresDffAvgAllTone>dffLimit; 
[~,tonePeakIndex] = max(imgPresDff,[],3);
tonePeakIndex(~toneRespRegion) = nan;
figure; imagesc(tonePeakIndex); clim([1 17]);
a=colorbar; a.Label.String = 'tone ID'; title('tonotopic map by pixel')
xlabel('x axis pixel'); ylabel('y axis pixel')

% PLOT 3 -- Tonotopy Map of Best Frequency
tempboundaries = bwboundaries(toneRespRegion);
imgBaselineTemp = nanmean(imgBaselineAvg,3);
figure; imagesc(imgBaselineTemp); hold on; colormap gray; clim([0 2000])
for i = 1:length(tempboundaries)
    plot(tempboundaries{i}(:,2),tempboundaries{i}(:,1),'r')
end 
xlabel('x axis pixel'); ylabel('y axis pixel');
title('structure reference map')

end