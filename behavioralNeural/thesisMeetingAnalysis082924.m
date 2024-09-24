clear;

ops.area = 'PPC';
ops.Fpath = ['D:\zz142\committee\110423_111223\green_' ops.area '\suite2p\plane0'];
ops.behavDates = {'20231104','20231105','20231106','20231107','20231108','20231109','20231112'};
ops.mouse = 'zz142'; ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
data = fn_loadBehNeuroData(ops);

%% get respone flag by RT
data = fn_analyzeTaskTransition(data,ops);


%% to process zz153
clear;

ops.mouse = 'zz153';
ops.area = 'PPC';
ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area ];
ops.behavDates = {'20240523','20240524','20240526','20240527','20240529',...
    '20240530','20240531','20240601','20240602','20240604','20240605','20240606','20240607',...
    '20240610','20240611','20240612','20240613','20240617','20240618'};
ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
%data = fn_loadBehNeuroData(ops);
[Fnew, beh, Fops,behOps] = fn_loadData(ops.mouse, ops.Fpath,ops.behavPath,ops.behavDates);
%% get trial aligned to stimulus
[data.dffStimList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps,'stim'); clear Fnew; 
%% get trial aligned to choice
[data.dffStimList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps,'choice'); clear Fnew; 

%% split data into stimulus and action types
data = fn_analyzeTaskTransition(data,ops);

%% zz153 -- compare passive and active trials
missPSTH = nanmean(data.dffStimList{3}(:,1:100,data.missFlag{3}),3);
actPSTH = nanmean(data.dffStimList{4}(:,1:100,data.oneNoteFlag{4} | data.twoNoteFlag{4}),3);

xFrameLim = 100;
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));

[~,sortIdx] = sort(nanmean(missPSTH(:,31:60),2),'descend');
figure; subplot(1,2,1);imagesc(xAxisStim,1:size(missPSTH,1),missPSTH(sortIdx,:)); clim([-0.08 0.08])
xticks(xtickVal); xticklabels(xtickStr);
ylabel('Neuron'); xlabel('Time in trial (sec)')

subplot(1,2,2);imagesc(xAxisStim,1:size(missPSTH,1),actPSTH(sortIdx,:)); clim([-0.08 0.08])
xticks(xtickVal); xticklabels(xtickStr);
ylabel('Neuron'); xlabel('Time in trial (sec)')

figure; subplot(1,2,1); hold on; plot([-2 5],[0 0],'Color',[0.8 0.8 0.8],'LineWidth',2);
plot(xAxisStim,nanmean(missPSTH,1),'Color',matlabColors(1),'LineWidth',2)
ylabel('df/f'); xlabel('Time in trial (sec)');xlim([-2 5]); ylim([-0.05 0.05])
subplot(1,2,2); hold on;
plot([-2 5],[0 0],'Color',[0.8 0.8 0.8],'LineWidth',2);
plot(xAxisStim,nanmean(actPSTH,1),'Color',matlabColors(1),'LineWidth',2)
ylabel('df/f'); xlabel('Time in trial (sec)');xlim([-2 5]);ylim([-0.05 0.05])
%% zz153 -- GROUP DATA FOR TASK 1 decoding
decodingLim = 100;
grouping = {[1,2],[4,5], [6 7 8 9 10 11 12 13 14 15], [16 17],[18],[19]};
s1a1 = getDataGrouping (data,grouping,'s1a1',true);
s2a2 = getDataGrouping (data,grouping,'s2a2',true);

[acc_t1,topNeuronIdx,neuronW_t1,neuronAcc_t1,acc_t1_shuf] = runDecoder(s1a1,s2a2,decodingLim);
%% plot decoding results
xFrameLim = 100; 
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));

tempShuf = mean(acc_t1_shuf,3); tempShuf = tempShuf(:);

figure; hold on;
plot([0 0],[0.4 1],'LineWidth',2,'Color',[0.8 0.8 0.8])
fill([-2 5 5 -2],[prctile(tempShuf,99) prctile(tempShuf,99) prctile(tempShuf,1) prctile(tempShuf,1)],...
    [0.8 0.8 0.8],'LineWidth',2,'EdgeColor','none','FaceAlpha',0.4);
