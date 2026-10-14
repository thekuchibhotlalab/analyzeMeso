function [Fnew, removalMetric] = fn_correctForMotionFrames(F,moveX,moveY,nFramesSum)

moveXBaseline = zeros(size(moveX)); moveYBaseline = zeros(size(moveY));
for i = 1:length(nFramesSum)-1
    tempFrame = nFramesSum(i)+1:nFramesSum(i+1); 
    tempX = moveX(tempFrame); tempY = moveY(tempFrame); 
    moveXBaseline(tempFrame) = smoothdata(tempX,'movmean',3000);
    moveYBaseline(tempFrame) = smoothdata(tempY,'movmean',3000);
end
removalMetric = abs(moveX-moveXBaseline)+abs(moveY-moveYBaseline);

figure; hold on; plot(moveX-moveXBaseline); 
plot(moveY-moveYBaseline); 
plot(removalMetric);
figure; histogram(removalMetric)

removalThreshold = Inf; 
Fnan = F; 
Fnan(:,removalMetric>removalThreshold) = nan; 

Fnew = fillmissing(Fnan,'linear',2);

end 