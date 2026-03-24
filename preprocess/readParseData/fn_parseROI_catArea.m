function fn_parseROI_catArea(mousePath,roiName,roiSize)
% fn_parseROI_catArea(mousePath,roiName,roiSize)
% fn_parseROI_catArea(mousePath,'AC',[676 676])
temp = dir(mousePath);
mkdir([mousePath filesep 'green_' roiName]);


for i = 1:length(temp)     
    tiffPath  = [mousePath filesep temp(i).name];
    fileNames = dir([tiffPath filesep '*.tif']);
    fileName = {fileNames.name};
    
    for j = 1:length(fileName)
        disp(fileName{j})
        fn_saveh5(mousePath,tiffPath,fileName{j},roiName,roiSize);
    end
end 

end


%% ALL FUNCTIONS
function fn_saveh5(mousePath,tiffPath,filename,roiOrder,roiSize)
stack = TIFFStack([tiffPath filesep filename]);
nFrames = size(stack,3);
gFrames = 1:1:nFrames; 
frameBin = 2000; 
frameParseG = parseFrame(gFrames,frameBin);


stripeSize = floor((size(stack,1) - sum(roiSize)) / (length(roiSize)-1));
start = 0; roiY = {}; 
for i = 1:length(roiSize)
    idx = start+1:start+roiSize(i);
    roiY{i} = idx;
    start = idx(end) + stripeSize;
end 

for j = 1:length(frameParseG)
    tempStack = {};
    for k = 1:length(roiSize)
        tic;
        yFrames = roiY{k}; totalFrame = 0;
        
        tempSplit = strsplit(filename,'.');
        tempSplit = strsplit(tempSplit{1},'_');
        tempSplitName = strjoin(tempSplit(1:end-1),'_'); tempSplitNum = tempSplit{4};
        tempSplitNum = strip(tempSplitNum,'left','0');tempSplitName = [tempSplitName tempSplitNum];
        tempStack{k} = int16(stack(yFrames, :,frameParseG{j}));
        temph5Size = [size(tempStack,1) size(tempStack,2)];
        
    end

    saveFilename = [mousePath filesep 'green_' roiOrder filesep tempSplitName '_parsed.h5'];
    saveImgname = [mousePath filesep 'green_' roiOrder filesep tempSplitName '_meanImg.mat'];

    tempStack = cat(2,tempStack{:});
    meanImg = fn_fastAlign(tempStack(:,:,1:200));
    meanImg = nanmean(meanImg,3);
    save(saveImgname,'meanImg'); 

    if(j==1)
        h5create(saveFilename,'/data',[temph5Size Inf],'DataType','int16','ChunkSize',[temph5Size frameBin]);
        h5write(saveFilename,'/data',tempStack,[1 1 1],[temph5Size size(tempStack,3)]);
    else
        h5write(saveFilename,'/data',tempStack,[1 1 totalFrame+1],[temph5Size size(tempStack,3)]);
    end  
    totalFrame = totalFrame + size(tempStack,3);
    toc;  disp(['Chunk ' int2str(j) ' done'])
end
end


function frameParse = parseFrame(frameIdx,frameBin)
nChunk = ceil(length(frameIdx)/frameBin);
frameParse = {};
for i = 1:nChunk
    if i~=nChunk; frameParse{i} = frameIdx(frameBin*(i-1)+1:frameBin*i);
    else; frameParse{i} = frameIdx(frameBin*(i-1)+1:length(frameIdx));
    end
end
end