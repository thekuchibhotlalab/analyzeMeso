datapath = 'G:\rockfish\ziyi\zz159_AC';

load([datapath filesep 'ops.mat'],'ops');
load([datapath filesep 'alignedOps.mat' ],'alignedOps');
load([datapath filesep 'stackROI_final_tracked.mat' ]);
load([datapath filesep 'stackROI_final.mat' ]);

%% compute image patch correlation
refStackSel = loadRefstacksel('G:\rockfish\ziyi\zz159_AC\roiTracking\refStackReconstruct');
xSize = size(alignedOps.suite2pImg,1);
ySize = size(alignedOps.suite2pImg,2);
roiImgSize = 20;

middleIndices = midIshereIdx(stackROI.ishere);
corrIndiceRaw = zeros(size(refStackSel,3),length(middleIndices));
corrIndice = zeros(size(refStackSel,3),length(middleIndices));
corrIndiceCenter = zeros(size(refStackSel,3),length(middleIndices));


for i = 1:size(roiFinal,2)
    centroid = stackROI.centroidRaw{i};

    tempShiftX = centroid(1);
    tempShiftY =  centroid(2); 
    tempROISizeX = min([xSize-round(tempShiftX)  round(tempShiftX)-1 roiImgSize]);
    tempROISizeY = min([ySize-round(tempShiftY)  round(tempShiftY)-1 roiImgSize]);
    tempROISize = min([tempROISizeX,tempROISizeY]);
    selX = round(tempShiftX) - tempROISize : round(tempShiftX) + tempROISize;
    selY = round(tempShiftY) - tempROISize : round(tempShiftY) + tempROISize;

    % Adjust for out-of-bounds indices and pad with NaNs
    patchSize = 2 * tempROISize + 1;
    patch = nan(patchSize, patchSize,size(refStackSel,3)); % Initialize patch with NaNs
    
    % Valid indices within bounds
    validX = selX(selX > 0 & selX <= size(refStackSel, 1));
    validY = selY(selY > 0 & selY <= size(refStackSel, 2));
    
    % Corresponding indices in the patch
    patchX = find(selX > 0 & selX <= size(refStackSel, 1));
    patchY = find(selY > 0 & selY <= size(refStackSel, 2));
    
    % Insert valid data into the patch
    patch(patchX, patchY,:) = refStackSel(validX, validY, :);

    patch(patch==0) = nan;

    patch2 = reshape(patch,size(patch,1)*size(patch,2), []);
    patch1 = patch(10:end-10,10:end-10,:);
    patch1 = reshape(patch1,size(patch1,1)*size(patch1,2), []);
    
    a = corr(patch1,'rows','complete');
    b = corr(patch2,'rows','complete');

    corrIndiceRaw(:,i) = a(:,4);
    if ~isnan(middleIndices(i))
        corrIndice(:,i) = b(:,middleIndices(i));
        corrIndiceCenter(:,i) = a(:,middleIndices(i));
    else
        corrIndice(:,i) = b(:,4);
        corrIndiceCenter(:,i) = a(:,4);
    end 
end
%% example image
i = 160;
figure; fn_plotImgROI(alignedOps.suite2pImg(:,:,i),roiFinal(i,:),ishereFinal(i,:));
xlim([250 410]); ylim([160 340])
%% make summary plot
tempIshere = ishereFinal; tempIshere(isnan(tempIshere)) = 0;
figure; 
subplot(2,2,1); histogram(nanmean(ishereFinal,1),0:0.05:1); 
ylabel('Number of Neurons'); xlabel('Percentage of session present')
title(['Histogram of #accepted' newline 'neurons over #sessions'])

subplot(2,2,2);cdfplot(1-nanmean(ishereFinal,1)); 
[f,x] = ecdf(1-nanmean(ishereFinal,1));
tempIdx1 = find(f>=0.8,1,'first'); tempIdx2 = find(f>=0.7,1,'first');
xline(x(tempIdx1),'--'); xline(x(tempIdx2),'--')
ylabel('Percentage of neuron tracked');
xlabel('Percentage of session excluded')
title(['Cdf of #accepted' newline 'neurons over #sessions'])

nDepth = nansum(stackROI.ishere,1);
subplot(2,2,3); histogram(nDepth)
xticks([0 1 3 5 7]); xticklabels({'Rej.','0um','10um','20um','30um'});
xlabel('Present depth'); ylabel('Number of neurons')
title(['Depth range of' newline 'accepted neurons'])

subplot(2,2,4);
corrHere = corrIndiceCenter(stackROI.ishere==1);
corrNotHere = corrIndiceCenter(stackROI.ishere==0);
histogram(corrNotHere,-0.1:0.05:1); hold on; histogram(corrHere,-0.1:0.05:1);
xlabel('Image pixel correlation with reference img');
ylabel('Cells'); legend({'Rejected','Accepted'},"Location","best");
title(['Correlation of accepted vs.' newline ' rejected cells with reference image'])

