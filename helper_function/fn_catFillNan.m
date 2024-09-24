function catmat = fn_catFillNan(dim,matA,matB,nandim)

switch dim 
    case 1 % if 1 or 2 dimension, 
        if size(matA,2) < size(matB,2)
            tempNan = nan(size(matA,1),size(matB,2)-size(matA,2) );
            matA = cat(2,matA,tempNan);
        elseif size(matA,2) > size(matB,2)
            tempNan = nan(size(matB,1),size(matA,2)-size(matB,2));
            matB = cat(2,matB,tempNan);
        end
        catmat = cat(1,matA,matB);

    case 2

        if size(matA,1) < size(matB,1)
            tempNan = nan(size(matB,1)-size(matA,1),size(matA,2));
            matA = cat(1,matA,tempNan);
        elseif size(matA,1) > size(matB,1)
            tempNan = nan(size(matA,1)-size(matB,1),size(matB,2));
            matB = cat(1,matB,tempNan);
        end
        catmat = cat(2,matA,matB);
    case 3

        if nandim == 2
            if size(matB,2)>size(matA,2)
                tempNan = nan(size(matA,1), size(matB,2)-size(matA,2),size(matA,3));
                matA = cat(2, matA,tempNan);
                catmat = cat(3,matA,matB);
            else
                tempNan = nan(size(matB,1), size(matA,2)-size(matB,2),size(matB,3));
                matB = cat(2, matB,tempNan);
                catmat = cat(3,matA,matB);

            end
        elseif nandim==1
            disp('not implemented yet')
        end 


end
