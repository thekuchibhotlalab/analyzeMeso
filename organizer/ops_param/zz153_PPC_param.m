% Information about mouse and recording area
myOps.mouse = 'zz153';
myOps.area = 'PPC'; 
myOps.ID = [myOps.mouse '_' myOps.area]; 
% Information about data location of the animal
myOps.behavPath = ['G:\ziyi\mesoData\' myOps.mouse '_behavior\matlab\']; 
myOps.TCpath = 'C:\Users\zzhu34\Documents\tempdata\zz153_PPC';
myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
myOps.spkname = [myOps.TCpath filesep myOps.ID '_spk.mat'];
myOps.infoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.trackingName = [myOps.TCpath filesep 'stackROI_final_tracked.mat'];
myOps.behavPath = 'G:\ziyi\mesoData\zz153_behavior';
myOps.alignOpsPath = 'G:\rockfish\ziyi\zz153_PPC';
% Information about recording and behavior
%myOps.dayT1 = [20240516,20240522];
%myOps.dayT1_expert = [20240516,20240522];
%myOps.dayT2 = [20240523,20240618];
%myOps.dayT2_expert = [20240516,20240522];
%myOps.dayInterleave= [20240516,20240522];

myOps.frameRate = 15; 
% selection criteria for tracking
myOps.trackingSessionSel = 107; 
% chunking of days for TCA analysis of 7 different periods
myOps.chunkDays = {[1 2 3],[4 5],[6 8 9],... % task 1 naive learnig expert
    [10 11 12],[13 14 15 16],[17 18 19],... % task 2 naive leanring expert 
    [20 21]}; % interleaved 
myOps.normSpk = true; 


