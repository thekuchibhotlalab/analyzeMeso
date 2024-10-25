%% 0.1 --- load suite2p data
clear;
area = 'PPC';
Fpath = ['D:\zz142\committee\110423_111223\green_' area '\suite2p\plane0'];
%Fpath = 'D:\zz142\committee\111623_112923\tifs\green_AC\suite2p\plane0'; 
behavDates = {'20231104','20231105','20231106','20231107','20231108','20231109','20231112'};
%behavDates = {'20231116','20231117','20231118','20231119','20231121','20231122','20231125','20231127','20231128','20231129'};
mouse = 'zz142'; behavPath = ['G:\ziyi\mesoData\' mouse '_behavior\matlab\']; 
[dffStimList, dffChoiceList, selectedBehList] = fn_loadData(mouse, Fpath,behavPath,behavDates);

%% Visualize the activity in one session
selSession = 4; 
selectedBeh = selectedBehList{selSession}; dffStim = dffStimList{selSession};
stimL = selectedBeh(:,5)==3; stimR = selectedBeh(:,5)==4;
choiceL = selectedBeh(:,6)==1; choiceR = selectedBeh(:,6)==2; miss = selectedBeh(:,6)==0;
flagList = {stimL & choiceL, stimL & choiceR, stimR & choiceR, stimR & choiceL};
titleList = {'stimL; choiceL','stimL; choiceR','stimR; choiceR','stimR; choiceL'};

sortF = sum(nanmean(dffStim(:,31:50,stimL & choiceL),3),2); 
[~,sortIdx] = sort(sortF,'descend');

xdata = ((1:size(dffStim,2))-30)/15; 

figure; 
for i = 1:4
    subplot(2,2,i);
    fn_plotPSTH(dffStim,'sortIdx', sortIdx, 'selFlag', flagList{i},'xaxis',xdata,'xlim',[-2 6],'title',titleList{i}); 
end 
%% separate activating and inhibiting neuron types
avgAct = [];
for i = 1:length(dffStimList)-1
    tempAct = nanmean(nanmean(dffStimList{i}(:,31:60,:),2),3);
    avgAct = cat(2, avgAct, tempAct);
end
meanAvgAct = mean(avgAct,2); meanAbsAvgAct = mean(abs(avgAct),2);
%figure; histogram(meanAbsAvgAct)
activeFlag = meanAbsAvgAct>0.015 & meanAvgAct>0;
suppressFlag = meanAbsAvgAct>0.015 & meanAvgAct<=0;
%% one session all trial types
[flagList,titleList] = fn_selectStim(selectedBehList{selSession},2);
figure; 
for i = 1:6
    subplot(2,3,i); xdata = ((1:size(dffStimList{selSession},2))-30)/15;
    temp = dffStimList{selSession}(activeFlag,:,:);
    sortF = sum(nanmean(temp(:,31:60,stimL & choiceL),3),2); 
    [~,sortIdx] = sort(sortF,'descend');
    fn_plotPSTH(temp,'sortIdx', sortIdx, 'selFlag', flagList{i},'xaxis',xdata,'xlim',[-2 6],'title',titleList{i}); 
    if i==1; climm = clim; else; clim(climm); end 
end 
%% evaluate the stability of PSTH across days
dffStimActL = {};
dffStimActR = {};
[flagList,titleList] = fn_selectStim(selectedBehList{4},2);
temp = nanmean(nanmean(dffStimList{4}(activeFlag,31:60,flagList{1}),2),3); [~,sortIdx] = sort(temp,'descend');
figure; 
for i = 1:length(behavDates)
    [flagList,titleList] = fn_selectStim(selectedBehList{i},2);
    subplot(1,length(behavDates),i); xdata = ((1:size(dffStimList{i},2))-30)/15;
    tempF = dffStimList{i}(activeFlag,:,:); 
    %fn_plotPSTH(tempF,'sortIdx',sortIdx, 'selFlag', flagList{1},'xaxis',xdata,'xlim',[-2 6],'title',titleList{1}); 
    fn_plotPSTH(tempF,'sortIdx',sortIdx, 'selFlag', flagList{1},'xaxis',xdata,'xlim',[-2 6]); yticks([])
    dffStimActL{i} = nanmean(nanmean(tempF(:,31:60,flagList{1}),2),3);
    dffStimActR{i} = nanmean(nanmean(tempF(:,31:60,flagList{3}),2),3);
    if i==1; climm = clim; else; clim(climm); end 
end 
dffStimActL = fn_cell2mat(dffStimActL,2);dayCorrL = corr(dffStimActL);
dffStimActR = fn_cell2mat(dffStimActR,2);dayCorrR = corr(dffStimActR);
figure; subplot(1,2,1); imagesc(dayCorrL); colorbar; 
subplot(1,2,2); hold on; plot(dayCorrL(4,:),'-o'); plot(dayCorrR(4,:),'-o'); ylim([0 1])

%%
plot(dayCorrL(4,:)/2+dayCorrR(4,:)/2,'-o','Color',matlabColors(3)); ylim([0 1])

%% evaluate the stability of PSTH across days
warning('off');
dffStimAct = [];
trainDecoderSession = 4; 

rep = 100; decoderAcc = nan(length(behavDates),rep);
decoderDp = nan(length(behavDates),rep);
for n = 1:rep
    [flagList,titleList] = fn_selectStim(selectedBehList{trainDecoderSession},2);
    tempF = squeeze(nanmean(dffStimList{trainDecoderSession}(activeFlag,31:60,:),2)); 
    tempF_choiceL = tempF(:,flagList{1} | flagList{3});
    tempF_chocieR = tempF(:,flagList{2} | flagList{4});
    tempCellSel = randperm(size(tempF_choiceL,1)); tempCellSel = tempCellSel(1:20);
    decoder = fn_runLDA(tempF_choiceL(tempCellSel,:),tempF_chocieR(tempCellSel,:));
    decoderAcc(trainDecoderSession,n) = decoder.acc;
    decoderDp(trainDecoderSession,n) = decoder.dp;
    for i = 1:length(behavDates)-1
        if i~= trainDecoderSession
            [flagList,titleList] = fn_selectStim(selectedBehList{i},2);
            tempF = squeeze(nanmean(dffStimList{i}(activeFlag,31:60,:),2)); 
            tempF_choiceL = tempF(:,flagList{1} | flagList{3});
            tempF_chocieR = tempF(:,flagList{2} | flagList{4});
            decoder = fn_runLDA(tempF_choiceL(tempCellSel,:),tempF_chocieR(tempCellSel,:),'decoder',decoder);
            decoderAcc(i,n) = decoder.acc; 
            decoderDp(i,n) = decoder.dp; 
        end
    end 
    
end

warning('on');
errorbar(1:7,mean(decoderDp,2),fn_nansem(mean(decoderDp,2)),'Color',matlabColors(2))
plot(mean(decoderDp,2),'Color',matlabColors(2))

%% all functions
function [proj,basis] = run_PCA(dff,flagCell,tempColors,tempLine,nFramePCA)

dffStimPCA = cellfun(@(x)(squeeze(nanmean(dff(:,1:nFramePCA,x),3))), flagCell,'UniformOutput',false);
dffStimPCAFlat = fn_cell2mat(cellfun(@(x)(smoothdata(x,2,'movmean',10)),dffStimPCA,'UniformOutput',false),2);
[basis, varExp, proj, covMat] = fn_pca(dffStimPCAFlat,'zscore',true);

figure; 
for j = 1:6
    subplot(2,4,j);
    hold on;
    
    for i = 1:length(flagCell)
        plot(smoothdata(proj(j,(i-1)*nFramePCA+1:(i)*nFramePCA),'movmean',1),tempLine{i},'Color',tempColors(i,:)); 
    end
end

subplot(2,4,7);
plot(varExp,'-o'); xlim([1 20])

subplot(2,4,8);
plot(cumsum(varExp)); xlim([1 20]); ylim([0 1])
end

