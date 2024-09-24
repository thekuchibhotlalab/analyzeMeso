clear;
stackPath = 'D:\zz159\stack';
%meanImgPath = 'D:\zz153\green_PPC'; 
meanImgPath = 'D:\zz159\green_AC';
filenames = dir([stackPath filesep '*.tif']);
%refStack = 'zz153_20240523_stack_00001.tif'; 
refStack = 'zz159_20240629_stack_00001.tif';
pixlearea = [900 450]; nFramesPerDepth = 20;nDepth=60;

frame = [1 1 Inf];
zstackRef = tiffreadVolume([stackPath filesep refStack],'PixelRegion', {[1 inf], [1 inf], frame});
%zstackRef = zstackRef(1:pixlearea(1),:,:);
zstackRef = zstackRef(end-pixlearea(2)+1:end,:,:);
zstackRef = reshape(zstackRef,[size(zstackRef,1) size(zstackRef,2) nFramesPerDepth nDepth]);
zstackRef = fn_fastAlignStack(zstackRef);

totalFiles = 0; 
allMatchStr = struct(); 
for i = 1:length(filenames)
    disp(filenames(i).name); 
    frame = [1 1 Inf]; nFramesPerDepth = 20; 
    tempStackName = filenames(i).name;
    
    zstack = tiffreadVolume([stackPath filesep filenames(i).name],'PixelRegion', {[1 inf], [1 inf], frame});
    %zstack = zstack(1:pixlearea(1),:,:); 
    zstack = zstack(end-pixlearea(2)+1:end,:,:);
    nDepth = size(zstack,3)/nFramesPerDepth;
    zstack = reshape(zstack,[size(zstack,1) size(zstack,2) nFramesPerDepth nDepth]);

    % align stacks
    zstack = fn_fastAlignStack(zstack);

    [allCorrcoeff, x_values] = fn_runRegStackDepth(zstack,zstackRef);
    [tempIdx, tempVal] = fn_findLongestAsymptote(allCorrcoeff);
    if mod(length(tempIdx),2) == 1; stackMatchIdx = x_values(median(tempIdx)); 
    elseif tempVal(2)>tempVal(1); stackMatchIdx = x_values(ceil(median(tempIdx))); 
    else stackMatchIdx = x_values(floor(median(tempIdx))); end
    
    tempDate = strsplit(tempStackName,'_');tempDate = tempDate{2};
    meanImgName = dir([meanImgPath filesep '*_' tempDate '_*.mat']);
    for j = 1:length(meanImgName)
        tic;
        totalFiles = totalFiles+1;
        allMatchStr(totalFiles).stackMatchIdx = stackMatchIdx; 
        allMatchStr(totalFiles).currStack = filenames(i).name;
        allMatchStr(totalFiles).refStack = refStack;

        loadMeanImgName = [meanImgPath filesep meanImgName(j).name];
        load(loadMeanImgName);
        [~, corrCoeff,corrCoeffCurrPatch] = fn_matchPlane2Stack(meanImg,zstack);

        midIdx = nDepth/2+0.5; 
        [tempIdx, tempVal] = fn_findLongestAsymptote(smoothdata(corrCoeff,'movmean',4),0.006);
        if mod(length(tempIdx),2) == 1; meanImgLoc = median(tempIdx)-midIdx; 
        elseif tempVal(2)>tempVal(1); meanImgLoc = ceil(median(tempIdx))-midIdx; 
        else meanImgLoc = floor(median(tempIdx))-midIdx; end

        allMatchStr(totalFiles).meanImgLocCurrUncorr = meanImgLoc;
        allMatchStr(totalFiles).corrCoeffCurr = corrCoeff;
        meanImgLoc = meanImgLoc+stackMatchIdx;
        allMatchStr(totalFiles).meanImgLocCurr = meanImgLoc;

        [tempIdx, tempVal] = fn_findLongestAsymptote(smoothdata(corrCoeffCurrPatch,'movmean',4),0.006);
        if mod(length(tempIdx),2) == 1; meanImgLoc = median(tempIdx)-midIdx; 
        elseif tempVal(2)>tempVal(1); meanImgLoc = ceil(median(tempIdx))-midIdx; 
        else meanImgLoc = floor(median(tempIdx))-midIdx; end

        
        allMatchStr(totalFiles).meanImgLocCurrUncorrPatch = meanImgLoc;
        allMatchStr(totalFiles).corrCoeffCurrPatch = corrCoeffCurrPatch;
        meanImgLoc = meanImgLoc+stackMatchIdx;
        allMatchStr(totalFiles).meanImgLocCurrPatch = meanImgLoc;


        [~, corrCoeff2,corrCoeffPatch] = fn_matchPlane2Stack(meanImg,zstackRef);
     
        [tempIdx, tempVal] = fn_findLongestAsymptote(smoothdata(corrCoeff2,'movmean',4),0.006);
        if mod(length(tempIdx),2) == 1; meanImgLoc2 = median(tempIdx)-midIdx; 
        elseif tempVal(2)>tempVal(1); meanImgLoc2 = ceil(median(tempIdx))-midIdx; 
        else meanImgLoc2 = floor(median(tempIdx))-midIdx; end

        [tempIdx, tempVal] = fn_findLongestAsymptote(smoothdata(corrCoeffPatch,'movmean',4),0.006);
        if mod(length(tempIdx),2) == 1; meanImgLocPatch = median(tempIdx)-midIdx; 
        elseif tempVal(2)>tempVal(1); meanImgLocPatch = ceil(median(tempIdx))-midIdx; 
        else meanImgLocPatch = floor(median(tempIdx))-midIdx; end

        allMatchStr(totalFiles).meanImgLocPatch = meanImgLocPatch;
        allMatchStr(totalFiles).meanImgLocRef = meanImgLoc2;
        allMatchStr(totalFiles).corrCoeffRef = corrCoeff2;
        allMatchStr(totalFiles).corrCoeffPatch = corrCoeffPatch;
        allMatchStr(totalFiles).meanImgName = meanImgName(j).name;
        % allMatchStr(totalFiles).alignedImgCurr = cat(3, zstackRef(:,:,...
        %     ceil(midIdx+allMatchStr(totalFiles).meanImgLocCurr)),...
        %     zstack(:,:,ceil(midIdx+allMatchStr(totalFiles).meanImgLocCurrUncorr)),...
        %     meanImg);
        % allMatchStr(totalFiles).alignedImgRef = cat(3, zstackRef(:,:,...
        %     ceil(midIdx+allMatchStr(totalFiles).meanImgLocRef)),meanImg);

        patchwarp_results = patchwarp_across_sessions(meanImg(:,:,1), zstackRef(:,:,...
            ceil(allMatchStr(totalFiles).meanImgLocPatch+midIdx)),'euclidean','affine', 6, 0.15, 0);      
        tempMat = cat(3, zstackRef(:,:,ceil(midIdx+allMatchStr(totalFiles).meanImgLocRef)),...
            patchwarp_results.image2_warp2, meanImg);

        allMatchStr(totalFiles).alignedImgPatch = fn_fastAlign(tempMat);
        
        toc

    end 


