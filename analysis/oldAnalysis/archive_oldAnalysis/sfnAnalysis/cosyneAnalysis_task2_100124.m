%%
clear;
mouse = 'zz153'; t2_trans = 20240523; inter_trans = 20240613;
Fpath = ['C:\Users\zzhu34\Documents\tempdata\' mouse '_PPC\parsedF_choice'];
filename = dir([Fpath filesep 'F_*mat']);
parsedF = cell(4,2,length(filename)); trialNum = zeros(4,2,length(filename));
for i = 1:length(filename)
    data = load([Fpath filesep filename(i).name ]);
    parsedF{1,1,i}= data.s1a1; parsedF{1,2,i}= data.s1a2;
    parsedF{2,1,i}= data.s2a1; parsedF{2,2,i}= data.s2a2;
    parsedF{3,1,i}= data.s3a1; parsedF{3,2,i}= data.s3a2;
    parsedF{4,1,i}= data.s4a1; parsedF{4,2,i}= data.s4a2;
    Fsize{i} = getSize(parsedF(:,:,i));
end 
Fsize = fn_cell2mat(Fsize,3);
%% for zz159

switch mouse

    case 'zz153'

        groupingT1 = {1:6,7:9,11:12,13:22,23:24,25:26};
        groupingT2 = {[12,13,14],[15,16,17], [18,19, 20,21,22],23:24,25:26};

    case 'zz159' % day 6 and day 26 are outlier
        groupingT1 = {[1 2 3 4 5], [7 8 9 10 11 12],[13 14 15 16],17:26,27:29,30:31};
        groupingT2 = {[16 17 18 19],20:22,23:25,27:29,30:31};
end 

tempSize1 = cellfun(@(x)(sum(Fsize(1:2,1:2,x),3)), groupingT1,'UniformOutput',false); tempSize1 = fn_cell2mat(tempSize1,3);
tempSize2 = cellfun(@(x)(sum(Fsize(3:4,1:2,x),3)), groupingT2,'UniformOutput',false); tempSize2 = fn_cell2mat(tempSize2,3);

groupF_T1 = getDataGrouping (parsedF,groupingT1); groupF_T2 = getDataGrouping (parsedF,groupingT2);

decodingSize1 = squeeze(tempSize1(1,1,:));decodingSize2 = squeeze(tempSize1(2,2,:));
decodingSize3 = squeeze(tempSize2(1,1,:)); decodingSize4 = squeeze(tempSize2(2,2,:));
subsample = min([decodingSize1;decodingSize2;decodingSize3;decodingSize4]);


%%
[neuronW_t1,neuronAcc_t1,acc_t1_shuf] = ...
    runDecoder(squeeze(groupF_T1(1,1,:)),squeeze(groupF_T1(2,2,:)),subsample);
[neuronW_t2,neuronAcc_t2,acc_t2_shuf] = ...
    runDecoder(squeeze(groupF_T2(3,1,:)),squeeze(groupF_T2(4,2,:)),subsample);

save(['C:\Users\zzhu34\Documents\tempdata\' mouse '_PPC\parsedF_choice\decoding.mat'],...
    'neuronW_t1','neuronAcc_t1','acc_t1_shuf','neuronW_t2','neuronAcc_t2','acc_t2_shuf');

%%
mouse = 'zz153';
load(['C:\Users\zzhu34\Documents\tempdata\' mouse '_PPC\parsedF_choice\decoding.mat'],...
    'neuronW_t1','neuronAcc_t1','acc_t1_shuf','neuronW_t2','neuronAcc_t2','acc_t2_shuf');
%% evaluate decoding 

tempPlot1 = nanmean(neuronAcc_t1(:,:,26:35),3); tempSum1 = max(tempPlot1,[],2);
tempPlot2 = nanmean(neuronAcc_t2(:,:,26:35),3);  tempSum2 = max(tempPlot2,[],2);
%% Now, compare decoding of task 1 stimuli
selFlag = tempSum1>0.55 | tempSum2>0.55;
tempPlot1 = tempPlot1(selFlag,:);
tempPlot2 = tempPlot2(selFlag,:);

figure; 
subplot(1,2,1); hold on;
for i = 1:5; fn_plotHistLine(tempPlot1(:,i),'histCountArgIn',{0.4:0.02:1.0},...
        'plotArgIn',{'Color',fn_colorAlpha(multitaskColors('s2a2'),0.25+0.25*(i-1)),'LineWidth',2});
    ylimm = [0 12]; plot([mean(tempPlot1(:,i)) mean(tempPlot1(:,i))],ylimm,'--','LineWidth',1,'Color',...
        fn_colorAlpha(multitaskColors('s2a2'),0.25+0.25*(i-1)));
end 

subplot(1,2,2); hold on;
for i = 1:5; fn_plotHistLine(tempPlot2(:,i),'histCountArgIn',{0.4:0.02:1.0},...
        'plotArgIn',{'Color',fn_colorAlpha(multitaskColors('s4a2'),0.25+0.25*(i-1)),'LineWidth',2});
    ylimm = [0 12]; plot([mean(tempPlot2(:,i)) mean(tempPlot2(:,i))],ylimm,'--','LineWidth',1,'Color',...
        fn_colorAlpha(multitaskColors('s4a2'),0.25+0.25*(i-1)));
end
%% Now, compare decoding of task 1 stimuli
figure; 
temp = squeeze(neuronAcc_t1(selFlag,:,:));
[~,sortIdx] = sort(squeeze(mean(temp(:,1,28:50),3)),'descend');
for i = 1:5
    subplot(5,2,1+(i-1)*2); 
    imagesc(squeeze(temp(sortIdx,i,:)));caxis([0.4 0.7]); xlim([20 40]); colorbar
    subplot(5,2,2+(i-1)*2); hold on;
    plot([30 30],[0.45 0.7],'Color',[0.8 0.8 0.8]);
    fn_plotMeanErrorbar(1:size(temp,3),squeeze(temp(sortIdx,i,:)),matlabColors(1),matlabColors(1)...
        , {'LineWidth',2},{'faceAlpha',0.2});
    xlim([20 40]); ylim([0.45 0.7])

end 
 
%% correlation between task 1 decoding and task 2 decoding

figure; 
subplot(1,6,1);hold on;
plot([0.4 1],[0.4 1],'--','Color',[0.8 0.8 0.8]); plot([0.4 1],[0.5 0.5],'Color',[0.8 0.8 0.8]); plot([0.5 0.5],[0.4 1],'Color',[0.8 0.8 0.8])
scatter(tempPlot1(:,3),tempPlot2(:,1),5,matlabColors(1),'filled'); 
legend('','','',['corr = ' num2str(corr(tempPlot1(:,3),tempPlot2(:,1)))]); xlim([0.4 1]); ylim([0.4 1])
xlabel('Task 1 decoding'); ylabel('Task 2 decoding'); title('T1(T1 exp) - T2(T2 naive)')

subplot(1,6,2);hold on;
plot([0.4 1],[0.4 1],'--','Color',[0.8 0.8 0.8]); plot([0.4 1],[0.5 0.5],'Color',[0.8 0.8 0.8]); plot([0.5 0.5],[0.4 1],'Color',[0.8 0.8 0.8])
scatter(tempPlot1(:,4),tempPlot2(:,1),5,matlabColors(1),'filled'); 
legend('','','',['corr = ' num2str(corr(tempPlot1(:,4),tempPlot2(:,1)))]); xlim([0.4 1]); ylim([0.4 1])
xlabel('Task 1 decoding'); ylabel('Task 2 decoding'); title('T1(T2 learning) - T2(T2 naive)')

subplot(1,6,3);hold on;
plot([0.4 1],[0.4 1],'--','Color',[0.8 0.8 0.8]); plot([0.4 1],[0.5 0.5],'Color',[0.8 0.8 0.8]); plot([0.5 0.5],[0.4 1],'Color',[0.8 0.8 0.8])
scatter(tempPlot1(:,4),tempPlot2(:,2),5,matlabColors(1),'filled'); 
legend('','','',['corr = ' num2str(corr(tempPlot1(:,4),tempPlot2(:,2)))]); xlim([0.4 1]); ylim([0.4 1])
xlabel('Task 1 decoding'); ylabel('Task 2 decoding'); title('T1(T2 learning) - T2(T2 learning)')

subplot(1,6,4);hold on;
plot([0.4 1],[0.4 1],'--','Color',[0.8 0.8 0.8]); plot([0.4 1],[0.5 0.5],'Color',[0.8 0.8 0.8]); plot([0.5 0.5],[0.4 1],'Color',[0.8 0.8 0.8])
scatter(tempPlot1(:,4),tempPlot2(:,3),5,matlabColors(1),'filled'); 
legend('','','',['corr = ' num2str(corr(tempPlot1(:,4),tempPlot2(:,3)))]); xlim([0.4 1]); ylim([0.4 1])
xlabel('Task 1 decoding'); ylabel('Task 2 decoding'); title('T1(T2 learning) - T2(T2 exp)')

subplot(1,6,5); hold on;
plot([0.4 1],[0.4 1],'--','Color',[0.8 0.8 0.8]); plot([0.4 1],[0.5 0.5],'Color',[0.8 0.8 0.8]); plot([0.5 0.5],[0.4 1],'Color',[0.8 0.8 0.8])
scatter(tempPlot1(:,5),tempPlot2(:,4),5,matlabColors(1),'filled');
legend('','','',['corr = ' num2str(corr(tempPlot1(:,5),tempPlot2(:,4)))]);
xlim([0.4 1]); ylim([0.4 1]); xlabel('Task 1 decoding'); ylabel('Task 2 decoding'); title('T1(int) - T2(int)')

subplot(1,6,6); hold on;
plot([0.4 1],[0.4 1],'--','Color',[0.8 0.8 0.8]); plot([0.4 1],[0.5 0.5],'Color',[0.8 0.8 0.8]); plot([0.5 0.5],[0.4 1],'Color',[0.8 0.8 0.8])
scatter(tempPlot1(:,6),tempPlot2(:,5),5,matlabColors(1),'filled');
legend('','','',['corr = ' num2str(corr(tempPlot1(:,6),tempPlot2(:,5)))]);
xlim([0.4 1]); ylim([0.4 1]); xlabel('Task 1 decoding'); ylabel('Task 2 decoding'); title('T1(int late) - T2(int late)')
%% correlation within task 1 or within task 2
figure; 
for i = 1:4
subplot(1,5,i);scatter(tempPlot1(:,1),tempPlot1(:,i+1),5,'filled');...
    title(['corr' num2str(corr(tempPlot1(:,1),tempPlot1(:,i+1)))]); xlim([0 1]); ylim([0 1])
end 
subplot(1,5,5); imagesc(corr(tempPlot1)); clim([0 0.8]); colorbar

figure; 
for i = 1:4
subplot(1,5,i);scatter(tempPlot2(:,1),tempPlot2(:,i+1),5,'filled');...
    title(['corr' num2str(corr(tempPlot2(:,1),tempPlot2(:,i+1)))]); xlim([0 1]); ylim([0 1])
end 
subplot(1,5,5); imagesc(corr(tempPlot2)); clim([0 0.8]); colorbar;

%% find evolution fo task 1 specific neuron
flag1 = tempPlot1(:,5)>0.58 & tempPlot2(:,1)>0.68 & tempPlot1(:,1)<0.55; sum(flag1)
temp1 = neuronAcc_t1(selFlag,:,:);  temp1 = (temp1(flag1,:,:)); 
temp2 = neuronAcc_t2(selFlag,:,:); temp2 = (temp2(flag1,:,:)); 
xFrameLim = 100; 
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));

figure;
for i = 1:3; subplot(2,7,i); hold on;
    plot([0 0],[0.45 0.85],'Color',[0.8 0.8 0.8])
    fn_plotMeanErrorbar(xAxisStim,squeeze(temp1(:,i,:)),...
        multitaskColors('s1a1'),multitaskColors('s1a1'),{'LineWidth',2},{'faceAlpha',0.2}); 
    xlim([-1 1]); ylim([0.45 0.85])
end

subplot(2,7,5); hold on;
plot([0 0],[0.45 0.85],'Color',[0.8 0.8 0.8])
fn_plotMeanErrorbar(xAxisStim,squeeze(temp1(:,4,:)),...
        multitaskColors('s1a1'),multitaskColors('s1a1'),{'LineWidth',2},{'faceAlpha',0.2}); 
xlim([-1 1]); ylim([0.45 0.85])

for i = 4:6; subplot(2,7,7+i); hold on;
    plot([0 0],[0.45 0.85],'Color',[0.8 0.8 0.8])
    fn_plotMeanErrorbar(xAxisStim,squeeze(temp2(:,i-3,:)),...
        multitaskColors('s3a1'),multitaskColors('s3a1'),{'LineWidth',2},{'faceAlpha',0.2});
    xlim([-1 1]); ylim([0.45 0.85])
end
subplot(2,7,7); hold on;
plot([0 0],[0.45 0.85],'Color',[0.8 0.8 0.8])
fn_plotMeanErrorbar(xAxisStim,squeeze(temp1(:,5,:)),...
        multitaskColors('s1a1'),multitaskColors('s1a1'),{'LineWidth',2},{'faceAlpha',0.2}); 
xlim([-1 1]); ylim([0.45 0.85])
subplot(2,7,14); hold on;
plot([0 0],[0.45 0.85],'Color',[0.8 0.8 0.8])
fn_plotMeanErrorbar(xAxisStim,squeeze(temp2(:,4,:)),...
        multitaskColors('s3a1'),multitaskColors('s3a1'),{'LineWidth',2},{'faceAlpha',0.2}); 
xlim([-1 1]); ylim([0.45 0.85])
%% evaluate SI, not ideal since SI is quite noisy

s1a1 = squeeze(groupF_T1(1,1,:));
s2a2 = squeeze(groupF_T1(2,2,:));
s3a1 = squeeze(groupF_T2(3,1,:));
s4a2 = squeeze(groupF_T2(4,2,:));

s1a1Mean = cellfun(@(x)(mean(x,3)),s1a1,'UniformOutput',false); s1a1Mean = fn_cell2mat(s1a1Mean,3);
s2a2Mean = cellfun(@(x)(mean(x,3)),s2a2,'UniformOutput',false); s2a2Mean = fn_cell2mat(s2a2Mean,3);
s3a1Mean = cellfun(@(x)(mean(x,3)),s3a1,'UniformOutput',false); s3a1Mean = fn_cell2mat(s3a1Mean,3);
s4a2Mean = cellfun(@(x)(mean(x,3)),s4a2,'UniformOutput',false); s4a2Mean = fn_cell2mat(s4a2Mean,3);
[~,sortIdx] = sort((nanmean(s1a1Mean(:,31:60,end),2)),'descend');

figure;
for i = 1:7
    subplot(2,7,i); imagesc(s1a1Mean(sortIdx,:,i)); clim([-0.05 0.05]); xlim([20 50])
    if i>1
    subplot(2,7,i+7); imagesc(s3a1Mean(sortIdx,:,i-1)); clim([-0.05 0.05]); xlim([20 50])
    end 
end

figure;
for i = 1:7
    subplot(2,7,i); imagesc(s1a1Mean(sortIdx,:,i)-s2a2Mean(sortIdx,:,i)); clim([-0.05 0.05]); xlim([20 50])
    if i>1
    subplot(2,7,i+7); imagesc(s3a1Mean(sortIdx,:,i-1)-s4a2Mean(sortIdx,:,i-1)); clim([-0.05 0.05]); xlim([20 50])
    end 
end

figure; hold on;
for i = 1:9; subplot(9,1,i);
    plot(nanmean(abs(s1a1Mean(sortIdx,:,i)-s2a2Mean(sortIdx,:,i)),1)); end 
%% SI
SI1 = (squeeze(mean(s1a1Mean (:,40:50,:),2)) - squeeze(mean(s2a2Mean (:,40:50,:),2))) ./ ...
    (abs(squeeze(mean(s1a1Mean (:,40:50,:),2))) + abs(squeeze(mean(s2a2Mean (:,40:50,:),2))));
SI2 = (squeeze(mean(s3a1Mean (:,40:50,:),2)) - squeeze(mean(s4a2Mean (:,40:50,:),2))) ./ ...
    (abs(squeeze(mean(s3a1Mean (:,40:50,:),2))) + abs(squeeze(mean(s4a2Mean (:,40:50,:),2))));
SI1 = SI1(selFlag,:); SI2 = SI2(selFlag,:);
figure; imagesc(corr(SI2)); colorbar;
figure; imagesc(corr(SI1)); colorbar;





%%
[~,sortIdx] = sort(tempPlot1(:,4),1,'descend'); figure; imagesc(tempPlot1(sortIdx,:)); clim([0.4 0.8])

figure; imagesc(corr(cat(2,tempPlot1,tempPlot2)))
%% plot single neuron

xFrameLim = 100; 
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));
xticks(xtickVal); xticklabels(xtickStr); xlim([-1.5 5]); 

