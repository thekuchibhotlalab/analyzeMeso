w%% plot PSTH
mouseList = {'zz153_T1_PPC','zz159_T1_PPC','zz151_T1_AC','zz159_T1_AC'};

for i = 1:length(mouseList)
    data = retrieveT1(mouseList{i});
    
    plotPSTH(data,mouseList{i},'stim',1,0);
    plotPSTH(data,mouseList{i},'stim',1,1);
    plotPSTH(data,mouseList{i},'stim',2,0);
    plotPSTH(data,mouseList{i},'stim',2,1);
    
    plotPSTH(data,mouseList{i},'choice',1,0);
    plotPSTH(data,mouseList{i},'choice',1,1);
    plotPSTH(data,mouseList{i},'choice',2,0);
    plotPSTH(data,mouseList{i},'choice',2,1);
end 

%% plot cluster

mouseList = {'zz153_T1_PPC','zz159_T1_PPC','zz151_T1_AC','zz159_T1_AC'};
selDay = {};
for i = 1:length(mouseList)
    data = retrieveT1(mouseList{i});
    
    if strcmp(mouseList{i},'zz159_T1_AC')
        selDay = [1:5 7:13 15:16]; 
    elseif strcmp(mouseList{i},'zz159_T1_PPC')
        selDay = [1:5 7:12 14:15]; 
    elseif strcmp(mouseList{i},'zz151_T1_AC') 
        selDay = 1:16;
    elseif strcmp(mouseList{i},'zz153_T1_PPC') 
        selDay = [1:9 11];
    end 

    fn_plotCluster(data,'stim',selDay,mouseList{i});
    fn_plotCluster(data,'stim_wholeTrial',selDay,mouseList{i});
    fn_plotCluster(data,'choice',selDay,mouseList{i});
    fn_plotCluster(data,'choice_wholeTrial',selDay,mouseList{i});
end 
%% plot PCA 
selFrame = 26:60;
selAct = {}; 
for i = 1:length(data.dffStimList)
    [flagList, titleList] = fn_selectStim(data.selectedBehList{i},1);
    temp = {}; 
    for j = 1:4
        try 
            temp{j} = nanmean(data.dffStimList{i}(:,selFrame,flagList{j}),3);
        catch
            disp('ahh')
        end 
        if isempty(temp{j}); temp{j} = nan(size(data.dffStimList{i},1),length(selFrame)); end 
    end 
    selAct{i} = cat(3,temp{:});
end 
fn_plotPCA(selAct);
%% retrieve data
function data = retrieveT1(mouse)
ops.mouse = mouse; 
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
    case 'zz151_T1_AC'

        ops.mouse = 'zz151';
        ops.area = 'AC'; ops.task = 'task1';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240325','20240417'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
end 

[data, beh, behOps, Fops] = fn_loadBehNeuroData(ops);
if isfield(ops,'Fpath2')
    ops.Fpath = ops.Fpath2; ops.dayRange = ops.dayRange2; 
    [data2, beh2, behOps2, Fops2] = fn_loadBehNeuroData(ops); 
    tempCat = @(x,y)(cat(2,x,y));
    data = fn_structfun(tempCat,{data,data2});
end 

end 




