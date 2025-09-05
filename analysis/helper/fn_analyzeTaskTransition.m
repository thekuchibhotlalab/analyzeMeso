function data = fn_analyzeTaskTransition(data,ops,plotFlag)
if ~exist('plotFlag'); plotFlag = false; end 
% load the data
nDays = length(ops.dateNum);
% analyze response time changes during each day
responseTime = cellfun(@(x)(x(:,9)-x(:,8)),data.selectedBehList,'UniformOutput',false);
miss = cellfun(@(x)(x(:,6)==0),data.selectedBehList,'UniformOutput',false);

responseTimeMean = cellfun(@mean,responseTime); responseTimeSEM = cellfun(@fn_nansem,responseTime);
figure; subplot(2,3,1);hold on; errorbar(1:nDays,responseTimeMean,responseTimeSEM); 
subplot(2,3,2);hold on; bar(cellfun(@(x)(sum(x<1/3)),responseTime)); title('trials with 1 note')
subplot(2,3,3);hold on; bar(cellfun(@(x)(sum(x<2/3 & x>=1/3)),responseTime)); title('trials with 2 notes')
subplot(2,3,4);hold on; bar(cellfun(@(x)(sum(x<1 & x>=2/3)),responseTime)); title('trials with 3 notes')
subplot(2,3,5);hold on; bar(cellfun(@(x,y)(sum(x>1 & y~=1)),responseTime,miss)); title('trials with more than 3 notes')
subplot(2,3,6);hold on; bar(cellfun(@(y)(sum(y==1)),miss)); title('miss trials');

% get time axis 
xFrameLim = 100; 
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xAxisChoice = ((1:(xFrameLim))-50)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));
xtickStim = xtickVal*15+30; xtickChoice = xtickVal*15+50;

if plotFlag; plotPSTH_allTrial(); end 

% select trials of analysis
data.oneNoteFlag = cellfun(@(x)(x<1/3),responseTime,'UniformOutput',false);
data.twoNoteFlag = cellfun(@(x)(x<2/3 & x>=1/3),responseTime,'UniformOutput',false);
data.threeNoteFlag = cellfun(@(x)(x<1 & x>=2/3),responseTime,'UniformOutput',false);
data.morethantwoNoteFlag = cellfun(@(x,y)(x>2/3 & y~=1),responseTime,miss,'UniformOutput',false);
data.missFlag = cellfun(@(y)(y==1),miss,'UniformOutput',false);

% do the session alignment
stim = cellfun(@(x)(x(:,5)),data.selectedBehList,'UniformOutput',false);
act = cellfun(@(x)(x(:,6)),data.selectedBehList,'UniformOutput',false);

% select a trial type and show the PSTH
stim1_oneNote_actL_Flag = cellfun(@(x,y,z)(x==1 & y==1 & z==1),data.oneNoteFlag, stim, act, 'UniformOutput',false);
stim1_twoNote_actL_Flag = cellfun(@(x,y,z)(x==1 & y==1 & z==1),data.twoNoteFlag, stim, act, 'UniformOutput',false);


stim2_oneNote_actR_Flag = cellfun(@(x,y,z)(x==1 & y==2 & z==2),data.oneNoteFlag, stim, act, 'UniformOutput',false);
stim2_twoNote_actR_Flag = cellfun(@(x,y,z)(x==1 & y==2 & z==2),data.twoNoteFlag, stim, act, 'UniformOutput',false);

disp(['COUNT Note 1 -- stim 1, act L: ' int2str(cellfun(@sum, stim1_oneNote_actL_Flag))])
disp(['COUNT Note 1-- stim 2, act R: ' int2str(cellfun(@sum, stim2_oneNote_actR_Flag))])
disp(['COUNT Note 2 -- stim 1, act L: ' int2str(cellfun(@sum, stim1_twoNote_actL_Flag))])
disp(['COUNT Note 2 -- stim 2, act R: ' int2str(cellfun(@sum, stim2_twoNote_actR_Flag))])


% select a trial type and show the PSTH
align2Session = 1; toneIdx = 31:60; 
[data.s1a1{1},data.s1a1{2},data.s1a1{3}] = alignPlotPSTH(align2Session,1,1,plotFlag);
[data.s1a2{1},data.s1a2{2},data.s1a2{3}] = alignPlotPSTH(align2Session,1,2,plotFlag);
[data.s2a2{1},data.s2a2{2},data.s2a2{3}] =alignPlotPSTH(align2Session,2,2,plotFlag);
[data.s2a1{1},data.s2a1{2},data.s2a1{3}] =alignPlotPSTH(align2Session,2,1,plotFlag);
align2Session = 8;
try
    [data.s3a1{1},data.s3a1{2},data.s3a1{3}] =alignPlotPSTH(align2Session,3,1,plotFlag); %corrMat=testCorrelation(actCell1,align2Session);
    [data.s3a2{1},data.s3a2{2},data.s3a2{3}] =alignPlotPSTH(align2Session,3,2,plotFlag); %corrMat=testCorrelation(actCell1,align2Session);
    [data.s4a2{1},data.s4a2{2},data.s4a2{3}] =alignPlotPSTH(align2Session,4,2,plotFlag);
    [data.s4a1{1},data.s4a1{2},data.s4a1{3}] =alignPlotPSTH(align2Session,4,1,plotFlag);
catch
    disp('task 2 not successful')
end