figure; 
for i = 1:7
    cdfplot(corrIndiceRaw(i,:)); hold on;
end
xlabel('Image pixel correlation with reference img');
ylabel('Cells'); legend({'-15um','-10um','-5um','0um','5um','10um','15um'},"Location","best");
title(['Correlation of cells with reference' newline 'image, as function of depth'])
%% visualize offset map
tempCenter = ops.refStackSelLoc(4);
tempTotalOff = squeeze(nanmean(nanmean(abs(ops.offsetMap - tempCenter),1),2));
[offsetValueRanked, offsetRank] = sort(tempTotalOff,'descend');
figure; plot(offsetValueRanked); xlabel('Session Number'); ylabel('z-depth diff from center');
figure;startIdx  = 0;
for i = 1:20
    
    if i <= 10
        subplot_tight(4,10,i,[0.01 0.01])
    else
        subplot_tight(4,10,i+10,[0.01 0.01])
    end 
    tempPlot = ops.offsetMap(:,:,offsetRank(i+startIdx)) - tempCenter;
    imagesc(tempPlot(10:end-10,10:end-10)); colormap redblue;
    clim([-30 30]);
    xticks([]); yticks([]);
    
    if i <= 10
        subplot_tight(4,10,i+10,[0.01 0.01])
    else
        subplot_tight(4,10,i+20,[0.01 0.01])
    end
    
    fn_plotImgROI(zeros(size(ops.suite2pRefImg))+0.5,roiFinal(offsetRank(i+startIdx),:),ishereFinal(offsetRank(i+startIdx),:))
    xticks([]);yticks([])
    colormap redblue
end 
%% visualize all offsetmap
figure;
for i = 1:length(offsetRank)
    subplot_tight(10,22,i,[0.01 0.01])

    tempPlot = ops.offsetMap(:,:,offsetRank(i)) - tempCenter;
    imagesc(tempPlot(10:end-10,10:end-10)); colormap redblue;
    clim([-15 15]);xticks([]);yticks([])
    colormap redblue
end 

subplot_tight(10,22,length(offsetRank)+1,[0.01 0.01]);xticks([]);yticks([])
colormap redblue; c = colorbar; 
c.Ticks = [0 1/6 1/3 0.5 2/3 5/6 1]; % Custom tick positions
c.TickLabels = {'-15','-10','-5','0','5','10','15'}; % Custom labels
% cticks([0 1/6 1/3 0.5 2/3 5/6 1]); cticklabels({'-15','-10','-5','0','5','10','15'})
%% visualize the stackROI tracked
figure; 
for i = 1:7
    subplot_tight(1,7,i,[0.01 0.01])
    fn_plotImgROI(zeros(size(ops.suite2pRefImg)),stackROI.coordRedrawn(i,:),stackROI.ishere(i,:));
    xticks([]);yticks([])
end 


%% functions
function img = loadRefstacksel(folder_path)
    % Get a list of all files in the folder
    files = dir([folder_path filesep '*.tiff']);
    
    % Extract the filenames
    filenames = {files.name};
    
    % Filter filenames that contain 'refImg' but do not contain '_'
    filtered_filenames = filenames(contains(filenames, 'refImg') & ~contains(filenames, '_'));
    img = {};
    for k = 1:length(filtered_filenames)
        img{k} = double(imread([folder_path filesep filtered_filenames{k}]));
    end 
    img = fn_cell2mat(img,3);
end 


function centroid = getCentroid(contourCoords)
    % Validate the input
    if size(contourCoords, 2) ~= 2
        error('Input must be an Nx2 matrix of [row, column] coordinates.');
    end
    
    % Extract row (y) and column (x) coordinates
    rows = contourCoords(:, 1); % y-coordinates
    cols = contourCoords(:, 2); % x-coordinates
    
    % Compute the centroid
    centroid = [mean(rows), mean(cols)];
end


function middleIndices = midIshereIdx(ishere)

% Initialize output array
middleIndices = nan(1, size(ishere,2)); % Use NaN for cases with no '1's

% Loop through each column
for col = 1:size(ishere,2)
    onesIdx = find(ishere(:, col)); % Get indices of ones
    
    if ~isempty(onesIdx)
        numOnes = length(onesIdx);
        if mod(numOnes, 2) == 1
            % Odd case: Pick the exact middle
            midIdx = ceil(numOnes / 2);
        else
            % Even case: Pick the index that is closer to the center of original 7 indices
            midIdx1 = numOnes / 2;
            midIdx2 = midIdx1 + 1;
            % Compare their distances from the center index (4 in a 7-length row)
            if abs(onesIdx(midIdx1) - 4) <= abs(onesIdx(midIdx2) - 4)
                midIdx = midIdx1;
            else
                midIdx = midIdx2;
            end
        end
        middleIndices(col) = onesIdx(midIdx); % Store the middle index
    end
end

end 

