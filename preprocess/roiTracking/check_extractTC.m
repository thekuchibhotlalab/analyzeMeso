%% read bin file
clear;
binPath = 'C:\Users\zzhu34\Documents\tempdata\zz166\zz153_suite2p'; 
A = fn_readBinSuite2p(binPath,'data.bin',1000);
A2 = fn_readBinSuite2p(binPath,'data_elastix.bin',1000);
A3 = fn_readBinSuite2p(binPath,'data_suite2p.bin',1000);
load([binPath filesep 'stackROI_final_tracked.mat']);
A4 = fn_readBinSuite2p('C:\Users\zzhu34\Documents\tempdata\zz166\zz153_suite2p\example2','data_suite2p.bin',1000);
load('G:\rockfish\ziyi\zz153_PPC\imagingSession\zz153_20240509_PT1_parsed\suite2p\plane0\data_F.mat')
%%
Ly = size(A3,2); Lx = size(A3,1);
roiSel = roiFinal(1,:);
mask2 = cellfun(@(x)(createMaskFromROI(x, [Lx Ly])),roiSel,'UniformOutput',false);
%%
nROI = 10;
TC = zeros(size(A3,3),nROI);
for i = 1:nROI
    TC(:,i) = getTC(A3, mask2{i});
end 

%%
ishereFinal(isnan(ishereFinal)) = 0;
ishere = logical(ishereFinal(1,:));
selTrace = allTraces(:,ishere);
selTrace = reshape(selTrace,40,17,10,[]);
meanTrace = zscore(squeeze(nanmean(nanmean(selTrace,2),3)),0,1);
figure; subplot(1,2,1);imagesc(smoothdata(meanTrace',2,'movmean',3))
xlabel('frame'); ylabel('neuron')
subplot(1,2,2);plot(nanmean(meanTrace,2)); xline(8);
xlabel('frame'); ylabel('z-score activity')
%% function
function TC = getTC(img,mask)

    tempMask = repmat(mask,[1 1 size(img,3)]);
    temp = img.* tempMask;
    TC = squeeze(sum(sum(temp,1),2)) ./ sum(mask(:));

end 

function mask = createMaskFromROI(roiCoords, imgSize)
% createMaskFromROI - Converts ROI coordinates to a binary mask.
%
% Inputs:
%   roiCoords - An N×2 array of [x, y] coordinates outlining the ROI.
%   imgSize   - A 2-element vector specifying the size of the mask [height, width].
%
% Output:
%   mask      - A binary mask of size imgSize with ROI pixels set to 1.

    % Validate inputs
    if isempty(roiCoords)
        mask = false(imgSize(1), imgSize(2));

        return
    elseif size(roiCoords,2) ~= 2
        error('roiCoords must be an N×2 array of [x, y] coordinates.');
    end

    if length(imgSize) ~= 2
        error('imgSize must be a 2-element vector [height, width].');
    end

    % Extract X and Y coordinates
    x = roiCoords(:,1);
    y = roiCoords(:,2);

    % Create the binary mask
    mask = poly2mask(y, x, imgSize(1), imgSize(2));
end
