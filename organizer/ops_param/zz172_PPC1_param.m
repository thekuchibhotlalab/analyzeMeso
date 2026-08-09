myOps.mouse = 'zz172';
myOps.area = 'PPC1'; 
myOps.ID = [myOps.mouse '_' myOps.area]; 


myOps.TCpath = ['B:\' myOps.ID];
myOps.TCname = [myOps.TCpath filesep myOps.ID '_TC.mat'];
myOps.spkname = [myOps.TCpath filesep myOps.ID '_spk.mat'];
myOps.infoName = [myOps.TCpath filesep myOps.ID '_sessionInfo.mat'];
myOps.trackingName = [myOps.TCpath filesep 'stackROI_final_tracked.mat'];
myOps.behavPath = ['G:\ziyi\mesoData\' myOps.mouse '_behavior'];
myOps.alignOpsPath = ['B:\' myOps.ID];

myOps.frameRate = 15; 
myOps.trackingSessionSel = 166; 
myOps.chunkDays = {[1 2],[ 3 4 5 6],[7 8 9 10 11 12 13],... % T1 naive to expert
    [14 15],[21:32], [35:38],... % T2 naive to expert 
    [ 39]}; % interleave days

myOps.normSpk = true; 


