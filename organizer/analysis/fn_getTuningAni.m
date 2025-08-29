function [TCout, peakAct,baseAct, peakIndex, peakStd] = fn_getTuningAni(TC,funcParam)

if ~exist("funcParam"); funcParam = 'tuningParamMesoPT'; end 
plotFlag = false;

nNeuron = size(TC,2);
nFrame = size(TC,1);
eval(funcParam);

nTrials = nFrame/ nFramesPerTrial;
%---------SHIFT THE TC FOR PRETONE PERIOD-----------
TC = zscore(TC,1); % keep a copy of original TC
TC = circshift(TC,1-toneOnset,1); % shift 1 on 1st axix so that tone is on frame 1 instead of 0
%---------GAUSSIAN FILTER TO SMOOTH THE TRACES-----------
TC = smoothdata(TC,1,'movmean',smoothWindow);
TCpretone = circshift(TC,pretoneFrames,1);
%---------COMPUTE DFF-----------
%baseline = prctile(TC,50,1);
%baseline = mean(TC,1);
%TC = TC ./ repmat(baseline,[size(TC,1) 1]);
%TCpretone = TCpretone ./ repmat(baseline,[size(TC,1) 1]);

%---------RESHAPE TC AND PRETONE-----------
TC=reshape(TC,nFramesPerTone,nTones,nTrials,nNeuron); 
TCpretone = reshape(TCpretone,nFramesPerTone,nTones,nTrials,nNeuron);
%---------REORDER TC TO ALIGN WITH TONE FREQUENCY ORDER-----------
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

[maxValue,peakIndex] = max(toneMean(pretoneFrames+1:pretoneFrames+ceil(frameRate*0.66),:),[],1);

if plotFlag
    %---------PLOT ALL TONE EVOKED-----------
    frameAxis = pretoneFrames:20:nFramesPerTone;
    frameLabel = cellfun(@num2str,num2cell(frameAxis-pretoneFrames),'UniformOutput',false);
    psthFig = figure;
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.15, 0.04, 0.85, 0.96]);% Enlarge figure to full screen.
    for i = 1:nTones
        subplot(3,6,i)
        imagesc(squeeze(trialMean(:,i,:))');
        caxis([prctile(trialMean(:),5) prctile(trialMean(:),95)])
        title([toneLabel{toneindex(i)} 'HZ'])
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
end 
peakFrames = peakIndex;
peakAct = [];baseAct = [];  peakStd = []; 

for i = 1:nNeuron
    peakAct(:,i) = nanmean(squeeze(TCpretone_reorder(pretoneFrames+peakFrames(i),:,:,i)),2);
    baseAct(:,i) = nanmean(squeeze(nanmean(TCpretone_reorder(1:pretoneFrames-3,:,:,i),1)),2);

    tempPeak =squeeze(TCpretone_reorder(pretoneFrames+peakFrames(i),:,:,i));
    tempBase = squeeze(nanmean(TCpretone_reorder(1:pretoneFrames-3,:,:,i),1));
    peakStd(:,i) = std(tempPeak-tempBase,0,2); 
end 


TCout = squeeze(nanmean(TCpretone_reorder,3));
peakAct = peakAct-baseAct;
end 