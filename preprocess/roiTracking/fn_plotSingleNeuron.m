a = nansum(ishereFinal,1);
[~,cellIndex] = sort(a,'descend');

figure; 
cellIdx = cellIndex(40);
tempPlot = 11:20:210;
for i = 1:length(tempPlot)
    subplot_tight(1,10,i);
    imagesc(alignedOps.suite2pImg(:,:,tempPlot(i))); hold on; colormap gray;
    temp = roiFinal{tempPlot(i),cellIndex};
    plot([temp(:,2);temp(1,2)],[temp(:,1);temp(1,1)],'r','LineWidth', 2)
    xlim([nanmean(temp(:,2))-20 nanmean(temp(:,2))+20])
    ylim([nanmean(temp(:,1))-20 nanmean(temp(:,1))+20])


end 