load('TCA-nonneg_zz153_159PPC_spkNorm_cluster1.mat');
load('outDffMat_PPC_zz153_spkNorm.mat','outDffMat','clusterLabel');
outDffMat_153 = outDffMat; neuron153 = size(outDffMat_153,1);
clusterLabel_153 = clusterLabel;

load('outDffMat_PPC_zz159_spkNorm.mat','outDffMat','clusterLabel');
outDffMat_159 = outDffMat; neuron159 = size(outDffMat_159,1);
clusterLabel_159 = clusterLabel;

outDffMat = cat(1,outDffMat_153,outDffMat_159);
nanFlag = isnan(nanmean(nanmean(nanmean(outDffMat,2),3),4));


nModel = 12; selTC = 5;
selComp = M{nModel}.U{1}(:,selTC);

selComp = projectIdxBack(selComp, nanFlag);

[selComp_sort, idx_sort] = sort(selComp,'descend');


[maxVal,bestComp] = max(M{nModel}.U{1},[],2);
figure; 
plot(nansum(outDffMat((bestComp==selTC),:,1,4),1))
%% stim figure
datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);

plotPSTH = dataPPC.trialTypeInfo.dffStim{4}{8}(clusterLabel_153==1,:,:);
plotPSTHL = dataPPC.trialTypeInfo.dffStim{4}{5}(clusterLabel_153==1,:,:);
plotRT = dataPPC.trialTypeInfo.behSelTrialType{4}{8}.RT;
tempRT = nanmean(plotRT);

plotIdx = find(bestComp==3); plotIdx = plotIdx(plotIdx<neuron153);
tempPlotNeuron = 6; timeAxis = ((1:30)-10)/15;

figure;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,:),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{}); hold on;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTHL(plotIdx(tempPlotNeuron),:,:),3),matlabColors(2), matlabColors(2,0.2),...
    {'LineWidth',2},{});
xline(tempRT,'--'); xline(0); xlim([-0.6 1.33])
xlabel('Time from stimulus onset (s)'); ylabel('norm. spk')
legend({'','stim4','','stim3'})

%% late in trial figure
datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);

plotPSTH = dataPPC.trialTypeInfo.dffChoice{2}{4}(clusterLabel_153==1,:,:);
plotPSTHL = dataPPC.trialTypeInfo.dffChoice{2}{1}(clusterLabel_153==1,:,:);
plotRT = dataPPC.trialTypeInfo.behSelTrialType{2}{1}.RT;
tempRT = nanmean(plotRT);

plotIdx = find(bestComp==6); plotIdx = plotIdx(plotIdx<neuron153);
tempPlotNeuron = 3; timeAxis = ((1:30)-11)/15;

figure;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,:),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{}); hold on;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTHL(plotIdx(tempPlotNeuron),:,:),3),matlabColors(2), matlabColors(2,0.2),...
    {'LineWidth',2},{});
xline(2/15,'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from choice threshold reached (s)'); ylabel('norm. spk')
legend({'','stim2','','stim1'}); ylim([0 0.02])
%% choice figure task selective
datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);

plotPSTH = dataPPC.trialTypeInfo.dffStim{5}{8}(clusterLabel_153==1,:,:);
plotPSTH1 = dataPPC.trialTypeInfo.dffStim{2}{4}(clusterLabel_153==1,:,:);
plotWheel = dataPPC.trialTypeInfo.wheelChoice{5}{8};
plotRT = dataPPC.trialTypeInfo.behSelTrialType{5}{8}.RT;
%plotIdx = find(bestComp==9) - neuron153; plotIdx = plotIdx(plotIdx>0);
plotIdx = find(bestComp==5); plotIdx = plotIdx(plotIdx<neuron153);
tempPlotNeuron = 5; timeAxis = ((1:30)-11)/15;

figure;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,:),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{}); hold on;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH1(plotIdx(tempPlotNeuron),:,:),3),matlabColors(2), matlabColors(2,0.2),...
    {'LineWidth',2},{});
