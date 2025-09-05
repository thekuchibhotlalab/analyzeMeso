function [imgBaselineAvg,imgPresAvg] = fn_getToneActWF_SU(filename, roiOps)

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
nFramesPerTone = 200;
%nFramesPerTonePerChan = 100;
selFrameEachTone = 60; 

nFramesPerTrial = nFramesPerTone * nTones; % 850
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 17.1; % in the future, do not hard code this.

% process each trial
imgPres = cell(1,nTones);
imgBaseline = cell(1,nTones);
imgStack = TIFFStack(filename);
for i = 1:nTrials
    disp(['Trial ' int2str(i)])
    for j = 1:nTones
        tempFrameStart = (i-1)*nFramesPerTrial + (j-1)*nFramesPerTone; 

        selFrame = [tempFrameStart+selChan, tempFrameStart+selFrameEachTone];
        %img = fn_readTiff(filename,selFrame);

        
        %img = permute(img,[2 1 3]);xpix = size(img,2); ypix = size(img,1); nFrame = size(img,3); 
        img = imgStack(:,:,selFrame(1):nChan:selFrame(2));

        [imgCell, imgFOV] = fn_splitFOV(img, roiOps);
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
imgPresDff = imgPresAvg-imgBaselineAvg ;
%imgBaselineF(imgBaselineF<0) = 0; imgBaselineF = imgBaselineF+20;
for i = 1:length(tone)
    K = (1/(18*18*20))*ones(18,18*20);
    temp = conv2(imgPresDff(:,:,i),K,'same');
    imgPresDff(:,:,i) = temp - mean(temp(:)) ;
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

K = (1/(6*42))*ones(6,42);
tempImg = conv2(mean(imgPresAvg,3)-mean(imgBaselineAvg,3),K,'same');
figure; imagesc(tempImg);colormap gray; clim([-3 3]);

figure; imagesc(nanmean(imgBaselineAvg,3)); colormap gray; clim([0 1000])
%imgFOV = fn_getFOV(tiffPath,fileName,[tempFrameStart nChan tempFrameStart+nFramesPerTrial-2],roiSize,roiPos,nROI);
%tempImg = mean(imgFOV,3);
%figure; imagesc(tempImg');colormap gray; clim([0 prctile(tempImg(:),99)]);



end