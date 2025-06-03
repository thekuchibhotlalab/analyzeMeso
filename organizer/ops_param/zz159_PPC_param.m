ops.mouse = 'zz159';
ops.area = 'PPC'; 
ops.ID = [ops.mouse '_' ops.area]; 


ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
ops.TCpath = 'C:\Users\zzhu34\Documents\tempdata\zz159_PPC';
ops.TCname = [ops.TCpath filesep ops.ID '_TC.mat'];
%ops.sessionInfoName = [ops.TCpath filesep ops.ID '_sessionInfo.mat'];
ops.trackingName = [ops.TCpath filesep 'stackROI_final_tracked.mat'];

ops.dayT1 = [20240516,20240522];
ops.dayT1_expert = [20240516,20240522];
ops.dayT2 = [20240523,20240618];
ops.dayT2_expert = [20240516,20240522];
ops.dayInterleave= [20240516,20240522];