xline(nanmean(plotRT),'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from stimulus onset (s)'); ylabel('norm. spk')
legend({'','T2,R','','T1,R'}); ylim([0 0.04])

%% choice figure task inselective
datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);

plotPSTH = dataPPC.trialTypeInfo.dffStim{5}{5}(clusterLabel_153==1,:,:);
plotPSTH1 = dataPPC.trialTypeInfo.dffStim{2}{1}(clusterLabel_153==1,:,:);
plotWheel = dataPPC.trialTypeInfo.wheelChoice{5}{8};
plotRT = dataPPC.trialTypeInfo.behSelTrialType{5}{5}.RT;
%plotIdx = find(bestComp==9) - neuron153; plotIdx = plotIdx(plotIdx>0);
plotIdx = find(bestComp==3); plotIdx = plotIdx(plotIdx<neuron153);
tempPlotNeuron = 5; timeAxis = ((1:30)-11)/15;

figure;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,:),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{}); hold on;
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH1(plotIdx(tempPlotNeuron),:,:),3),matlabColors(2), matlabColors(2,0.2),...
    {'LineWidth',2},{});
xline(nanmean(plotRT),'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from stimulus onset (s)'); ylabel('norm. spk')
%legend({'','T2,R','','T1,R'}); 
ylim([0 0.02])

%% choice figure
datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);

plotPSTH = dataPPC.trialTypeInfo.dffChoice{4}{8}(clusterLabel_153==1,:,:);
plotWheel = dataPPC.trialTypeInfo.wheelChoice{4}{8};
plotRT = dataPPC.trialTypeInfo.behSelTrialType{4}{8}.RT;
%plotIdx = find(bestComp==9) - neuron153; plotIdx = plotIdx(plotIdx>0);
plotIdx = find(bestComp==5); plotIdx = plotIdx(plotIdx<neuron153);
 
%figure; imagesc(squeeze(plotPSTH(plotIdx,:,:))')
tempPSTH_pop = squeeze(nanmean(plotPSTH(plotIdx,:,:),1));

figure; imagesc(tempPSTH_pop')


a =  [zeros(1,size(plotWheel,2)); diff(plotWheel,1)];
temp = a<-7; b = []; 
for i = 1:size(temp,2)
    try
        b(i) = find(temp(:,i),1,'first');
    catch
        b(i) = 0;
    end 
end 


timeAxis = ((1:30)-11)/15;

% use neuron 9 and neuron 18 for detailed evoked response

tempPlotNeuron = 8;

figure;
plotPSTH_stim = dataPPC.trialTypeInfo.dffStim{4}{8}(clusterLabel_153==1,:,:);
plotPSTH_stimPlot = squeeze(plotPSTH_stim(plotIdx(tempPlotNeuron),:,:));
plotWheel_stim = dataPPC.trialTypeInfo.wheelStim{4}{8};

firstMove = [];
for i = 1:size(plotWheel_stim,2)
    try
        firstMove(i) = find(plotWheel_stim(10:end,i)<-15,1,'first')+9;
    catch
        firstMove(i) = round(plotRT(i)*15)+10;
    end 
end 

[sort_RT,sort_Idx] = sort(firstMove,'ascend');

imagesc(smoothdata(plotPSTH_stimPlot(:,sort_Idx),2,'movmean',5)'); colormap(flipud(gray)); hold on;
plot(firstMove(sort_Idx),1:165,'Color','r','LineWidth',2)
xline(10,'LineWidth',2);
ylabel('Trials');xticks([-2.5 10 17.5 25]); xticklabels({'-0.5','0','0.5','1'})
xlabel('Time from Tone onset');






figure; 
%subplot(3,1,1);
%imagesc(squeeze(plotPSTH(plotIdx(tempPlotNeuron),:,tempSelTrial))')
%ylabel('Trials');xticks([-3.5 11 18.5 26]); xticklabels({'-0.5','0','0.5','1'})

subplot(3,1,1);
tempSelTrial =  b'>=8 & plotRT<0.27; 
disp(sum(tempSelTrial))
tempRT = nanmean(plotRT(tempSelTrial));
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,tempSelTrial),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{});
xline(-tempRT,'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from Choice threshold reached'); ylabel('norm. spk')

subplot(3,1,2);
tempSelTrial =  b'>=8 & plotRT>0.27 & plotRT<0.42; 
disp(sum(tempSelTrial))
tempRT = nanmean(plotRT(tempSelTrial));
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,tempSelTrial),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{});
xline(-tempRT,'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from Choice threshold reached'); ylabel('norm. spk')

