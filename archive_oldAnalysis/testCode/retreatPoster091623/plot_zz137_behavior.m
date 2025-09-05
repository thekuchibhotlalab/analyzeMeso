clear;
behDay = '091223'; % 091223 %'091523' %'092323' %'092523' %'093023'
behDay2 = '20230912';
suite2ppath = ['C:\Users\zzhu34\Documents\tempdata\zz137\zz137_' behDay '\suite2p\plane0\'];
data = load([suite2ppath 'Fall.mat']);
behpath = 'J:\ziyi\mesoData\zz137_behavior\';

%% Get all data needed
F = data.F(data.iscell(:,1)==1,:);
inhFlag = data.redcell(data.iscell(:,1)==1,1)==1;
yLoc = cellfun(@(x)(max(x.ypix)), data.stat)'; yLoc = yLoc(data.iscell(:,1)==1);
PPCflag = yLoc<820 & yLoc<400 ; ACflag = yLoc>=820; 


dff = fn_getDff(F','method', 'movMean','dffWindow', 1000)';
notNanFlag = ~(sum(isnan(dff),2)>0);
dff = dff(notNanFlag,:); inhFlag = inhFlag(notNanFlag);
PPCflag = PPCflag(notNanFlag);ACflag = ACflag(notNanFlag);

figure; imagesc(dff); clim([-0.2 0.5])

%nFrame = [17523 10742]; %'092523' 
%nFrame = [10900, 10683]; %092323
%nFrame = [12662, 12352]; %091523
%nFrame = [11174, 11452]; %'093023'
nFrame = [18630 11304]; %'091223'
behData1 = load([behpath 'zz137_' behDay2 '_2AFCsession2_allData.mat']);behData1 = behData1.allData;
behData2 = load([behpath 'zz137_' behDay2 '_2AFCsession3_allData.mat']);behData2 = behData2.allData;
behData2(:,1) = behData2(:,1) + 100; behData2(:,7:9) = behData2(:,7:9) + nFrame(1);

behData = cat(1,behData1,behData2);

%% Parse out trial
[dffStim, dffChoice] = fn_parseTrialFromTC(dff,behData);
stimL = behData(:,2)==1; stimR = behData(:,2)==2;
choiceL = behData(:,3)==1; choiceR = behData(:,3)==2; miss = behData(:,3)==0;
%flagCell = {stimL&choiceL, stimL&choiceR, stimL&miss, stimR&choiceL, stimR&choiceR, stimR&miss}; 
%tempColors = [matlabColors(1);matlabColors(1);[0.6 0.6 0.6]; matlabColors(2);matlabColors(2);[0.6 0.6 0.6]];
%tempLine = {'-' ,'--','o','-','--','o'};
nFramePCA = 120;
flagCell = {stimL&choiceL, stimL&choiceR, stimR&choiceL, stimR&choiceR}; 
tempColors = [matlabColors(1);matlabColors(1); matlabColors(2);matlabColors(2)];
tempLine = {'-' ,'--','-','--'};
%proj = run_PCA(dffStim(PPCflag&~inhFlag,:,:),flagCell,tempColors,tempLine,nFramePCA);
%proj = run_PCA(dffStim(ACflag&inhFlag,:,:),flagCell,tempColors,tempLine,nFramePCA);
[projS,basisS] = run_PCA(dffChoice(PPCflag&~inhFlag,:,:),flagCell,tempColors,tempLine,nFramePCA);


selFlag = PPCflag&~inhFlag; 
figure; subplot(1,2,1)
corrL = nanmean(dffStim(selFlag,21:70,flagCell{1}),3); [~,sortIdx] = sort(sum(corrL(:,11:15),2),'descend');
imagesc(corrL(sortIdx,:)); clim([-0.03 0.2]); xticks([10 25 40]); xticklabels([0 1 2])
subplot(1,2,2);
corrR = nanmean(dffStim(selFlag,21:70,flagCell{2}),3); [~,sortIdx] = sort(sum(corrR(:,11:15),2),'descend');
imagesc(corrR(sortIdx,:)); clim([-0.03 0.2]); xticks([10 25 40]); xticklabels([0 1 2])


figure; subplot(1,2,1)
corrL = nanmean(dffChoice(selFlag,41:90,flagCell{1} | flagCell{4}),3); [~,sortIdx] = sort(sum(corrL(:,11:15),2),'descend');
imagesc(corrL(sortIdx,:)); clim([-0.03 0.2]); xticks([10 25 40]); xticklabels([0 1 2])
subplot(1,2,2);
corrR = nanmean(dffChoice(selFlag,41:90,flagCell{2} | flagCell{3}),3); [~,sortIdx] = sort(sum(corrR(:,11:15),2),'descend');
imagesc(corrR(sortIdx,:)); clim([-0.03 0.2]); xticks([10 25 40]); xticklabels([0 1 2])

%%
plotdim = [1 2];
figure; hold on;
for i = 1:length(flagCell)
    temp1 = projS(plotdim(1),(i-1)*nFramePCA+1:(i)*nFramePCA);
    temp2 = projS(plotdim(2),(i-1)*nFramePCA+1:(i)*nFramePCA);
    plot(smoothdata(temp1,'movmean',1),smoothdata(temp2,'movmean',1) ,tempLine{i},'Color',tempColors(i,:)); 
end
%% Choice -- get trial by trial projection
[projC,basisC] = run_PCA(dffChoice(PPCflag&~inhFlag,:,:),flagCell,tempColors,tempLine,nFramePCA);
tempDff = dffChoice(PPCflag&~inhFlag,:,:); tempDff = reshape(tempDff,[size(tempDff,1) size(tempDff,2)*size(tempDff,3)]);
projTT = basisC' * tempDff / size(basisC,1); projTT = reshape(projTT,[size(projTT,1) size(dffChoice,2) size(dffChoice,3)]);
rt = behData(:,6) - behData(:,5);
rtFast = rt<0.75 & rt>0.25; rtMid = rt>0.75 & rt<3; rtSlow = rt<3 & rt>2;
projTT_fast = sortProj(projTT,behData,rtFast,nFramePCA); projTT_fast = fn_cell2mat(cellfun(@(x)(x(1,:)),projTT_fast,'UniformOutput',false),1);
projTT_mid = sortProj(projTT,behData,rtMid,nFramePCA); projTT_mid = fn_cell2mat(cellfun(@(x)(x(1,:)),projTT_mid,'UniformOutput',false),1);
projTT_slow = sortProj(projTT,behData,rtSlow,nFramePCA); projTT_slow = fn_cell2mat(cellfun(@(x)(x(1,:)),projTT_slow,'UniformOutput',false),1);
figure;
for i = 1:4
    subplot(2,2,i); hold on; 
    plot(projTT_fast(i,:)); plot(projTT_mid(i,:)); plot(projTT_slow(i,:));
end

figure;
subplot(3,1,1); hold on; 
plot(projTT_fast(1,:),'-','Color',matlabColors(1));  plot(projTT_fast(2,:),'--','Color',matlabColors(1)); 
plot(projTT_fast(3,:),'-','Color',matlabColors(2));  plot(projTT_fast(4,:),'--','Color',matlabColors(2)); 
subplot(3,1,2); hold on; 
plot(projTT_mid(1,:),'-','Color',matlabColors(1));  plot(projTT_mid(2,:),'--','Color',matlabColors(1)); 
plot(projTT_mid(3,:),'-','Color',matlabColors(2));  plot(projTT_mid(4,:),'--','Color',matlabColors(2)); 
    
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

function [newFstim,newFchoice] = fn_parseTrialFromTC(F,behData)
nNeuron = size(F,1);
nTrials = size(behData,1);
newF_stimAligned = cell(1,nTrials);
newF_choiceAligned = cell(1,nTrials);
preFrameStim = 30; tempFrameStim = 0;
preFrameChoice = 50; tempFrameChoice = 0;
for i = 1:nTrials
    if i<nTrials; endFrame = behData(i+1,7)-1;
    else endFrame = size(F,2); end 
    stimFrameStart = behData(i,7)-preFrameStim;
    choiceFrame = behData(i,8)-preFrameChoice;
    newF_stimAligned{i} = F(:,stimFrameStart:endFrame);
    tempFrameStim = max([tempFrameStim size(newF_stimAligned{i},2)]);
    newF_choiceAligned{i} = F(:,choiceFrame:endFrame);
    tempFrameChoice = max([tempFrameStim size(newF_choiceAligned{i},2)]);
end


newFstim = nan(nNeuron,tempFrameStim ,nTrials);
newFchoice = nan(nNeuron,tempFrameChoice ,nTrials);

for i = 1:nTrials
    newFstim(:,1:size(newF_stimAligned{i},2),i) = newF_stimAligned{i};
    newFchoice(:,1:size(newF_choiceAligned{i},2),i) = newF_choiceAligned{i};
end

end

function projAvg = sortProj(proj,behData,trialFlag,selFrame)
projSel = proj(:,:,trialFlag);behSel = behData(trialFlag,:);
stimL = behSel(:,2)==1; stimR = behSel(:,2)==2;
choiceL = behSel(:,3)==1; choiceR = behSel(:,3)==2; miss = behSel(:,3)==0;
flagCell = {stimL&choiceL, stimL&choiceR, stimR&choiceL, stimR&choiceR}; 
projAvg = cellfun(@(x)(smoothdata(squeeze(nanmean(projSel(:,1:selFrame,x),3)),2,'movmean',10)), flagCell,'UniformOutput',false);

end