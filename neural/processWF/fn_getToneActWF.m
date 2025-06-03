function [imgBaselineAvg,imgPresAvg] = fn_getToneActWF(filename, roiOps)

%tiffPath = 'D:\labData\2pData_meso\zz129';
%fileName = 'zz128_AC_00001.tif';
%roiSize = [550 1000]; nROI = 2; roiPos = [1;2];  tempFrame = [2 2 200];
%imgFOV = fn_getFOV(tiffPath,fileName,tempFrame,roiSize,roiPos,nROI);

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

for i = 1:nTrials
    disp(['Trial ' int2str(i)])
    tempFrameStart = (i-1)*nFramesPerTrial; 

    selFrame = [tempFrameStart+1, tempFrameStart+nFramesPerTrial];
    img = fn_readTiff(filename,selFrame);
    %img = permute(img,[2 1 3]);xpix = size(img,2); ypix = size(img,1); nFrame = size(img,3); 

    [imgCell, imgFOV] = fn_splitFOV(img, roiOps);
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
imgPresDff = (imgPresAvg-imgBaselineAvg )./imgBaselineAvgRep * 100;
%imgBaselineF(imgBaselineF<0) = 0; imgBaselineF = imgBaselineF+20;
for i = 1:length(tone)
    K = (1/1600)*ones(40,40);
    temp = conv2(imgPresDff(:,:,i),K,'same');
    imgPresDff(:,:,i) = (temp - mean(temp(:))) ./ max(temp(:));
end 

figure; 
for i = 1:length(tone)
    subplot(3,6,i);

    tempImg = imgPresDff(:,:,i);
    imagesc((tempImg)); colormap gray; clim([-0.5 1]);
    title([int2str(round(tone(toneindex(i)))) ' Hz'])
end
toneMultiply = reshape(1:length(tone),[1 1 length(tone)]);
normFactor = imgPresDff - min(imgPresDff,[],3);
imgPresDffNorm = normFactor ./ repmat(nansum(normFactor,3),[1 1 length(tone)]);
toneMapAvg = nansum(imgPresDffNorm .* repmat(toneMultiply,[size(imgPresDff,1) size(imgPresDff,2) 1]),3);
figure; imagesc(toneMapAvg); colorbar

K = (1/720)*ones(120,6);
tempImg = conv2(mean(imgPresAvg,3)-mean(imgBaselineAvg,3),K,'same');
figure; imagesc(tempImg);colormap gray; clim([-3 3]);


%imgFOV = fn_getFOV(tiffPath,fileName,[tempFrameStart nChan tempFrameStart+nFramesPerTrial-2],roiSize,roiPos,nROI);
%tempImg = mean(imgFOV,3);
%figure; imagesc(tempImg');colormap gray; clim([0 prctile(tempImg(:),99)]);



end