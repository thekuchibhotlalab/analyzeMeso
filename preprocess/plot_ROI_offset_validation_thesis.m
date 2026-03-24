session = [a1([1 2 3 6 7]);a2([50 30 1:3])];
cellIndex = sortIdx(800);

figure; 
for i = 1:10
subplot_tight(1,10,i)
imagesc(ops.offsetMap(1:800,:,session(i))-36); colormap redblue; caxis([-15 15]);hold on;
plot(roiFinal{session(i),cellIndex}(:,2),roiFinal{session(i),cellIndex}(:,1),'Color',[0 0 0],'LineWidth', 2)
cellIndex2 = sortIdx(800);
plot(roiFinal{session(i),cellIndex2}(:,2),roiFinal{session(i),cellIndex2}(:,1),'Color',[0 0 0],'LineWidth', 2)
xticks([]); yticks([]); xlim([25 450]); ylim([25 800])
end
figure;
for i = 1:10
    subplot_tight(1,10,i)
imagesc(alignedOps.suite2pImg(:,:,session(i))); colormap gray; hold on;
title(ishereFinal(session(i),cellIndex));
plot(roiFinal{session(i),cellIndex}(:,2),roiFinal{session(i),cellIndex}(:,1),'r','LineWidth', 2)
tempX = nanmean(roiFinal{i+10,cellIndex}(:,2));tempY = nanmean(roiFinal{i+10,cellIndex}(:,1));
xlim([tempX-20 tempX+20]); ylim([tempY-20 tempY+20]); xticks([]); yticks([]);
end