nNeuron = sortIdx(3);
figure('OuterPosition',[0 500 2000 300]); 
for i = 1:7
    subplot(2,7,i);
    fn_plotMeanErrorbar(xAxisStim,squeeze(s1a1{i}(nNeuron,1:xFrameLim,:))',multitaskColors('s1a1'),...
        multitaskColors('s1a1'),{'LineWidth',2,'Color',multitaskColors('s1a1')}, {'Facealpha',0.2}); hold on;
    fn_plotMeanErrorbar(xAxisStim,squeeze(s2a2{i}(nNeuron,1:xFrameLim,:))',multitaskColors('s2a2'),...
        multitaskColors('s2a2'),{'LineWidth',2,'Color',multitaskColors('s2a2')}, {'Facealpha',0.2}); hold on;
    ylim([-0.2 0.4]);xlim([-1 2])
    xlabel('time after stim onset (s)'); ylabel('df/f'); %title('Naive')
    %if i==9; legend('','stim L, act L','','stim R, act R'); end 
    if i>1
        subplot(2,7,i+7);
        fn_plotMeanErrorbar(xAxisStim,squeeze(s3a1{i-1}(nNeuron,1:xFrameLim,:))',multitaskColors('s4a1'),...
            multitaskColors('s3a1'),{'LineWidth',2,'Color',multitaskColors('s3a1')}, {'Facealpha',0.2}); hold on;
        fn_plotMeanErrorbar(xAxisStim,squeeze(s4a2{i-1}(nNeuron,1:xFrameLim,:))',multitaskColors('s4a2'),...
            multitaskColors('s4a2'),{'LineWidth',2,'Color',multitaskColors('s4a2')}, {'Facealpha',0.2}); hold on;
        ylim([-0.2 0.4]);xlim([-1 2])
        xlabel('time after stim onset (s)'); ylabel('df/f'); %title('Naive')
        %if i==9; legend('','stim L, act L','','stim R, act R'); end 
    end 
end
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

