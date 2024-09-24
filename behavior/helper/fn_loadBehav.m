function beh = fn_loadBehav(ops)
% THIS IS THE OLDER VERSION OF beh = fn_getBehav(ops)
filelist = dir([ops.datapath filesep ops.mouse '_*_2AFCsession*.mat']);
filename = {filelist.name}; tempDay = ''; dayCount = 0;
beh = {}; tempBeh = []; sessionCount = 0; 
for i = 1:length(filename)
    tempFilename = strsplit(filename{i},'_');
    day = tempFilename{2}; 
    load([ops.datapath filesep filename{i}],'allData');
    if ~strcmp(tempDay,day)
        if dayCount ~=0; beh{dayCount} = tempBeh;end
        sessionCount = 1;
        dayCount = dayCount+1; tempDay= day; 
        
        allData = processAllData(allData,dayCount,sessionCount,day);
        tempBeh = allData; 
    else
        sessionCount = sessionCount+1; 
        allData = processAllData(allData,dayCount,sessionCount,day); 
        
        tempBeh = fn_catFillNan(1,tempBeh,allData);
        
        %if size(tempBeh,2) == size (allData,2)
        %    tempBeh = cat(1,tempBeh,allData);
        %elseif size(tempBeh,2) < size (allData,2)
        %    tempBeh = cat(2,tempBeh, nan(size(tempBeh,1),size (allData,2)-size(tempBeh,2)));
        %    tempBeh = cat(1,tempBeh,allData);
        %elseif size(tempBeh,2) > size (allData,2)
        %    allData = cat(2,allData, nan(size(allData,1),size (tempBeh,2)-size(allData,2)));
        %    tempBeh = cat(1,tempBeh,allData);
        %end 
    end
    if i==length(filename) && ~isempty(tempBeh); beh{dayCount} = tempBeh; end
end

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

end 


function allData = processAllData(allData,dayCount,sessionCount,day)
nanFlag = isnan(allData(:,1));
allData = allData(~nanFlag,:) ;
tempDayCount = ones(size(allData,1),1) * dayCount;
tempSessionCount = ones(size(allData,1),1) * sessionCount;
tempDate = ones(size(allData,1),1) * str2double(day);
allData = cat(2,tempDate,tempDayCount,tempSessionCount,allData); 

end