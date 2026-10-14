clear;
F = readNPY('F.npy');
cellFlag = readNPY('iscell.npy');
F = F(logical(cellFlag(:,1)),:);
F = F((sum(F==0,2)~=size(F,2)),:);
%%
frames = [17000 42000 8000 40500]/2;
cumFrames = [0 cumsum(frames)];
for i = 1:length(frames)
    fileF{i} = F(:,cumFrames(i)+1:cumFrames(i+1));
end
fileF = cellfun(@calculateDff,fileF,'UniformOutput',false);

%% get puretone tuning
tuningData = fileF{1};
tuningData(sum(isnan(tuningData),2)==size(tuningData,2),:) = [];
tuningData(:,1) = 1;
testGetTuning(tuningData');

%% pure tone decoding 
load('C:\Users\zzhu34\Documents\tempdata\ab01\FM_14x\suite2p\plane0\tuning\population\tuning.mat','TCpretone_reorder');

temp9 = squeeze(TCpretone_reorder(:,1,:,:)); temp16 = squeeze(TCpretone_reorder(:,9,:,:));
popAccPT = []; popWPT = [];
tic;
for j = 1:size(temp9,1)
    temp1 = squeeze(temp9(j,:,:)); temp2 = squeeze(temp16(j,:,:));
    decoder = fn_runDecoder(temp1,temp2, 0.8);
    popAccPT(i,j) = mean(decoder.popAcc(:,2));
    popWPT(i,j,:) = mean(decoder.popW(:,2));
end
toc;
%% get short sweep tuning
shortFMdata = fileF{3}; 
shortFMdata(:,1) = 1;
shortFMdata = smoothdata(zscore(shortFMdata,0,2),2,'gaussian',5);
shortFMdata = reshape(shortFMdata, size(shortFMdata,1),50,8,10);
shortUp = shortFMdata(:,:,[5 7 1 3],:); shortDown = shortFMdata(:,:,[2 4 8 6],:);

% plot avg response over tones
tempUp = nanmean(nanmean(shortUp,3),4); tempDown = nanmean(nanmean(shortDown,3),4);
figure; subplot(2,1,1);imagesc(tempUp);caxis([-0.2 0.5])
subplot(2,1,2);imagesc(tempDown);caxis([-0.2 0.5])


figure; plot(nanmean(tempUp,1));
hold on;plot(nanmean(tempDown,1));
figure; subplot(2,1,1);imagesc(tempUp-tempDown);caxis([-0.2 0.5])
subplot(2,1,2);plot(nanmean(tempUp-tempDown,1));
%% compute selectivity to sweep at different modulation rate
avgAct = (tempUp + tempDown)/2; [act,peakFrame] = max(avgAct(:,11:20),[],2); peakFrame = peakFrame + 10;
[~, neuronSortIdx] = sort(act,'descend');
act = {};
act{1,1} = squeeze(shortFMdata(:,:,5,:)); act{2,1} = squeeze(shortFMdata(:,:,7,:));
act{3,1} = squeeze(shortFMdata(:,:,1,:)); act{4,1} = squeeze(shortFMdata(:,:,3,:));
act{1,2} = squeeze(shortFMdata(:,:,2,:)); act{2,2} = squeeze(shortFMdata(:,:,4,:));
act{3,2} = squeeze(shortFMdata(:,:,8,:)); act{4,2} = squeeze(shortFMdata(:,:,6,:));
act = cellfun(@(x)(x(neuronSortIdx,:,:,:)),act,'UniformOutput',false);
act = cellfun(@(x)(x-repmat(mean(x(:,1:10,:),2),[1 size(x,2) 1])),act,'UniformOutput',false);
meanAct = cellfun(@(x)squeeze(mean(x,3)),act,'UniformOutput',false);
stdAct = cellfun(@(x)squeeze(std(x,0,3)),act,'UniformOutput',false);
semAct = cellfun(@(x)squeeze(std(x,0,3)/sqrt(size(x,3))),act,'UniformOutput',false);

peakMeanAct = cellfun(@(x)getPeakAct(x,peakFrame),meanAct,'UniformOutput',false);
peakStdAct = cellfun(@(x)getPeakAct(x,peakFrame),stdAct,'UniformOutput',false);
peakSEMAct = cellfun(@(x)getPeakAct(x,peakFrame),semAct,'UniformOutput',false);
%%
nTopNeuron = 100;
dprimeDir = zeros(nTopNeuron,4);
for j = 1:4
    dprimeDir(:,j) = (peakMeanAct{j,1}(1:nTopNeuron) - peakMeanAct{j,2}(1:nTopNeuron)) * 2 ./...
        (peakStdAct{j,1}(1:nTopNeuron) + peakStdAct{j,2}(1:nTopNeuron));
end   
dprime = abs(dprimeDir);

meanDprime = mean(dprime,2); [temp,tempIdx] = sort(meanDprime,'descend');
%[basis, varExp, proj, covMat] = fn_pca(dprimeDir(tempIdx(1:50),:)');
tempAct = fn_cell2mat(peakMeanAct(:),2);
actCorr = corr(tempAct);


%figure; scatter(proj(1,:),proj(2,:));
figure; for i = 1:4; subplot(2,2,i); histogram(dprime(:,i),0:1/4:2.5); end
figure; for i = 1:4; subplot(2,2,i); histogram(peakMeanAct{i,1},-0.5:0.1:1.5); title(['Resp to up' int2str(i)]);end
figure; for i = 1:4; subplot(2,2,i); histogram(peakMeanAct{i,2},-0.5:0.1:1.5); title(['Resp to down' int2str(i)]);end
figure; imagesc(actCorr); colorbar; caxis([-0.2, 0.6])
%%
for i = 1:nTopNeuron
    figure;subplot(2,1,1);
    errorbar([peakMeanAct{1,1}(i) peakMeanAct{2,1}(i) peakMeanAct{3,1}(i) peakMeanAct{4,1}(i)],...)
    [peakSEMAct{1,1}(i) peakSEMAct{2,1}(i) peakSEMAct{3,1}(i) peakSEMAct{4,1}(i)],'LineWidth',3); hold on; 
    errorbar([peakMeanAct{1,2}(i) peakMeanAct{2,2}(i) peakMeanAct{3,2}(i) peakMeanAct{4,2}(i)],...)
    [peakSEMAct{1,2}(i) peakSEMAct{2,2}(i) peakSEMAct{3,2}(i) peakSEMAct{4,2}(i)],'LineWidth',3);
    ylabel('mean zscore')
    
    subplot(2,1,2); plot(dprime(i,:),'LineWidth',3); ylim([0 max(dprime(i,:))]);
    xlabel('Sweep'); ylabel('d-prime')
    saveas(gcf, ['C:\Users\zzhu34\Documents\tempdata\ab01\FM_14x\suite2p\plane0\sweepShortTuning\cell' int2str(i) '.png']);
    close gcf;
