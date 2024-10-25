function savePSTHperDay(data,mouse,alignStr,stim,closeupFlag)
%closeupFlag = 0;
%stim = 2; 
switch alignStr
    case 'stim'
        choiceFlag = false;
    case 'choice'
        choiceFlag = true;
end 

if choiceFlag; selAct = data.dffChoiceList;
else; selAct = data.dffStimList; end 

figure; climmm = [-0.15 0.15];
xAxLabel = (1:100)/15-2; sortFrames = 31:40;tempMax = [];tempMin = [];



for i = 1:length(selAct)
    tempBehav = data.selectedBehList{i};tempMean = {};tempRT = {};
    tempFlag =  {tempBehav(:,5)==stim & tempBehav(:,6)==stim,...
        tempBehav(:,5)==stim & tempBehav(:,6)==3-stim,...
        tempBehav(:,5)==stim & tempBehav(:,6)==0}; 

    for j = 1:length(tempFlag)
        tempRT{j} = nanmean(tempBehav(tempFlag{j},9) - tempBehav(tempFlag{j},8));
        subplot_tight(4,length(selAct),i+length(selAct)*(j-1),[0.025 0.015]); 
        if j==1
            [sortIdx] = fn_plotPSTH(selAct{i},'sortIdx','descend','sortSelIdx',sortFrames,...
                'selFlag',tempFlag{j},'xaxis',xAxLabel); hold on; clim(climmm);
        else
            fn_plotPSTH(selAct{i},'sortIdx',sortIdx,'sortSelIdx',sortFrames,...
                'selFlag',tempFlag{j},'xaxis',xAxLabel); hold on; clim(climmm);
        end 

        if ~choiceFlag;  xline(tempRT{1}, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1);
        else;  xline(-tempRT{1}, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1); end  
        fn_textOnImg(gca,['n=' int2str(sum(tempFlag{j}))] );  xline(0, '-','Color',[0.4 0.4 0.4], 'LineWidth', 1);
        if i~=1; yticks([]); end 
        tempMean{j} = nanmean(nanmean(selAct{i}(:,:,tempFlag{j}),1),3); 
        [tempBias,tempAcc,~,~,acc_L,acc_R] = fn_getAccBias(tempBehav(:,5), tempBehav(:,5)==tempBehav(:,6),tempBehav(:,6)==0);
        if j==1; temp = {acc_L,acc_R}; title(['acc=' num2str(tempAcc,'%.2f')  ',s' int2str(stim) '=' num2str(temp{stim},'%.2f')]); end 
        if closeupFlag; xlim([-0.6 0.6]); end 
    end 
    tempMax(i) = max(fn_cell2mat(tempMean,2)); tempMin(i) = min(fn_cell2mat(tempMean,2));
    
end 

tempMax = ceil(max(tempMax)*100)/100; tempMin = ceil(min(tempMin)*100)/100;
for i = 1:length(selAct)
    tempBehav = data.selectedBehList{i};
    subplot_tight(8,length(selAct),i+length(selAct)*6,[0.025 0.015]); hold on;
    tempFlag = {tempBehav(:,5)==stim & tempBehav(:,6)==stim,tempBehav(:,5)==stim & tempBehav(:,6)==3-stim,tempBehav(:,5)==stim & tempBehav(:,6)==0};
    for j = 1:length(tempFlag)
        tempMean = squeeze(nanmean(selAct{i}(:,:,tempFlag{j}),1)); if isrow(tempMean); tempMean  = tempMean'; end 
        fn_plotMeanErrorbar(xAxLabel,smoothdata(tempMean,1,'movmean',1)',matlabColors(j),matlabColors(j), {'LineWidth',2},...
            {'faceAlpha',0.2});

        tempRT = nanmean(tempBehav(tempFlag{j},9) - tempBehav(tempFlag{j},8));
        if ~choiceFlag; xline(tempRT, '-','Color',matlabColors(j), 'LineWidth', 1);
        else; xline(-tempRT, '-','Color',matlabColors(j), 'LineWidth', 1); end 
    end
    xline(0, '-','Color',[0.8 0.8 0.8], 'LineWidth', 1);
    ylim([tempMin tempMax]); if i~=1; yticks([]); end; xlim([xAxLabel(1) xAxLabel(end)]);
    if closeupFlag; xlim([-0.6 0.6]); end 
end 
subplot_tight(8,1,8,[0.025 0.015]);
fn_textOnPlot('text', gca, 16);

fn_figureSizePDF(gcf,'C:\Users\zzhu34\Documents\tempdata\mesoFig', 'PSTH.pdf')

close gcf; 

