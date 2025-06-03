function [imgBaselineAvg,imgPresAvg] = fn_getToneActWF_sbx(fileName,paramFun)

global nPlanes
nPlanes = 2;
% tone ID
eval(paramFun);


[pathstr, name, ext] = fileparts(fileName);
% process each trial
imgPres = cell(1,nTones);
imgBaseline = cell(1,nTones);

tempStart = 0; 
for i = 1:nTrials
    disp(['Trial ' int2str(i)])
    imgFOV = loadSbx(fileName,tempStart,nFramesPerTrial*nPlanes);
    imgFOV = squeeze(imgFOV(1,:,:,:));
    imgFOV = imgFOV(:,:,1:2:end);
    imgFOV = reshape(imgFOV,size(imgFOV,1),size(imgFOV,2),nFramesPerTone,nTones);
    
    for j = 1:nTones
        temp = imgFOV(:,:,1:toneOnset+5,j);
        imgBaseline{j}{i} = mean(temp(:,:,1:toneOnset),3);
        imgPres{j}{i} =  mean(temp(:,:,toneOnset+1:end),3);
    end

    tempStart = tempStart+nFramesPerTrial*nPlanes;
end

% plot the figure
imgPresAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgPres,'UniformOutput',false),3);
imgBaselineAvg = fn_cell2mat(cellfun(@(x)(mean(fn_cell2mat(x,3),3)),imgBaseline,'UniformOutput',false),3);
imgPresAvg = imgPresAvg(:,:,toneindex); imgBaselineAvg = imgBaselineAvg(:,:,toneindex);
imgBaselineF = mean(imgBaselineAvg,3); imgBaselineF(imgBaselineF<0) = 0; imgBaselineF = imgBaselineF+20;

smoothRange = 40;

figure; 
for i = 1:17
    subplot(3,6,i);
    K = (1/smoothRange.^2)*ones(smoothRange,smoothRange);
    tempImg = conv2(imgPresAvg(:,:,i)-imgBaselineAvg(:,:,i),K,'same');
    tempBaseline = conv2(imgBaselineF,K,'same'); 
    %imagesc((tempImg./tempBaseline-1)'); colormap gray; clim([-0.05 0.05]);
    imagesc((tempImg)'); colormap gray; clim([-100 100]);
    title([int2str(round(tone(toneindex(i)))) ' Hz'])
end

K = (1/144)*ones(12,12);
tempImg = conv2(mean(imgPresAvg,3)-mean(imgBaselineAvg,3),K,'same');
figure; imagesc(tempImg');colormap gray; clim([-3 3]);


%imgFOV = fn_getFOV(tiffPath,fileName,[tempFrameStart nChan tempFrameStart+nFramesPerTrial-2],roiSize,roiPos,nROI);
%tempImg = mean(imgFOV,3);
%figure; imagesc(tempImg');colormap gray; clim([0 prctile(tempImg(:),99)]);

%tempImg = {};
%for i = 1:17
%    K = (1/7200)*ones(120,6);
%    tempImg{i} = conv2(imgPresAvg(:,:,i)-imgBaselineAvg(:,:,i),K,'same');
%    tempBaseline = conv2(imgBaselineF,K,'same'); 
%end
%tempImg = fn_cell2mat(tempImg,3);[~,a] = max(tempImg,[],3);
%figure;
%imagesc(a); colormap jet; clim([1 17])

end


function frames = loadSbx(filename,startFrame,nFrame)
    [pathstr, name, ext] = fileparts(filename);
    frames = double(sbxread([pathstr filesep name],startFrame,nFrame));


end 