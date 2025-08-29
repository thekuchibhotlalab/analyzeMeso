%% step 0: before corss-session alignment, quickly assess image correlation
load('meanimagesredperday.mat'); 
redImg_plane2 = cellfun(@(x)(x(:,:,2)),meanimgdayred,'UniformOutput',false); % this is just here to take the 2nd plane
refIdx = 15; 
redImg_plane2 = step0_enhanceCropRawRecording(redImg_plane2, refIdx);
[corrMap, imgTracking] = step2_assessImgCorr(redImg_plane2); 

%% step 1: now we do an additional corss-session alignment
%  starting with step 1, we save the enhanced images for elastix+suite2p alignment
elastixPath = 'G:\ziyi\pythonCode_shared\elastix';
load('meanimagesredperday.mat');

redImg_plane2 = cellfun(@(x)(x(:,:,2)),meanimgdayred,'UniformOutput',false);
refIdx = 15; 
step1_enhanceAlignedRecording(elastixPath, redImg_plane2, refIdx);
% this should save all the enhanced mean images in .mat files in 'rawElastix folder' under elastix path 
%% step 1.1 -- run rockfish scripts to align the session with elasix and suite2p if needed

%% step 2  -- now run across session alignment check, compare with step 0 to see if anything has changed
suite2ppath = 'G:\rockfish\ziyi\jenni\meanImg_red_plane2\alignedElastix\';
binPath = [suite2ppath filesep 'suite2p\plane0'];
img = fn_readBinSuite2p(binPath,'data.bin') / 5000;
img = img(:,:,1:2:end); % here we take every two or three images because we duplicated them in suite2p. In rashi's case, take every 3rd image

[corrMap, imgTracking, corrVal] = step2_assessImgCorr(img,'plotFigure', true); 
% also visualize the day-by-day image here
implay(img(:,:,:)./max(img(:)))
%% step 2.1 -- visualize the correlation map, the tracked and untracked images
figure;
for i = 1:size(corrMap,3)
    subplot(5,6,i);
    imagesc(corrMap(:,:,i)); clim([0 0.8])
end 

figure;
for i = 1:size(corrMap,3)
    subplot_tight(5,6,i,0.01);
    imagesc(imgTracking.trackedImg(:,:,i)); clim([0 1]); colormap gray; 
    xticks([]); yticks([])
end 
figure;
for i = 1:size(corrMap,3)
    subplot_tight(5,6,i,0.01);
    imagesc(imgTracking.unTrackedImg(:,:,i)); clim([0 1]); colormap gray; 
    xticks([]); yticks([])
end 
%% step 3.0 -- you can draw your ROI here and test, or just load an ROI.mat file. 
fn_drawROI(img(:,:,refIdx))

%% step 3.1 -- visualize tracking of all ROIs
figure;
[a,b] = fn_sqrtInt(size(img,3));
for i = 1:size(img,3)
    subplot_tight(a,b,i,0.01);
    imagesc(img(:,:,i)); clim([0 1]); colormap gray; hold on;
    for j = 1:length(roi_results)
        roi = roi_results{j};
        if ~isnan(imgTracking.trackedImg(round(roi.Centroid(2)),round(roi.Centroid(1)),i) )
            plot(roi.Contour(:,2),roi.Contour(:,1),'Color','g');
        else
            plot(roi.Contour(:,2),roi.Contour(:,1),'Color','r');
        end 
    end 
    
    xticks([]); yticks([]);
end 
%% step 3.2 -- visualize tracking of individual ROIs
visualizeROI(img,roi_results{1},imgTracking);


%% functions

function visualizeROI(img,roi,imgTracking)

imgPatch = 50; 
tempCropY = [roi.Centroid(2)-imgPatch roi.Centroid(2)+imgPatch];
tempCropX = [roi.Centroid(1)-imgPatch roi.Centroid(1)+imgPatch];
[a,b] = fn_sqrtInt(size(img,3));
figure;
for i = 1:size(img,3)
    subplot_tight(a,b,i,0.01);
    imagesc(img(:,:,i)); clim([0 1]); colormap gray; hold on;
    if ~isnan(imgTracking.trackedImg(round(roi.Centroid(2)),round(roi.Centroid(1)),i) )
        plot(roi.Contour(:,2),roi.Contour(:,1),'Color','g');
    else
        plot(roi.Contour(:,2),roi.Contour(:,1),'Color','r');
    end 
    
    xticks([]); yticks([]);
    xlim(tempCropX); ylim(tempCropY);
end 


end 