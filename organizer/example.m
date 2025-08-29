tic; ani = Animal('zz159_PPC','actType','spk'); toc;

%%
ani.visualizePSTH();

%% select behavior and dff days that allow tracking of 
selDay = find(cell2mat(ani.dayInfo.isheresum)>(0.7*length(ani.dayInfo.ishere{1})));
selDayIshere = fn_cell2mat(ani.dayInfo.ishere(selDay),1);
ishereAllDay = all(selDayIshere(1:14,:),1);

selAct = ani.dayInfo.dffChoice(selDay);
selWheel = ani.dayInfo.wheelChoice(selDay);
selBehav = ani.dayInfo.behSel(selDay);
%% first plot one day to compare between spk and dff, PCA
dayPlot = 25;
daySort = 7; 
tempFlag = selBehav{daySort}.stimuli==2 &  selBehav{daySort}.choice==2;
[~,sortIdx] = sort(nanmean(nanmean(selAct{dayPlot}(:,25:30,tempFlag),3),2),'descend');
tempAct = selAct{dayPlot};
tempWheel = selWheel{dayPlot};
tempBehav = selBehav{dayPlot};
    
figure; 
plotOneDayPCA(tempAct,tempWheel,tempBehav,1,1,sortIdx)


%% plot multiple days, using spk only. 
figure; sortByDay = 7;
tempFlag = selBehav{sortByDay}.stimuli==2 &  selBehav{sortByDay}.choice==2;
[~,sortIdx] = sort(nanmean(nanmean(selAct{sortByDay}(:,25:30,tempFlag),3),2),'descend');
maxPlot = 10; startIdx = 11; plotMargin = [0.02 0.005];
for i = 1:maxPlot

    tempAct = selAct{i+startIdx-1};
    tempWheel = selWheel{i+startIdx-1};
    tempBehav = selBehav{i++startIdx-1};
    
    plotOneDay(tempAct,tempWheel,tempBehav,maxPlot,i,sortIdx,plotMargin);
end 

%% 
function plotOneDay(tempAct,tempWheel,tempBehav,maxPlot,pos,sortIdx,plotMargin)
    i = pos; 
    flag = tempBehav.stimuli==2 &  tempBehav.choice==2;
    psth_behav = tempBehav(flag,:);
    RTshift = 31-(psth_behav.RT*15);

    subplot_tight(3,maxPlot,i,plotMargin)


    fn_plotPSTH(tempAct,'selFlag',flag,'sortIdx',sortIdx); xlim([1 75]);%clim([0 0.03]);


    xline(31); xline(nanmean(RTshift));yticks([]);
    
    subplot_tight(3,maxPlot,maxPlot+i,plotMargin)
    psth = nanmean(tempAct(:,:,flag),3);
    plot(nanmean(psth,1));xlim([1 75]);
    xline(31); xline(nanmean(RTshift)); yticks([]);
    
    subplot_tight(3,maxPlot,maxPlot*2+i,plotMargin)
    psth_wheel = tempWheel(:,flag);
    xline(31); xline(nanmean(RTshift)); yticks([]);
    for j = 1:size(psth_wheel,2)
        temp = round(RTshift(j));
        if temp<1; temp = 1; end 
        psth_wheel(:,j) = psth_wheel(:,j) - psth_wheel(temp,j);
    end 
    plot(nanmean(psth_wheel,2));xlim([1 75]);
    xline(31); xline(nanmean(RTshift));yticks([]);

end


function plotOneDayPCA(tempAct,tempWheel,tempBehav,maxPlot,pos,sortIdx)
    i = pos; 
    flag = tempBehav.stimuli==2 &  tempBehav.choice==2;
    psth_behav = tempBehav(flag,:);
    RTshift = 31-(psth_behav.RT*15);

    subplot(3,maxPlot,i)


    fn_plotPSTH(tempAct,'selFlag',flag,'sortIdx',sortIdx); xlim([1 75]);%clim([0 0.03]);


    xline(31); xline(nanmean(RTshift));yticks([]);
    
    
    psth = nanmean(tempAct(:,:,flag),3);
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(psth);
    for k = 1:3; plotPC(k); end 

    subplot(6,maxPlot,maxPlot*5+i)
    psth_wheel = tempWheel(:,flag);
    xline(31); xline(nanmean(RTshift)); yticks([]);
    for j = 1:size(psth_wheel,2)
        temp = round(RTshift(j));
        if temp<1; temp = 1; end 
        psth_wheel(:,j) = psth_wheel(:,j) - psth_wheel(temp,j);
    end 
    plot(nanmean(psth_wheel,2));xlim([1 75]);
    xline(31); xline(nanmean(RTshift));yticks([]);

    function plotPC(idx)
        subplot(6,maxPlot,maxPlot*(idx+1)+i)
        plot(COEFF(:,idx)); xlim([1 75]);
        xline(31); xline(nanmean(RTshift)); yticks([]);
    end 

end