%%
clear;
ops.mouse = 'zz159';
switch ops.mouse
    case 'zz153'
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240613','20240618'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];    
    case 'zz159'
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        %ops.dayRange = {'20240725','20240727'}; % expert level
        ops.dayRange = {'20240705','20240710'}; % task 2 transition
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];    
end 
[Fnew, beh, Fops,behOps] = fn_loadData(ops);
if strcmp(ops.area, 'AC')
    [data.dffStimList, data.selectedBehList,behOps] = fn_parseTrial(Fnew, beh, Fops, behOps,'stim'); clear Fnew;
else
    [data.dffStimList, data.selectedBehList,behOps] = fn_parseTrial(Fnew, beh, Fops, behOps,'choice'); clear Fnew;
end
data.dffStimList = fn_cell2mat(data.dffStimList,3);
data.selectedBehList = fn_cell2mat(data.selectedBehList,1);
%% do kishiore's analysis
sessionSplit = [0; find(diff(data.selectedBehList(:,3))); size(data.selectedBehList,1)];
if strcmp(ops.mouse,'zz153'); sessionSplit(end) = []; end 
% by doing this, we are discarding the last trial in zz153, which had 10 trials with miss
nSplit = 2; 
tempBeh = data.selectedBehList;
tempBeh(:,end+1) = tempBeh(:,9)-tempBeh(:,8); % reaction time
tempBeh(:,4) = 1:size(tempBeh,1);

act = {};  actNum = {}; actRT = {};
actAcc = {};  actBias = {}; 
rtLim  = 2; timeSel = 1:60; tempCount = 0; 
for i= 1:length(sessionSplit)-1
    tempIdx = sessionSplit(i)+1:sessionSplit(i+1);
    tempBehDay = tempBeh(tempIdx,:);

    if length(unique(tempBehDay(:,5)))==2; nSplit = 2;
    else; nSplit = 1;end 
    nSplitTrial = size(tempBehDay,1)/nSplit;
    for j = 1:nSplit
        tempCount = tempCount+1; 
        splitBeh = tempBehDay(nSplitTrial*(j-1)+1:nSplitTrial*j,:);
        % get flag for s1a1,s2a2,s3a1,s4a2
        tempFlag = {splitBeh(:,5) == 1 & splitBeh(:,6) == 1 & splitBeh(:,14) <= rtLim,...
            splitBeh(:,5) == 2 & splitBeh(:,6) == 2 & splitBeh(:,14) <= rtLim,...
            splitBeh(:,5) == 3 & splitBeh(:,6) == 1 & splitBeh(:,14) <= rtLim,...
            splitBeh(:,5) == 4 & splitBeh(:,6) == 2 & splitBeh(:,14) <= rtLim};
        tempF = cellfun(@(x)(data.dffStimList(:,:,splitBeh(x,4))), tempFlag, 'UniformOutput',false);
        
        for k = 1:length(tempF)
            if ~isempty(tempF{k}); act{tempCount,k} = nanmean(tempF{k}(:,timeSel,:),3);
            else; act{tempCount,k} = []; end 
            if ~isempty(tempF{k}); actNum{tempCount,k} = size(tempF{k},3);
            else; actNum{tempCount,k} = 0; end 
            actRT{tempCount,k} =  nanmean(splitBeh(tempFlag{k},14));


        end 
        flagT1 = splitBeh(:,5)<=2; [bias1,acc1] = fn_getAccBias(splitBeh(flagT1,5),...
            splitBeh(flagT1,5)==splitBeh(flagT1,6),splitBeh(flagT1,6)==0); 
        flagT2 = splitBeh(:,5)>=3; [bias2,acc2] = fn_getAccBias(splitBeh(flagT2,5),...
            splitBeh(flagT2,5)==(splitBeh(flagT2,6)+2),splitBeh(flagT2,6)==0); 
        actAcc{tempCount,1} = acc1; actAcc{tempCount,2} = acc2; 
        actBias{tempCount,1} = bias1; actBias{tempCount,2} = bias2; 
        

    end 
end 
%% zz153
switch ops.mouse
    case 'zz153'
        daySplit = [0 6 16 24];
        daySplitPlot = [3.5 9.5];
        
        flagT1 = [1 2 5 9 10 11 12 13 14 19 20 21 22 23];
        flagT2 = [3 4 5 7 8  11 15 16 14 17 18 21 17 18];
        flagInt=[ 0 0 1 0 0  1  0  0  1  0  0  1  0  0];
    case 'zz159'
        daySplit = [0 11 21 31];
        daySplitPlot = [7.5 13.5];
        
        flagT1 = [1 2 3 4  5 6  11 14 15 16 17 18 21 22 23 26 29 30 31];
        flagT2 = [7 8 9 10 9 10 11 12 13 16 19 20 21 24 25 26 27 28 31];
        flagInt=[ 0 0 0 0  0 0  1  0  0  1  0  0   1 0  0   1 0  0   1];
