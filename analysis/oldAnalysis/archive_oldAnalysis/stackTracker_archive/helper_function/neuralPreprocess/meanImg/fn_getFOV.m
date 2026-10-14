function imgFOV = fn_getFOV(tiffPath,fileName,frame,roiSize,roiPos,nROI)

img = (tiffreadVolume([tiffPath filesep fileName],'PixelRegion', {[1 inf], [1 inf], frame}));
img = permute(img,[2 1 3]);xpix = size(img,1); ypix = size(img,2); nFrame = size(img,3); 

spacing = floor((ypix - roiSize(2)*nROI) / (nROI-1)); 
disp([fileName ' Spacing is ' num2str(spacing)])


ycat = size(roiPos,1); xcat = size(roiPos,2);
FOVSize = roiSize .* [xcat ycat];

imgFOV = nan(FOVSize(1),FOVSize(2),nFrame);

for i = 1:max(roiPos(:))
    [tempY,tempX] = find(roiPos==i);

    tiffLoc = (i-1)*(roiSize(2)+spacing)+1;
    fovLocX = (tempX-1)*(roiSize(1))+1;
    fovLocY = (tempY-1)*(roiSize(2))+1;

    imgFOV(fovLocX:fovLocX+roiSize(1)-1,fovLocY:fovLocY+roiSize(2)-1,:) = img(:,tiffLoc:tiffLoc+roiSize(2)-1,:);

end


end