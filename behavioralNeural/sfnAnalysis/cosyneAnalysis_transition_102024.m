%%
clear;
ops.mouse = 'zz159';
switch ops.mouse
    case 'zz153'
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240524','20240611'};
        ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\'];    
    case 'zz159'
        ops.area = 'PPC'; ops.task = 'task2';
        ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
        ops.dayRange = {'20240705','20240724'}; % task 2 transition
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
data.selectedBehList(:,end+1) = data.selectedBehList(:,9)-data.selectedBehList(:,8);
data.selectedBehList(:,end+1) = 1:size(data.selectedBehList,1);
%% do kishiore's analysis
idxT2 = find(data.selectedBehList(:,5)>=3,1);
binSize = 50;

beh_t2 = data.selectedBehList(idxT2:end,:);

startIdx = 1; rtLim = 1;
act = cell(1,2);tempCount = 0; accuracy = [];
while startIdx<size(beh_t2,1)
    
    temp3 = beh_t2(startIdx:end,5) == 3 & beh_t2(startIdx:end,6) == 1 & beh_t2(startIdx:end,14) <= rtLim; tempCount3 = cumsum(temp3);
    temp4 = beh_t2(startIdx:end,5) == 4 & beh_t2(startIdx:end,6) == 2 & beh_t2(startIdx:end,14) <= rtLim; tempCount4 = cumsum(temp4);
    endIdx = startIdx - 1 + max([find(tempCount3==binSize,1) find(tempCount4==binSize,1)]);
    disp([startIdx endIdx])
    if endIdx<size(beh_t2,1)
        splitBeh = beh_t2(startIdx:endIdx,:);

        tempFlag = {find(splitBeh(:,5) == 3 & splitBeh(:,6) == 1 & splitBeh(:,14) <= rtLim),...
            find(splitBeh(:,5) == 4 & splitBeh(:,6) == 2 & splitBeh(:,14) <= rtLim)};
        tempIdx = cellfun(@(x)(round(linspace(1,length(x),binSize))),tempFlag,'UniformOutput',false);
        tempF = cellfun(@(x,y)(data.dffStimList(:,:,splitBeh(x(y),15))), tempFlag,tempIdx, 'UniformOutput',false);
        tempCount = tempCount+1; 
        act(tempCount,:) = cellfun(@(x)(nanmean(x,3)),tempF,'UniformOutput',false);
        
        [bias1,acc1] = fn_getAccBias(splitBeh(:,5),...
            splitBeh(:,5)==splitBeh(:,6)+2,splitBeh(:,6)==0); 
        accuracy(tempCount) = acc1;
    end 
    startIdx = endIdx+1; 
end 



idxT1 = idxT2-1;
binSize = 50;

beh_t1 = data.selectedBehList(1:idxT1,:);
temp1 = beh_t1(:,5) == 1 & beh_t1(:,6) == 1 & beh_t1(:,14) <= rtLim; tempCount1 = cumsum(temp1,'reverse');
temp2 = beh_t1(:,5) == 2 & beh_t1(:,6) == 2 & beh_t1(:,14) <= rtLim; tempCount2 = cumsum(temp2,'reverse');
startIdx = min([find(tempCount1==binSize,1,'last') find(tempCount2==binSize,1,'last')]);

tempFlag = {find(beh_t1(startIdx:end ,5) == 1 & beh_t1(startIdx:end,6) == 1 & beh_t1(startIdx:end,14) <= rtLim),...
        find(beh_t1(startIdx:end,5) == 2 & beh_t1(startIdx:end,6) == 2 & beh_t1(startIdx:end,14) <= rtLim)};
tempIdx = cellfun(@(x)(round(linspace(1,length(x),binSize))),tempFlag,'UniformOutput',false);
tempF = cellfun(@(x,y)(data.dffStimList(:,:,beh_t1(x(y),15))), tempFlag,tempIdx, 'UniformOutput',false);
actRef = cellfun(@(x)(nanmean(x,3)),tempF,'UniformOutput',false);

figure; 
%%
corrL = []; corrR = []; accPlot = [];rtPlot = [];
corrLim = 15:60;
for i = 1:size(act,1)
     temp = corr(act{i,1}(:,corrLim)',actRef{1}(:,corrLim)'); 
     corrL(:,i) = diag(temp);
     temp = corr(act{i,2}(:,corrLim)',actRef{2}(:,corrLim)'); 
     corrR(:,i) = diag(temp);

     %accPlot(i) = actAcc{t2Flag(i),2};

     %rtPlot(i) = nanmean([actRT{t2Flag(i),3} actRT{t2Flag(i),4}]);
     
end

figure; hold on; plot(nanmean(corrL,1),'o')
xlabel('T2 Trials in training (binned)'); ylabel('correlation'); title('corr between T1(stim=L) and T2(stim=L)')
figure; hold on; plot(nanmean(corrR,1),'o')
xlabel('T2 Trials in training (binned)'); ylabel('correlation'); title('corr between T1(stim=R) and T2(stim=R)')

figure; hold on; plot(accuracy,'o')
xlabel('T2 Trials in training (binned)'); ylabel('accuracy'); title('perofrmance of T2')


temp1 = fn_cell2mat(act(:,1),3); temp1 = squeeze(nanmean(temp1(:,corrLim,:),2)); corr1 = corr(temp1,'rows','complete');
temp2 = fn_cell2mat(act(:,2),3); temp2 = squeeze(nanmean(temp2(:,corrLim,:),2)); corr2 = corr(temp2,'rows','complete');

figure; subplot(1,2,1); imagesc(corr1); clim([0 1]); colorbar
subplot(1,2,2); imagesc(corr2); clim([0 1]); colorbar


figure; 
[~,sortIdx] = sort(nanmean(act{1,1}(:,26:32) + act{2,2}(:,26:32),2),'descend');
for i = 1:11
    subplot_tight(2,12,1+i,[0.04 0.015]);
    imagesc(act{i,1}(sortIdx,:)); clim([-0.1 0.1]); yticks([]); xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
    subplot_tight(2,12,13+i,[0.04 0.015]);
    imagesc(act{i,2}(sortIdx,:)); clim([-0.1 0.1]); yticks([]); xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
end  

 subplot_tight(2,12,1,[0.04 0.015]);
 imagesc(actRef{1}(sortIdx,:)); clim([-0.05 0.05]); yticks([]); xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})

 subplot_tight(2,12,13,[0.04 0.015]);
 imagesc(actRef{2}(sortIdx,:)); clim([-0.05 0.05]); yticks([]); xticks([15 30 45 60]);xticklabels({'-1','0','1','2'})
