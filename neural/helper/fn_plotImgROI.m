function fn_plotImgROI(img,roiCoordCell,ishere)
if nargin == 2; ishere = ones(size(roiCoordCell)); end 
imagesc(img(:,:)); clim([0 1])
colormap gray; hold on; 
for i = 1:size(roiCoordCell,2)
    if ~isempty(roiCoordCell{i})
        if ishere(i)==1
            fill(roiCoordCell{i}(:,2),roiCoordCell{i}(:,1),'r','FaceColor','none','EdgeColor','g')
        else
            fill(roiCoordCell{i}(:,2),roiCoordCell{i}(:,1),'r','FaceColor','none','EdgeColor','r')
        end
    end
end



end