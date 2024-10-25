clear;
%datapath = 'D:\zz153\green_AC';
%filename = dir([datapath filesep]); filename = {filename(3:end).name}; filename(end) = [];
%dateStrAlignTo = '20240523'; dateAlignTo = find(strcmp(filename,dateStrAlignTo));
%patchwarpImg = cell(1,length(dateAlignTo));
%origImg = cell(1,length(dateAlignTo));

sessionDay1 = '20240523';
load(['G:\rockfish\ziyi\zz159_PPC\batch4\20240629\suite2p\plane0\Fall.mat'],'ops','iscell','stat');
Img1 = double(cat(3, ops.meanImg./max(ops.meanImg(:)), ops.meanImgE./max(ops.meanImgE(:)), ...
    medfilt2(fn_applyPadding(ops.max_proj./max(ops.max_proj(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]),...
    medfilt2(fn_applyPadding(ops.Vcorr./max(ops.Vcorr(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3])));

%load(['D:\zz153\green_PPC' filesep 'zz153_' sessionDay1 '_baseline1_meanImg'],'meanImg');
%Img1 = meanImg; 
% make ROI masks out of ROI coordinates
iscellFlag = iscell(:,1);
tempRoi = stat(logical(iscellFlag))';
roisMaskAll = zeros(size(Img1,1),size(Img1,2));
roisMask = cell(1,length(tempRoi)); 
roisBound = cell(1,length(tempRoi)); 
for k = 1:length(tempRoi) % neuron in each plane 
    bound = boundary(double(tempRoi{k}.xpix)', double(tempRoi{k}.ypix)',1); % restricted bound
    tempCoord = [tempRoi{k}.xpix(bound)' tempRoi{k}.ypix(bound)'];
    roisMask{k} = poly2mask(double(tempCoord(:,1)),double(tempCoord(:,2)),size(Img1,1),size(Img1,2));
    roisMaskAll(roisMask{k}) = 1; 
    roisBound{k} = tempCoord;
end
%%
%sessionDay2 = '20240601';
load(['G:\rockfish\ziyi\zz159_PPC\batch8\20240727\suite2p\plane0\Fall.mat'],'ops','iscell','stat');
Img2 = double(cat(3, ops.meanImg./max(ops.meanImg(:)), ops.meanImgE./max(ops.meanImgE(:)), ...
    medfilt2(fn_applyPadding(ops.max_proj./max(ops.max_proj(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]),...
    medfilt2(fn_applyPadding(ops.Vcorr./max(ops.Vcorr(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3])));

%load(['D:\zz153\green_PPC' filesep 'zz153_' sessionDay2 '_baseline1_meanImg'],'meanImg');
%Img2 = meanImg;
%%
transform1 = 'euclidean';
transform2 = 'affine'; % affine is basically 'patchwarp'
warp_blocksize = 12;
warp_overlap_pix_frac = 0.1;
norm_radius = 0; 
tempImg1 = Img2(:,:,1);tempImg1 = tempImg1./prctile(tempImg1(:),99.8);
tempImg2 = Img1(:,:,1);tempImg2 = tempImg2./prctile(tempImg2(:),99.8);
patchwarp_results = patchwarp_across_sessions(tempImg1, tempImg2, transform1, transform2, warp_blocksize, warp_overlap_pix_frac, norm_radius);

implay(cat(3,patchwarp_results.image1_all(:,:,1),patchwarp_results.image2_warp2(:,:,1)));
implay(cat(3,patchwarp_results.image1_all(:,:,1),patchwarp_results.image2_warp1(:,:,1)));



%% then, apply transformation of ROI masks

[roisMaskAll_rigid,roisMaskAll_new] = patchwarp_across_sessions_apply(roisMaskAll, patchwarp_results, 1);
[~] = patchwarp_across_sessions_apply(roisMaskAll, patchwarp_results, 0);
[roisBoundNew,~] = bwboundaries (roisMaskAll_new);
[roisBoundRigid,~] = bwboundaries (roisMaskAll_rigid);

figure;
subplot(1,3,1);temp = Img1(:,:,1); imagesc(temp/prctile(temp(:),99.8));colormap gray;caxis([0 1])
hold on;
for i = 1:length(roisBound); plot(roisBound{i}(:,1),roisBound{i}(:,2),'Color',matlabColors(1),'LineWidth',2); end 
title('Session 1')


subplot(1,3,2);temp = Img2(:,:,1); imagesc(temp/prctile(temp(:),99.8));colormap gray;caxis([0 1])
hold on;
for i = 1:length(roisBoundRigid); plot(roisBoundRigid{i}(:,2),roisBoundRigid{i}(:,1),'Color',matlabColors(1),'LineWidth',2); end 
title('Session 2, euclidean only')


subplot(1,3,3);
temp = Img2(:,:,1); %temp = Img2(:,:,1); 
imagesc(temp/prctile(temp(:),99.8));colormap gray;caxis([0 1])
hold on;
for i = 1:length(roisBoundNew); plot(roisBoundNew{i}(:,2),roisBoundNew{i}(:,1),'Color',matlabColors(1),'LineWidth',2); end 
title('Apply session 1 ROI to session 2, but ROI patchwarped')

implay(cat(3,roisMaskAll,roisMaskAll_rigid,roisMaskAll_new>0.7))

%% other things to try:
% 1. use active contour to draw out 3D ROIs
% 2. match plane, do affine transformatin, and apply the 3-D roi, matching
% the plane, to the new plane