function [actCell1,actCell2,actCell3] = alignPlotPSTH(align2Session,stimulus,choice,plotFlag)
    oneNoteFlag = cellfun(@(x,y,z)(x==stimulus & y==choice & z==1), stim, act,data.oneNoteFlag, 'UniformOutput',false);
    twoNoteFlag = cellfun(@(x,y,z)(x==stimulus & y==choice & z==1), stim, act,data.twoNoteFlag, 'UniformOutput',false);
    noMissFlag = cellfun(@(x,y,z)(x==stimulus & y==choice & z==1), stim, act,data.morethantwoNoteFlag, 'UniformOutput',false);

    for k=  1:nDays
        actCell1{k}= data.dffStimList{k}(:,:,oneNoteFlag{k});
        actCell2{k}= data.dffStimList{k}(:,:,twoNoteFlag{k});
        actCell3{k}= data.dffStimList{k}(:,:,noMissFlag{k});
    end

    [~, sortIdx] = sort(nanmean(nanmean(data.dffStimList{align2Session}(:,toneIdx,oneNoteFlag{align2Session}),3),2),'descend');
    if plotFlag
        figure; actCell1 = cell(1,nDays); actCell2 = cell(1,nDays); actCell3 = cell(1,nDays); 
        for k=  1:nDays
            subplot_tight(2,nDays,k,[0.04 0.02]);
            fn_plotPSTH(nanmean(data.dffStimList{k}(:,1:xFrameLim,oneNoteFlag{k}),3),'sortIdx', sortIdx,'xlim',[-2 5],'xaxis',xAxisStim);            subplot_tight(2,nDays,k+nDays,[0.04 0.02]);
            fn_plotPSTH(nanmean(data.dffStimList{k}(:,1:xFrameLim,twoNoteFlag{k}),3),'sortIdx', sortIdx,'xlim',[-2 5],'xaxis',xAxisStim); 
        end 
    end 

end


function plotPSTH_allTrial()
    if isfield(data,'dffStimList')
        figure('Name','PSTH -- all trials, stim', 'NumberTitle', 'off'); 
        for i = 1:nDays
            subplot_tight(1,nDays,i,[0.04 0.02]);
            tempImg = nanmean(data.dffStimList{i},3); if i==1; tempAxis = prctile(tempImg(:),95); end  
            imagesc(nanmean(data.dffStimList{i},3)); xlim([0 100]); clim([-tempAxis tempAxis])
            xticks(xtickStim);xticklabels(xtickStr); title(ops.date{i})
            if i>1; yticks([]);end 
        end 
    end 
    if isfield(data,'dffChoiceList')
        figure('Name','PSTH -- all trials, choice', 'NumberTitle', 'off'); 
        for i = 1:nDays
            subplot_tight(1,nDays,i,[0.04 0.02]);
            tempImg = nanmean(data.dffChoiceList{i},3); if i==1; tempAxis = prctile(tempImg(:),95); end  
            imagesc(nanmean(data.dffChoiceList{i},3)); xlim([0 100]); clim([-tempAxis tempAxis])
            xticks(xtickChoice);xticklabels(xtickStr); title(ops.date{i})
            if i>1; yticks([]);end 
        end 
    end 


end 
end

function actCell = alignPlotPSTH(nDays,toneIdx,align2Session,data,selFlag)

[~, sortIdx] = sort(nanmean(nanmean(data.dffStimActive{align2Session}(:,toneIdx,selFlag{align2Session}),3),2),'descend');
figure; actCell = cell(1,nDays); 
for i = 1:nDays
    subplot(1,nDays,i);xdata = ((1:size(data.dffStimList{i},2))-30)/15;
    fn_plotPSTH(nanmean(data.dffStimActive{i}(:,:,selFlag{i}),3),'sortIdx', sortIdx,'xlim',[-2 6],'xaxis',xdata); 
    actCell{i}= squeeze(nanmean(data.dffStimActive{i}(:,toneIdx,selFlag{i}),2));
end 


end

function corrMat=testCorrelation(actCell,align2Session)
    actCellpre = fn_cell2mat(actCell(1:2),2); 
    actCellalign = fn_cell2mat(actCell(3),2); 
    actCellpost1 = fn_cell2mat(actCell(4:5),2); 
    actCellpost2 = fn_cell2mat(actCell(6:7),2); 
    selTrial = 8; nRep = 1000;
    corrMat = zeros(4,nRep);
    for i = 1:nRep
        tempAlignIdx = randperm(size(actCellalign,2)); tempAlign = nanmean(actCellalign(:,tempAlignIdx(1:selTrial)),2);
        tempAlignIdx = randperm(size(actCellpre,2)); corrMat(1,i) = corr(tempAlign,nanmean(actCellpre(:,tempAlignIdx(1:selTrial)),2));
        tempAlignIdx = randperm(size(actCellalign,2)); corrMat(2,i) = corr(tempAlign,nanmean(actCellalign(:,tempAlignIdx(1:selTrial)),2));
        tempAlignIdx = randperm(size(actCellpost1,2)); corrMat(3,i) = corr(tempAlign,nanmean(actCellpost1(:,tempAlignIdx(1:selTrial)),2));
        tempAlignIdx = randperm(size(actCellpost2,2)); corrMat(4,i) = corr(tempAlign,nanmean(actCellpost2(:,tempAlignIdx(1:selTrial)),2));
    end

end 
