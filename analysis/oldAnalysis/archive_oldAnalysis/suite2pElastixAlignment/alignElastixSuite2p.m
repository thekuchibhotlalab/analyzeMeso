%% STEP 1 -- get the meanImg
clear;
datapath = 'G:\rockfish\ziyi\zz153_PPC'; mouse = 'zz153'; 
mouseArea = strsplit(datapath,'\'); mouseArea = mouseArea{end};
%output = fn_dirfun(datapath, @loadSuite2pMeanImg);

output = fn_dirFilefun([datapath filesep 'meanImg/sessionImg/raw'], @loadmat,'*.mat');
output_SessionName = fn_dirFilefun([datapath filesep 'meanImg/sessionImg/raw'], @loadmatSessionName,'*.mat');

firstEmpty = find(cellfun(@isempty, output),1);
disp(['Total number of sessions are ' int2str(firstEmpty-1)])
if ~isempty(firstEmpty); output = output(1:firstEmpty-1); end
output = cellfun(@enhancedImage, output,'UniformOutput',false);
output = fn_cell2mat(output,3); 
output = fn_fastAlign(output,'center');
output = round(output*5000); 
% implay(output./prctile(output(:),98.5))
%% STEP1.5 -- save the enhanced 
refIdx = 75;
ref = output(:,:,refIdx); refName = output_SessionName{refIdx};
save([datapath filesep '\meanImg\refImg.mat'],'ref');
for i = 1:size(output,3)
    meanImg = output(:,:,i); 
    save([datapath filesep 'meanImg\sessionImg\' mouse '_session' num2str(i,'%02d') '.mat'],'meanImg');
end 
fn_saveMP4(output,['C:\Users\zzhu34\Documents\tempdata\mesoFig\' filesep mouseArea '_enhancedImg.mp4']);
%% STEP2 -- RUN PYTHON SCRIPT TO USE SIMPLE ELASTIX FOR AFFINE TRANFORMATION
% create folders of registeredImg_simpleElastix and transformParams_simpleElastix
%% STEP3 -- CHECK THE ALIGNED TIFF FILES FROM 
clear;
datapath = 'G:\rockfish\ziyi\zz153_PPC'; mouse = 'zz153'; 
output2 = fn_dirFilefun([datapath filesep '\meanImg\registeredImg_simpleElastix\'], @readTiff, '*.tiff');
output2 = fn_cell2mat(output2,3);
implay(output2./prctile(output2(:),98.5))
fn_saveMP4(output2,['C:\Users\zzhu34\Documents\tempdata\mesoFig\' filesep mouseArea '_enhancedImg.mp4']);


%% STEP 4 -- chck suite2p alignment of mean image
suite2ppath = [datapath filesep 'meanImg\registeredImg_simpleElastix\suite2p\plane0'];
load([suite2ppath filesep 'Fall.mat'],'ops','ops_matlab'); if ~exist('ops'); ops = ops_matlab; end

fileID = fopen([suite2ppath filesep 'data.bin'],'r'); % open binary file 
alignedImg = fread(fileID,inf,'*int16');
alignedImg = double(reshape(alignedImg,ops.Lx,ops.Ly,[]));% alignedImg = alignedImg(:,:,1:2:end);
alignedImg = permute(alignedImg,[2 1 3]);
implay(alignedImg ./prctile(alignedImg (:),98.5))

%% step 5 -- load iamgeJ roi and check the alignemnt 
roi = ReadImageJROI('G:\rockfish\ziyi\zz153_PPC\meanImg\roi.zip');
figure; imagesc(alignedImg(:,:,143)); colormap gray; hold on;
for k = 1:length(roi) % number of neurons in this plane
    tempMask = roipoly(zeros(size(alignedImg,1),size(alignedImg,2)),roi{k}.mnCoordinates(:,2),...
        roi{k}.mnCoordinates(:,1));   
    roisMask{k} = logical(tempMask);
    roisCoord{k} = roi{k}.mnCoordinates;
    fill(roisCoord{k}(:,1),roisCoord{k}(:,2),matlabColors(1),'FaceColor','none','LineWidth',2);
end

%% STEP5 -- load reference stack, align that stack
refLoc = 'G:\rockfish\ziyi\zz159_AC\meanImg\refStack\green_AC';
filename =  'zz159_20240707_stack1_parsed.h5';
refStack = double(h5read([refLoc filesep filename], '/data', [1 1 1], [Inf Inf Inf]));

%unalignedImg = fn_dirFilefun('G:\rockfish\ziyi\zz153_AC\meanImg\sessionImg\', @load,'*.mat');
%unalignedImg = cellfun(@(x)(x.meanImg),unalignedImg,'UniformOutput',false); 
%unalignedImg = fn_cell2mat(unalignedImg,3); unalignedImg = unalignedImg/max(unalignedImg(:));

framePerPlane = 20;
refStack = reshape(refStack,size(refStack,1),size(refStack,2),framePerPlane,[]);
meanStack = nan(size(refStack,1),size(refStack,2),size(refStack,3));
meanStack_enhanced = nan(size(refStack,1),size(refStack,2),size(refStack,3));
for i = 1:size(refStack,4)
    tempStack = fn_fastAlign(refStack(:,:,:,i));
    meanStack(:,:,i) = medfilt2(nanmean(tempStack,3),[3 3]);
    meanStack_enhanced(:,:,i) = imgaussfilt(enhancedImage(nanmean(tempStack,3),3),3);
end 
meanStack = fn_fastAlign(meanStack,'center');
meanStack_enhanced = fn_fastAlign(meanStack_enhanced,'center');


%% quality check -- check the file names of zz153 and zz159
datapath = 'G:\rockfish\ziyi\zz153_AC'; mouse = 'zz153'; 
outputAC = fn_dirFilefun([datapath filesep 'meanImg/sessionImg/raw'], @loadmatSessionName,'*.mat');
datapath = 'G:\rockfish\ziyi\zz153_PPC'; mouse = 'zz153'; 
outputPPC = fn_dirFilefun([datapath filesep 'meanImg/sessionImg/raw'], @loadmatSessionName,'*.mat');

a = cellfun(@(x,y)(strcmp(x(end-20:end),y(end-20:end))),outputAC,outputPPC);

%%
offsetMap = {};offsetMapSmooth = {}; overallOffset = []; alignedImg = alignedImg./prctile(alignedImg(:),99.8);
for i = 1:size(alignedImg,3)
    tic; 
    [overallOffset(i) ]= registerImage(meanStack_enhanced, alignedImg(:,:,i));
    offsetMapSmooth{i} = imgaussfilt(offsetMap{i}, 10);  % Smoothing on Y-offsets
    t=toc;
    disp(['day ' int2str(i) ', time = ' num2str(t) ' sec'])
end 
%%
[offsetMapTemp,overallOffsetTemp ]= registerImage(meanStack_enhanced, alignedImg(:,:,25), 80);

%%
load('G:\rockfish\ziyi\zz153_AC\20240628\suite2p\plane0\Fall.mat','ops');
temp = ops.meanImg'; temp = temp ./ prctile(temp(:),99.5);
temp2 = meanStack(:,:,30);
tempImg = fn_fastAlign(cat(3,temp2./prctile(temp2(:),99.5), temp));

%% all functions

function img = readTiff(x)
    img = imread(x);
end

function meanImg = loadmat(datapath)
    load(datapath, 'meanImg');
end

function sessionName = loadmatSessionName(datapath)
    load(datapath, 'sessionName');
end


function meanImg = loadSuite2pMeanImg(suite2ppath)
datapath = [suite2ppath filesep 'suite2p' filesep 'plane0' filesep 'Fall.mat'];
load(datapath,'ops');
meanImg = ops.meanImg; 

end 

function [overallOffset] = registerImage(fixedImage, movingImage)

    [imgHeight, imgWidth, nImg] = size(fixedImage);

    % Determine step size for overlapping blocks (1/4 of Pix)

    % Initialize arrays to store offsets and counts
    overallCrop = 100;
    overallOffset = fn_align(fixedImage(overallCrop+1:end-overallCrop,overallCrop+1:end-overallCrop,:),...
        movingImage(overallCrop+1:end-overallCrop,overallCrop+1:end-overallCrop));
end 

function offset = fn_align(fixedBlock,movingBlock)
    corrMetric = nan(size(fixedBlock,3),1);
    for i = 1:size(fixedBlock,3)
        temp = fixedBlock(:,:,i);
        [tempAligned,tempShift] = fn_fastAlign(cat(3,temp,movingBlock),'center');
        tempCrop = max(abs(tempShift),[],1);
        tempAligned = tempAligned(tempCrop+1:end-tempCrop,tempCrop+1:end-tempCrop,:);
        tempAligned(:,:,2) = fn_fastAlignTwoImgPatchwarp(tempAligned(:,:,1),tempAligned(:,:,2));

        a = reshape(tempAligned,size(tempAligned,1)*size(tempAligned,2),[]);
        d = corr(a); corrMetric(i) = d(end,1);

    end 
    midIdx = floor(size(fixedBlock,3)/2);
    [tempIdx, tempVal] = fn_findLongestAsymptote(smoothdata(corrMetric,'movmean',3),0.006);
    if mod(length(tempIdx),2) == 1; offset = median(tempIdx)-midIdx; 
    elseif tempVal(2)>tempVal(1); offset = ceil(median(tempIdx))-midIdx; 
    else offset = floor(median(tempIdx))-midIdx; end

    tempAligned = fn_fastAlign(cat(3,fixedBlock,movingBlock),'center');
    tempAligned = tempAligned(tempCrop+1:end-tempCrop,tempCrop+1:end-tempCrop,:);
    a = reshape(tempAligned,size(tempAligned,1)*size(tempAligned,2),[]);
    d = corr(a); 
end 