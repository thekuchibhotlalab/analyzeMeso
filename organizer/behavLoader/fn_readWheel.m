function [wheelFrame, wheelTime] = fn_readWheel(filename)

tempFrame = load([filename '_frame.txt']);
tempDiff = [0 diff(tempFrame)];
frame = find(tempDiff>0);

tempTimer = load([filename '_timer.txt']);
tempDiff = [0 diff(tempTimer)];
timer = find(tempDiff>0); % each entry of timer is 100ms

tempWheel  = load([filename '_wheel.txt']);
wheelFrame = tempWheel(frame);
wheelTime = tempWheel(timer); 
end 