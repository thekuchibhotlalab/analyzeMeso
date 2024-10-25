function data = fn_plotPSTHbyDay(mouse,plotFlag)
ops.mouse = mouse; if ~exist('plotFlag'); plotFlag = false; end
switch ops.mouse
    case 'zz153_T1_PPC'
        ops.mouse = 'zz153';ops.area = 'PPC'; ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
        ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240516','20240522'};

        ops.task2 = 'task2';
        ops.Fpath2 = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task2 filesep ];
        ops.dayRange2 = {'20240523','20240528'};

    case 'zz153_T2_PPC'
        ops.mouse = 'zz153';
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240523','20240618'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
            
    case 'zz159_T1_PPC'
        ops.mouse = 'zz159';
        ops.area = 'PPC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240613','20240628'}; % task 2 transition
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];    

        ops.task2 = 'task2';
        ops.Fpath2 = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task2 filesep ];
        ops.dayRange2 = {'20240629','20240706'};
    case 'zz159_T1_AC'
        ops.mouse = 'zz159';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240613','20240628'}; % task 2 transition
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];    

        ops.task2 = 'task2';
        ops.Fpath2 = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task2 filesep ];
        ops.dayRange2 = {'20240629','20240706'};
    case 'zz151_T1'

        ops.mouse = 'zz151';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240325','20240417'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
end 

[data, beh, behOps] = fn_loadBehNeuroData(ops);
if isfield(ops,'Fpath2')
    ops.Fpath = ops.Fpath2; ops.dayRange = ops.dayRange2; 
    [data2, beh2, behOps2] = fn_loadBehNeuroData(ops); 
    tempCat = @(x,y)(cat(2,x,y));
    data = fn_structfun(tempCat,{data,data2});
end 
    


if plotFlag; plotPSTH(data); end 

    function plotPSTH(data)

        disp('plot data')


    end 

end 