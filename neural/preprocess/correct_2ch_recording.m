function correct_2ch_recording(corretionPath)

fname = dir([corretionPath filesep '*.h5']);

frameBin = 2000; 


for i = 1:length(fname)     
    disp(fname(i).name)
    h5name  = [corretionPath filesep fname(i).name];
    data_old = h5read(h5name,'/data', [ 1 1 1], [676 512 Inf], [1 1 1]);
    data_new = data_old(:,:,1:2:end); 

    saveFilename = [corretionPath filesep 'corrected' filesep fname(i).name];
    
    frameParseG = parseFrame(1:size(data_new,3),frameBin);
    totalFrame = 0;
    for j = 1:length(frameParseG)
        tempStack = int16(data_new(:, :,frameParseG{j}));
        temph5Size = [size(tempStack,1) size(tempStack,2)];
        if(j==1)
            h5create(saveFilename,'/data',[temph5Size Inf],'DataType','int16','ChunkSize',[temph5Size frameBin]);
            h5write(saveFilename,'/data',tempStack,[1 1 1],[temph5Size size(tempStack,3)]);
        else
            h5write(saveFilename,'/data',tempStack,[1 1 totalFrame+1],[temph5Size size(tempStack,3)]);
        end  
        totalFrame = totalFrame + size(tempStack,3);
    end

    meanImgFrames = 2000; 
    if size(data_new,3)>meanImgFrames; meanImg = fn_fastAlign(data_new(:,:,1:meanImgFrames));
    else; meanImg = fn_fastAlign(data_new(:,:,1:end));
    end 
    meanImg = nanmean(meanImg,3);
    save([saveFilename(1:end-3) '.mat'],'meanImg'); 
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