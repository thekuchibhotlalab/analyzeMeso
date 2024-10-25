function fn_parseROI_meanImg(mousePath,roiOrder,roiSize)
temp = dir(mousePath);
for k = 1:length(roiOrder)
    mkdir([mousePath filesep 'green_' roiOrder{k}]);
end 

for i = 3:length(temp)     
    tiffPath  = [mousePath filesep temp(i).name];
    fileNames = dir([tiffPath filesep '*.tif']);
    fileName = {fileNames.name};
    
    for j = 1:length(fileName)
        disp(fileName{j})
        try
            saveh5(mousePath,tiffPath,fileName{j},roiOrder,roiSize);
        catch

            disp([fileName{j} ' not done!'])
        end
    end
end 

end

%% ALL FUNCTIONS
function frameParse = parseFrame(frameIdx,frameBin)
nChunk = ceil(length(frameIdx)/frameBin);
frameParse = {};
for i = 1:nChunk
    if i~=nChunk; frameParse{i} = frameIdx(frameBin*(i-1)+1:frameBin*i);
    else; frameParse{i} = frameIdx(frameBin*(i-1)+1:length(frameIdx));
    end
end
end


function saveh5(mousePath,tiffPath,filename,roiOrder,roiSize)
stack = TIFFStack([tiffPath filesep filename]);
nFrames = size(stack,3);
meanImgFrames = 2000; 
if length(roiOrder) == 2
    roiY{1} = 1:roiSize(1);
    roiY{2} = (size(stack,1)-roiSize(2)+1):size(stack,1);
else
    error('ERROR -- nROI other than 2 has not implemented')
end
for k = 1:length(roiOrder)
    tic;
    yFrames = roiY{k}; 
    % put patch warp here
    if size(stack,3)>meanImgFrames; meanImg = fn_fastAlign(stack(yFrames,:,1:meanImgFrames));
    else; meanImg = fn_fastAlign(stack(yFrames,:,1:end));
    end 
    meanImg = nanmean(meanImg,3);
    save(saveImgname,'meanImg'); 



    toc;  
end


end