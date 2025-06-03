function [location, corrCoeff,corrCoeffPatch] = fn_matchPlane2Stack(meanImg, zStack) 
    cropMargin = 20; 
    meanImg = medfilt2(meanImg,[3 3]);
    for i =1:size(zStack,3); zStack(:,:,i) = medfilt2(zStack(:,:,i),[3 3]); end 

    tempStack = fn_fastAlign(cat(3,meanImg,zStack));
    tempStack = tempStack(cropMargin+1:end-cropMargin, cropMargin+1:end-cropMargin,:);

    corrCoeffPatch = zeros(size(zStack,3),1);
    for i = 1:size(tempStack,3)-1
        patchwarp_results = patchwarp_across_sessions(tempStack(:,:,1), tempStack(:,:,1+i), 'euclidean',...
                    'affine', 6, 0.15, 0);      
        temp = corrcoef(cat(2,patchwarp_results.image1_all(:),...
            patchwarp_results.image2_warp2(:)), 'Rows', 'pairwise'); 
        corrCoeffPatch(i) = temp(1,2);
    end 

    tempStack = reshape(tempStack, size(tempStack,1)*size(tempStack,2), []);
    corrCoeff = corrcoef(tempStack, 'Rows', 'pairwise');  
    corrCoeff = corrCoeff(1,2:end);
    [maxCorr, location] = max(corrCoeff);



end