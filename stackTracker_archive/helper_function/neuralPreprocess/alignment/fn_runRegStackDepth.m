function [allCorrcoeff,x_values] = fn_runRegStackDepth(zstackCurr,zstackRef)

nDepth = 10; x_values = -nDepth:nDepth;
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
    avgCorrcoeff = fn_fastRegStack(zstackCurr, zstackRef, depthDifference,true);
    avgCorrcoeffs_R(i) = avgCorrcoeff;
    depthDifference = depthDifference+1;
end

allCorrcoeff = [fliplr(avgCorrcoeffs_R(2:end)) avgCorrcoeffs];
end 