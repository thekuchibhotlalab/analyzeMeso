function fn_plotCluster(data,period,selDay,mouseStr)
% plot cluster function

switch period
    case 'stim'
        tempSel = data.dffStimList;
        selFrame = 28:36; 
    case 'choice'
        tempSel = data.dffChoiceList;
        selFrame = 16:36;
    case 'joint'
        tempSel = data.dffStimList;
        selFrame = 28:36;
    case 'stim_wholeTrial'
        tempSel = data.dffStimList;
        selFrame = 21:71;
    case 'choice_wholeTrial'
        tempSel = data.dffChoiceList;
        selFrame = 16:71;


end 
selAct = []; daylabel = [];
for i = 1:length(selDay)


    [flagList, titleList] = fn_selectStim(data.selectedBehList{selDay(i)},1);
    selAct = cat(1,selAct,[smoothdata(nanmean(tempSel{selDay(i)}(:,selFrame,flagList{1}),3),2,'movmean',3),...
        smoothdata(nanmean(tempSel{selDay(i)}(:,selFrame,flagList{2}),3),2,'movmean',3)]);
    selActOrig = cat(1,selAct,[nanmean(tempSel{selDay(i)}(:,selFrame,flagList{1}),3),...
        nanmean(tempSel{selDay(i)}(:,selFrame,flagList{2}),3)]);
    daylabel = cat(1,daylabel, ones(size(tempSel{selDay(i)},1),1)*selDay(i));

end 


tempnanFlag = sum(isnan(selAct),2)==size(selAct,2);
selAct(tempnanFlag,:) = []; selActOrig(tempnanFlag,:) = []; daylabel(tempnanFlag) = []; 
selAct(:,sum(isnan(selAct),1)==size(selAct,1)) = []; selActOrig(:,sum(isnan(selActOrig),1)==size(selActOrig,1)) = [];

[reducedData_umap, umapStruct, ~] = run_umap(selAct,...
    'n_neighbors', 10,'metric','correlation', 'min_dist', 0.02, 'n_components', 3, 'n_epochs',600,'verbose','none');


distances = pdist(reducedData_umap, 'correlation');  % You can choose other metrics like 'correlation'
Z = linkage(distances, 'average');  % You can choose 'single', 'complete', or 'average' linkage
maxClusters = 10;
avgSilhouette = zeros(1, maxClusters);

for k = 1:maxClusters
    clusterIdx = cluster(Z, 'maxclust', k);
    silhouetteVals = silhouette(reducedData_umap, clusterIdx, 'correlation');
    avgSilhouette(k) = mean(silhouetteVals);
end

% Step 4: find best number of clusters
[~,numClusters] = max(avgSilhouette);  % Choose how many clusters you expect (modify if needed)
clusterIdx = cluster(Z, 'maxclust', numClusters);  % Assign each neuron to a cluster


colorLim = prctile(selAct(:),98); colorLim = [-colorLim colorLim];
% LEFT PANELS, PANEL 3
figure; length1 = 0.16; marginx = 0.03; marginy = 0.04;
position = [marginx, marginy, length1, 0.3];ax = axes('Position', position); hold on; 
for i = 1:numClusters
    tempDay = daylabel(clusterIdx==i);
    fn_plotHistLine(tempDay, 'histCountArgIn',{0:1:max(daylabel),'Normalization','count'},...
        'plotArgIn',{'Color',matlabColors(i),'LineWidth',2})
end 
xlim([0 max(daylabel)]); xlabel('Days in training'); ylabel('Neuron count in cluster')

