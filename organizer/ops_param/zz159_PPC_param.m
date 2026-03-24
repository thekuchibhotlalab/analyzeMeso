myOps.mouse = 'zz159';
myOps.area = 'PPC'; 
myOps.ID = [myOps.mouse '_' myOps.area]; 


myOps.behavPath = ['G:\ziyi\mesoData\' myOps.mouse '_behavior\matlab\']; 
myOps.TCpath = ['C:\Users\zzhu34\Documents\tempdata\' myOps.ID];
myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
myOps.spkname = [myOps.TCpath filesep myOps.ID '_spk.mat'];
myOps.infoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.trackingName = [myOps.TCpath filesep 'stackROI_final_tracked.mat'];
myOps.behavPath = ['G:\ziyi\mesoData\' myOps.mouse '_behavior'];
myOps.alignOpsPath = ['G:\rockfish\ziyi\' myOps.ID];

myOps.dayT1 = [20240516,20240522];
myOps.dayT1_expert = [20240516,20240522];
myOps.dayT2 = [20240523,20240618];
myOps.dayT2_expert = [20240516,20240522];
myOps.dayInterleave= [20240516,20240522];

myOps.frameRate = 15; 
myOps.trackingSessionSel = 149; 
myOps.chunkDays = {[1 2 3],[ 4 5 6],[7 8 15 16 17],... % T1 naive to expert
    [18],[19 20 21 22 23], [24 25 26 27],... % T2 naive to expert 
    [ 28 29 30 31 32 33]}; % interleave days

myOps.normSpk = true; 