end


%%
popAcc = zeros(4,size(shortUp,2));
popW = zeros(4,size(shortUp,2),size(shortUp,1));
for i = 1:4
    tic;
    for j = 1:size(shortUp,2)
        tempUp = squeeze(shortUp(:,j,i,:)); tempDown = squeeze(shortDown(:,j,i,:));
        decoder = fn_runDecoder(tempUp',tempDown', 0.8);
        popAcc(i,j) = mean(decoder.popAcc(:,2));
        popW(i,j,:) = mean(decoder.popW(:,2));
    end
    toc;
end

%% ROC between up and down
selectROCFrame = 14:47;
tic;
rocAuc =[];rocAucZscore = [];
for j  = 1:size(trialUp,1)
    tempUp = squeeze(mean(trialUp(j,selectROCFrame,:),2));
    tempDown = squeeze(mean(trialDown(j,selectROCFrame,:),2));
    [tempAUC,tempAUCZ] = fn_roc(tempUp,tempDown);
    rocAuc(j) = tempAUC;
    rocAucZscore(j) = tempAUCZ;
end

toc;
%% ROC for up-responsive and down-responsive
baselineFrame = 1:10;
toneFrame = 14:47;
for j  = 1:size(trialUp,1)
    tempTone = squeeze(mean(trialUp(j,toneFrame,:),2));
    tempBase = squeeze(mean(trialUp(j,baselineFrame,:),2));
    [tempAUC,tempAUCZ] = fn_roc(tempBase,tempTone);
    rocAucUp(j) = tempAUC;
    rocAucZscoreUp(j) = tempAUCZ;
end

