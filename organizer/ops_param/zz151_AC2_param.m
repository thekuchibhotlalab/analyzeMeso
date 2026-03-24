myOps.mouse = 'zz151';
myOps.area = 'AC2'; 
myOps.ID = [myOps.mouse '_' myOps.area]; 


myOps.behavPath = ['G:\ziyi\mesoData\' myOps.mouse '_behavior\matlab\']; 
myOps.TCpath = 'C:\Users\zzhu34\Documents\tempdata\zz151_AC';
myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
%myOps.sessionInfoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.trackingName = [myOps.TCpath filesep 'stackROI_final_tracked_' myOps.area '.mat'];
myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
myOps.spkname = [myOps.TCpath filesep myOps.ID '_spk.mat'];
myOps.infoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.behavPath = 'G:\ziyi\mesoData\zz151_behavior';
myOps.alignOpsPath = 'G:\rockfish\ziyi\zz151_AC2';


myOps.frameRate = 15; 
myOps.trackingSessionSel = 169; 
myOps.chunkDays = {[1 2 3 4],[5 6 7 8],[9 10 11 12 12 14 17],... % task 1 nniave learnig expert
    [18 19 20],[21 22 23],[24 25 26 27 28 29],... % task 2 naive leanring expert 
    [30 31 32 33 34 35]}; % interleaved 

myOps.normSpk = true; 

