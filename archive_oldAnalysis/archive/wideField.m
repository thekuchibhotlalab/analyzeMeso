%% read the 
%% read the 
clear; 
tiffPath = 'D:\labData\2pData_meso\zz131\050823\wholefov';
fileName = 'zz131_050823_dc_pt_00001_00001.tif';
roiSize = [1024 128]; nROI = 8; roiPos = [2 1 3 4 5 6 7 8]; 
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
nFramesPerTrial = nFramesPerTone * nTones; % 850
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 17.1; % in the future, do not hard code this.

%%

tempFrame = [2 2 200];
imgFOV = fn_getFOV(tiffPath,fileName,tempFrame,roiSize,roiPos,nROI);



%%
filePath = 'D:\labData\2pData_meso\zz131\050823\wholefov\suite2p\plane0';

fileID = fopen([filePath filesep 'data.bin'],'r');

A = fread(fileID,xpix*ypix*nFramesPerTrial,'*int16');
reA = reshape(A,xpix*ypix,[]);
rereA = reshape(reA,xpix,ypix,[]);

fclose all;
