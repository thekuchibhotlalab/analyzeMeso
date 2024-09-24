function [imgBaselineAvg,imgPresAvg] = fn_getToneActWF(tiffPath,fileName,roiSize,nROI,roiPos)

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
    tempFrameStart = (i-1)*nFramesPerTrial+selChan; 
    imgFOV = fn_getFOV(tiffPath,fileName,[tempFrameStart nChan tempFrameStart+nFramesPerTrial-selChan],roiSize,roiPos,nROI);
    
    %[~,T] = sbxalignxMat(imgFOV,1:size(imgFOV,3));
    %for k=1:size(imgFOV,3); imgFOV(:,:,k) = circshift(imgFOV(:,:,k),T(k,:)); end

    tempIdx = 0:nFramesPerTonePerChan:size(imgFOV,3)-1;
    for j = 1:nTones
        imgBaseline{j}{i} = mean(imgFOV(:,:,(tempIdx(j)+1):(tempIdx(j)+10)),3);
        imgPres{j}{i} = mean(imgFOV(:,:,(tempIdx(j)+11):(tempIdx(j)+15)),3);
    end
end

% plot the figure
imgPresAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgPres,'UniformOutput',false),3);
imgBaselineAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgBaseline,'UniformOutput',false),3);
imgPresAvg = imgPresAvg(:,:,toneindex); imgBaselineAvg = imgBaselineAvg(:,:,toneindex);
imgBaselineF = mean(imgBaselineAvg,3); imgBaselineF(imgBaselineF<0) = 0; imgBaselineF = imgBaselineF+20;
figure; 
for i = 1:17
    subplot(3,6,i);
    K = (1/720)*ones(120,6);
    tempImg = conv2(imgPresAvg(:,:,i)-imgBaselineAvg(:,:,i),K,'same');
    tempBaseline = conv2(imgBaselineF,K,'same'); 
    %imagesc((tempImg./tempBaseline-1)'); colormap gray; clim([-0.05 0.05]);
    imagesc((tempImg)'); colormap gray; clim([-20 20]);
    title([int2str(round(tone(toneindex(i)))) ' Hz'])
end

K = (1/720)*ones(120,6);
tempImg = conv2(mean(imgPresAvg,3)-mean(imgBaselineAvg,3),K,'same');
figure; imagesc(tempImg');colormap gray; clim([-3 3]);


imgFOV = fn_getFOV(tiffPath,fileName,[tempFrameStart nChan tempFrameStart+nFramesPerTrial-2],roiSize,roiPos,nROI);
tempImg = mean(imgFOV,3);
figure; imagesc(tempImg');colormap gray; clim([0 prctile(tempImg(:),99)]);

%tempImg = {};
%for i = 1:17
%    K = (1/7200)*ones(120,6);
%    tempImg{i} = conv2(imgPresAvg(:,:,i)-imgBaselineAvg(:,:,i),K,'same');
%    tempBaseline = conv2(imgBaselineF,K,'same'); 
%end
%tempImg = fn_cell2mat(tempImg,3);[~,a] = max(tempImg,[],3);
%figure;
%imagesc(a); colormap jet; clim([1 17])

end