%L PANEL 2
position = [marginx, 0.28+marginy*2, length1, 0.28];ax = axes('Position', position);
[~,sortIdx] = sort(clusterIdx,'ascend');
corrmat = corr(selAct(sortIdx,:)');
imagesc(corrmat); clim([-0.5 1]);
clim([-0.5 1])

%L PANEL 1
position = [marginx, 0.56+marginy*3, length1, 0.28];ax = axes('Position', position);
plot(1:maxClusters, avgSilhouette(1:end), '-o');
xlabel('Number of clusters');
ylabel('Average Silhouette Score');
title('Silhouette Method');

%M PANEL 2
length2 = 0.28;
position = [marginx*2+length1, marginy, length2, 0.43];ax = axes('Position', position);
colors = jet; colors = colors(floor(linspace(1,size(colors,1),selDay(end))),:);
gscatter(reducedData_umap(:,1), reducedData_umap(:,2), daylabel,colors);  % Use clusterIdx from hierarchical clustering
xlabel('UMAP Dimension 1');
ylabel('UMAP Dimension 2');
title('UMAP of Neuron Activity with days in learning');

%M PANEL 1
position = [marginx*2+length1, 0.47+marginy*2, length2, 0.43];ax = axes('Position', position);
gscatter(reducedData_umap(:,1), reducedData_umap(:,2), clusterIdx);  % Use clusterIdx from hierarchical clustering
xlabel('UMAP Dimension 1');
ylabel('UMAP Dimension 2');
title('UMAP of Neuron Activity with Clustering');

% cluster PSTH
clusterStartLocX = marginx*3+length1+length2;
clusterLengthX = (1 - clusterStartLocX - 2*marginx) / (numClusters+1);
xaxisL = (selFrame-30)/15; 
for i = 1:numClusters
    position = [clusterStartLocX+clusterLengthX*(i-1), marginy*2+0.43, clusterLengthX, 0.43];ax = axes('Position', position);
    imagesc(xaxisL,1:sum(clusterIdx==i),selActOrig(clusterIdx==i,1:size(selActOrig,2)/2)); clim(colorLim)
    hold on; xline(0,'Color',[0.4 0.4 0.4]); title(['PSTH stim=1, cluster=' int2str(i)],'FontSize',6);
    yticks([]);fn_textOnImg(ax,['n=' int2str(sum(clusterIdx==i))],  12); 
    
    position = [clusterStartLocX+clusterLengthX*(i-1), marginy, clusterLengthX, 0.43];ax = axes('Position', position);
    imagesc(xaxisL,1:sum(clusterIdx==i),selActOrig(clusterIdx==i,size(selActOrig,2)/2+1:end)); clim(colorLim)
    hold on; xline(0,'Color',[0.4 0.4 0.4]); title(['PSTH stim=2, cluster=' int2str(i)],'FontSize',6);
    yticks([]); fn_textOnImg(ax,['n=' int2str(sum(clusterIdx==i))],  12); xlabel('Time(s)');
end 

position = [clusterStartLocX+clusterLengthX*(numClusters) + marginx, marginy*2+0.43, clusterLengthX, 0.43];ax1 = axes('Position', position); hold on;
for i = 1:numClusters
    temp = selActOrig(clusterIdx==i,1:size(selActOrig,2)/2);
    fn_plotMeanErrorbar(xaxisL,temp,matlabColors(i),matlabColors(i),{'LineWidth',2},{'faceAlpha',0.2});
    xline([0 0],'Color',[0.4 0.4 0.4]); title('Avg. df/f each cluster, s1');
end 
ylimm1 = ylim; 


position = [clusterStartLocX+clusterLengthX*(numClusters) + marginx, marginy, clusterLengthX, 0.43];ax2 = axes('Position', position); hold on;
for i = 1:numClusters
    temp = selActOrig(clusterIdx==i,size(selActOrig,2)/2+1:end);
    fn_plotMeanErrorbar(xaxisL,temp,matlabColors(i),matlabColors(i),{'LineWidth',2},{'faceAlpha',0.2});
    xline([0 0],'Color',[0.4 0.4 0.4]); title('Avg. df/f each cluster, s2');
end 
xlabel('Time(s)');
ylimm2 = ylim; 

ylimm = [min([ylimm1(1) ylimm2(1)]) max([ylimm1(2) ylimm2(2)])];
ylim(ax1,ylimm);ylim(ax2,ylimm);

position = [clusterStartLocX, 0.94, 1-clusterStartLocX, 0.06];ax = axes('Position', position); hold on;
fn_textOnPlot([strrep(mouseStr, '_', '__')  ', cluster using ' period], ax, 12);
fn_figureSizePDF(gcf,'C:\Users\zzhu34\Documents\tempdata\mesoFig', 'umap_cluster.pdf')

end 