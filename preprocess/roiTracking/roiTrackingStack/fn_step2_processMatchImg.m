function fn_step2_processMatchImg(filename_match,startFlag)

%filename_match = 'G:\ziyi\mesoData\zz179\0203\zz179_20260204_2AFC_00001.tif'; 
roiOps.nROI = 2;
roiOps.yLen = [676 676];

if ~exist('startFlag'); startFlag = 'start'; end 
tic; 
matchStack = TIFFStack(filename_match);
maxFrames = min([size(matchStack,3),200]); 
switch startFlag
    case 'start'
        tempMovie = matchStack(:,:,1:maxFrames);
    case 'end '
        tempMovie = matchStack(:,:,end-maxFrames+1:end);
end 
[matchMovies, ~] = fn_splitFOV(tempMovie, roiOps);

matchImg = {}; matchImgMean = {}; 
for i = 1:length(matchMovies)
    tempStack = matchMovies{i};
    temp = fn_fastAlign(tempStack);
    matchImgMean{i} = nanmean(temp,3); 
    %matchImgMean = imboxfilt(nanmean(temp,3),[3 3]);
    matchImg{i} = enhancedImage(matchImgMean{i},6);
end 
[filepath,tempname,~] = fileparts(filename_match); filename_save = [filepath filesep tempname '_' startFlag '.mat'];
save(filename_save,'matchImg','matchImgMean');
toc;

end 
