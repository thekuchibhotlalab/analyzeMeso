% datapath = 'D:\zz153\green_AC';
% filename = dir([datapath filesep '*.mat']);
% meanImgCell = {};
% for i = 1:length(filename)
%     load([datapath filesep filename(i).name])
%     meanImgCell{i} = meanImg; 
% end 
% 
% meanImgCell = fn_cell2mat(meanImgCell,3);
% [meanImgCell, transform_coord] = fn_fastAlign(meanImgCell);

%% now apply patch warp 
% transform1 = 'euclidean';
% transform2 = 'affine'; % affine is basically 'patchwarp'
% warp_blocksize = 6;
% warp_overlap_pix_frac = 0.5;
% norm_radius = 0;  % Set to 0 when the signals are sparse or the result does not look good
% 
% % Perform patchwarp across sessions, here I crop 20 pixels on each side; you can write the code in better ways probably
% meanImg_patchwarped = zeros(size(meanImgCell));
% for i = 1:size(meanImgCell,3)
%     patchwarp_results = patchwarp_across_sessions(meanImgCell(:,:,1), meanImgCell(:,:,i), transform1, transform2, warp_blocksize, warp_overlap_pix_frac, norm_radius);
%     meanImg_patchwarped(:,:,i) = patchwarp_results.image2_warp2;
% end 

%% visualize
%implay(meanImg_patchwarped./prctile(meanImg_patchwarped(:),99.9))
%%
clear;
datapath = 'D:\zz153\green_AC';
filename = dir([datapath filesep]); filename = {filename(3:end).name}; filename(end) = [];
dateStrAlignTo = '20240523'; dateAlignTo = find(strcmp(filename,dateStrAlignTo));
patchwarpImg = cell(1,length(dateAlignTo));
origImg = cell(1,length(dateAlignTo));
for i = 1:length(filename)
    disp(['processing: ' filename{i}])
    tic;
    patchwarpResults = loadData(dateStrAlignTo,filename{i},datapath);
    patchwarpImg{i} = patchwarpResults.image2_warp2(:,:,1);
    origImg{i} = patchwarpResults.image2_all(:,:,1);
    toc;
end 
save([datapath filesep 'patchWarp_aligned.mat'],'patchwarpImg','origImg')

%%

patchwarpImg = cellfun(@(x)(x./prctile(x(:),99.9)),patchwarpImg,'UniformOutput',false);
patchwarpImg = fn_cell2mat(patchwarpImg,3);
origImg = cellfun(@(x)(x./prctile(x(:),99.9)),origImg,'UniformOutput',false);
origImg = fn_cell2mat(origImg,3);
%%
implay(patchwarpImg)
%%
transform1 = 'euclidean';
transform2 = 'affine'; % affine is basically 'patchwarp'
warp_blocksize = 6;
warp_overlap_pix_frac = 0.15;
norm_radius = 0; 
patchwarp_results = patchwarp_across_sessions(meanImgCell(:,:,1), meanImgCell(:,:,87), transform1, transform2, warp_blocksize, warp_overlap_pix_frac, norm_radius);
implay(cat(3,patchwarp_results.image1_all,patchwarp_results.image2_warp2)/prctile(meanImgCell(:),99.9));

%%

load('C:\Users\zzhu34\Documents\tempdata\zz153_AC\session87_patchwarpTest\suite2p\plane0\Fall.mat','ops');
Img2 = cat(3, ops.meanImg./max(ops.meanImg(:)), ops.meanImgE./max(ops.meanImgE(:)), ...
    medfilt2(applyPadding(ops.max_proj./max(ops.max_proj(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]),...
    medfilt2(applyPadding(ops.Vcorr./max(ops.Vcorr(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]));

load('C:\Users\zzhu34\Documents\tempdata\zz153_AC\session1_patchwarpTest\suite2p\plane0\Fall.mat','ops');
Img1 = cat(3, ops.meanImg./max(ops.meanImg(:)), ops.meanImgE./max(ops.meanImgE(:)), ...
    medfilt2(applyPadding(ops.max_proj./max(ops.max_proj(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]),...
    medfilt2(applyPadding(ops.Vcorr./max(ops.Vcorr(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]));

%%
transform1 = 'euclidean';
transform2 = 'affine'; % affine is basically 'patchwarp'
warp_blocksize = 2;
warp_overlap_pix_frac = 0.5;
norm_radius = 0; 
patchwarp_results = patchwarp_across_sessions(Img1(:,:,1), Img2(:,:,1), transform1, transform2, warp_blocksize, warp_overlap_pix_frac, norm_radius);

implay(cat(3,patchwarp_results.image1_all(:,:,1),patchwarp_results.image2_warp2(:,:,1)./prctile(reshape(patchwarp_results.image1_all(:,:,1),1,[]),95)));
implay(cat(3,patchwarp_results.image1_all(:,:,1),patchwarp_results.image2_all(:,:,1)./prctile(reshape(patchwarp_results.image1_all(:,:,1),1,[]),95)));


%%
function newImg = applyPadding(img,desizedSize)
    pad1 = (desizedSize(1)-size(img,1))/2;
    pad2 = (desizedSize(2)-size(img,2))/2;
    newImg = zeros(desizedSize(1),desizedSize(2));
    newImg(pad1+1:end-pad1,pad2+1:end-pad2) = img;
end

function patchwarp_results = loadData(dateStr1,dateStr2,loadPath)
    path1 = [loadPath filesep dateStr1 filesep 'suite2p\plane0\Fall.mat'];
    load(path1,'ops');
    Img1 = cat(3, ops.meanImg./max(ops.meanImg(:)), ops.meanImgE./max(ops.meanImgE(:)), ...
    medfilt2(applyPadding(ops.max_proj./max(ops.max_proj(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]),...
    medfilt2(applyPadding(ops.Vcorr./max(ops.Vcorr(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]));

    path2 = [loadPath filesep dateStr2 filesep 'suite2p\plane0\Fall.mat'];
    load(path2,'ops');
    Img2 = cat(3, ops.meanImg./max(ops.meanImg(:)), ops.meanImgE./max(ops.meanImgE(:)), ...
    medfilt2(applyPadding(ops.max_proj./max(ops.max_proj(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]),...
    medfilt2(applyPadding(ops.Vcorr./max(ops.Vcorr(:)),[size(ops.meanImg,1), size(ops.meanImg,2)]),[3 3]));

    transform1 = 'euclidean';
    transform2 = 'affine'; % affine is basically 'patchwarp'
    warp_blocksize = 3;
    warp_overlap_pix_frac = 0.5;
    norm_radius = 0; 

    patchwarp_results = patchwarp_across_sessions(Img1(:,:,1:3), Img2(:,:,1:3),...
        transform1, transform2, warp_blocksize, warp_overlap_pix_frac, norm_radius);
end