for j  = 1:size(trialDown,1)
    tempTone = squeeze(mean(trialDown(j,toneFrame,:),2));
    tempBase = squeeze(mean(trialDown(j,baselineFrame,:),2));
    [tempAUC,tempAUCZ] = fn_roc(tempBase,tempTone);
    rocAucDown(j) = tempAUC;
    rocAucZscoreDown(j) = tempAUCZ;
end


%% get decoder weight
selectDecoderFrame = 1:75;
cellWLong = []; cellAccLong = [];popWLong = [];popAccLong = [];

for i = 1:length(selectDecoderFrame)
    tic;
    decoder = fn_runDecoder(squeeze(trialUp(:,selectDecoderFrame(i),:))',...
        squeeze(trialDown(:,selectDecoderFrame(i),:))', 0.8);
    
    cellWLong(:,i) = mean(decoder.cellW,2);
    cellAccLong(:,i) = mean(decoder.cellAcc(:,:,2),2);
    popWLong(:,i) = mean(decoder.popW,2);
    popAccLong(i) = mean(decoder.popAcc(:,2));
    toc;

end

%% plot best neurons
timeAxis = (-9:size(trialUp,2)-10)/15.63;
meanAcc = mean(cellAccLong(:,11:31),2);
[~,topNeuron] = sort(meanAcc,'descend');
toneFrames = 14:49;
for i = 1:2
    tempUp = squeeze(trialUp(topNeuron(i),:,:)); tempDown = squeeze(trialDown(topNeuron(i),:,:));
    figure; hold on; plot(timeAxis,mean(tempUp,2),'Color',matlabColors(1),'LineWidth',2)
    fn_plotFillErrorbar(timeAxis,(nanmean(tempUp,2))',...
        (nanstd(tempUp,0,2)./sqrt(size(tempUp,2)))',...
        matlabColors(1),'faceAlpha',0.2,'LineStyle','none');
    plot(timeAxis,mean(tempDown,2),'Color',matlabColors(2),'LineWidth',2)
    fn_plotFillErrorbar(timeAxis,(nanmean(tempDown,2))',...
        (nanstd(tempDown,0,2)./sqrt(size(tempDown,2)))',...
        matlabColors(2),'faceAlpha',0.2,'LineStyle','none');
    ylimm = ylim;
    plot([0 0],ylimm,'Color',[0.8 0.8 0.8],'LineWidth',2)
    plot([2.5 2.5],ylimm,'Color',[0.8 0.8 0.8],'LineWidth',2)
    xlim([timeAxis(1) timeAxis(end)]); xlabel('Time(s)'); ylim(ylimm);ylabel('Dff')
    
    trialUp40 = (squeeze(FMdata(:,:,9,:))); %40 oct/s
    trialDown40 = (squeeze(FMdata(:,:,23,:)));
    tempUp40 = mean(squeeze(trialUp40(topNeuron(i),toneFrames,:)),1);
    tempDown40 = mean(squeeze(trialDown40(topNeuron(i),toneFrames,:)),1);

    trialUp10 = (squeeze(FMdata(:,:,16,:))); % 10 oct/3 
    trialDown10 = (squeeze(FMdata(:,:,2,:)));
    tempUp10 = mean(squeeze(trialUp10(topNeuron(i),toneFrames,:)),1);
    tempDown10 = mean(squeeze(trialDown10(topNeuron(i),toneFrames,:)),1);
    
    tempUp20 = mean(tempUp(toneFrames,:),1); tempDown20 = mean(tempDown(toneFrames,:),1);
    
    figure; hold on
    errorbar([mean(tempUp10) mean(tempUp20) mean(tempUp40)],...
        [fn_sem(tempUp10) fn_sem(tempUp20) fn_sem(tempUp40)],'LineWidth',2)
    errorbar([mean(tempDown10) mean(tempDown20) mean(tempDown40)],...
        [fn_sem(tempDown10) fn_sem(tempDown20) fn_sem(tempDown40)], 'LineWidth',2)
    xticks([1 2 3]); xlim([0.5 3.5])
    xticklabels({'10 oct/s','20 oct/s','40 oct/s'}); xlabel('Modulation Rate')
    ylabel('Dff'); 
end




%% select neurons to do decoding
selectDecoderFrame = 1:75;
toneFrames = 14:49;
selectNeuron = topNeuron([1 3 4 6 9 11 14 15 16 17 19 21 22 23 24 27 28 31 32 33]);
totalAcc = [];
%selectNeuron = 355;
tic;

for j = 1:length(selectNeuron)
    tempSel = selectNeuron(1:j);
    trialUpSel = (squeeze(FMdata(:,:,1,:)));trialUpSel = trialUpSel(tempSel,:,:);
    trialDownSel = (squeeze(FMdata(:,:,15,:)));trialDownSel = trialDownSel(tempSel,:,:);
    cellWLongSel = []; cellAccLongSel = [];popWLongSel = [];popAccLongSel = [];

    for i = 1:length(selectDecoderFrame)
        tempUp = squeeze(trialUpSel(:,selectDecoderFrame(i),:))';
        tempDown = squeeze(trialDownSel(:,selectDecoderFrame(i),:))';
        if size(tempUp,1)==1
            tempUp = tempUp'; tempDown = tempDown';
        end
        decoder = fn_runDecoder(tempUp,tempDown,0.8);

        cellWLongSel(:,i) = mean(decoder.cellW,2);
        cellAccLongSel(:,i) = mean(decoder.cellAcc(:,:,2),2);
        popWLongSel(:,i) = mean(decoder.popW,2);
        popAccLongSel(i) = mean(decoder.popAcc(:,2));


    end

    totalAcc(j) = mean(popAccLongSel(toneFrames));
end

toc;
figure; plot(smoothdata(popAccLongSel,'gaussian',5))

%%

ptROC = load('C:\Users\zzhu34\Documents\tempdata\ab01\FM_14x\suite2p\plane0\tuning\population\tuning.mat',...
    'rocAuc','peakFrames','trialMedian','ttestToneH','signrankToneH','anovaPeak');
rocAucPt = ptROC.rocAuc;
%popTuningMedian = ptROC.popTuningMedian;
ttestToneH = ptROC.ttestToneH;
signrankToneH = ptROC.signrankToneH;
anovaPeak = ptROC.anovaPeak;
peakFrames = ptROC.peakFrames;
trialMedian = ptROC.trialMedian;

for i = 1:length(peakFrames)
   tuningCurve(:,i) = squeeze(trialMedian(10+peakFrames(i),:,i))-1;
end

sweepSelNeuron = (rocAucUp>0.75 | rocAucDown>0.75);
rocBestSweep = max([rocAucUp;rocAucDown],[],1);
rocAucBestPT = max(rocAucPt,[],1);
toneSelNeuron = rocAucBestPT>0.75;
sum(sweepSelNeuron & toneSelNeuron)
figure; scatter(rocBestSweep(sweepSelNeuron), rocAucBestPT(sweepSelNeuron))
xlabel('ROC of Sweep'); ylabel('ROC of Tone')
sum((rocAuc>0.75 | rocAuc<0.25) & toneSelNeuron)

sum((rocAuc>0.75 | rocAuc<0.25) & toneSelNeuron)
upToneSelNeuron = (rocAuc<0.25 & toneSelNeuron);
downToneSelNeuron = (rocAuc>0.75 & toneSelNeuron);

figure; hold on;
tempUp = nanmean(tuningCurve(:,upToneSelNeuron),2);
tempDown = nanmean(tuningCurve(:,downToneSelNeuron),2); 
b =  [tempDown ones(length(tempDown),1)] \ tempUp;
fitDown = [tempDown ones(length(tempDown),1)] * b;
plot(tempUp*4+0.1,'LineWidth',3,'Color',matlabColors(1,0.8)); 
plot(fitDown*4+0.1,'LineWidth',3,'Color',matlabColors(2,0.8)); 
xlabel('Frequency'); ylabel('Normalized Dff'); xlim([1 17])
set(gca, 'XTick', [1 5 9 13 17]);
set(gca, 'XTickLabel', [4 8 16 32 64]);

%%
shortFMdata = fileF{4}; 
shortFMdata(:,1) = 1;
shortFMdata = smoothdata(zscore(shortFMdata,0,2),2,'gaussian',5);
shortFMdata = shortFMdata(:,1:20000);
shortFMdata = reshape(shortFMdata, size(shortFMdata,1),50,8,50);
shortUp = shortFMdata(:,:,[5 7 1 3],:); shortDown = shortFMdata(:,:,[2 4 8 6],:);

%%
toneOnest = 10;
FMdata = fileF{2};
FMdata(:,1) = 1; FMdata = FMdata-1;
FMdataZscore = smoothdata(zscore(FMdata,0,2),2,'gaussian',5);
FMdataZscore = reshape(FMdataZscore, size(FMdata,1),75,28,10);

FMdata = smoothdata(FMdata,2,'gaussian',5);
FMdata = reshape(FMdata, size(FMdata,1),75,28,10);
trialUp = (squeeze(FMdata(:,:,1,:)));
trialDown = (squeeze(FMdata(:,:,15,:)));

%trialUp = (squeeze(FMdata(:,:,9,:))); %40 oct/s
%trialDown = (squeeze(FMdata(:,:,23,:)));

%trialUp = (squeeze(FMdata(:,:,16,:))); % 10 oct/3 
%trialDown = (squeeze(FMdata(:,:,2,:)));

avgFMdata = squeeze(nanmean(FMdataZscore,4));
% analyze the test stimuli first
avgUp = avgFMdata(:,:,1);

[~,tempIdx] = max(avgUp(sweepSelNeuron,11:49),[],2);
[~,neuronSortIdx] = sort(tempIdx,'ascend');

temp = avgUp(sweepSelNeuron,:); temp = temp(neuronSortIdx,:);
figure; subplot(2,1,1);imagesc(temp);caxis([-0.2 1])
xticks([10 25.6 41.2 56.9 72.5]); xticklabels({'0','1','2','3','4'})
yticks([1 size(temp,1)]); xlabel('Time (s)'); ylabel('Neurons')
subplot(2,1,2);plot(nanmean(temp,1));
avgDown = avgFMdata(:,:,15);

[~,tempIdx] = max(avgDown(sweepSelNeuron,11:49),[],2);
[~,neuronSortIdx] = sort(tempIdx,'ascend');

temp2 = avgDown(sweepSelNeuron,:); temp2 = temp2(neuronSortIdx,:);
figure; subplot(2,1,1);imagesc(temp2);caxis([-0.2 1]); colorbar
xticks([10 25.6 41.2 56.9 72.5]); xticklabels({'0','1','2','3','4'})
yticks([1 size(temp,1)]); xlabel('Time (s)'); ylabel('Neurons')
subplot(2,1,2);plot(nanmean(temp2,1));

upSel = rocAuc<0.25;
downSel = rocAuc>0.75;
temp = avgUp(upSel,:) - avgDown(upSel,:);
temp = temp - repmat(mean(temp(:,1:10),2),[1 75]);
figure; imagesc(temp);caxis([-1 1])
xticks([10 25.6 41.2 56.9 72.5]); xticklabels({'0','1','2','3','4'})
yticks([1 size(temp,1)]); xlabel('Time (s)'); ylabel('Neurons')

figure;
plot(timeAxis,nanmean(temp,1),'LineWidth',2,'Color',matlabColors(1)); hold on
timeAxis = (-9:size(trialUp,2)-10)/15.63;
fn_plotFillErrorbar(timeAxis,(nanmean(temp,1)),...
        (nanstd(temp,0,1)./sqrt(size(temp,1))),...
        matlabColors(1),'faceAlpha',0.2,'LineStyle','none');
   
temp = -(avgDown(downSel,:) - avgUp(downSel,:));
temp = temp - repmat(mean(temp(:,1:10),2),[1 75]);
plot(timeAxis,nanmean(temp,1),'LineWidth',2,'Color',matlabColors(2)); hold on
timeAxis = (-9:size(trialUp,2)-10)/15.63;
fn_plotFillErrorbar(timeAxis,(nanmean(temp,1)),...
        (nanstd(temp,0,1)./sqrt(size(temp,1))),...
        matlabColors(2),'faceAlpha',0.2,'LineStyle','none');
ylimm = ylim;
plot([0 0],ylimm,'LineWidth',2,'Color',[0.8 0.8 0.8]); plot([2.5 2.5],ylimm,'LineWidth',2,'Color',[0.8 0.8 0.8]);
xlabel('Time(s)');ylabel('Dff');
xlim([timeAxis(1) timeAxis(end)]); ylim(ylimm);
%%
function F = calculateDff(F)
F = F ./ smoothdata(F,2,'movmean',2000);

end

function newMat = getPeakAct(mat,idx)
    newMat = zeros(size(mat,1),1);
    for i = 1:size(mat,1)
        newMat(i) = mat(i,idx(i));
    end

end
