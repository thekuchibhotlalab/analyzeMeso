function imgMat = step1_enhanceAlignedRecording(elastixPath, imgCell, refIdx)

% enhance the image
enhanceDiameter = [15 15]; enhanceZscoreLimit = 7; 
imgMat = cellfun(@(x)(enhancedImage(x,enhanceZscoreLimit,enhanceDiameter)),imgCell,'UniformOutput',false);
imgMat = fn_cell2mat(imgMat,3);
% align and save the reference image
ref = imgMat(:,:,refIdx);
[imgMat, transformCoord] = fn_fastAlign(imgMat,'refImg',ref);

% save image of each session
for i = 1:size(imgMat,3)
    meanImg = round(imgMat(:,:,i)*5000);
    save([elastixPath filesep 'rawElastix' filesep 'session' num2str(i,'%02d') '.mat'], 'meanImg');
end

% save reference image
ref = round(ref*5000);
save([ elastixPath filesep 'refImg.mat' ], 'ref','transformCoord');
end 