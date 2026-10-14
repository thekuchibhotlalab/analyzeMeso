function testGetTuning(TC)

%---------DECLARE SOME PARAMETERS-----------
nPlanes = 1;
savePath = 'C:\Users\zzhu34\Documents\tempdata\ab01\FM_14x\suite2p\plane0\tuning';
sep = '\';
sumTC = sum(TC(1:end-1,:),1); TC(:,sumTC==0) = 5000 + randi(100,size(TC,1),sum(sumTC==0));
nNeuron = size(TC,2);

nTones = 17;
nTrials = 10;
nFramesPerTone = 50; % 50
nFramesPerTrial = nFramesPerTone * nTones; % 850
startTrial = 1; % the first tone is on frame 0
nFrames = nFramesPerTrial*nTrials; % 4250
frameRate = 15.63; % in the future, do not hard code this.
pretoneFrames = 10;
baselineFrames = 5;

smoothWindow = 5;

saveSingleNeuronFlag = true;
toneOnset = 10;

%---------SHIFT THE TC FOR PRETONE PERIOD-----------
TC_original = TC; % keep a copy of original TC
TC = circshift(TC,1-toneOnset,1); % shift 1 on 1st axix so that tone is on frame 1 instead of 0
%---------GAUSSIAN FILTER TO SMOOTH THE TRACES-----------
TC = smoothdata(TC,1,'gaussian',smoothWindow);
TCpretone = circshift(TC,pretoneFrames,1);
%---------COMPUTE DFF-----------
%baseline = prctile(TC,50,1);
baseline = mean(TC,1);
TC = TC ./ repmat(baseline,[size(TC,1) 1]);
TCpretone = TCpretone ./ repmat(baseline,[size(TC,1) 1]);
%---------RESHAPE TC AND PRETONE-----------
TC=reshape(TC,nFramesPerTone,nTones,nTrials,nNeuron); 
TCpretone = reshape(TCpretone,nFramesPerTone,nTones,nTrials,nNeuron);
%---------REORDER TC TO ALIGN WITH TONE FREQUENCY ORDER-----------
toneorder = [45254.834 8000 13454.34264 4756.82846 5656.854249,...
    22627.417 64000 53817.37058 4000 9513.65692,...
    16000 6727.171322 19027.31384 26908.6852 32000,...
    11313.7085 38054.62768];
toneindex = [9;4;5;12;2;10;16;3;11;13;6;14;15;17;1;8;7];
TC_reorder=zeros(size(TC));
TCpretone_reorder = zeros(size(TCpretone));
for x=1:nTones
    index=toneindex(x);%+1; %the "+1" is because the first 20 frames are 38 kHz that wraps around
    TC_reorder(:,x,:,:)=TC(:,index,:,:);
    TCpretone_reorder(:,x,:,:)=TCpretone(:,index,:,:);
