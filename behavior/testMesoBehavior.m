%% LOAD DATA INTO EACH DAY
clear;
mouse = 'zz159';
datapath = ['G:\ziyi\mesoData\' mouse '_behavior\'];
filelist = dir([datapath filesep mouse '_*_2AFCsession*.mat']);
filename = {filelist.name}; tempDay = ''; dayCount = 0;
beh = {}; tempBeh = []; sessionCount = 0; 
for i = 1:length(filename)
    tempFilename = strsplit(filename{i},'_');
    day = tempFilename{2}; 
    load([datapath filesep filename{i}],'allData');
    if ~strcmp(tempDay,day)
        if dayCount ~=0; beh{dayCount} = tempBeh;end
        sessionCount = 1;
        dayCount = dayCount+1; tempDay= day; 
        
        allData = processAllData(allData,dayCount,sessionCount,day);
        tempBeh = allData; 
    else
        sessionCount = sessionCount+1; 
        allData = processAllData(allData,dayCount,sessionCount,day); 
        if size(tempBeh,2) == size (allData,2)
            tempBeh = cat(1,tempBeh,allData);
        elseif size(tempBeh,2) < size (allData,2)
            tempBeh = cat(2,tempBeh, nan(size(tempBeh,1),size (allData,2)-size(tempBeh,2)));
            tempBeh = cat(1,tempBeh,allData);
        elseif size(tempBeh,2) > size (allData,2)
            allData = cat(2,allData, nan(size(allData,1),size (tempBeh,2)-size(allData,2)));
            tempBeh = cat(1,tempBeh,allData);
        end 
    end
    if i==length(filename) && ~isempty(tempBeh); beh{dayCount} = tempBeh; end
end

%%
behOps = struct(); 
behOps.mouse = mouse; %'zz142'; 
behOps.datapath = ['G:\ziyi\mesoData\' behOps.mouse '_behavior\']; %['G:\ziyi\mesoData\' behOps.mouse '_behavior\matlab\']; 
%behOps.date = behavDates; %{'20231106','20231107','20231108','20231109','20231112'};
%behOps.dateNum = cellfun(@(x)(str2num(x)),behOps.date);
behOps.plot = true;  behOps.interleaved = true;
beh = fn_getBehav(behOps);



%% FILL IN MISSING ENTRIES AND CONCATENATE ALL DAYS
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
%% PLOT PERFORMANCE
makeAccPlot(beh, 1:size(beh,1),40)

%% plot two task separately
[task2First] = find(beh(:,5)>2,1,'first'); task2First = 6552; interleaveIdx = 10059;
windowSize = 200;
selIdx =1:task2First-1;makeAccPlot(beh, selIdx,windowSize);
selIdx =task2First:interleaveIdx; makeAccPlot(beh, selIdx,windowSize);
selIdx =interleaveIdx+1:size(beh,1); makeAccPlot(beh, selIdx,windowSize);
%selIdx =task2First:10576; makeAccPlot(beh, selIdx,windowSize);
%selIdx =10577:size(beh,1); makeAccPlot(beh, selIdx,windowSize);

%% see probe data
day = 6;
probeFlag = (beh(:,7) == 2 & beh(:,2) == day);
[~,~,~,~,acc_L,acc_R,ar_L,ar_R] = fn_getAccBias(beh(probeFlag,5),beh(probeFlag,5)==beh(probeFlag,6),beh(probeFlag,6)==0);
%% FUNCTIONS
function makeAccPlot(beh, selIdx,windowSize)
    [bias,acc,dprime,crit,acc_L,acc_R,stimL,ar_L,ar_R] = fn_getAccBiasSmooth(beh(selIdx,5),beh(selIdx,7),windowSize);
    figure; subplot(4,1,1); plot(acc_L); hold on; plot(acc_R); ylabel('accuracy L,R'); legend('L','R');
    xlim([1 length(acc_L)]); ylim([0 1])
    subplot(4,1,2); plot(acc); hold on; plot([1 length(acc_L)],[0.5 0.5], 'Color',[0.8 0.8 0.8]);
    ylabel('accuracy'); xlim([1 length(acc_L)]); ylim([0.2 1])
    subplot(4,1,3); plot(ar_L); hold on; plot(ar_R); ylabel('action rate');  legend('L','R'); xlim([1 length(acc_L)]); ylim([0 1])

    subplot(4,1,4); plot(stimL); ylabel('stimulus probability'); xlim([1 length(acc_L)]); ylim([0 1])

end

function allData = processAllData(allData,dayCount,sessionCount,day)
nanFlag = isnan(allData(:,1));
allData = allData(~nanFlag,:) ;
tempDayCount = ones(size(allData,1),1) * dayCount;
tempSessionCount = ones(size(allData,1),1) * sessionCount;
tempDate = ones(size(allData,1),1) * str2double(day);
allData = cat(2,tempDate,tempDayCount,tempSessionCount,allData); 

end