plot([-2 5],[0.5 0.5],'LineWidth',2,'Color',[0.8 0.8 0.8])
h = [];h(1) = plot(xAxisStim,(acc_t1(1,:)),'LineWidth',2.5,'Color',matlabColors(1));
h(2) =plot(xAxisStim,(acc_t1(3,:)),'LineWidth',2.5,'Color',matlabColors(2));
h(3) = plot(xAxisStim,(acc_t1(5,:)),'LineWidth',2.5,'Color',matlabColors(3));
legend(h,{'Expert T1','Learning T2','Interleaved'});

xticks(xtickVal); xticklabels(xtickStr); xlim([-1.5 5]); 
ylabel('Choice decoding accuracy'); xlabel('Time in trial (sec)')

% for i = [1 3 5 7 9]
%     figure; 
%     for j = 1:length(s1a1)
%         subplot(1,length(s1a1),j)
%         plot(xAxisStim,nanmean(s1a1{j}(topNeuronIdx{1}(i),1:xFrameLim,:),3)); hold on;
%         plot(xAxisStim,nanmean(s2a2{j}(topNeuronIdx{1}(i),1:xFrameLim,:),3));
%     end
% end 
%% zz153 -- GROUP DATA FOR TASK 2 decoding
grouping = {[1,2],[4,5], [6 7 8 9 10 11 12 13 14 15], [16 17],[18],[19]};
grouping = {[5 6],[ 7 8], [9,10], 11, 12, 13, 14,15, [16 17],[18],[19]};
s3a1 = getDataGrouping (data,grouping,'s3a1',true);
s4a2 = getDataGrouping (data,grouping,'s4a2',true);
[acc_t2,topNeuronIdx_t2,neuronW_t2,neuronAcc_t2,acc_t2_shuf] = runDecoder(s3a1,s4a2,decodingLim);
%% plot decoding results
tempShuf = mean(acc_t2_shuf,3); tempShuf = tempShuf(:);

figure; hold on; 
plot([0 0],[0.4 1],'LineWidth',2,'Color',[0.8 0.8 0.8])
fill([-2 5 5 -2],[prctile(tempShuf,99) prctile(tempShuf,99) prctile(tempShuf,1) prctile(tempShuf,1)],...
    [0.8 0.8 0.8],'LineWidth',2,'EdgeColor','none','FaceAlpha',0.4);
plot([-2 5],[0.5 0.5],'LineWidth',2,'Color',[0.8 0.8 0.8])
h = [];h(1) = plot(xAxisStim,mean(acc_t2(1:2,:)),'LineWidth',2.5,'Color',matlabColors(1));
h(2) =plot(xAxisStim,mean(acc_t2([5 6],:)),'LineWidth',2.5,'Color',matlabColors(2));
h(3) = plot(xAxisStim,mean(acc_t2([8 9 10],:)),'LineWidth',2.5,'Color',matlabColors(3));
legend(h,{'Day1-2','Day5-6','Interleaved'});xlim([-1.5 5]);

xticks(xtickVal); xticklabels(xtickStr); xlim([-1.5 5]); 
ylabel('Choice decoding accuracy'); xlabel('Time in trial (sec)')
%% compare similarity of neural activity
selFlag = topNeuronIdx_t2{5}(1:150);
plotStability(selFlag,s4a2);
plotStability(selFlag,s3a1);

selFlag = topNeuronIdx{2}(1:150);
plotStability(selFlag,s1a1);
plotStability(selFlag,s2a2);

%% compare similarity of neural difference
selFlag = topNeuronIdx_t2{5}(1:150);
plotStabilityDiff(selFlag,s3a1,s4a2);

selFlag = topNeuronIdx_t2{1}(1:150);
plotStabilityDiff(selFlag,s1a1,s2a2);

selFlag = topNeuronIdx{1}(1:150);
plotStabilityDiff(selFlag,s1a1,s2a2);

%% plot decoding single cell
xFrameLim = 100; 
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xAxisChoice = ((1:(xFrameLim))-50)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));
xticks(xtickVal); xticklabels(xtickStr); xlim([-1.5 5]); 
ylabel('Choice decoding accuracy'); xlabel('Time in trial (sec)')

alignToDecodingDay = 1;
for z = 1:10
    figure;
    for i = 1:10
        for j = 1:length(s3a1)
            subplot_tight(10,length(s3a1),(i-1)*10+j,[0.02 0.02])
            plot(xAxisStim,nanmean(s3a1{j}(topNeuronIdx_t2{alignToDecodingDay}(i+(z-1)*10),1:xFrameLim,:),3)); hold on;
            plot(xAxisStim,nanmean(s4a2{j}(topNeuronIdx_t2{alignToDecodingDay}(i+(z-1)*10),1:xFrameLim,:),3));
        end
    end 
