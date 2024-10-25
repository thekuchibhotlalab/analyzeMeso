%% load data
[align_PPC1,daySplit1] = plotArea('zz153_PPC');
[align_PPC2,daySplit2] = plotArea('zz159_PPC');
[align_AC,daySplit3] = plotArea('zz159_AC');

%% take out the outlier days
takeOutDay = [3,10,14,15];
daySplit3_new = [0;floor(daySplit3)];
alignACtemp = align_AC;
for i = 1:length(takeOutDay)
    tempIdx = daySplit3_new(takeOutDay(i))+1:daySplit3_new(takeOutDay(i)+1);
    for j = tempIdx; alignACtemp(j).stackMatchIdx = nan;end  
end 
alignACtemp(isnan([alignACtemp(:).stackMatchIdx])) = [];
[~,daySplit_temp] = unique({alignACtemp.currStack});
daySplit_temp = daySplit_temp(2:end-1)-0.5;
figure; plotIndiv(alignACtemp, daySplit_temp); title('zz159 AC');

%% plot the two animals for PPC
takeOutDay = 18;
daySplit1_new = [0;floor(daySplit1); length(align_PPC1)];
alignPPCtemp = align_PPC1;
for i = 1:length(takeOutDay)
    tempIdx = daySplit1_new(takeOutDay(i))+1:daySplit1_new(takeOutDay(i)+1);
    for j = tempIdx; alignPPCtemp(j).meanImgLocRef = nan;end  
end 
alignPPCtemp(isnan([alignPPCtemp(:).meanImgLocRef])) = [];
[~,daySplit1_new] = unique({alignPPCtemp.currStack});
daySplit1_new = daySplit1_new(2:end-1)-0.5;
align_PPC1_new = alignPPCtemp;

figure; hold on; plotIndiv(align_PPC1_new, daySplit1_new,false); 
plotIndiv(align_PPC2, daySplit2,false,matlabColors(1)/2+matlabColors(3)/2); 
title('zz159 AC');

%%
figure; hold on; plotIndiv(align_PPC1, daySplit1); 

%% all functions
function [alignData,daySplit] = plotArea(mouseArea)
 
switch mouseArea
    case 'zz153_PPC'
        loadPath = 'C:\Users\zzhu34\Documents\tempdata\zz153_PPC\meanImg';
    case 'zz153_AC'
        loadPath = 'C:\Users\zzhu34\Documents\tempdata\zz153_AC\meanImg';
    case 'zz159_PPC'
        loadPath = 'C:\Users\zzhu34\Documents\tempdata\zz159_PPC\meanImg';
    case 'zz159_AC'
        loadPath = 'C:\Users\zzhu34\Documents\tempdata\zz159_AC\task2\meanImg';
end 
fname = 'planeMatchPatch.mat';
alignData = load([loadPath filesep fname]); alignData = alignData.allMatchStr;
[~,daySplit] = unique({alignData.currStack});
daySplit = daySplit(2:end-1)-0.5;

% make plot 
figure; subplot(1,2,1); plotIndiv(alignData, daySplit); title(strjoin(strsplit(mouseArea,'_'),' '));
subplot(1,2,2); plotIndiv(alignData, daySplit,true);  title(strjoin(strsplit(mouseArea,'_'),' '));
end 


function plotIndiv(alignData, daySplit,absFlag,scatterColor)
if ~exist('scatterColor'); scatterColor = matlabColors(1);end 
allOffset = cell2mat({alignData(:).meanImgLocPatch});
allOffset = allOffset - median(allOffset);
if ~exist("absFlag"); absFlag = false; end 
if absFlag; allOffset = abs(allOffset); end 
maxY = max([max(abs(allOffset))+2 15]);

fill([1 length(alignData) length(alignData) 1],[-5 -5 5 5],[0.9 0.9 0.9],'LineWidth',2,'EdgeColor','none');
hold on;
plot([1 length(alignData)],[0 0],'Color',[0.8 0.8 0.8],'LineWidth',2);
for i = 1:length(daySplit)
    plot([daySplit(i) daySplit(i)],[-maxY maxY],'Color',[0.8 0.8 0.8],'LineWidth',2);
end 

scatter(1:length(allOffset),allOffset,20, scatterColor,'filled');

if ~absFlag; ylim([-maxY maxY]); else; ylim([0 maxY]); end  

xlim([1 length(alignData)]);
xlabel('Session'); ylabel ('Z-depth difference')
end 
