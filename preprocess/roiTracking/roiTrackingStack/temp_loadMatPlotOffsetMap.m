%% organize data
clear; 
[offsetMap,offsetImg,offsetX,offsetY,tempMeanOffset] = load_and_concat_mat('G:\ziyi\mesoData\zz180\alignment');
%%
allOffsetMap1 = cat(3,offsetMap{:,1});
allOffsetMap2 = cat(3,offsetMap{:,2});
allOffsetMap1_flat = reshape(allOffsetMap1, size(allOffsetMap1,1)*size(allOffsetMap1,2),[]);
figure; subplot(1,2,1);
imagesc(corr(allOffsetMap1_flat,'rows','complete')); colorbar;

avg_map = nanmean(allOffsetMap2(:,:,20:40),3);
subplot(1,2,2);
imagesc(avg_map-30); colormap redblue; colorbar; clim([-10 10])




%%
figure; plot(tempMeanOffset(:,2))
avg_map = nanmean(allOffsetMap2(:,:,21:46),3);
figure;
imagesc(avg_map-30); colormap redblue; colorbar; clim([-20 20])
figure; 
sessionSel = 9:3:46;
for i = 1:length(sessionSel)
    subplot_tight(3,6,i)
    imagesc(allOffsetMap1(:,:,sessionSel(i))-30);clim([-20 20]);
    colormap redblue;



end 
%% all functions
function [var1_all, var2_all, var3_all, var4_all,var5_all] = load_and_concat_mat(folderPath)

% Load all .mat files in folder
files = dir(fullfile(folderPath, '*.mat'));

% Preallocate cell arrays
nFiles = length(files);

var1_all = cell(nFiles,2);
var2_all = cell(nFiles,2);
var3_all = cell(nFiles,2);
var4_all = cell(nFiles,2);
var5_all = zeros(nFiles,2);
for k = 1:nFiles
    disp(files(k).name)
    tic; 
    filePath = fullfile(files(k).folder, files(k).name);
    data = load(filePath);
    
    % ---- Replace with your actual variable names ----
    var1_all(k,:) = data.offsetMap;
    var2_all(k,:) = data.offsetImg;
    var3_all(k,:) = data.offsetX;
    var4_all(k,:) = data.offsetY;
    var5_all(k,:) = data.tempMeanOffset;
    t = toc; disp(t)
end

end
