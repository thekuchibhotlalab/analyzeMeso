myOps.mouse = 'zz180';
myOps.area = 'PPC'; 
myOps.ID = [myOps.mouse '_' myOps.area]; 


myOps.TCpath = ['B:\' myOps.ID];
myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
myOps.spkname = [myOps.TCpath filesep myOps.ID '_spk.mat'];
myOps.infoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.trackingName = [myOps.TCpath filesep 'stackROI_final_tracked.mat'];
myOps.behavPath = ['G:\ziyi\mesoData\' myOps.mouse '_behavior'];
myOps.alignOpsPath = ['B:\' myOps.ID];

myOps.frameRate = 15; 
myOps.trackingSessionSel = 100; 
myOps.chunkDays = {[1],[ 2 3],[9 10],... % T1 naive to expert
    [11 12],[16 18 ], [21:24],... % T2 naive to expert 
    [ 25]}; % interleave days

myOps.normSpk = true; 