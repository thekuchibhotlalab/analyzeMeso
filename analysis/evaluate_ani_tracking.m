%% directly 
ani = 'zz153_PPC';
datapath = ['C:\Users\zzhu34\Documents\tempdata\' ani];
load([datapath filesep 'ops.mat']);
load([datapath filesep 'stackROI_final_tracked.mat']);
%% RUN tracking
[sessionCount1,sessionCount2,ishereSession1,sessionSel1] = selTracking(ops, ishereFinal);

%% PLOT results
figure; plot(sessionCount1); hold on; plot(sessionCount2); title([ani 'tracking results']);
xlabel('nSessions Selected');ylabel('nNeuron Tracked')
%% plot offset map
figure; plotIdx = 10:10:size(ops.offsetMap,3);
for i = 1:length(plotIdx)
    subplot(4,5,i);
    imagesc(ops.offsetMap(:,:,plotIdx(i)) - nanmean(ops.offsetMap(:)));
    colormap redblue
end 
a = squeeze(nanmean(nanmean(abs(ops.offsetMap - nanmean(ops.offsetMap(:))),1),2));
figure; plot(a); title(['mean offset is ' num2str(nanmean(a)) ' um'])

%% Thesis plot 1 -- plot the offset of tracked cell vs. non-tracked cells
nSession = length(sessionCount1); 
nROI = size(ishereFinal,2);
thre = round(length(sessionCount1)*0.65);
sessionSel = sessionSel1{thre};
sessionNoSel = find((~ismember(1:nSession, sessionSel)));

roiSel = find(ishereSession1{thre});
roiOffset = zeros(length(sessionSel),length(roiSel)); 
warning off; 
for i = 1:length(sessionSel)
    disp(i);
    for j = 1: length(roiSel)
        tempROIcoord = roiFinal{sessionSel(i),roiSel(j)};
        try
            poly = polyshape(tempROIcoord(:,1), tempROIcoord(:,2));
            % Use the built-in centroid function
            [cx, cy] = centroid(poly);
            cx = round(cx); cy = round(cy);
            roiOffset(i,j) = ops.offsetMap(cx,cy,sessionSel(i));
        catch 
            roiOffset(i,j) = nan;
        end 
    end 
end
% compare with the untarcked neurons
includeROI = (nansum(ishereFinal,1)~=0);
roiSel = (ishereSession1{thre});
roiSelBad = find((~roiSel) & includeROI); 
roiOffsetBad = nan(length(sessionSel),length(roiSelBad));

for i = 1:length(sessionSel)
    disp(i);
    for j = 1: length(roiSelBad)
        tempROIcoord = roiFinal{sessionSel(i),roiSelBad(j)};
        % Use the built-in centroid function
        try
            poly = polyshape(tempROIcoord(:,1), tempROIcoord(:,2));
            [cx, cy] = centroid(poly);
            cx = round(cx); cy = round(cy);
            roiOffsetBad(i,j) = ops.offsetMap(cx,cy,sessionSel(i));
        catch

        end 
    end 
end

figure; histogram(abs(roiOffset(:)-ops.refStackSelLoc(4)), 0:0.5:25,'Normalization','probability'); 
hold on; histogram(abs(roiOffsetBad(:)-ops.refStackSelLoc(4)),0:0.5:25,'Normalization','probability')
legend({'neuron accepted','neuron rejected'})
xlabel('offset (um)');ylabel('probability')


figure; histogram([ abs(roiOffset(:)-ops.refStackSelLoc(4)) ; abs(roiOffsetBad(badIshere==1)-ops.refStackSelLoc(4))], 0:0.5:25,'Normalization','probability'); 
hold on; histogram(abs(roiOffsetBad(badIshere==0)-ops.refStackSelLoc(4)),0:0.5:25,'Normalization','probability')
legend({'neuron accepted','neuron rejected'})
xlabel('offset (um)');ylabel('probability')


%% Plot 2 -- plot learning curve plot the session selected with behavior
ani = Animal('zz153_PPC','loadNeural', false);
[sortedSessionInfo] = ani.sortBehSessionInfo;
%% Plot 2 
nSessions = height(sortedSessionInfo);

padTo16 = @(m) [m, nan(size(m, 1), 16 - size(m, 2))];
paddedBehCells = cellfun(padTo16, sortedSessionInfo.beh, 'UniformOutput', false);


allBeh = cat(1,paddedBehCells{:});
nTrialsPerSession = cellfun(@(x) size(x, 1), sortedSessionInfo.beh);
sessionEnd = cumsum(nTrialsPerSession);
sessionStart = [1; sessionEnd(1:end-1) + 1];

[~,accT1] = fn_getAccBiasSmooth(allBeh(:,2),allBeh(:,4),300,'task1');
[~,accT2] = fn_getAccBiasSmooth(allBeh(:,2),allBeh(:,4),300,'task2');

figure; hold on;

for i = 1:length(sessionSel)
    tempIdx = find(sessionSel(i) == sortedSessionInfo.sessionNum);
    if ~isempty(tempIdx) % baseline sessions can make it empty
        area([sessionStart(tempIdx) sessionStart(tempIdx) sessionEnd(tempIdx) sessionEnd(tempIdx)],...
            [0 1 1 0],'FaceColor',[0.8 0.8 0.8],'LineStyle','none')
    end 
end 
plot(accT1); plot(accT2)

%% Plot 2 -- plot individual cells with behavio
sessionPlot = [7 17 23 31 41 48 54 64 72 80 92 110 121 132];
temp = ishereFinal(sessionPlot,:); goodNeuron = find(all(temp,1));

plotGoodNeuron = [11 12 14]; 
figure; 
for i = 1:length(plotGoodNeuron)
    for j = 1:length(sessionPlot)
        subplot_tight(length(plotGoodNeuron),length(sessionPlot),(i-1)*length(sessionPlot)+j,[0.01 0.01]);
        imagesc(alignedOps.suite2pImg(:,:,sessionPlot(j))); hold on; colormap gray;
        temp = roiFinal{sessionPlot(j),goodNeuron(plotGoodNeuron(i))};
        plot([temp(:,2);temp(1,2)],[temp(:,1);temp(1,1)],'r','LineWidth', 2)
        xlim([nanmean(temp(:,2))-20 nanmean(temp(:,2))+20])
        ylim([nanmean(temp(:,1))-20 nanmean(temp(:,1))+20])
        xticks([]); yticks([]);
    end 
end 

figure;  hold on; 
for i = 1:length(sessionPlot)
    tempIdx = find(sessionPlot(i) == sortedSessionInfo.sessionNum);
    if ~isempty(tempIdx) % baseline sessions can make it empty
        area([sessionStart(tempIdx) sessionStart(tempIdx) sessionEnd(tempIdx) sessionEnd(tempIdx)],...
            [0 1 1 0],'FaceColor',[0.8 0.8 0.8],'LineStyle','none')
    end 
end 
plot(accT1);plot(accT2)


%% ALL FUNCTIONS
function [sessionCount1,sessionCount2,ishereSession1,sessionSel1] = selTracking(ops, ishere)
    nSession = size(ishere,1);
    offsetMap = ops.offsetMap;

    avgOffset = squeeze(nanmean(nanmean(abs(offsetMap- ops.refStackSelLoc(4)),1),2)); 
    [sortedOffset,sortIdx] = sort(abs(avgOffset),'ascend');
    for k = 1:nSession
        temp = ishere(sortIdx(1:k),:);
        ishereSession1{k} = all(temp,1);
        sessionCount1(k) = sum(ishereSession1{k});
        sessionSel1{k} = sortIdx(1:k);
        % add day number on the original matrix 
    end 

    offsetMap_flat = reshape(offsetMap,size(offsetMap,1)*size(offsetMap,2),[]);
    offsetMapCorr = corr(offsetMap_flat,'rows','complete');
    tempNan = isnan(offsetMap_flat(:,1));offsetMap_flat(tempNan,:) = [];
    tempDist = squareform(pdist(offsetMap_flat'));
    offsetDist = sum(tempDist,1);
    [~,refIdx] = min(offsetDist); refDist = tempDist(refIdx,:);
    [sortedOffset,sortIdx] = sort(refDist,'ascend');
    for k = 1:nSession
        temp = ishere(sortIdx(1:k),:);
        ishereSession2{k} = all(temp,1);
        sessionCount2(k) = sum(ishereSession2{k});
        sessionSel2{k} = sortIdx(1:k);
        % add day number on the original matrix 
    end 
end 

