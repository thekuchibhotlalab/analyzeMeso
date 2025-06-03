function [mat_aligned, transform_coord] = fn_fastAlign(mat,method,refImg)
if ~exist("method"); method = 'default'; end 
if ~exist("refImg"); refImg = []; end 

if strcmp(method,'default')
    mat_aligned = nan(size(mat));
    [~,transform_coord] = sbxalignxMat(mat,1:size(mat,3));
    for j=1:size(mat,3); mat_aligned(:,:,j) = circshift(mat(:,:,j),transform_coord(j,:)); end
elseif strcmp(method,'center')
    mat_aligned = mat;
    transform_coord = zeros(size(mat_aligned,3),2);
    midIdx =  ceil(size(mat,3)/2);
    for i = (midIdx+1):size(mat,3)
        try
            [~,t] = sbxalignxMat(cat(3,mat_aligned(:,:,i),...
                mat_aligned(:,:,i-1)),1:2);   
        catch
            t = zeros(2);
        end 
        mat_aligned(:,:,i) = circshift(mat_aligned(:,:,i),t(1,:));
        transform_coord(i,:) = t(1,:); 
    end
    for i = midIdx-1:-1:1
        try
            [~,t] = sbxalignxMat(cat(3,mat_aligned(:,:,i),...
                mat_aligned(:,:,i+1)),1:2);
        catch
            t = zeros(2);
        end 
        mat_aligned(:,:,i) = circshift(mat_aligned(:,:,i),t(1,:));
        transform_coord(i,:) = t(1,:); 
    end
elseif strcmp(method,'refImg') || strcmp(method,'ref')
    mat_aligned = mat;
    transform_coord = zeros(size(mat_aligned,3),2);
    for i =1:size(mat,3)
        [~,t] = sbxalignxMat(cat(3,mat_aligned(:,:,i),...
            refImg),1:2);   
        mat_aligned(:,:,i) = circshift(mat_aligned(:,:,i),t(1,:));
        transform_coord(i,:) = t(1,:); 
    end
   


end 

end