end 
%% get nbumber 11,52, 44, 48
z= 1;
figure;
alignToDecodingDay=10;
t1_plotNum = [1, 2, 6, 11, 12 , 13];
t2_plotNum = [3, 4, 5, 6,7,8,9, 10,11, 13];

ymax_t2_1 = cellfun(@(x)(max(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s3a1,'UniformOutput',true); 
ymax_t2_2 = cellfun(@(x)(max(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s4a2,'UniformOutput',true); 
ymin_t2_1 = cellfun(@(x)(min(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s3a1,'UniformOutput',true); 
ymin_t2_2 = cellfun(@(x)(min(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s4a2,'UniformOutput',true); 

ymax_t1_1 = cellfun(@(x)(max(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s1a1,'UniformOutput',true); 
ymax_t1_2 = cellfun(@(x)(max(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s2a2,'UniformOutput',true); 
ymin_t1_1 = cellfun(@(x)(min(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s1a1,'UniformOutput',true); 
ymin_t1_2 = cellfun(@(x)(min(nanmean(x(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3))),s2a2,'UniformOutput',true); 

for j = 1:length(t2_plotNum)
    subplot_tight(2,13,t2_plotNum(j),[0.06 0.01]); hold on; 
    plot([0 0],[min([ymin_t2_1 ymin_t2_2])  max([ymax_t2_1 ymax_t2_2])*1.1 ], 'Color',[0.8 0.8 0.8],'LineWidth',2);
    plot(xAxisStim,nanmean(s3a1{j}(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3),'LineWidth',2,'Color',multitaskColors('s3a1')); 
    plot(xAxisStim,nanmean(s4a2{j}(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3),'LineWidth',2, 'Color',multitaskColors('s4a2'));
    %xlim([-1 1]); xticks(-1:0.25:1); 
    ylim([min([ymin_t2_1 ymin_t2_2])  max([ymax_t2_1 ymax_t2_2])*1.1 ]);
    if j>1; yticks([]); end 
    if j<=length(t1_plotNum)
        subplot_tight(2,13,13+t1_plotNum(j),[0.06 0.01]); hold on;
        plot([0 0],[min([ymin_t1_1 ymin_t1_2])  max([ymax_t1_1 ymax_t1_2])*1.1 ], 'Color',[0.8 0.8 0.8],'LineWidth',2);
        plot(xAxisStim,nanmean(s1a1{j}(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3),'Color',multitaskColors('s1a1'),'LineWidth',2); hold on;
        plot(xAxisStim,nanmean(s2a2{j}(topNeuronIdx_t2{alignToDecodingDay}(z),1:xFrameLim,:),3),'Color',multitaskColors('s2a2'),'LineWidth',2);
        %xlim([-1 1]);xticks(-1:0.25:1); 
        ylim([min([ymin_t1_1 ymin_t1_2])  max([ymax_t1_1 ymax_t1_2])*1.1 ]); 
        if j>1; yticks([]); end 
    end
    
end

%% decoding scatter plot
selFrame = 31:40;
neuronAcc_T1_mean = nanmean(neuronAcc_t1(:,:,selFrame),3);
neuronAcc_T2_mean = nanmean(neuronAcc_t2(:,:,selFrame),3);

figure; subplot(3,1,1);scatter(neuronAcc_T1_mean(:,1),neuronAcc_T1_mean(:,end),10,multitaskColors('s1a1'),'filled');
xlim([0.4 1]); ylim([0.4 1])
subplot(3,1,2);scatter(neuronAcc_T1_mean(:,1),neuronAcc_T2_mean(:,3),10,multitaskColors('s3a1'),'filled');
xlim([0.4 1]); ylim([0.4 1])
subplot(3,1,3);scatter(neuronAcc_T1_mean(:,end),neuronAcc_T2_mean(:,end),10,multitaskColors('s3a1'),'filled');
xlim([0.4 1]); ylim([0.4 1])


figure;

idx1 = neuronAcc_T1_mean(:,1)<0.7 & neuronAcc_T1_mean(:,end)>0.7; hold on;
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(idx1,1,:),1)),'LineWidth',2)
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(idx1,end,:),1)),'LineWidth',2)
xlim([-2 5]); ylim([0.4 1.0])
legend('T1 Expert','T1-T2 interleaved')

%% zz153 -- GROUP DATA -- APPLY TASK 1 NEURONS to decoding to TASK 2
% selneuron = topNeuronIdx{end}(1:20);
% tempT1_s1 = cellfun(@(x)(x(selneuron,:,:)),s1a1,'UniformOutput',false);
% tempT1_s2 = cellfun(@(x)(x(selneuron,:,:)),s2a2,'UniformOutput',false);
% [acc_applyt1_t1,~] = runDecoder(tempT1_s1,tempT1_s2,decodingLim);
% tempT2_s3 = cellfun(@(x)(x(selneuron,:,:)),s3a1,'UniformOutput',false);
% tempT2_s4 = cellfun(@(x)(x(selneuron,:,:)),s4a2,'UniformOutput',false);
% [acc_applyt1_t2,~] = runDecoder(tempT2_s3,tempT2_s4,decodingLim);
nTop = 20;
temp1 = nanmean(neuronAcc_t1(topNeuronIdx{1}(1:nTop),1,31:60),3);
temp2 = nanmean(neuronAcc_t1(topNeuronIdx{1}(1:nTop),end,31:60),3);

t1_t2_diff_idx = [2 5 7 9 15];
t1_t2_same_idx = [1 3 4 6 8 10 11 12 13 14];

t1_start_end_same_idx = [1 2  7 9 10 12 13 14 15];
t1_start_end_diff_idx = [3 4 5 6 8 11];

figure; 
subplot(1,2,1);hold on; 
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(topNeuronIdx{5}(t1_t2_same_idx),5,:),1)),'LineWidth',2)
plot(xAxisStim,squeeze(nanmean(neuronAcc_t2(topNeuronIdx{5}(t1_t2_same_idx),9,:),1)),'LineWidth',2)
legend('T1 interleaved','T2 interleaved')
subplot(1,2,2);hold on; 
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(topNeuronIdx{5}(t1_t2_diff_idx),5,:),1)),'LineWidth',2)
plot(xAxisStim,squeeze(nanmean(neuronAcc_t2(topNeuronIdx{5}(t1_t2_diff_idx),9,:),1)),'LineWidth',2)
legend('T1 interleaved','T2 interleaved')

figure; 
subplot(1,2,1); hold on; 
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(topNeuronIdx{5}(t1_start_end_same_idx),5,:),1)),'LineWidth',2)
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(topNeuronIdx{5}(t1_start_end_same_idx),1,:),1)),'LineWidth',2)
legend('T1 interleaved', 'T1 before T2')


