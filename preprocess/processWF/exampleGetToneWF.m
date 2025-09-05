% First specify the 
roiOps.nROI = 4; % This is the number of ROIs
roiOps.ylen  = 152; % This the pixel size of a ROI on the y-axis
% This matrix tells how ROI needs to be concatenated and in what order
% E.g. [1;2;3;4] concetenate vertically and [1 2 3 4] concetenate horizontally
% [1 2; 3 4] make a 2*2 concatenation of the ROIs.
roiOps.roiPos = [1 2 3 4]; 
roiOps.selChan=1; roiOps.nChan=2; % This specifies the channel of recording
% Finally run your WF analysis code
[imgBaselineAvg,imgPresAvg] = fn_getToneActWF_SU(...
    'C:\Users\zzhu34\Documents\tempdata\sk269\20250716_00001.tif', roiOps);


%[imgBaselineAvg,imgPresAvg] = fn_getToneActWF(...
%    'C:\Users\zzhu34\Documents\tempdata\zz173\zz173_20250707_WF_00001.tif', roiOps);