end 
corrL = []; corrR = []; accPlot = [];rtPlot = [];
for i = 1:length(flagT1)
     temp = corr(act{flagT1(i),1}',act{flagT2(i),3}'); 
     corrL(:,i) = diag(temp);
     accPlot(i) = (actAcc{flagT1(i),1}+actAcc{flagT2(i),2})/2;
     rtPlot(i) = nanmean([actRT{flagT1(i),1} actRT{flagT1(i),2} actRT{flagT2(i),3} actRT{flagT2(i),4}]);
     temp = corr(act{flagT1(i),2}',act{flagT2(i),4}'); 
     corrR(:,i) = diag(temp);
end

tempAxis = 1:length(flagInt);
figure; hold on; plot(tempAxis(~logical(flagInt)),nanmean(corrL(:,~logical(flagInt)),1),'o')
plot(tempAxis(logical(flagInt)),nanmean(corrL(:,logical(flagInt)),1),'o')
for i = 1:length(daySplitPlot); plot([daySplitPlot(i) daySplitPlot(i)],[0 0.9],'Color',[0.8 0.8 0.8]);end 
legend({'block','interleaved'}); xlabel('Training session'); ylabel('correlation'); title('corr between T1(stim=L) and T2(stim=L)')


figure; hold on; plot(tempAxis(~logical(flagInt)),nanmean(corrR(:,~logical(flagInt)),1),'o')
plot(tempAxis(logical(flagInt)),nanmean(corrR(:,logical(flagInt)),1),'o')
for i = 1:length(daySplitPlot); plot([daySplitPlot(i) daySplitPlot(i)],[0 0.9],'Color',[0.8 0.8 0.8]);end 
legend({'block','interleaved'}); xlabel('Training session'); ylabel('correlation'); title('corr between T1(stim=R) and T2(stim=R)')



figure; hold on; plot(tempAxis(~logical(flagInt)),nanmean(accPlot(:,~logical(flagInt)),1),'o')
plot(tempAxis(logical(flagInt)),nanmean(accPlot(:,logical(flagInt)),1),'o'); ylim([0.5 1.0])
for i = 1:length(daySplitPlot); plot([daySplitPlot(i) daySplitPlot(i)],[0 1.0],'Color',[0.8 0.8 0.8]);end 
legend({'block','interleaved'}); xlabel('Session'); ylabel('% correct choice'); title('Avg. accuracy in each session')

figure; hold on; plot(tempAxis(~logical(flagInt)),nanmean(rtPlot(:,~logical(flagInt)),1),'o')
plot(tempAxis(logical(flagInt)),nanmean(rtPlot(:,logical(flagInt)),1),'o'); ylim([0 1.0])
for i = 1:length(daySplitPlot); plot([daySplitPlot(i) daySplitPlot(i)],[0 1.0],'Color',[0.8 0.8 0.8]);end 
legend({'block','interleaved'}); xlabel('Session'); ylabel('response time'); title('Avg. response time in each session')
%%

figure; subplot(1,2,1); imagesc(act{11,1}); caxis([-0.1 0.1]); xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
subplot(1,2,2); imagesc(act{11,3}); caxis([-0.1 0.1]);xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
figure; subplot(1,2,1); imagesc(act{26,1}); caxis([-0.1 0.1]);xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
subplot(1,2,2); imagesc(act{26,3}); caxis([-0.1 0.1]);xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
%%
t2Flag = 13:25;
corrL = []; corrR = []; accPlot = [];rtPlot = [];
for i = 1:length(t2Flag)
     temp = corr(act{12,1}',act{t2Flag(i),3}'); 
     corrL(:,i) = diag(temp);
     accPlot(i) = actAcc{t2Flag(i),2};
     rtPlot(i) = nanmean([actRT{t2Flag(i),3} actRT{t2Flag(i),4}]);
     temp = corr(act{12,2}',act{t2Flag(i),4}'); 
     corrR(:,i) = diag(temp);
end

figure; hold on; plot(nanmean(corrL,1),'o')
xlabel('Training session'); ylabel('correlation'); title('corr between T1(stim=L) and T2(stim=L)')
figure; hold on; plot(nanmean(corrR,1),'o')
xlabel('Training session'); ylabel('correlation'); title('corr between T1(stim=L) and T2(stim=L)')

figure; hold on; plot(accPlot,'o')
xlabel('Training session'); ylabel('accuracy'); title('performance accuracy')

%% all functions

function groupF = getDataGrouping (parsedF,grouping)
    groupF = {};
    for i = 1:length(grouping)
        tempP = parsedF(:,:,grouping{i});
        for j = 1:size(tempP,1)
            for k = 1:size(tempP,2)
                groupF{j,k,i} = cat(3,tempP{j,k,:});
            end 
        end 

    end 
        


end 

function tempSize = getSize(inCell)
    tempSize = zeros(size(inCell));
    for i = 1:size(inCell,1)
        for j = 1:size(inCell,2)
            if ~isempty(inCell{i,j})
                tempSize(i,j) = size(inCell{i,j},3);
            else
                tempSize(i,j) = 0;
            end
        end 
    end

end 