subplot(1,2,2); hold on; 
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(topNeuronIdx{5}(t1_start_end_diff_idx),5,:),1)),'LineWidth',2)
plot(xAxisStim,squeeze(nanmean(neuronAcc_t1(topNeuronIdx{5}(t1_start_end_diff_idx),1,:),1)),'LineWidth',2)
legend('T1 interleaved', 'T1 before T2')

%%
z= 3;
alignToDecodingDay=6;
t1_plotNum = [1, 2, 6, 11, 12 , 13];
t2_plotNum = [3, 4, 5, 6,7,8,9, 10,11, 13];


figure; subplot(2,2,1)
fn_plotMeanErrorbar(xAxisStim,squeeze(s3a1{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s3a1'),...
    multitaskColors('s3a1'),{'LineWidth',2,'Color',multitaskColors('s3a1')}, {'Facealpha',0.2}); hold on;
fn_plotMeanErrorbar(xAxisStim,squeeze(s4a2{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s4a2'),...
    multitaskColors('s4a2'),{'LineWidth',2,'Color',multitaskColors('s4a2')}, {'Facealpha',0.2}); hold on;
ylimm = ylim; ylim(ylimm);




subplot(2,2,2)
fn_plotMeanErrorbar(xAxisStim,squeeze(s3a1{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s3a1'),...
    multitaskColors('s3a1'),{'LineWidth',2,'Color',multitaskColors('s3a1')}, {'Facealpha',0.2}); hold on;
fn_plotMeanErrorbar(xAxisStim,squeeze(s4a2{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s4a2'),...
    multitaskColors('s4a2'),{'LineWidth',2,'Color',multitaskColors('s4a2')}, {'Facealpha',0.2}); hold on;
xlim([-1 1]); xticks(-1:1)
 ylim(ylimm);

subplot(2,2,3); hold on;

fn_plotMeanErrorbar(xAxisStim,squeeze(s1a1{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s1a1'),...
    multitaskColors('s1a1'),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
fn_plotMeanErrorbar(xAxisStim,squeeze(s2a2{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s2a2'),...
    multitaskColors('s2a2'),{'LineWidth',2}, {'Facealpha',0.2}); hold on;

ylim(ylimm);

subplot(2,2,4); hold on;

fn_plotMeanErrorbar(xAxisStim,squeeze(s1a1{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s1a1'),...
    multitaskColors('s1a1'),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
fn_plotMeanErrorbar(xAxisStim,squeeze(s2a2{2}(topNeuronIdx_t2{2}(z),1:xFrameLim,:))',multitaskColors('s2a2'),...
    multitaskColors('s2a2'),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
xlim([-1 1]); xticks(-1:1)
 ylim(ylimm);


% for j = 1:length(t2_plotNum)
%     subplot(2,13,t2_plotNum(j))
% 
%     fn_plotMeanErrorbar(xAxisStim,squeeze(s3a1{j}(topNeuronIdx{alignToDecodingDay}(z),1:xFrameLim,:))',matlabColors(1),...
%         matlabColors(1),{'LineWidth',2,'Color',matlabColors(1)}, {'Facealpha',0.2}); hold on;
%     fn_plotMeanErrorbar(xAxisStim,squeeze(s4a2{j}(topNeuronIdx{alignToDecodingDay}(z),1:xFrameLim,:))',matlabColors(1),...
%         matlabColors(2),{'LineWidth',2,'Color',matlabColors(2)}, {'Facealpha',0.2}); hold on;
%     xlim([-1 1]); xticks(-1:0.25:1)
%     if j<=length(t1_plotNum)
%         subplot(2,13,13+t1_plotNum(j)); hold on;
% 
%         fn_plotMeanErrorbar(xAxisStim,squeeze(s1a1{j}(topNeuronIdx{alignToDecodingDay}(z),1:xFrameLim,:))',matlabColors(3),...
%             matlabColors(3),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
%         fn_plotMeanErrorbar(xAxisStim,squeeze(s2a2{j}(topNeuronIdx{alignToDecodingDay}(z),1:xFrameLim,:))',matlabColors(4),...
%             matlabColors(4),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
%         xlim([-1 1]); xticks(-1:0.25:1)
% 
%     end
% end
%% plot results
figure; subplot(1,2,1);hold on;
plot([0 0],[0.4 1],'LineWidth',2,'Color',[0.8 0.8 0.8])
plot([-2 5],[0.5 0.5],'LineWidth',2,'Color',[0.8 0.8 0.8])
h = [];h(1) = plot(xAxisStim,(acc_applyt1_t1(1,:)),'LineWidth',2.5,'Color',matlabColors(1));
h(2) =plot(xAxisStim,(acc_applyt1_t1(3,:)),'LineWidth',2.5,'Color',matlabColors(2));
h(3) = plot(xAxisStim,(acc_applyt1_t1(5,:)),'LineWidth',2.5,'Color',matlabColors(3));
legend(h,{'Expert T1','Learning T2','Interleaved'});

xticks(xtickVal); xticklabels(xtickStr); xlim([-1.5 5]); 
ylabel('Choice decoding accuracy'); xlabel('Time in trial (sec)')

subplot(1,2,2);hold on;
plot([0 0],[0.4 1],'LineWidth',2,'Color',[0.8 0.8 0.8])
plot([-2 5],[0.5 0.5],'LineWidth',2,'Color',[0.8 0.8 0.8])
h = [];h(1) = plot(xAxisStim,mean(acc_applyt1_t2([1 2],:),1),'LineWidth',2.5,'Color',matlabColors(1));
h(2) =plot(xAxisStim,mean(acc_applyt1_t2([5 6],:),1),'LineWidth',2.5,'Color',matlabColors(2));
h(3) = plot(xAxisStim,mean(acc_applyt1_t2([9 10],:),1),'LineWidth',2.5,'Color',matlabColors(3));
legend(h,{'Day1-2','Day5-6','Interleaved'});

xticks(xtickVal); xticklabels(xtickStr); xlim([-1.5 5]); 
ylabel('Choice decoding accuracy'); xlabel('Time in trial (sec)')

%% quantify intersection
nTopNeuron = 150; 
figure; 
subplot(1,2,1)
[val,pos]=intersect(topNeuronIdx{2}(1:nTopNeuron),topNeuronIdx_t2{1}(1:nTopNeuron));
p=pie([length(val)/(nTopNeuron*2-length(val)) (nTopNeuron*2-length(val)*2)/(nTopNeuron*2-length(val))]);
%p(1).FaceColor = [0.5 0.5 0.5]; p(2).FaceColor = matlabColors(2);
subplot(1,2,2)
[val,pos]=intersect(topNeuronIdx{end}(1:nTopNeuron),topNeuronIdx_t2{end}(1:nTopNeuron));
p=pie([length(val)/(nTopNeuron*2-length(val)) (nTopNeuron*2-length(val)*2)/(nTopNeuron*2-length(val))]);
%p(1).FaceColor = [0.5 0.5 0.5]; p(2).FaceColor = matlabColors(2);
%% ARCHIVE -- For task 1, look at selectivity index
grouping = {[5 6 7],[ 8 9],10, 11, 12, 13, 14,15, [16 17],[18 19]};
toneIdx = 31:60; stim_SI1 = {};stim_SI2 = {};
for i = 1:length(grouping)
    tempCell1 = {}; tempCell2 = {}; tempCell3 = {}; tempCell4 = {};
    for j = 1:length(grouping{i})
        tempCell1{j} = cat(3,data.s1a1{1}{grouping{i}(j)},data.s1a1{2}{grouping{i}(j)});
        tempCell2{j} = cat(3,data.s2a2{1}{grouping{i}(j)},data.s2a2{2}{grouping{i}(j)});
        tempCell3{j} = cat(3,data.s3a1{1}{grouping{i}(j)},data.s3a1{2}{grouping{i}(j)});
        tempCell4{j} = cat(3,data.s4a2{1}{grouping{i}(j)},data.s4a2{2}{grouping{i}(j)});
    end 
    disp(['Group ' int2str(i)])
    stim_SI1{i} = fn_getSI(fn_cell2mat(tempCell1,3),fn_cell2mat(tempCell2,3),toneIdx);
    stim_SI2{i} = fn_getSI(fn_cell2mat(tempCell3,3),fn_cell2mat(tempCell4,3),toneIdx);
end
stim_SI1 = fn_cell2mat(stim_SI1,2);
stim_SI2 = fn_cell2mat(stim_SI2,2);
%% ARCHIVE
figure; imagesc(stim_SI1); colorbar
[~,tempSortIdx ]= sort(stim_SI2(:,1),'descend'); 
figure; imagesc(stim_SI2(tempSortIdx,:)); colorbar
corrMat = corr(stim_SI2);
figure; imagesc(corrMat); colorbar;

figure;plot(sum(abs(stim_SI2),1));

%% ARCHIVE -- For task 2, do correlational analysis
toneIdx = 31:60; s3a1 = {};s4a2 = {};
grouping = {[5 6 7],[ 8 9],10, 11, 12, 13, 14,15, [16 17],[18 19]};
for i = 1:length(grouping)
    tempCell1 = {}; tempCell2 = {}; tempCell3 = {}; tempCell4 = {};
    for j = 1:length(grouping{i})
        tempCell1{j} = data.s3a1{1}{grouping{i}(j)}(:,toneIdx,:);
        tempCell2{j} = data.s3a1{2}{grouping{i}(j)}(:,toneIdx,:);
        tempCell3{j} = data.s4a2{1}{grouping{i}(j)}(:,toneIdx,:);
        tempCell4{j} = data.s4a2{2}{grouping{i}(j)}(:,toneIdx,:);
    end 
    s3a1{1}{i} = nanmean(nanmean(fn_cell2mat(tempCell1,3),2),3);
    s3a1{2}{i} = nanmean(nanmean(fn_cell2mat(tempCell2,3),2),3);
    s4a2{1}{i} = nanmean(nanmean(fn_cell2mat(tempCell3,3),2),3);
    s4a2{2}{i} = nanmean(nanmean(fn_cell2mat(tempCell4,3),2),3);
    a = fn_cell2mat(tempCell1,3); 
    disp(size(a,3))
end

s3a1{1} = fn_cell2mat(s3a1{1},2);
s3a1{2} = fn_cell2mat(s3a1{2},2);

s4a2{1} = fn_cell2mat(s4a2{1},2);
s4a2{2} = fn_cell2mat(s4a2{2},2);
corrMat = []; 
corrMat(:,:,1) = corr(s3a1{1});
corrMat(:,:,2) = corr(s3a1{2});
corrMat(:,:,3) = corr(s4a2{1});
corrMat(:,:,4) = corr(s4a2{2});
figure; imagesc(mean(corrMat,3)); clim([0.2 1]); colorbar
meanCorrMat = mean(corrMat,3);
figure; plot(meanCorrMat(5,:))

%% ARCHIVE -- For task 1, do correlational analysis
grouping = {[1,2],[4],[5], [6 7 8 9 10 11 12 13 14 15], [16 17],[18],[19]};
toneIdx = 31:60; s1a1 = {};s2a2 = {};
for i = 1:length(grouping)
    tempCell1 = {}; tempCell2 = {}; tempCell3 = {}; tempCell4 = {};
    for j = 1:length(grouping{i})
        tempCell1{j} = data.s1a1{1}{grouping{i}(j)}(:,toneIdx,:);
        tempCell2{j} = data.s1a1{2}{grouping{i}(j)}(:,toneIdx,:);
        tempCell3{j} = data.s2a2{1}{grouping{i}(j)}(:,toneIdx,:);
        tempCell4{j} = data.s2a2{2}{grouping{i}(j)}(:,toneIdx,:);
    end 
    s1a1{1}{i} = nanmean(nanmean(fn_cell2mat(tempCell1,3),2),3);
    s1a1{2}{i} = nanmean(nanmean(fn_cell2mat(tempCell2,3),2),3);
    s2a2{1}{i} = nanmean(nanmean(fn_cell2mat(tempCell3,3),2),3);
    s2a2{2}{i} = nanmean(nanmean(fn_cell2mat(tempCell4,3),2),3);
    a = fn_cell2mat(tempCell4,3); 
    disp(size(a,3))
end

s1a1{1} = fn_cell2mat(s1a1{1},2);
s1a1{2} = fn_cell2mat(s1a1{2},2);

s2a2{1} = fn_cell2mat(s2a2{1},2);
s2a2{2} = fn_cell2mat(s2a2{2},2);
corrMat = []; 
corrMat(:,:,1) = corr(s1a1{1});
corrMat(:,:,2) = corr(s1a1{2});
corrMat(:,:,3) = corr(s2a2{1});
corrMat(:,:,4) = corr(s2a2{2});
figure; imagesc(mean(corrMat,3)); clim([0.2 1]); colorbar

%% ARCHIVE -- to process zz153
clear;

ops.mouse = 'zz153';
ops.area = 'PPC';
ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area ];
ops.behavDates = {'20230523','20240524','20240526','20240527','20240528','20240529','20240530'};
ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
data = fn_loadBehNeuroData(ops);

%% FUNCTIONS
function [tempAcc, topNeuronIdx,neuronW,neuronAcc,tempAccShuf] = runDecoder(data1,data2,decodingLim)
subSample = 21;
tempAcc = zeros(length(data1),decodingLim); 
tempAccShuf = zeros(length(data1),decodingLim,100); 
decodingLim = 100; selTopNeuronLim = 31:60;
topNeuronIdx = {}; nTop = 20; 
neuronAcc = zeros(size(data1{1},1),length(data1),decodingLim);
neuronW = zeros(size(data1{1},1),length(data1),decodingLim);
for i = 1:length(data1)
    tic;
    tempS1a1 = smoothdata(data1{i},2,'movmean',1); 
    tempS2a2 = smoothdata(data2{i},2,'movmean',1); 
    tempCellAcc = zeros(size(data1{i},1),length(selTopNeuronLim)); 

    for j = 1:length(selTopNeuronLim)
        temp1 = squeeze(tempS1a1(:,selTopNeuronLim(j),:)); temp2 = squeeze(tempS2a2(:,selTopNeuronLim(j),:));
        if size(temp1,2) > size(temp2,2); temp1 = temp1(:,1:size(temp2,2)); 
        else; temp2 = temp2(:,1:size(temp1,2)); end 
        temp1 = temp1(:,1:subSample); 
        temp2 = temp2(:,1:subSample);

        decoder = fn_runDecoder(temp1',temp2', 0.8);
        tempCellAcc(:,j) = decoder.cellAcc(:,2);
    end
    [~, topNeuronIdx{i}] = sort(mean(tempCellAcc,2),'Descend'); 
    tempTop = topNeuronIdx{i}(1:nTop);

    for j = 1:decodingLim
        temp1 = squeeze(tempS1a1(tempTop,j,:)); temp2 = squeeze(tempS2a2(tempTop,j,:));
        
        if size(temp1,2) > size(temp2,2); temp1 = temp1(:,1:size(temp2,2)); 
        else; temp2 = temp2(:,1:size(temp1,2)); end 
        temp1 = temp1(:,1:subSample); 
        temp2 = temp2(:,1:subSample); 

        decoder = fn_runDecoder(temp1',temp2', 0.8);
        tempAcc(i,j) = decoder.topAcc(2);
        tempAccShuf(i,j,:) = decoder.popAccShuf(:,2);

        % weights of all neurons
        temp1 = squeeze(tempS1a1(:,j,1:subSample)); temp2 = squeeze(tempS2a2(:,j,1:subSample));
        decoder = fn_runDecoder(temp1',temp2', 0.8);
        neuronAcc(:,i,j) = decoder.cellAcc(:,2);
        neuronW(:,i,j) = decoder.cellW;
    end
    t = toc; disp(t)
end

end 
function outCell = getDataGrouping (data,grouping,fldname,catRT)
    if ~exist('catRT'); catRT = true; end 
    outCell = cell(1,length(grouping));
    for i = 1:length(grouping)
        tempCell = {};
        for j = 1:length(grouping{i})
            if catRT
                tempCell{j} = cat(3,data.(fldname){1}{grouping{i}(j)},data.(fldname){2}{grouping{i}(j)});
            else
                tempCell{j} = cat(3,data.(fldname){1}{grouping{i}(j)});
            end 
    
        end 
    
        outCell{i} = fn_cell2mat(tempCell,3);

    end 


end 

function plotStability(selFlag,s4a2)

s4a2_sel = fn_cell2mat(cellfun(@(x)(nanmean(x(selFlag,1:100,:),3)),s4a2,'UniformOutput',false),3);
s4a2_selmean = squeeze(nanmean(s4a2_sel(:,28:60,:),2));
[~,sortIdx] = sort(s4a2_selmean(:,5),'Descend');

xFrameLim = 100;
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));

figure; 
for i = 1:size(s4a2_sel,3)
    subplot_tight(1,size(s4a2_sel,3),i,[0.05 0.01]);
    imagesc(xAxisStim,1:size(s4a2_selmean,1),s4a2_sel(sortIdx,:,i));yticks([]); clim([-0.15 0.15]);
    xticks(xtickVal)
end
figure; imagesc(corr(s4a2_selmean)); clim([0.2 1]); colorbar

end

function plotStabilityDiff(selFlag,s3a1,s4a2)

s4a2_sel = fn_cell2mat(cellfun(@(x)(nanmean(x(selFlag,1:100,:),3)),s4a2,'UniformOutput',false),3);
s3a1_sel = fn_cell2mat(cellfun(@(x)(nanmean(x(selFlag,1:100,:),3)),s3a1,'UniformOutput',false),3);
tempDiff = s3a1_sel-s4a2_sel;
diff_selmean = squeeze(nanmean(tempDiff(:,28:60,:),2));
[~,sortIdx] = sort(diff_selmean(:,5),'Descend');

xFrameLim = 100;
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));

figure; 
for i = 1:size(tempDiff,3)
    subplot_tight(1,size(tempDiff,3),i,[0.05 0.01]);
    imagesc(xAxisStim,1:size(tempDiff,1),tempDiff(sortIdx,:,i));yticks([]); clim([-0.08 0.08]);
    xticks(xtickVal)
end
figure; imagesc(corr(diff_selmean)); clim([0.2 1]); colorbar

end

function SI = fn_getSI(act1,act2,idx)
    actMean1 = nanmean(nanmean(act1(:,idx,:),2),3); actMean2 = nanmean(nanmean(act2(:,idx,:),2),3);
    actStd1 = nanstd( squeeze(nanmean(act1(:,idx,:),2)),0,2);
    actStd2 = nanstd( squeeze(nanmean(act2(:,idx,:),2)),0,2);
    %SI = (actMean1-actMean2) ./ (abs(actMean1)+abs(actMean2));
    SI = (actMean1-actMean2) ./ sqrt(actStd1.^2+actStd2.^2);
    disp(['Mat size are: ' int2str(size(act1,3)) ' and ' int2str(size(act2,3))])



end 