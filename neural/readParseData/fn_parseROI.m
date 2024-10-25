function fn_parseROI(mousePath,roiOrder,roiSize)
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
gFrames = 1:1:nFrames; %rFrames = 2:2:nFrames;
frameBin = 2000; 
frameParseG = parseFrame(gFrames,frameBin);
%frameParseR = parseFrame(rFrames,frameBin);
%roiOrder = {'AC'}; roiY = {1:450};
if length(roiOrder) == 2
    roiY{1} = 1:roiSize(1);
    roiY{2} = (size(stack,1)-roiSize(2)+1):size(stack,1);
else
    error('ERROR -- nROI other than 2 has not implemented')
end
%roiOrder = {'PPC','AC'}; roiY = {1:900,1023:1472};%roiY = {1:526,649:1548};
for k = 1:length(roiOrder)
    tic;
    yFrames = roiY{k}; totalFrame = 0;
    
    tempSplit = strsplit(filename,'.');
    tempSplit = strsplit(tempSplit{1},'_');
    tempSplitName = strjoin(tempSplit(1:end-1),'_'); tempSplitNum = tempSplit{4};
    tempSplitNum = strip(tempSplitNum,'left','0');tempSplitName = [tempSplitName tempSplitNum];
    saveFilename = [mousePath filesep 'green_' roiOrder{k} filesep tempSplitName '_parsed.h5'];
    saveImgname = [mousePath filesep 'green_' roiOrder{k} filesep tempSplitName '_meanImg.mat'];
    meanImgFrames = 2000; 
    if size(stack,3)>meanImgFrames; meanImg = fn_fastAlign(stack(yFrames,:,1:meanImgFrames));
    else; meanImg = fn_fastAlign(stack(yFrames,:,1:end));
    end 
    meanImg = nanmean(meanImg,3);
    save(saveImgname,'meanImg'); 

    for j = 1:length(frameParseG)
        tempStack = int16(stack(yFrames, :,frameParseG{j}));
        temph5Size = [size(tempStack,1) size(tempStack,2)];
        if(j==1)
            h5create(saveFilename,'/data',[temph5Size Inf],'DataType','int16','ChunkSize',[temph5Size frameBin]);
            h5write(saveFilename,'/data',tempStack,[1 1 1],[temph5Size size(tempStack,3)]);
        else
            h5write(saveFilename,'/data',tempStack,[1 1 totalFrame+1],[temph5Size size(tempStack,3)]);
        end  
        totalFrame = totalFrame + size(tempStack,3);
    end

    toc;  
end


end