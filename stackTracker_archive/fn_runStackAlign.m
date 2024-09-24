function fn_runStackAlign(handles)

    frame = [1 1 Inf]; nFramesPerDepth = 20; 
    %
    zstackCurr = tiffreadVolume( handles.currName,'PixelRegion', {[1 inf], [1 inf], frame});
    zstackRef = tiffreadVolume( handles.refName,'PixelRegion', {[1 inf], [1 inf], frame});
    nDepth = size(zstackCurr,3)/nFramesPerDepth;
    if str2double(handles.nROI) == 2
        roi1 = 1:str2double(handles.roi1); roi2 = (size(zstackCurr,1)-str2double(handles.roi2)+1):size(zstackCurr,1);
        
        zstackCurr1 = fn_fastAlignROI(zstackCurr,roi1,nFramesPerDepth,nDepth);
        zstackRef1 = fn_fastAlignROI(zstackRef,roi1,nFramesPerDepth,nDepth);

        fn_runStackAlignROI(zstackCurr1,zstackRef1);
    elseif str2double(handles.nROI) == 1
        zstackCurr1 = fn_fastAlignROI(zstackCurr,roi1,nFramesPerDepth,nDepth);
        zstackRef1 = fn_fastAlignROI(zstackRef,roi1,nFramesPerDepth,nDepth);

        fn_runStackAlignROI(zstackCurr1,zstackRef1);
        
    else
        error('ROI more than 2 is not implemented yet!')
    end
   
end

function zstack_aligned = fn_fastAlignROI(zstack,roi,nFramesPerDepth,nDepth)
zstack = zstack(roi,:,:);
zstack = reshape(zstack,[size(zstack,1) size(zstack,2) nFramesPerDepth nDepth]);
zstack_aligned = fn_fastAlignStack(zstack);

end

function fn_runStackAlignROI(zstackCurr,zstackRef)

nDepth = 10; 
avgCorrcoeffs = zeros(1, nDepth+1);
avgCorrcoeffs_R = zeros(1, nDepth+1);

% in order
depthDifference = 0;
for i = 1:(nDepth+1)
    avgCorrcoeff = fn_fastRegStack(zstackCurr, zstackRef, depthDifference);
    avgCorrcoeffs(i) = avgCorrcoeff;
    depthDifference = depthDifference+1;
end

% reverse 
depthDifference = 0; 
for i = 1:(nDepth+1)
    avgCorrcoeff = fn_fastRegStack(zstackCurr, zstackRef, depthDifference);
    avgCorrcoeffs_R(i) = avgCorrcoeff;
    depthDifference = depthDifference+1;
end

figure; hold on;
x_values_positive = 0:nDepth;  x_values_negative = 0:-1:-nDepth; 

% Plot avgCorrcoeffs against the positive x-values
plot(x_values_positive, avgCorrcoeffs, 'b-o'); % 'b-o' specifies blue color and circle markers
% Plot avgCorrcoeffs_R against the negative x-values
plot(x_values_negative, avgCorrcoeffs_R, 'r-o'); % 'r-o' specifies red color and circle markers
hold off;
% Add labels and legend for clarity
xlabel('Depth Differences');
ylabel('Correlation');
xvalues = [x_values_positive x_values_negative]; avgCorr = [avgCorrcoeffs avgCorrcoeffs_R];
[maxCorr,maxIdx] = max(avgCorr); 
title(['Best matching depth difference = ' int2str(xvalues(maxIdx))...
    'um. Need to be deeper by ' int2str(xvalues(maxIdx)) 'um']);

end

