function beh = fn_getBehav(ops)
% ops.mouse (required) -- mouse name, 'zz142'
% ops.datapath (required) -- location of data ['G:\ziyi\mesoData\' mouse '_behavior\matlab\']
% ops.plot -- flag for plotting
% ops.date -- date to plot, a cell of {}
% ops.dayRange -- range of dates to plot, an array of doubles [20231016, 20231104]
filelist = dir([ops.datapath filesep ops.mouse '_*_2AFCsession*.mat']);
if isfield(ops,'date') 
    if ~iscell(ops.date); ops.date = {ops.date}; end 
    fileSel = false(1,length(filelist));
    for i=1:length(filelist)
        tempName = strsplit(filelist(i).name,'_'); tempName = tempName{2};
        fileSel(i) = contains(tempName,ops.date);
    end
    filelist = filelist(fileSel);
end

if isfield(ops,'dayRange') 
    fileSel = zeros(1,length(filelist));
    for i=1:length(filelist)
        tempName = strsplit(filelist(i).name,'_'); tempName = tempName{2};
        fileSel(i) = str2double(tempName);
    end
    tempIdx = fileSel>=ops.dayRange(1) & fileSel<=ops.dayRange(2);
    filelist = filelist(tempIdx);
end

filename = {filelist.name}; tempDay = ''; dayCount = 0;
beh = {}; tempBeh = []; %sessionCount = 0; 
for i = 1:length(filename)
    tempFilename = strsplit(filename{i},'_');
    day = tempFilename{2}; 
    load([ops.datapath filesep filename{i}],'allData');
    if ~strcmp(tempDay,day)
        if dayCount ~=0; beh{dayCount} = tempBeh;end

        tempSplit = strsplit(filename{i},'_');
        sessionCount = str2num(tempSplit{3}(end));
        dayCount = dayCount+1; tempDay= day; 
        
        allData = processAllData(allData,dayCount,sessionCount,day);
        tempBeh = allData; 
    else
        tempSplit = strsplit(filename{i},'_');
        sessionCount = str2num(tempSplit{3}(end));
        allData = processAllData(allData,dayCount,sessionCount,day); 

        tempBeh = fn_catFillNan(1,tempBeh,allData);

        %tempBeh = cat(1,tempBeh,allData);
    end
    if i==length(filename) && ~isempty(tempBeh); beh{dayCount} = tempBeh; end
end



% FILL IN MISSING ENTRIES AND CONCATENATE ALL DAYS
tempSize = [];
for i = 1:length(beh);tempSize(i) = size(beh{i},2); end
maxSize = max(tempSize);
for i = 1:length(beh)
    if size(beh{i},2) < maxSize
        tempNan = nan(size(beh{i},1),maxSize-size(beh{i},2));
        beh{i} = cat(2,beh{i},tempNan);
    end
end
beh = fn_cell2mat(beh,1);



% PLOT PERFORMANCE
if isfield(ops,'plot') && ops.plot
    makePlot(beh)
end

if isfield(ops,'interleaved') && ops.interleaved
    tempbeh1 = beh; tempbeh1(beh(:,5)==3 | beh(:,5)==4,:) = nan; daySep = find(diff(beh(:,1),1)>0);
    tempbeh2 = beh; tempbeh2(beh(:,5)==1 | beh(:,5)==2,:) = nan; 
    [bias1,acc1,~,~,~,~,~,ar_L,ar_R] = fn_getAccBiasSmooth(tempbeh1(:,5),tempbeh1(:,7),100); ar1 = (ar_L+ar_R)/2; 
    [bias2,acc2,~,~,~,~,~,ar_L,ar_R] = fn_getAccBiasSmooth(tempbeh2(:,5),tempbeh2(:,7),100); ar2 = (ar_L+ar_R)/2; 
    figure; subplot(4,1,1); hold on; plot(acc1,'LineWidth',2); plot(acc2,'LineWidth',2); ylim([0.4 1]);xlim([1 length(acc1)]); ylabel('accuracy');
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[0 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 
    subplot(4,1,2); hold on; plot(bias1,'LineWidth',2); plot(bias2,'LineWidth',2); plot([1 length(acc1)],[0 0], 'Color',[0.8 0.8 0.8]);
    xlim([1 length(acc1)]);ylim([-1 1]); ylabel('bias');
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[-1 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 
    subplot(4,1,3); plot(ar1,'LineWidth',2); hold on; plot(ar2,'LineWidth',2); ylabel('action rate');  legend('L','R','AutoUpdate','off');xlim([1 length(acc1)]);
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[0 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 
end

end

%% FUNCTIONS
function  makePlot (beh)
    daySep = find(diff(beh(:,1),1)>0);
    [bias,acc,dprime,crit,acc_L,acc_R,stimL,ar_L,ar_R] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),200);
    figure; subplot(4,1,1); hold on; plot(acc,'LineWidth',2); ylim([0.4 1]);xlim([1 length(acc)]); ylabel('accuracy');
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[0 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 
    %hold on; plot(acc_R); ylabel('accuracy L,R'); legend('L','R');
    subplot(4,1,2); plot(bias,'LineWidth',2); hold on; plot([1 length(acc_L)],[0 0], 'Color',[0.8 0.8 0.8]);
    xlim([1 length(acc)]);ylim([-1 1]); ylabel('bias');
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[-1 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 
    subplot(4,1,3); plot(ar_L,'LineWidth',2); hold on; plot(ar_R,'LineWidth',2); ylabel('action rate');  legend('L','R','AutoUpdate','off');xlim([1 length(acc)]);
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[0 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 
    subplot(4,1,4); hold on; plot(stimL); ylabel('stimulus probability'); xlim([1 length(acc)]);
    for i = 1:length(daySep); plot([daySep(i) daySep(i)]+0.5,[0 1],'Color',[0.8 0.8 0.8],'LineWidth',2); end 

end 
function allData = processAllData(allData,dayCount,sessionCount,day)
nanFlag = isnan(allData(:,1));
allData = allData(~nanFlag,:) ;
tempDayCount = ones(size(allData,1),1) * dayCount;
tempSessionCount = ones(size(allData,1),1) * sessionCount;
tempDate = ones(size(allData,1),1) * str2double(day);
allData = cat(2,tempDate,tempDayCount,tempSessionCount,allData); 

end