end
save([meanImgPath filesep 'planeMatchPatch.mat'],'allMatchStr')

%%
daySplit = [];
for i = 1:length(filenames)
    tempStackName = filenames(i).name;
    tempDate = strsplit(tempStackName,'_');tempDate = tempDate{2};
    meanImgName = dir([meanImgPath filesep '*_' tempDate '_*.mat']);
    daySplit(i) = length(meanImgName);
end 
daySplit = cumsum(daySplit);daySplit = daySplit(1:end-1)+0.5;


allOffset = cell2mat({allMatchStr(:).meanImgLocPatch});
allOffset = allOffset - 4.5;

figure; subplot(1,2,1);
hold on;
plot([1 length(allMatchStr)],[0 0],'Color',[0.8 0.8 0.8],'LineWidth',2);
fill([1 length(allMatchStr) length(allMatchStr) 1],[-5 -5 5 5],[0.9 0.9 0.9],'LineWidth',2,'EdgeColor','none');
for i = 1:length(daySplit)
    plot([daySplit(i) daySplit(i)],[-15 15],'Color',[0.8 0.8 0.8],'LineWidth',2);
end 

scatter(1:length(allOffset),allOffset,20, matlabColors(1),'filled');
ylim([-15 15]); xlim([1 length(allMatchStr)]);
ylabel('Session'); xlabel ('Z-depth difference')

subplot(1,2,2);
hold on;
plot([1 length(allMatchStr)],[0 0],'Color',[0.8 0.8 0.8],'LineWidth',2);
fill([1 length(allMatchStr) length(allMatchStr) 1],[0 0 5 5],[0.9 0.9 0.9],'LineWidth',2,'EdgeColor','none');
for i = 1:length(daySplit)
    plot([daySplit(i) daySplit(i)],[-15 15],'Color',[0.8 0.8 0.8],'LineWidth',2);
end 

scatter(1:length(allOffset),abs(allOffset),20, matlabColors(1),'filled');
ylim([0 15]); xlim([1 length(allMatchStr)]);
ylabel('Session'); xlabel ('Z-depth difference')

%% check the alignment of refImg in suite2p


%% check the alignment
i=53;
temp = allMatchStr(i).alignedImgCurr;
temp = fn_fastAlign(temp)./max(temp(:))*1.1;
implay(temp)

i=56;
temp2 = allMatchStr(i).alignedImgCurr;
temp2 = fn_fastAlign(temp2)./max(temp2(:))*1.3;
implay(temp2)

temp3 = fn_fastAlign(cat(3,temp(:,:,2:end),temp2(:,:,2:end)));
implay(temp3)

%%
transform1 = 'euclidean';
transform2 = 'affine'; % affine is basically 'patchwarp'
warp_blocksize = 6;
warp_overlap_pix_frac = 0.15;
norm_radius = 0; 
patchwarp_results = patchwarp_across_sessions(temp2(:,:,1), temp2(:,:,2), transform1,...
    transform2, warp_blocksize, warp_overlap_pix_frac, norm_radius);
implay(cat(3,patchwarp_results.image1_all,patchwarp_results.image2_warp2));
% I think we need to try patch warp
% and also try getting mean image from the 
