function imgMat = step0_enhanceCropRawRecording( imgCell)
% enhance the image
enhanceDiameter = [15 15]; enhanceZscoreLimit = 7; 
imgMat = cellfun(@(x)(enhancedImage(x,enhanceZscoreLimit,enhanceDiameter)),imgCell,'UniformOutput',false);
imgMat = fn_cell2mat(imgMat,3);
% align and crop the 
[imgMat, transformCoord] = fn_fastAlign(imgMat);
imgMat = cropEdge(imgMat,transformCoord);
end 

function imgMat = cropEdge(imgMat,transformCoord)
    addtionalCrop = 10; 
    xCrop1 = max(transformCoord(:,1));
    xCrop2 = min(transformCoord(:,1)); if xCrop2>0; xCrop2 = 0; else; xCrop2 = -xCrop2;end 
    xCrop1 = xCrop1+addtionalCrop; xCrop2 = xCrop2+addtionalCrop;
    
    yCrop1 = max(transformCoord(:,2));
    yCrop2 = min(transformCoord(:,2)); if yCrop2>0; yCrop2 = 0; else; yCrop2 = -yCrop2;end 
    yCrop1 = yCrop1+addtionalCrop; yCrop2 = yCrop2+addtionalCrop;
    
    imgMat = imgMat(xCrop1:end-xCrop2,yCrop1:end-yCrop2,:);
end 