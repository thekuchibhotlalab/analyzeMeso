function [mat_aligned, transform_coord] = fn_fastAlign(mat)

mat_aligned = nan(size(mat));
[~,transform_coord] = sbxalignxMat(mat,1:size(mat,3));
for j=1:size(mat,3); mat_aligned(:,:,j) = circshift(mat(:,:,j),transform_coord(j,:)); end

end