function fn_saveTrialAvgData(mouse)

    switch mouse

    case 'zz153_T1_PPC'
        ops.mouse = 'zz153';
        ops.area = 'PPC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240516','20240522'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
        
    case 'zz153_T2_PPC'
        ops.mouse = 'zz153';
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240523','20240618'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 

    case 'zz153_Exp_PPC'
        ops.mouse = 'zz153';
        ops.area = 'PPC'; ops.task = 'task1'; % the interleaved data is registered together with pretraining
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240619','20240627'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 

    case 'zz159_T1_AC'
        ops.mouse = 'zz159';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240613','20240628'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
    case 'zz159_T2_AC'
        ops.mouse = 'zz159';
        ops.area = 'AC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240629','20240727'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
    case 'zz159_T2_PPC'
        ops.mouse = 'zz159';
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240629','20240727'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
    case 'zz159_T1_PPC'
        ops.mouse = 'zz159';
        ops.area = 'PPC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240613','20240628'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
    
    case 'zz151_T1'

        ops.mouse = 'zz151';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240325','20240417'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 

    case 'zz151_T2'

        ops.mouse = 'zz151';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        %ops.dayRange = {'20240413','20240503'};
        ops.dayRange = {'20240428','20240516'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];
    case 'zz151_Exp'

        ops.mouse = 'zz151';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        %ops.dayRange = {'20240413','20240503'};
        ops.dayRange = {'20240517','20240608'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];
    end 

    [Fnew, beh, Fops,behOps] = fn_loadData(ops);
    if strcmp(ops.area, 'AC')
        [data.dffStimList, data.selectedBehList,behOps] = fn_parseTrial(Fnew, beh, Fops, behOps,'stim'); clear Fnew;
    else
        [data.dffStimList, data.selectedBehList,behOps] = fn_parseTrial(Fnew, beh, Fops, behOps,'choice'); clear Fnew;
    end         
    data = fn_analyzeTaskTransition(data,behOps);
    
mkdir([ops.Fpath filesep 'parsed_F' ]);    
for i = 1:length(behOps.dateNum)
    saveList = {};
    s1a1 = cat(3,data.s1a1{1}{i},data.s1a1{2}{i},data.s1a1{3}{i});saveList = [saveList, 's1a1'];
    s2a2 = cat(3,data.s2a2{1}{i},data.s2a2{2}{i},data.s2a2{3}{i});saveList = [saveList, 's2a2'];
    s1a2 = cat(3,data.s1a2{1}{i},data.s1a2{2}{i},data.s1a2{3}{i});saveList = [saveList, 's1a2'];
    s2a1 = cat(3,data.s2a1{1}{i},data.s2a2{2}{i},data.s2a1{3}{i});saveList = [saveList, 's2a1'];
    if isfield(data,'s3a1'); s3a1 = cat(3,data.s3a1{1}{i},data.s3a1{2}{i},data.s3a1{3}{i});
    else; s3a1 = []; end;  saveList = [saveList, 's3a1']; 
    if isfield(data,'s3a2'); s3a2 = cat(3,data.s3a2{1}{i},data.s3a2{2}{i},data.s3a2{3}{i});
    else; s3a2 = []; end;  saveList = [saveList, 's3a2']; 
    if isfield(data,'s4a1'); s4a1 = cat(3,data.s4a1{1}{i},data.s4a1{2}{i},data.s4a1{3}{i});
    else; s4a1 = [];end; saveList = [saveList, 's4a1'];    
    if isfield(data,'s4a2'); s4a2 = cat(3,data.s4a2{1}{i},data.s4a2{2}{i},data.s4a2{3}{i});
    else; s4a2 = [];end; saveList = [saveList, 's4a2'];
    nTrials = [length(s1a1) length(s1a2) length(s2a1) length(s2a2) ...
        length(s3a1) length(s3a2) length(s4a1) length(s4a2)];
    
    save([ops.Fpath filesep 'parsed_F' filesep 'F_' int2str(behOps.dateNum(i)) '.mat'],saveList{:},'nTrials');

end
end 