subplot(3,1,3);
tempSelTrial =  b'>=8 & plotRT>0.42; 
disp(sum(tempSelTrial))
tempRT = nanmean(plotRT(tempSelTrial));
fn_plotMeanErrorbar(timeAxis,nanmean(plotPSTH(plotIdx(tempPlotNeuron),:,tempSelTrial),3),matlabColors(1), matlabColors(1,0.2),...
    {'LineWidth',2},{});
xline(-tempRT,'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from Choice threshold reached'); ylabel('norm. spk')
%%
subplot(3,1,3);
fn_plotMeanErrorbar(timeAxis,(-nanmean(plotWheel(:,tempSelTrial),2) + nanmean(plotWheel(7,tempSelTrial),2))',...
    matlabColors(1), matlabColors(1,0.2),{'LineWidth',2},{});
xline(-tempRT,'--'); xline(0); xlim([-0.66 1.26])
xlabel('Time from Choice threshold reached'); ylabel('Degree of wheel movement')
%% functions


function idx_x = projectIdxBack(idx_y, nanFlag)
% Projects a processed index vector back to its original size, reinserting NaNs.
%
% This function is used when data has been cleaned by removing NaNs, processed,
% and the results (e.g., cluster indices) need to be mapped back to the
% original data structure, preserving the locations of the original NaNs.
%
% INPUTS:
%   idx_y       - A vector of size Y (e.g., [1, 1, 2, 3, 2,...]). This is the
%                 index vector from the NaN-removed, processed data.
%
%   nanFlag     - A logical vector of size X (the original data size). It must
%                 be TRUE at indices where the original data had a NaN, and
%                 FALSE otherwise. (e.g., from `isnan(originalData)`).
%
% OUTPUT:
%   idx_x       - A vector of size X, where the values from idx_y have been
%                 placed into the non-NaN locations, and NaN values have been
%                 inserted into the locations specified by nanFlag.
%
% EXAMPLE USAGE:
%   originalData = [10, 20, NaN, 40, NaN, 60];
%   nanFlag = isnan(originalData);      % [false, false, true, false, true, false]
%   processedData = originalData(~nanFlag); % [10, 20, 40, 60]
%   % Imagine some processing gives us an index for the valid data:
%   processedIdx = [1, 1, 2, 1];
%   fullIdx = projectIdxBack(processedIdx, nanFlag);
%   % fullIdx will be: [1, 1, NaN, 2, NaN, 1]

% --- Input Validation ---
num_valid_points = sum(~nanFlag);
if numel(idx_y) ~= num_valid_points
    error('The number of elements in idx_y (%d) must match the number of non-NaN points in nanFlag (%d).', numel(idx_y), num_valid_points);
end

% --- Core Logic ---

% 1. Initialize the output vector 'idx_x' to be the full original size (size X).
%    Pre-filling with NaNs is the most direct way to handle the requirement.
idx_x = nan(size(nanFlag));

% 2. Use logical indexing to place the processed indices.
%    The logical flag '~nanFlag' gives us the exact indices in 'idx_x'
%    where the valid data originally was. We place the 'idx_y' values
%    directly into these slots.
idx_x(~nanFlag) = idx_y;

end
