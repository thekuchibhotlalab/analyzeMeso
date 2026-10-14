function fn_parseROI(tiffPath)
fileNames = dir([tiffPath filesep '*.tif']);
fileName = {fileNames.name};
for i = 1:length(fileName)
    disp(fileName{i})
    saveh5(tiffPath,fileName{i});
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


function saveh5(tiffPath,filename)
stack = TIFFStack([tiffPath filesep filename]);
nFrames = size(stack,3);
gFrames = 1:2:nFrames; rFrames = 2:2:nFrames;
frameBin = 100; 
frameParseG = parseFrame(gFrames,frameBin);
frameParseR = parseFrame(rFrames,frameBin);
roiOrder = {'AC','PPC'}; roiY = {1:526,649:1548};
for k = 1:length(roiOrder)
    tic;
    yFrames = roiY{k}; totalFrame = 0;
    saveFilename = [tiffPath filesep 'green_' roiOrder{k} filesep filename(1:end-4) '_parsed.h5'];
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

    toc; tic;  totalFrame = 0;
    saveFilename = [tiffPath filesep 'red_' roiOrder{k} filesep filename(1:end-4) '_parsed.h5'];
    for j = 1:length(frameParseR)
        tempStack = int16(stack(yFrames, :,frameParseR{j}));
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