end
%---------PLOT ALL TONE EVOKED-----------
trialMean = squeeze(nanmean(TCpretone_reorder,3));
trialMeanTrialTC = reshape(trialMean,[nFramesPerTrial,nNeuron]);
trialSEM = squeeze(nanstd(TCpretone_reorder,0,3)) ./sqrt(nTrials);
trialMedian = squeeze(nanmedian(TCpretone_reorder,3));
trialMedianTrialTC = reshape(trialMedian,[nFramesPerTrial,nNeuron]);
toneMean = squeeze(nanmean(nanmean(TCpretone_reorder,2),3));
%---------PLOT ALL TONE EVOKED-----------
frameAxis = pretoneFrames:20:nFramesPerTone;
frameLabel = cellfun(@num2str,num2cell(frameAxis-pretoneFrames),'UniformOutput',false);
psthFig = figure;
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.15, 0.04, 0.85, 0.96]);% Enlarge figure to full screen.
for i = 1:nTones
    subplot(3,6,i)
    imagesc(squeeze(trialMean(:,i,:))');
    caxis([prctile(trialMean(:),5) prctile(trialMean(:),95)])
    title([num2str(round(toneorder(toneindex(i))),'%d') 'HZ'])
    if i>12
        xlabel('frames')
        frameAxis = pretoneFrames:10:nFramesPerTone;
        frameLabel = cellfun(@num2str,num2cell(frameAxis-pretoneFrames),'UniformOutput',false);
        xticks(frameAxis)
        xticklabels(frameLabel)
    else
        xticklabels([])
    end
    if mod(i,6) == 1
        ylabel('neurons') 
    else
        yticklabels([])
    end
end
subplot(3,6,18)
imagesc(toneMean')
xticks(frameAxis)
xticklabels(frameLabel)
xlabel('frames')
yticklabels([])
caxis([prctile(trialMean(:),5) prctile(trialMean(:),95)])
title('all tone')
saveas(gcf,[ savePath ...
        '/population/populationTonePSTH.png']);

%---------PLOT PEAK FRAME-----------
[maxValue,peakIndex] = max(toneMean(pretoneFrames+1:pretoneFrames+ceil(frameRate*0.66),:),[],1);
%[maxValue,peakIndex] = max(toneMean(pretoneFrames+1:pretoneFrames+1+frameRate,:),[],1);
latFig = figure;
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.15, 0.04, 0.45, 0.56]);% Enlarge figure to full screen.
subplot(2,2,1)
histogram(peakIndex)
xlabel('peak frame')
ylabel('frequency')
title('peak frame of all neurons')
subplot(2,2,2)
scatter(peakIndex,maxValue,15,'filled'); hold on; xlimm = xlim; 
plot(xlimm, [prctile(maxValue,50) prctile(maxValue,50)],'--','Color',[0.8 0.8 0.8]);
xlabel('peak frame')
ylabel('peak amplitude')
title('peak frame & amplitude')
subplot(2,2,3)
[~,sortIndex] = sort(peakIndex);
imagesc(toneMean(:,sortIndex)')
xticks(frameAxis)
xticklabels(frameLabel)
ylabel('roi')
title('average dff of all tones')
caxis([prctile(toneMean(:),5) prctile(toneMean(:),95)])
subplot(2,2,4)
plot(toneMean,'Color',[0.8 0.8 0.8]);hold on;
plot(mean(toneMean,2))
xticks(frameAxis)
xticklabels(frameLabel)
ylabel('dff')
title('population average dff')
xlim([0 nFramesPerTone])
saveas(gcf,[ savePath ...
        '/population/populationTonePeak.png']);

individualPeakFrameFlag = true;
if individualPeakFrameFlag
    peakFrames = peakIndex;
else
    peakFrames = ones(size(peakIndex)) * mode(peakIndex);
end

peakANOVA = nan((nTrials)*nTones,nTones+1,nNeuron);
peakANOVACorr = nan((nTrials)*nTones,nTones+1,nNeuron);
pretoneMean = (nanmean(TCpretone_reorder(1:pretoneFrames,:,:,:)));
TCpretone_reorderCorr = TCpretone_reorder - repmat(pretoneMean, [nFramesPerTone, 1, 1, 1]);
for i = 1:nTones
    for j = 1:nNeuron
        % Although most times we are taking 1 frame, but use nanmean here to allow multiple frames
        peakANOVA(((i-1)*(nTrials)+1):(i*(nTrials)),i,j) = ...
            squeeze(nanmean(TCpretone_reorder(pretoneFrames+peakFrames(j),i,:,j),1));
        peakANOVA(((i-1)*(nTrials)+1):(i*(nTrials)),end,j) = ...
            squeeze(nanmean(TCpretone_reorder(pretoneFrames,i,:,j),1));

        peakANOVACorr(((i-1)*(nTrials)+1):(i*(nTrials)),i,j) = ...
            squeeze(nanmean(TCpretone_reorderCorr(pretoneFrames+peakFrames(j),i,:,j),1));
        peakANOVACorr(((i-1)*(nTrials)+1):(i*(nTrials)),end,j) = ...
            squeeze(nanmean(TCpretone_reorderCorr(pretoneFrames,i,:,j),1));
    end
end

for i = 1:nNeuron
    [~,tempTuningPeak] = max(squeeze(trialMedian(pretoneFrames+peakFrames(i),:,i)));
    tuningPeak(i) = tempTuningPeak;
end
%---------DECLARE ALL MATRICES FOR SIGNIFICANT TESTS-----------
pairedTestTrials = 2:10; % trial 1 does not have pair for baseline
% paired ttest for peak-base>0
ttestToneP = zeros(nTones,nNeuron);
ttestToneH = zeros(nTones,nNeuron);
ttestAlpha = 0.05;
% sign rank test for peak-base>0
signrankToneP = zeros(nTones,nNeuron);
signrankToneH = zeros(nTones,nNeuron);
signrankAlpha = 0.05;
% anova test for any group difference + at least one tone above baseline
anovaPeak = zeros(2,nNeuron);
anovaSignifTone = zeros(nTones,nNeuron);
anovaPeakCorr = zeros(2,nNeuron);
anovaSignifToneCorr = zeros(nTones,nNeuron);
% roc analysis for tone response
nShuffle = 100;
rocAuc = zeros(nTones,nNeuron);
rocTpr = zeros(nTones,nNeuron);
rocAucZscore = zeros(nTones,nNeuron);
%---------RUN SIGNIFICANCE TESTS-----------
for i = 1:nNeuron
    tic;
    peakAct = squeeze(TCpretone_reorder(pretoneFrames+peakFrames(i),:,:,i));
    baseAct = squeeze(TCpretone_reorder(pretoneFrames,:,:,i));
    % Do paired tests
    for j = 1:nTones
        try
            [h,p] = ttest(peakAct(j,pairedTestTrials),baseAct(j,pairedTestTrials),'alpha',ttestAlpha,'tail','right');
            ttestToneP(j,i) = p; 
            ttestToneH(j,i) = h; 
        catch 
            disp(['Error in Cell ' int2str(i) 'Tone ' int2str(j) ' t test']);
            ttestToneP(j,i) = 1; % set p at 1
            ttestToneH(j,i) = 0; % set hypothesis wrong
        end
        try 
            [p,h,stats] = signrank(peakAct(j,pairedTestTrials),baseAct(j,pairedTestTrials),'alpha',signrankAlpha,'tail','right'); 
            signrankToneP(j,i) = p;
            signrankToneH(j,i) = h;
        catch 
            disp(['Error in Cell ' int2str(i) 'Tone ' int2str(j) ' signrank test']);
            signrankToneP(j,i) = 1; % set p at 1
            signrankToneH(j,i) = 0; % set hypothesis wrong
        end
    end
    % Do ANOVA test
    groupNames = cell(1,nTones+1);
    groupNames{end} = 'Baseline';
    for j = 1:nTones
        groupNames{j} = int2str(toneorder(toneindex(j)));
    end
    [p,h,stats] = anova1(peakANOVA(:,:,i),groupNames,'off');
    anovaPeak (1,i) = p;
    try
        [results,~,~,~] = multcompare(stats,'Display','off');
        results = results(results(:,2)==(nTones+1),6);
        anovaSignifTone(:,i) = (results<0.05);
        anovaPeak (2,i) = p<0.05 && sum(results<0.05)>0;

    [p,h,stats] = anova1(peakANOVACorr(:,:,i),groupNames,'off');
    anovaPeakCorr (1,i) = p;

    [results,~,~,~] = multcompare(stats,'Display','off');
    results = results(results(:,2)==(nTones+1),6);
    anovaSignifToneCorr(:,i) = (results<0.05);
    anovaPeakCorr (2,i) = p<0.05 && sum(results<0.05)>0;
    catch
       disp('wtf') 
    end
    
    
    
    
    % Do ROC analysis
    % take only 5 frames before 
    baseAct = squeeze(TCpretone_reorder(pretoneFrames-4:pretoneFrames,:,:,i));
    for j = 1:nTones
        rocAct = [baseAct(:)' peakAct(j,:)];
        rocLabel = [zeros(1,numel(baseAct)) ones(1,nTrials)];
        [tpr, fpr, threshold] = roc(rocLabel, rocAct);
        tempAuc = trapz([0 fpr 1],[0 tpr 1]);
        rocAuc(j,i) = tempAuc;
        tempFpr = find(fpr<0.05);
        rocTpr(j,i) = tpr(tempFpr(end));
        shuffAuc = zeros(1,nShuffle);
        for k = 1:nShuffle
            shuffLabel = rocLabel(randperm(length(rocLabel)));
            [tprShuff, fprShuff, thresholdShuff] = roc(shuffLabel, rocAct);
            shuffAuc(k) = trapz([0 fprShuff 1],[0 tprShuff 1]);
        end
        rocAucZscore(j,i) = (tempAuc - mean(shuffAuc)) / std(shuffAuc);
    end
    toc;
end

%---------SELECT CRITERIA FOR RESPONSIVE CELL-----------
responsiveCellFlag = anovaPeakCorr(2,:);


%---------PLOT SIGNICANT TEST RESULTS ON POPULATION LEVEL-----------
tuningPeakIndexMedian = zeros(1,nNeuron);
tuningPeakIndexMean = zeros(1,nNeuron);
popTuningPeakMedian = zeros(nTones,1);
popTuningPeakMean = zeros(nTones,1);
popTuningMedian = zeros(nTones,nNeuron);
popTuningMean = zeros(nTones,nNeuron);
for i = 1:nNeuron
    if responsiveCellFlag(i)

        [~,tempTuningPeakIndex] = max(squeeze(trialMedian(...
            pretoneFrames+peakFrames(i),:,i)));
        tuningPeakIndexMedian(i) = tempTuningPeakIndex;

        [~,tempTuningPeakIndex] = max(squeeze(trialMean(...
            pretoneFrames+peakFrames(i),:,i)));
        tuningPeakIndexMean(i) = tempTuningPeakIndex;

        popTuningMedian(:,i) = squeeze(trialMedian(pretoneFrames+peakFrames(i),:,i));
        popTuningMean(:,i) = squeeze(trialMean(pretoneFrames+peakFrames(i),:,i));
    else
        tuningPeakIndexMedian(i) = nan;
        tuningPeakIndexMean(i) = nan;
        popTuningMedian(:,i) = nan;
        popTuningMean(:,i) = nan;
    end
end

for i = 1:nTones
    popTuningPeakMedian(i) = sum(tuningPeakIndexMedian==i);
    popTuningPeakMean(i) = sum(tuningPeakIndexMean==i);
end

figure;
subplot(2,2,2)
toneRespCount = sum(anovaSignifToneCorr,2);
freqAxis = log2(sort(toneorder));
plot(freqAxis, toneRespCount,'LineWidth',2);
set(gca, 'XTick', log2([4000 8000 16000 32000 64000]));
set(gca, 'XTickLabel', [4 8 16 32 64]);
xlim([log2(4000) log2(64000)]);
xlabel('Frequency (kHz)');
ylabel('Cell Count')
title('Cell Count by Significance to Each Tone')


subplot(2,2,4)
freqAxis = log2(sort(toneorder));
plot(freqAxis, popTuningPeakMedian,'LineWidth',2); hold on;
plot(freqAxis, popTuningPeakMean,'LineWidth',2); 
set(gca, 'XTick', log2([4000 8000 16000 32000 64000]));
set(gca, 'XTickLabel', [4 8 16 32 64]);
xlim([log2(4000) log2(64000)]);
xlabel('Frequency (kHz)');
ylabel('Cell Count')
title('Cell Count by Peak Tone')
legend('Median','Mean')
% saveas(gcf,[filePath '/' savePath...
%         '/population/peakCount.png']);

subplot(2,2,3)
%errorbar(freqAxis, popTuning, popTuningStd,'LineWidth',2);
plot(freqAxis, nanmean(popTuningMedian,2),'LineWidth',2); hold on;
plot(freqAxis, nanmean(popTuningMean,2),'LineWidth',2);
set(gca, 'XTick', log2([4000 8000 16000 32000 64000]));
set(gca, 'XTickLabel', [4 8 16 32 64]);
xlim([log2(4000) log2(64000)]);
xlabel('Frequency (kHz)');
ylabel('mean F/F0');
legend('Median','Mean')
title('Mean Tuning Activity')

subplot(2,2,1)
percentResp = [sum(responsiveCellFlag), sum(~responsiveCellFlag)] ./ nNeuron;
pie([sum(responsiveCellFlag), sum(~responsiveCellFlag)],{['resp ' int2str(sum(responsiveCellFlag))],...
    ['not resp ' int2str(sum(~responsiveCellFlag))]});
title([int2str(percentResp(1)*100) '% cell Responsive'])
saveas(gcf,[ savePath ...
        '/population/populationTuning.png']);
%saveas(gcf,[ savePath ...
%        '/population/populationTuning.m']);
  
%%

%[~,peakIndex] = max(tuningMedian);
%{
figure;
for i = 1:nPlanes
    %cd([suite2ppath '\plane' num2str(i-1)]);
    data = load([suite2ppath sep 'plane' num2str(i-1) sep 'Fall.mat']); 
    refImg{i} = data.ops.meanImg;
    colormapIndex = round(linspace(1,64,17));
    C = colormap('jet');
    
    %if i==1
    %    rois = roisCoord(1:neuronEachPlane(i));
    %else
    %    rois = roisCoord(neuronEachPlane(i-1)+1:neuronPlane(end)); 
    %end
    
    subplot(2,2,i);           
    imagesc(refImg{i});colormap gray;hold on;
    ylim([0 size(refImg{i},1)]);xlim([0 size(refImg{i},2)]);
    
    subplot(2,2,2+i);             
    imagesc(refImg{i});colormap gray;hold on;
    ylim([0 size(refImg{i},1)]);xlim([0 size(refImg{i},2)]);

    for j = 1:neuronEachPlane(i)
        cellIndex = neuronPlane(i) + j;
        x = roisBound{i}{j}(:,1); %freehand rois have the outlines in x-y coordinates
        y = roisBound{i}{j}(:,2); %matlab matrices are inverted so x values are the 2nd column of mn coordinates, and y is the 1st columna
        if responsiveCellFlag(cellIndex)
            %plot(x,y,'.','color',C(colormapIndex(peakIndex(cellIndex)),:),'MarkerSize',1);
            patch(x,y,C(colormapIndex(tuningPeak(cellIndex)),:),'EdgeColor','none');
        else
            patch(x,y,[0.8 0.8 0.8],'EdgeColor','none');
            %plot(x,y,'.','color',[0.8 0.8 0.8],'MarkerSize',1);
        end
    end
    title(['Plane' int2str(i)])
end

saveas(gcf,[savePath...
        '/population/tuningMap.png']);
%}  
allDataName = {'anovaPeak', 'anovaSignifTone',...
    'anovaPeakCorr','anovaSignifToneCorr',...
    'popTuningMean', 'popTuningMedian',...
    'popTuningPeakMean', 'popTuningPeakMedian','peakFrames',...
    'rocAuc','rocTpr', 'rocAucZscore',...
    'signrankToneH', 'signrankToneP','signrankAlpha',...
    'ttestToneH', 'ttestToneP','ttestAlpha',...
    'tuningPeak','tuningPeakIndexMean', 'tuningPeakIndexMedian',...
    'toneRespCount',...
    'TC_original','TCpretone_reorder','TCpretone_reorderCorr',...
    'trialMean','trialMedian'};
save([savePath '/population/tuning.mat'],allDataName{:});
    
    
%saveas(gcf,[tuningFolderName...
%    '/population/tuningMap.m']);

%toneRespTable = zeros(nTones, 4);
%toneRespTable(:,1) = sort(toneorder);
%toneRespTable(:,2) = sum(neuronRespTable(1:end-1,2,:));
%toneRespTable(:,3) = popTuningMedian;
%toneRespTable(:,4) = popTuningMean;
%save([savePath '/population/toneRespTable.mat'],'toneRespTable');



%% single neuron analysis 
%plotNeuron = nNeuron;
%cellPerPlane = zeros(1,nPlanes);
%     roiName = [ filePath '/' roiFolderName '/' fileName '_roi' int2str(j),suffix,'.zip'];
    %roiName = [ filePath '/' roiFolderName '/' fileName '_roi' int2str(j) '.zip'];
    %roiName = [filePath '/' roiFolderName '/' fileName '_ot_' num2str(whichPlane-1,'%03d') '_rois.zip'];
    %rois = ReadImageJROI(roiName);
    %cellThisPlane = length(rois);
    %startingIndex = sum(cellPerPlane);
    %cellPerPlane(j) = cellThisPlane;
    %data = load([suite2ppath sep 'plane' num2str(j-1) sep 'Fall.mat']); 
    %refImg = data.ops.meanImg;
for i = 1:nNeuron
    tic;

    tuningFig = figure('visible','off');
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.15, 0.04, 0.6, 0.9]);% Enlarge figure to full screen.
    cellIndex = i;
    % REMEMBER TO CHANGE THIS LINE
    %cd([suite2ppath '\plane' num2str(j-1)]);
    %{
    subplot(2,2,1)
    imagesc(refImg{j});colormap gray;hold on;

    %x=roisCoord{i+currentNeuron(j)}.xpix; %freehand rois have the outlines in x-y coordinates
    %y=roisCoord{i+currentNeuron(j)}.ypix; %matlab matrices are inverted so x values are the 2nd column of mn coordinates, and y is the 1st columna
    %plot(x,y,'.','color',[0.8 0.8 0.8],'MarkerSize',3);

    x=roisBound{j}{i}(:,1); %freehand rois have the outlines in x-y coordinates
    y=roisBound{j}{i}(:,2); %matlab matrices are inverted so x values are the 2nd column of mn coordinates, and y is the 1st columna
    patch(x,y,C(colormapIndex(tuningPeak(cellIndex)),:),'EdgeColor','none');
    title(['Cell #' int2str(cellIndex) ' Plane #' int2str(j) ' FoV'])
    %}
    subplot(4,2,2)
    plot(TC_original(:,cellIndex),'LineWidth',0.5);
    xlim([1 size(TC_original,1)]);
    xlabel('Frames')
    ylabel('Fluorescence')
    title('Raw Fluorescence')

    subplot(4,2,4)
    tempSampleRate = 1;
    timeAxis = (0:tempSampleRate:nFramesPerTrial-1) * nPlanes / 30;
    TC_trial = reshape(TC_reorder,[nFramesPerTrial,nTrials,nNeuron]);
    for k = 1:nTrials     
        plot(timeAxis,TC_trial(1:tempSampleRate:nFramesPerTrial,k,cellIndex),'color',[0.9 0.9 0.9],'LineWidth',0.5); hold on
    end

    timeAxis = (0:nFramesPerTrial-1) * nPlanes / 30;
    p1 = plot(timeAxis, trialMedianTrialTC(:,cellIndex),'LineWidth',1.2,'color',[0.0000 0.4470 0.7410]);
    p2 = plot(timeAxis, trialMeanTrialTC(:,cellIndex),'LineWidth',1.2,'color',[0.8500 0.3250 0.0980]);
    yMax = 0.7 * max(trialMedianTrialTC(:,cellIndex)) + 0.3 * max(max(TC_trial(1:tempSampleRate:nFramesPerTrial,:,cellIndex)));
    yMin = 0.7 * min(trialMeanTrialTC(:,cellIndex)) + 0.3 * min(min(TC_trial(1:tempSampleRate:nFramesPerTrial,:,cellIndex)));
    onsetTime = (1:nFramesPerTone:nFramesPerTrial) * nPlanes / 30;
    for k = 1:nTones
        plot([onsetTime(k) onsetTime(k)],[yMin yMax],'LineWidth',0.5,'color',[0.4 0.4 0.4]);
    end
    %legend([p1, p2],'Median','Mean');
    xlim([0 timeAxis(end)])
    ylim([yMin yMax])
    ylabel('F/F0')
    xlabel('Time(s)')
    title('Mean Activity Across Trials')

    subplot(2,2,3)
    [rocMax,rocMaxIdx] = max(rocAuc(:,cellIndex));
    peakAct = squeeze(TCpretone_reorder(pretoneFrames+peakFrames(cellIndex),:,:,cellIndex));
    baseAct = squeeze(TCpretone_reorder(pretoneFrames-4:pretoneFrames,:,:,cellIndex));

    rocAct = [baseAct(:)' peakAct(rocMaxIdx,:)];
    rocLabel = [zeros(1,numel(baseAct)) ones(1,nTrials)];
    [tpr, fpr, threshold] = roc(rocLabel, rocAct);
    h_auc = plot([0 fpr 1],[0 tpr 1],'Color', [0 0 0], 'LineWidth', 1.2);hold on; 
    plot([0 1],[0 1],'Color',[0.8,0.8,0.8],'LineWidth',0.5)
    xlabel('false positive')
    ylabel('true positive')
    xlim([0 1])
    ylim([0 1])
    title(['ROC ' num2str(round(toneorder(toneindex(rocMaxIdx))),'%d') 'HZ'])
    legend(h_auc,['AUC ' num2str(rocMax,'%0.2f')])

    signifTonePoint = anovaSignifToneCorr(:,cellIndex);
    signifTuningMedian = trialMedian(pretoneFrames + ...
        peakFrames(cellIndex),logical(signifTonePoint),cellIndex);
    signifTonePoint = toneorder(toneindex(logical(signifTonePoint)));
    %neuronRespTable(1:end-1,[1 cellIndex+1]);
    %signifTuningMedian = trialMedian(:,cellIndex);
    %signifTuningMedian = signifTuningMedian(signifTonePoint(:,2)==1);
    %signifTonePoint = signifTonePoint(signifTonePoint(:,2)==1,1);
    subplot(2,2,4)
    freqAxis = log2(sort(toneorder));
    magicNum = sqrt(pi/2);
    h_med = errorbar(freqAxis, trialMedian(pretoneFrames + ...
        peakFrames(cellIndex),:,cellIndex),magicNum * trialSEM(...
        pretoneFrames+peakFrames(cellIndex),:,cellIndex),...
        'LineWidth',2,'color',[0.0000 0.4470 0.7410]); hold on;
    h_mean = errorbar(freqAxis, trialMean(pretoneFrames + ...
        peakFrames(cellIndex),:,cellIndex),trialSEM(...
        pretoneFrames+peakFrames(cellIndex),:,cellIndex),...
        'LineWidth',2,'color',[0.8500 0.3250 0.0980]);
    scatter(log2(signifTonePoint),signifTuningMedian,40,[0.2 0.2 0.2],'*');
    set(gca, 'XTick', log2([4000 8000 16000 32000 64000]));
    set(gca, 'XTickLabel', [4 8 16 32 64]);
    xlabel('Frequency (kHz)');
    xlim([log2(4000) log2(64000)]);
    ylabel('F/F0');

    yyaxis right
    h_roc = plot(freqAxis,rocAuc(:,cellIndex),'Color',[0.8 0.8 0.8],'LineWidth',2);
    ylabel('AUC')

    legend([h_med, h_mean, h_roc],'Median','Mean','ROC');
    title('Tuning Curve');

    if responsiveCellFlag(cellIndex)
        ylimit = get(gca,'YLim');
        scatter(freqAxis(2),ylimit(2)*0.9+ylimit(1)*0.1,40,[0 0 0],'*')
    end

    saveas(tuningFig,[savePath ...
        '/singleNeuron/Neuron' num2str(cellIndex,'%03d') '.png']);

    close(tuningFig);
    timeElapsed = toc;

    disp(['Cell #' int2str(cellIndex) ' Plane #1'  ' Time=' num2str(timeElapsed,'%03f') ' secs'])

end



end