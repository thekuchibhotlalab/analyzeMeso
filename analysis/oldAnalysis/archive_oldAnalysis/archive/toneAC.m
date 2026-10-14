%% AC imaging
clear; 
%tiffPath = 'D:\labData\2pData_meso\zz131\050823\FOV1';
%fileName = 'zz131_050823_fov1_pt_00002_00001.tif';
%roiSize = [512 300]; nROI = 4; roiPos = [1 2 3 4];  tempFrame = [2 2 200];
%imgFOV = fn_getFOV(tiffPath,fileName,tempFrame,roiSize,roiPos,nROI);


tiffPath = 'D:\labData\2pData_meso\zz129';
fileName = 'zz128_AC_00001.tif';
roiSize = [550 1000]; nROI = 2; roiPos = [1;2];  tempFrame = [2 2 200];
imgFOV = fn_getFOV(tiffPath,fileName,tempFrame,roiSize,roiPos,nROI);
%%

tone = [45254.834 8000 13454.34264 4756.82846 5656.854249,...
    22627.417 64000 53817.37058 4000 9513.65692,...
    16000 6727.171322 19027.31384 26908.6852 32000,...
    11313.7085 38054.62768];

toneLabel = strsplit(int2str(round(tone)));
toneindex = [9;4;5;12;2;10;16;3;11;13;6;14;15;17;1;8;7];
nPlanes = 1; nChan = 2;
nTones = length(tone);
nTrials = 10;
nFramesPerTone = 40 / nPlanes * nChan; % 50
nFramesPerTonePerChan = 40 / nPlanes;
nFramesPerTrial = nFramesPerTone * nTones; % 850
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 17.1; % in the future, do not hard code this.

%%
imgPres = cell(1,nTones);
imgBaseline = cell(1,nTones);

for i = 1:nTrials
    tempFrameStart = (i-1)*nFramesPerTrial+2; 
    imgFOV = fn_getFOV(tiffPath,fileName,[tempFrameStart 2 tempFrameStart+nFramesPerTrial-1],roiSize,roiPos,nROI);
    
    tempIdx = 0:nFramesPerTonePerChan:size(imgFOV,3)-1;
    for j = 1:nTones
        imgBaseline{j}{i} = mean(imgFOV(:,:,(tempIdx(j)+1):(tempIdx(j)+10)),3);
        imgPres{j}{i} = mean(imgFOV(:,:,(tempIdx(j)+11):(tempIdx(j)+15)),3);
    end
end
%%

imgPresAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgPres,'UniformOutput',false),3);
imgBaselineAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgBaseline,'UniformOutput',false),3);
imgPresAvg = imgPresAvg(:,:,toneindex); imgBaselineAvg = imgBaselineAvg(:,:,toneindex);
figure; 
for i = 1:17
    subplot(3,6,i);
    K = (1/100)*ones(10);
    tempImg = conv2(imgPresAvg(:,:,i)-imgBaselineAvg(:,:,i),K,'same');
    imagesc(tempImg'); colormap gray; clim([-5 5]);
    title([int2str(round(tone(toneindex(i)))) ' Hz'])
end
