%% PART 1 -- Load data and create animal object
% Load the saved animal object in the onedrive. This object pools neural and behavioral data 
%     (preprocessed data) together into one object. 
clear;
tic; ani = Animal('zz172_PPC1','actType','spk','tracking',true); 


%% PART 2.3 -- Recreate the behavioral learning curve
% behSel corresponds to all the behavioral sessions. We should be able to recreate the behavioral learning curve
behCombined = vertcat(ani.sessionInfo.behSel{:});
figure; 
[bias,acc] = fn_getAccBiasSmooth(behCombined.stimuli,behCombined.responseType,100);
plot(acc); xlabel('Trial in Training'); ylabel('Accuracy')

%% PART 3 -- Look at neural response by aligning to each trial
% Now we want to align
% To do this, we 'parse' the raw timecourse (TC) into activity of each trial
ani = ani.parseTrial;
%%
ani = ani.parseDay('tracking','minSessionsPerLearningPeriod',8);

%% a different version for zz159
ani = ani.parseDay('trackingMode','unrestrained');

%% get data for zz170 and zz172, no clustering
selTime = 21:55; 
[ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffStim','dffChoice','behSel'},'selTime',selTime,'stim',...
    [1,1,2,2,3,3,4,4],'choice',[1,2,1,2,1,2,1,2]);

[outDff,~,outCounts,matchedRT] = fn_matchRT(ani.trialTypeInfo);
%%
save('outDffMat_zz159_AC_spkNorm_stim_trial.mat','outDff');
%save('ani_zz153_PPC_parsed.mat','ani','-v7.3');


%%

outDff = cellfun(@(x)(nanmean(x,3)), outDff,'UniformOutput',false);
outDffMat= nan(size(outDff{1,1},1),size(outDff{1,1},2),size(outDff,1),size(outDff,2));
for i = 1:size(outDff,1)
    for j = 1:size(outDff,2)
        outDffMat(:,:,i,j) = outDff{i,j};
    end 
end 
save('outDffMat_zz173_PPC_spkNorm_stim.mat',"outDffMat");

%% for zz153 and 159, run clustering for simplicity
selTime = 11:45; 
[ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffStim','dffChoice','behSel'},'selTime',selTime,'stim',...
    [1,1,2,2,3,3,4,4],'choice',[1,2,1,2,1,2,1,2]);

selTrialType = cat(1, trialTypeInfo.dffChoice{:}); 
clustering = fn_runClustering(selTrialType,'projIdx',ani.ops.ishereAll);

%% save data for zz153 and zz159
selTime = 21:55; 
[ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffStim','dffChoice','behSel'},'selTime',selTime,'stim',...
    [1,1,2,2,3,3,4,4],'choice',[1,2,1,2,1,2,1,2]);
[outDff,~,outCounts,matchedRT] = fn_matchRT(ani.trialTypeInfo);

outDff = cellfun(@(x)(nanmean(x,3)), outDff,'UniformOutput',false);
outDffMat= nan(size(outDff{1,1},1),size(outDff{1,1},2),size(outDff,1),size(outDff,2));
for i = 1:size(outDff,1)
    for j = 1:size(outDff,2)
        outDffMat(:,:,i,j) = outDff{i,j};
    end 
end 
outDffMat = outDffMat(clustering.labelTracked~=1,:,:,:);
save('outDffMat_zz159_PPC_spkNorm_stim.mat',"outDffMat");
%%
rep = 20; 
M = {};VEpct = {}; TzProj = {};
for i = 1:rep
    [M{i},VEpct{i},TzProj{i}] = fn_runTCA_nonneg(outDffMat + 1e-6);
end 
%%
[M,VEpct,TzProj] = fn_runTCA_nonneg(outDffMat + 1e-6);

save('TCA-nonneg_zz173_PPC_spkNorm_stim_avg_byStimulusIdentity.mat','M','TzProj','VEpct');
%% PART 4 -- Examples of analysis that I have done
% Here I have some written code to plot individual neuron activity nicely
% see code fn_plotNeuronByPeriod.m and fn_plotNeuronOnePeriod.m
% fn_plotNeuronByPeriod(trialTypeInfo.dffChoice, 100);

%% PART 4.1 -- Examples clustering analysis
% see code multiDay_dimReduction.m
% Method: hierarchical clustering, use silhoutte score to determine best number of clusters
% Goal: cluster over neural dynamics over the whole learning period (from T1 early to interleaved), 
%     and across all trial types (8 trial types)
% Step 1: Find the neurons that we can track over the whole period of learning

% Now, open up ani, you should see a table in 'dayInfo'. These are 33 days selected from all
%     days where we can track a majority of neurons. You should also see ops.ishereAll, which tells 
%     you which neurons are tracked throughout these 33 days 
% Step 2: Gather data aligned to choice, and parse out all trial types (8 trial types). We also cut
%     the time axis here, selecting frame 11-45 (i.e. 20 frames before choice and 15 frames after)
selTime = 11:45;
[ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffChoice', 'behSel'}, 'selTime', selTime);

fn_plotNeuronByPeriod(trialTypeInfo.dffChoice, 100);
% Step 3: Reorganize the data. Now you should see selTrial as size 7*8, with 7 periods in learning 
%    (T1 E/M/L;T2 E/M/L; Int.), and 8 trial types. Note that trialTypeInfo also has the behavioral 
%    data corresponding to the neural data of each period
selTrialType = cat(1, trialTypeInfo.dffChoice{:}); 
% Step 4: run the clustering algorithm on data over all trial types and learning period
% Note that although we have 1242 cells in total, only 644 cells are tracked over all days. The 
%     clustering is performed on 644 cells that are tracked, and by specifying 'projIdx', we project 
%     the clustering labels to all the cells (1242)
clustering = fn_runClustering(selTrialType,'projIdx',ani.ops.ishereAll);
% You can record this analysis in the animal object
ani.analysis.clustering = clustering; 
%% PART 4.2 -- Look at clustering in specific period during learing
% In the clustering above, we see that both clusters show a preference to 'right-side' actions.
% When does this pattern develop? Is the activity different earlier on?
% Now, let's try clustering (over all trial types) but in early learning T1
clustering = fn_runClustering(selTrialType(1,:),'projIdx',ani.ops.ishereAll);
% Try mid-learning learning T1
clustering = fn_runClustering(selTrialType(2,:),'projIdx',ani.ops.ishereAll);
% Also, pay attention to the umap plot. A lot of times the neurons can form more like a spectrum
% rather than distinct clusters. In this case, a clustering analysis can give us some intuition 
% about the neural dynamics but unlikely to provide a fundamental understanding
%% Now find single neurons in specific clusters and check their activity over learning
cluster1 = find(ani.analysis.clustering.labelTracked == 1);
fn_plotNeuronByPeriod(trialTypeInfo.dffChoice, cluster1(6));

%% PART 5 -- Prepare TCA analysis
% In this section, we preapre the data and run TCA
% See fn_runTCA_RT_match.m also TCA_component_plot.m
% Save the trial-averaged data for each learning stage for multiple animal, so we can run
%     TCA by concatenating all animals together. This section saves 'dataTCA' for each animal, 
%     which is then loaded together in the next step to perform TCA
% OPTIONAL: I ran clustering analysis on the neural activities first, picks
%     out the active cluster, then only run TCA on the clustered data
% also see makeExampleNeuronFigureThesisPermission.m

clear;
mouse = {'zz153_PPC','zz159_PPC'}; dataTCA = {};
datapath = 'C:\Users\sli336\OneDrive - Johns Hopkins\Ziyi Zhu_files - mesoAnalysis_Ella\neuralData\';

for i = 1:length(mouse)
    filename = [ datapath mouse{i} '_spk_TC.mat'];
    ani = load(filename,[mouse{i}]);
    ani = ani.(mouse{i});
    ani = ani.parseTrial;
    ani = ani.parseDay('tracking');

    selTime = 11:45;
    [ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffChoice', 'behSel'}, 'selTime', selTime);
    selTrialType = cat(1, trialTypeInfo.dffChoice{:}); 
    clustering{i} = fn_runClustering(selTrialType,'projIdx',ani.ops.ishereAll); 
    [outDff,~,outCounts,matchedRT] = fn_matchRT(ani.trialTypeInfo);
    outDff = cellfun(@(x)(nanmean(x,3)), outDff,'UniformOutput',false);
    outDffMat= nan(size(outDff{1,1},1),size(outDff{1,1},2),size(outDff,1),size(outDff,2));
    
    for k = 1:size(outDff,1)
        for j = 1:size(outDff,2)
            outDffMat(:,:,k,j) = outDff{k,j};
        end 
    end 
    switch mouse{i}
        case 'zz153_PPC'
            outDffMat = outDffMat(clustering{i}.labelTracked==1,:,:,:);

        case 'zz159_PPC'
            outDffMat = outDffMat(clustering{i}.labelTracked~=1,:,:,:);
    end 
    dataTCA{i} = outDffMat;
    nNeuron(i) = size(outDffMat,1);
end
% You can choose to save these results Careful about overwriting
% save([datapath filesep strjoin(mouse,'_') '_dataTCA_choice.mat'],'dataTCA','clustering','nNeuron');

% %% PART 5.1 -- Run TCA analysis
% clear; 
% mouse = {'ani','zz159_PPC'}; 
% datapath = 'C:\Users\sli336\OneDrive - Johns Hopkins\Ziyi Zhu_files - mesoAnalysis_Ella\neuralData\';
% load([datapath filesep strjoin(mouse,'_') '_dataTCA_choice.mat'],'dataTCA','clustering','nNeuron');
% dataTCA = fn_cell2mat(dataTCA,1);
% [M,VEpct,TzProj] = fn_runTCA_nonneg(dataTCA + 1e-6);
% % You can choose to save these results. Careful about overwriting
% % save([datapath filesep strjoin(mouse,'_') '_fitTCA_choice.mat'],'M','VEpct','TzProj');

%% PART 5.1 new -- Run TCA analysis
clear; 
mouse = {'ani','zz159_PPC'}; 
datapath = 'C:\Users\sli336\OneDrive - Johns Hopkins\Ziyi Zhu_files - mesoAnalysis_Ella\neuralData\';

load([datapath filesep strjoin(mouse,'_') '_dataTCA_choice.mat'], ...
    'dataTCA','clustering','nNeuron');

dataTCA = fn_cell2mat(dataTCA,1);

[M,VEpct,TzProj] = fn_runTCA_nonneg(dataTCA + 1e-6);

% Save to a NEW test file, so you do not overwrite Ziyi's existing result
save([datapath filesep strjoin(mouse,'_') '_fitTCA_choice_EllaTest.mat'], ...
    'M','VEpct','TzProj','-v7.3');

%% PART 5.2 -- Load TCA analysis results
clear; 
datapath = 'C:\Users\zzhu34\Documents\GitHub\analyzeMeso\analysis\TCA\sfn2025Plot\';
load([datapath filesep 'TCA-nonneg_zz153_159_172_PPC_spkNorm_stim.mat']);
load([datapath filesep 'outDffMat_zz153_159_172_PPC_spkNorm_stim.mat'],'nNeuron');
%nNeuron(3) = nNeuron(3) + nNeuron(4);
%nNeuron(4) = []; % last two entries were the same animal, but different ROI, combine them
animalLabels = arrayfun(@(x)(['animal ' int2str(x)]),1:length(nNeuron),'UniformOutput',false);
if length(nNeuron) == 3
    animalLabels = {'zz153','zz159','zz172'};
end
if length(nNeuron) == 5
    animalLabels = {'zz151_AC1','zz153','zz159','zz170_AC1','zz170_AC2'};
end
%% PART 5.3 -- plot the TCA components
nModel = 12;
% Plot 1 -- Contribution and correlation of all tensor components (TCs)
% Left: lambda (weight) of each TC. Higher weight means more contribution to neural activity.
% Right: Correlation between all TCs. Chec if any components has unreasonably high correlation, 
%     or high negative correlation with each other. This may signal the model is overfit 
%     (too many components fitted) 
figure; subplot(1,2,1);plot(M{nModel}.lambda); xlabel('nTC'); ylabel('lambda');
subplot(1,2,2); imagesc(corr(M{nModel}.U{1})); colorbar;
title('Correlation matrix of the stimulus weights')
% Plot 2 -- The factors of each components
% Neural Component: weight of each neuron, i.e. how much this temporal
% component contribute to neural activity
% Time: temporal dynamics aligned to choice (or other trial events you choose). 
% Learning phase: Early/mid/late/interleaved. You can find patterns that are increasing, 
%     decreasing, or flat over learning. This tells how each dynamic change over learning. 
% Trial type: s1a1, s2a2, s3a1, and s4a1 respectively. This tells whether each component 
%     is task-specific, task-invariant, or trial-type specific
subtitles = {'neural','time','learning phase','trial type'};
figure;
for i = 1:4
    subplot(1,4,i);
    temp = M{nModel}.U{i}'; 
    imagesc(temp); colorbar; clim([prctile(temp(:),5) prctile(temp(:),95)])
    xlabel(subtitles{i})
    ylabel('nTC')
    if i==2; xline(10); end 
end 
% Plot 3 -- The 'variance explained of each component'
% kind of lick variance explained plot for PCA, but different in the sense that TCs are
%     not orthogonal, but PCs are. so var explained is not necessarily best metric.
% In the future, we also need to find the best way to quantify something
%     like var. exp.
figure; plot(VEpct); xlabel('nTC'); ylabel('Variance explained')
%% PART 5.4 -- visualize each TC component and interpret
% Here are code to visualize individual components
% The first two components plotted here, component 5 and 12, are task-invariant 
%     (L or R selective), and are gained through learning. 
% The last component (number 8), is task-specific and lost throuhg learing
%TCs = [4 8 10 11];
%TCs = [7 2 4];
TCs = [8 11];
figure; tempVar = [0 VEpct];
RTtemp = 0.6; %RTtemp = nanmean(matchedRT(:));

for i = 1:length(TCs)
    nTC = TCs(i);
    subplot(length(TCs),4,1 + 4*(i-1));
    neuralWeight = M{nModel}.U{1}(:,nTC);
    neuralWeight = neuralWeight(:);
    if sum(nNeuron) ~= length(neuralWeight)
        error('sum(nNeuron) (%d) does not match neural factor length (%d).',sum(nNeuron),length(neuralWeight));
    end
    nTopNeuron = max(1,ceil(0.2 * length(neuralWeight)));
    sortedWeight = sort(neuralWeight,'descend');
    topWeightThreshold = sortedWeight(nTopNeuron);
    significantNeuron = neuralWeight >= topWeightThreshold;

    animalStart = [1 cumsum(nNeuron(1:end-1)) + 1];
    animalEnd = cumsum(nNeuron);
    pctSignificant = nan(length(nNeuron),1);
    for animalIdx = 1:length(nNeuron)
        tempIdx = animalStart(animalIdx):animalEnd(animalIdx);
        pctSignificant(animalIdx) = 100 * sum(significantNeuron(tempIdx)) / nNeuron(animalIdx);
    end
    bar(pctSignificant,'FaceColor',[0.45 0.45 0.45],'EdgeColor','none');
    ylim([0 max(25,ceil(max(pctSignificant)/10)*10)]);
    ylabel('% neurons');
    title('Top 20% Neural Weight');
    xticks(1:length(nNeuron)); xticklabels(animalLabels); xtickangle(35);

    subplot(length(TCs),4,2 + 4*(i-1));
    nTime = size(M{nModel}.U{2}(:,nTC),1); timeAxis = ((1:nTime)-10)/15;
    plot(timeAxis,M{nModel}.U{2}(:,nTC),'Linewidth',2,'Color',[0.6 0.6 0.6]); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    ylim([0 0.2])
    xline(RTtemp,'--')

    subplot(length(TCs),4,3 + 4*(i-1));
    plot(M{nModel}.U{3}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',[0.6 0.6 0.6]); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])
    xticks(1:4); xticklabels({'E','M','L','Int'}); title('Learning Phase')


    subplot(length(TCs),4,4 + 4*(i-1));
    trialWeight = M{nModel}.U{4}(:,nTC);
    trialWeight = trialWeight(:);
    if length(trialWeight) ~= 4
        error('Expected four trial-type weights in M{nModel}.U{4}: T1L, T1R, T2L, T2R.');
    end

    if exist('multitaskColors','file')
        taskColors = [multitaskColors('s1a1'); multitaskColors('s3a1')];
    else
        taskColors = [0.20 0.45 0.85; 0.85 0.30 0.25];
    end
    trialX = [1; 1; 2; 2]; % T1, T1, T2, T2
    trialY = [2; 1; 2; 1]; % L, R, L, R
    trialColor = [repmat(taskColors(1,:),2,1); repmat(taskColors(2,:),2,1)];
    maxTrialWeight = max(trialWeight);
    if maxTrialWeight <= 0 || isnan(maxTrialWeight)
        bubbleSize = ones(size(trialWeight)) * 80;
    else
        bubbleSize = 80 + 520 * trialWeight ./ maxTrialWeight;
    end

    scatter(trialX,trialY,bubbleSize,trialColor,'filled', ...
        'MarkerFaceAlpha',0.78,'MarkerEdgeColor',[0.2 0.2 0.2],'LineWidth',1.2);
    hold on
    plot([1.5 1.5],[0.5 2.5],'-','Color',[0.75 0.75 0.75]);
    plot([0.5 2.5],[1.5 1.5],'-','Color',[0.75 0.75 0.75]);
    title('Trial Type');
    xlim([0.5 2.5]); ylim([0.5 2.5]); axis square
    xticks([1 2]); xticklabels({'T1','T2'});
    yticks([1 2]); yticklabels({'R','L'});
    set(gca,'YDir','normal','TickDir','out');

end 
%% PART 5.4B -- reorder the stimulus-averaged tensor by stimulus identity
% The input trial-type order is T1L, T1R, T2L, T2R. Because the physical
% stimuli assigned to these trial types differ between animals, reorder each
% animal's neuron block into the common order U, D, 5.7, 11.3.
datapath = 'C:\Users\zzhu34\Documents\GitHub\analyzeMeso\analysis\TCA\sfn2025Plot';
stimAvgInputFile = fullfile(datapath, ...
    'outDffMat_zz151_zz153_zz159_zz170_AC_spkNorm_stim_avg.mat');
stimAvgInput = load(stimAvgInputFile,'nNeuron','outDffMat');

nNeuron = stimAvgInput.nNeuron(:);
outDffMatOriginal = stimAvgInput.outDffMat;
mouseName = ["zz151"; "zz153"; "zz159"; "zz170"; "zz170"];
areaName = ["zz151_AC1"; "zz153"; "zz159"; "zz170_AC1"; "zz170_AC2"];
trialTypeOrderOriginal = ["T1L","T1R","T2L","T2R"];
stimulusIdentityOrder = ["U","D","5.7","11.3"];

% Each row follows nNeuron/areaName order; columns follow T1L,T1R,T2L,T2R.
stimulusByOriginalTrialType = [ ...
    "D",    "U",    "5.7",  "11.3"; ... % zz151
    "D",    "U",    "11.3", "5.7";  ... % zz153
    "5.7",  "11.3", "D",    "U";    ... % zz159
    "11.3", "5.7",  "U",    "D";    ... % zz170_AC1
    "11.3", "5.7",  "U",    "D"];       % zz170_AC2

if size(outDffMatOriginal,3) ~= 4
    error('Expected four trial types in dimension 3, but found %d.', ...
        size(outDffMatOriginal,3));
end
if numel(nNeuron) ~= size(stimulusByOriginalTrialType,1)
    error('nNeuron has %d areas, but the stimulus map has %d rows.', ...
        numel(nNeuron),size(stimulusByOriginalTrialType,1));
end
if sum(nNeuron) ~= size(outDffMatOriginal,1)
    error('sum(nNeuron) (%d) does not match the tensor neuron dimension (%d).', ...
        sum(nNeuron),size(outDffMatOriginal,1));
end

outDffMat = nan(size(outDffMatOriginal),'like',outDffMatOriginal);
neuronStart = [1; cumsum(nNeuron(1:end-1)) + 1];
neuronEnd = cumsum(nNeuron);
stimulusReorderIdx = nan(numel(nNeuron),4);
for animalIdx = 1:numel(nNeuron)
    [stimulusFound,stimulusReorderIdx(animalIdx,:)] = ismember( ...
        stimulusIdentityOrder,stimulusByOriginalTrialType(animalIdx,:));
    if ~all(stimulusFound) || numel(unique(stimulusReorderIdx(animalIdx,:))) ~= 4
        error('Stimulus identities for %s are missing or duplicated.',areaName(animalIdx));
    end
    neuronIdx = neuronStart(animalIdx):neuronEnd(animalIdx);
    outDffMat(neuronIdx,:,:) = outDffMatOriginal( ...
        neuronIdx,:,stimulusReorderIdx(animalIdx,:));
end

stimAvgOutputFile = fullfile(datapath, ...
    'outDffMat_zz151_zz153_zz159_zz170_AC_spkNorm_stim_avg_byStimulusIdentity.mat');
save(stimAvgOutputFile,'outDffMat','nNeuron','mouseName','areaName', ...
    'trialTypeOrderOriginal','stimulusIdentityOrder', ...
    'stimulusByOriginalTrialType','stimulusReorderIdx');
fprintf('Saved stimulus-identity tensor (%s) to:\n%s\n', ...
    strjoin(stimulusIdentityOrder,', '),stimAvgOutputFile);
%% PART 5.4C -- visualize the 3-D stimulus-period TCA
% This model was fit after averaging over the stimulus period, so its modes
% are neuron x learning stage x trial type (there is no temporal factor).
datapath = 'C:\Users\zzhu34\Documents\GitHub\analyzeMeso\analysis\TCA\sfn2025Plot';
stimAvgTCAFile = fullfile(datapath, ...
    'TCA-nonneg_zz151_zz153_zz159_zz170_AC_spkNorm_stim_avg.mat');
stimAvgDataFile = fullfile(datapath, ...
    'outDffMat_zz151_zz153_zz159_zz170_AC_spkNorm_stim_avg.mat');

stimAvgTCA = load(stimAvgTCAFile,'M','VEpct');
stimAvgData = load(stimAvgDataFile,'nNeuron');
M3D = stimAvgTCA.M;
VEpct3D = stimAvgTCA.VEpct;
nNeuron3D = stimAvgData.nNeuron(:);
animalLabels3D = {'zz151_AC1','zz153','zz159','zz170_AC1','zz170_AC2'};

% Select the model rank and the individual components to display here.
nModel3D = 4;
TCs3D = 1:min(4,nModel3D);
if nModel3D < 1 || nModel3D > numel(M3D)
    error('nModel3D must be between 1 and %d.',numel(M3D));
end
model3D = M3D{nModel3D};
if numel(model3D.U) ~= 3
    error('Expected a 3-D TCA model, but M3D{%d} has %d modes.', ...
        nModel3D,numel(model3D.U));
end
if any(TCs3D < 1) || any(TCs3D > size(model3D.U{1},2))
    error('TCs3D must contain component numbers between 1 and %d.', ...
        size(model3D.U{1},2));
end
if sum(nNeuron3D) ~= size(model3D.U{1},1)
    error('sum(nNeuron3D) (%d) does not match the neural factor length (%d).', ...
        sum(nNeuron3D),size(model3D.U{1},1));
end
if numel(animalLabels3D) ~= numel(nNeuron3D)
    animalLabels3D = arrayfun(@(x)sprintf('animal %d',x), ...
        1:numel(nNeuron3D),'UniformOutput',false);
end

% Plot 1: choose a rank using model fit, component contribution, and neural
% factor correlation. The vertical line marks the model used below.
figure('Name','3-D stimulus-period TCA model selection','Color','w');
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
nexttile;
plot(1:numel(VEpct3D),VEpct3D,'o-','LineWidth',1.5, ...
    'Color',[0.35 0.35 0.35],'MarkerFaceColor',[0.35 0.35 0.35]);
xline(nModel3D,'--','selected','LabelVerticalAlignment','bottom');
xlabel('Model rank'); ylabel('Variance explained (%)');
title('Model fit'); box off

nexttile;
plot(1:numel(model3D.lambda),model3D.lambda,'o-','LineWidth',1.5, ...
    'Color',[0.35 0.35 0.35],'MarkerFaceColor',[0.35 0.35 0.35]);
xlabel('TC'); ylabel('\lambda');
title(sprintf('Rank-%d contribution',nModel3D)); box off

nexttile;
imagesc(corr(model3D.U{1})); axis image
clim([-1 1]); colorbar
xlabel('TC'); ylabel('TC');
title('Neural-factor correlation');

% Plot 2: all factors in the selected 3-D model. Each row is one TC.
factorNames3D = {'Neuron','Learning stage','Trial type'};
figure('Name','3-D stimulus-period TCA factors','Color','w');
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for modeIdx = 1:3
    nexttile;
    factorToPlot = model3D.U{modeIdx}';
    imagesc(factorToPlot); colorbar
    factorClim = prctile(factorToPlot(:),[5 95]);
    if factorClim(2) > factorClim(1)
        clim(factorClim);
    end
    xlabel(factorNames3D{modeIdx}); ylabel('TC');
    title(sprintf('%s factor',factorNames3D{modeIdx}));
    if modeIdx == 2 && size(factorToPlot,2) == 4
        xticks(1:4); xticklabels({'E','M','L','Int'});
    elseif modeIdx == 3 && size(factorToPlot,2) == 4
        xticks(1:4); xticklabels({'T1L','T1R','T2L','T2R'});
    end
end

% Plot 3: selected components. Bubble areas use one common scale so trial-
% type weights can be compared across rows; the other y-axes are also shared.
nAnimals3D = numel(nNeuron3D);
animalStart3D = [1; cumsum(nNeuron3D(1:end-1)) + 1];
animalEnd3D = cumsum(nNeuron3D);
nSelectedTC3D = numel(TCs3D);
pctTopNeuron3D = nan(nAnimals3D,nSelectedTC3D);
learningWeights3D = model3D.U{2}(:,TCs3D);
trialWeights3D = model3D.U{3}(:,TCs3D);

for tcIdx = 1:nSelectedTC3D
    neuralWeight = model3D.U{1}(:,TCs3D(tcIdx));
    nTopNeuron = max(1,ceil(0.2 * numel(neuralWeight)));
    sortedWeight = sort(neuralWeight,'descend');
    significantNeuron = neuralWeight >= sortedWeight(nTopNeuron);
    for animalIdx = 1:nAnimals3D
        animalNeuronIdx = animalStart3D(animalIdx):animalEnd3D(animalIdx);
        pctTopNeuron3D(animalIdx,tcIdx) = ...
            100 * mean(significantNeuron(animalNeuronIdx));
    end
end

pctYMax3D = max(25,ceil(max(pctTopNeuron3D(:))/10)*10);
learningYMax3D = max(learningWeights3D(:));
if ~isfinite(learningYMax3D) || learningYMax3D <= 0
    learningYMax3D = 1;
end
maxTrialWeight3D = max(trialWeights3D(:));
if ~isfinite(maxTrialWeight3D) || maxTrialWeight3D <= 0
    maxTrialWeight3D = 1;
end
if exist('multitaskColors','file')
    taskColors3D = [multitaskColors('s1a1'); multitaskColors('s3a1')];
else
    taskColors3D = [0.20 0.45 0.85; 0.85 0.30 0.25];
end
trialX3D = [1; 1; 2; 2];
trialY3D = [2; 1; 2; 1];
trialColor3D = [repmat(taskColors3D(1,:),2,1); ...
    repmat(taskColors3D(2,:),2,1)];

figure('Name','Selected 3-D stimulus-period TCs','Color','w');
tiledlayout(nSelectedTC3D,3,'TileSpacing','compact','Padding','compact');
for tcIdx = 1:nSelectedTC3D
    nTC = TCs3D(tcIdx);

    nexttile;
    bar(pctTopNeuron3D(:,tcIdx),'FaceColor',[0.45 0.45 0.45], ...
        'EdgeColor','none');
    ylim([0 pctYMax3D]); xlim([0.5 nAnimals3D+0.5]);
    xticks(1:nAnimals3D); xticklabels(animalLabels3D); xtickangle(35);
    ylabel(sprintf('TC %d\n%% neurons',nTC));
    if tcIdx == 1; title('Top 20% neural weight'); end
    box off

    nexttile;
    plot(model3D.U{2}(:,nTC),'o-','MarkerSize',4,'LineWidth',2, ...
        'Color',[0.45 0.45 0.45]);
    yline(0); xlim([0.5 size(model3D.U{2},1)+0.5]);
    ylim([0 1.05*learningYMax3D]);
    if size(model3D.U{2},1) == 4
        xticks(1:4); xticklabels({'E','M','L','Int'});
        xline(3.5,':','Color',[0.65 0.65 0.65]);
    end
    if tcIdx == 1; title('Learning stage'); end
    box off

    nexttile;
    trialWeight = model3D.U{3}(:,nTC);
    if numel(trialWeight) ~= 4
        error('Expected four trial-type weights: T1L, T1R, T2L, T2R.');
    end
    bubbleSize = 80 + 520 * trialWeight(:) ./ maxTrialWeight3D;
    scatter(trialX3D,trialY3D,bubbleSize,trialColor3D,'filled', ...
        'MarkerFaceAlpha',0.78,'MarkerEdgeColor',[0.2 0.2 0.2], ...
        'LineWidth',1.2);
    hold on
    plot([1.5 1.5],[0.5 2.5],'-','Color',[0.75 0.75 0.75]);
    plot([0.5 2.5],[1.5 1.5],'-','Color',[0.75 0.75 0.75]);
    xlim([0.5 2.5]); ylim([0.5 2.5]); axis square
    xticks([1 2]); xticklabels({'T1','T2'});
    yticks([1 2]); yticklabels({'R','L'});
    set(gca,'YDir','normal','TickDir','out');
    if tcIdx == 1; title('Trial type'); end
end

%% part 5.5 -- make single neuron plots
load('outDffMat_zz172_PPC1_spkNorm_stim_trial.mat','outDff')
nComp = 4; 
tempNeuronIdx = nNeuron(1)+nNeuron(2)+1:nNeuron(1)+nNeuron(2)+nNeuron(3);
tempW = M{nModel}.U{1}(tempNeuronIdx,nComp);
[~,idx] = sort(tempW,'descend');
exampleNeuron = idx(5);
for iNeuron = 1:length(exampleNeuron)
    fn_plotOutDffNeuronByStage(outDff,exampleNeuron(iNeuron), ...
        'periodLabels',{'E','M','L','Int'}, ...
        'timeWindow',1:size(outDff{1,1},2), ...
        'eventFrame',10, ...
        'frameRate',15, ...
        'smoothWin',3, ...
        'xLim',[-0.5 1.5]);
end
%% try to find task specific neuron
T1L = nanmean(nanmean(outDff{4,1}(:,18:28,:),2),3);
T2L = nanmean(nanmean(outDff{4,3}(:,18:28,:),2),3);
tempTaskIdx = abs(T1L-T2L)/(T1L+T2L);

T1R = nanmean(nanmean(outDff{4,2}(:,18:28,:),2),3);
T2R = nanmean(nanmean(outDff{4,4}(:,18:28,:),2),3);
tempTaskIdx = (abs(T1L-T2L) + abs(T1R-T2R))./((T1L+T2L)+(T1R+T2R));

[~,idx] = sort(tempTaskIdx,'descend');
exampleNeuron = idx(6);
for iNeuron = 1:length(exampleNeuron)
    fn_plotOutDffNeuronByStage(outDff,exampleNeuron(iNeuron), ...
        'periodLabels',{'E','M','L','Int'}, ...
        'timeWindow',1:size(outDff{1,1},2), ...
        'eventFrame',10, ...
        'frameRate',15, ...
        'smoothWin',1, ...
        'xLim',[-0.5 1.5]);
end
%% try to plot all 7 stages
% for i = 1:size(trialTypeInfo.dffChoice{1}{1},1)
%     fn_plotNeuronByPeriod(trialTypeInfo.dffStim,i,'stimFrame',10,'smoothWin',3)
%     saveas(gcf,['D:\OneDrive - Johns Hopkins University\Lab meeting\mesoProject\data_figure_presentation\multi-task-kk-okinawa\zz153_PPC_stim\neuron'...
%         int2str(i) '.png']);
%     close gcf;
% end 

%selTime = 11:45; 
%[ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffStim','dffChoice','behSel'},'selTime',selTime,'stim',...
%    [1,1,2,2,3,3,4,4],'choice',[1,2,1,2,1,2,1,2]);
%for i = 1:size(trialTypeInfo.dffChoice{1}{1},1)
%
%    fn_plotNeuronByPeriod(trialTypeInfo.dffChoice,i,'stimFrame',20,'smoothWin',3)
%    saveas(gcf,['D:\OneDrive - Johns Hopkins University\Lab meeting\mesoProject\data_figure_presentation\multi-task-kk-okinawa\zz153_PPC_choice\neuron'...
%        int2str(i) '.png']);
%    close gcf;
%end

fn_plotNeuronByPeriod(trialTypeInfo_zz172.dffChoice,67,'stimFrame',20,'smoothWin',3)

fn_plotNeuronByPeriod(trialTypeInfo_zz172.dffChoice,67,'plotMode', 'compareTask','stimFrame',20,'smoothWin',3)
%%

%% Plot PSTH sorted by response latency to peak activity
selTime = 21:55; 
[ani,~,trialTypeInfo] = ani.chunkDaysByTrialType({'dffStim','dffChoice','wheelStim','wheelChoice','behSel'},'selTime',selTime,'stim',...
    [1,1,2,2,3,3,4,4],'choice',[1,2,1,2,1,2,1,2]);

%% 
%tempTrialType = cat(1,nanmean(trialTypeInfo_zz153.dffChoice{3}{4},3),...
%    nanmean(trialTypeInfo_zz172.dffChoice{3}{4},3));
%tempTrialType = cat(1,nanmean(trialTypeInfo.dffStim{2}{4},3));
tempTrialType = cat(1,nanmean(trialTypeInfo_zz153.dffChoice{3}{4},3),...
    nanmean(trialTypeInfo_zz172.dffChoice{3}{4},3));
selPSTH = tempTrialType;
plotPSTH = smoothdata(selPSTH,2,'movmean',2);
peakSearchWindow = 10:40;
minPeakActivity = 1e-3;
peakSearchWindow = peakSearchWindow(peakSearchWindow >= 1 & peakSearchWindow <= size(plotPSTH,2));
peakSearchMat = plotPSTH(:,peakSearchWindow);
peakSearchMat(isnan(peakSearchMat)) = -inf;
[peakValue,peakFrameLocal] = max(peakSearchMat,[],2);
activeNeuron = isfinite(peakValue) & peakValue >= minPeakActivity;
peakFrame = peakSearchWindow(peakFrameLocal);
[peakFramesorted,sortIdxLocal] = sort(peakFrame(activeNeuron),'ascend');
activeIdx = find(activeNeuron);
sortIdx = activeIdx(sortIdxLocal);

fprintf('Sorted PSTH includes %d/%d neurons with peak >= %.1e in frames [%s].\n', ...
    length(sortIdx),size(selPSTH,1),minPeakActivity,num2str(peakSearchWindow));

figure;
tempPlot = plotPSTH(sortIdx,:);tempPlot(103:105,:) = [];
imagesc(tempPlot);
colormap((gray));
caxis([0 0.01]);
xline(20.5,'r');
xlabel('Frame');
ylabel('Neuron sorted by peak latency');
title(sprintf('PSTH sorted by response latency: dffChoice{3}{4} (n=%d)',length(sortIdx)));
colorbar;

%% Plot one example neuron with trial SEM
% exampleMode:
%   'ramp'     - select neurons ramping up before choice.
%   'reward'   - select neurons by post-choice activity minus baseline only.
%   'stimulus' - select neurons by stimulus response in frames 21:23 minus baseline.
%   'taskChoice' - select active T1- or T2-preferring neurons before choice.
%   'taskReward' - select active T1- or T2-preferring neurons after choice.
%   'taskChoiceInv' - select active task-invariant neurons before choice.
%   'taskRewardInv'/'taskRewInv' - select active task-invariant neurons after choice.
exampleMode = 'taskReward';
exampleRank = 13;
stageIdx = 3;            % interleaved stage, where both tasks are present
t1lIdx = 2;
t1rIdx = 4;
task1TrialTypeIdx = [1 4];
task2TrialTypeIdx = [5 8];
taskUnrewTrialTypeIdx = [2 3 6 7];
minTaskActivityPercentile = 50;
taskActivityScalePercentile = 90;
maxTaskInvariantDPrime = 0.25;
eventFrame = 21;
frameRate = 15;
timeAxis = ((1:size(selPSTH,2)) - eventFrame) ./ frameRate;

baselineWindow = 1:8;
rampWindow = 10:20;              % select neurons ramping up before choice
rampStartWindow = 10:12;
preChoiceWindow = 16:19;
postChoiceWindow = 25:35;
stimulusResponseWindow = 22:23;
rampWindow = rampWindow(rampWindow >= 1 & rampWindow <= size(selPSTH,2));
baselineWindow = baselineWindow(baselineWindow >= 1 & baselineWindow <= size(selPSTH,2));
rampStartWindow = rampStartWindow(rampStartWindow >= 1 & rampStartWindow <= size(selPSTH,2));
preChoiceWindow = preChoiceWindow(preChoiceWindow >= 1 & preChoiceWindow <= size(selPSTH,2));
postChoiceWindow = postChoiceWindow(postChoiceWindow >= 1 & postChoiceWindow <= size(selPSTH,2));
stimulusResponseWindow = stimulusResponseWindow(stimulusResponseWindow >= 1 & stimulusResponseWindow <= size(selPSTH,2));

rampTemplate = linspace(0,1,length(rampWindow));
rampCorr = nan(size(plotPSTH,1),1);
for iNeuron = 1:size(plotPSTH,1)
    tempTrace = plotPSTH(iNeuron,rampWindow);
    validFrame = isfinite(tempTrace);
    if sum(validFrame) >= 3
        tempTraceValid = tempTrace(validFrame);
        rampTemplateValid = rampTemplate(validFrame);
        tempTraceValid = tempTraceValid - mean(tempTraceValid);
        rampTemplateValid = rampTemplateValid - mean(rampTemplateValid);
        rampDenom = sqrt(sum(tempTraceValid.^2) * sum(rampTemplateValid.^2));
        if rampDenom > 0
            rampCorr(iNeuron) = sum(tempTraceValid .* rampTemplateValid) ./ rampDenom;
        end
    end
end

baselineActivity = nanmean(plotPSTH(:,baselineWindow),2);
rampStartActivity = nanmean(plotPSTH(:,rampStartWindow),2);
preChoiceActivity = nanmean(plotPSTH(:,preChoiceWindow),2);
postChoiceActivity = nanmean(plotPSTH(:,postChoiceWindow),2);
postChoicePeak = max(plotPSTH(:,postChoiceWindow),[],2);
preChoiceGain = preChoiceActivity - rampStartActivity;
preChoiceResponse = preChoiceActivity - baselineActivity;
postChoiceJump = max(postChoicePeak - preChoiceActivity,0);
rampScore = preChoiceGain .* max(rampCorr,0) + 0.5 .* preChoiceResponse - 0.5 .* postChoiceJump;
rampScore(~activeNeuron | preChoiceGain <= 0 | preChoiceResponse <= 0 | rampCorr <= 0 | ~isfinite(rampScore)) = -inf;
rewardScore = postChoiceActivity - baselineActivity;
rewardScore(~isfinite(rewardScore)) = -inf;

stimPSTH = cat(1,nanmean(trialTypeInfo_zz153.dffStim{stageIdx}{t1rIdx},3),...
   nanmean(trialTypeInfo_zz172.dffStim{stageIdx}{t1rIdx},3));
%stimPSTH = nanmean(trialTypeInfo.dffStim{stageIdx}{t1rIdx},3);

stimulusResponseWindow = stimulusResponseWindow(stimulusResponseWindow <= size(stimPSTH,2));
stimulusBaselineWindow = baselineWindow(baselineWindow <= size(stimPSTH,2));
stimulusActivity = nanmean(stimPSTH(:,stimulusResponseWindow),2);
stimulusBaselineActivity = nanmean(stimPSTH(:,stimulusBaselineWindow),2);
stimulusScore = stimulusActivity - stimulusBaselineActivity;
stimulusScore(~isfinite(stimulusScore)) = -inf;

% Pool all trials within each task, matching the averages shown in the
% plot. Task selectivity is the T1-T2 mean difference divided by pooled
% trial standard deviation (d-prime), rather than a ratio of task means.
[task1ChoiceActivity153,task2ChoiceActivity153,taskChoiceSelectivity153] = ...
    taskVarianceNormalizedDifference(trialTypeInfo_zz153.dffChoice{stageIdx}, ...
    task1TrialTypeIdx,task2TrialTypeIdx,preChoiceWindow);
[task1ChoiceActivity172,task2ChoiceActivity172,taskChoiceSelectivity172] = ...
    taskVarianceNormalizedDifference(trialTypeInfo_zz172.dffChoice{stageIdx}, ...
    task1TrialTypeIdx,task2TrialTypeIdx,preChoiceWindow);
[task1RewardActivity153,task2RewardActivity153,taskRewardSelectivity153] = ...
    taskVarianceNormalizedDifference(trialTypeInfo_zz153.dffChoice{stageIdx}, ...
    task1TrialTypeIdx,task2TrialTypeIdx,postChoiceWindow);
[task1RewardActivity172,task2RewardActivity172,taskRewardSelectivity172] = ...
    taskVarianceNormalizedDifference(trialTypeInfo_zz172.dffChoice{stageIdx}, ...
    task1TrialTypeIdx,task2TrialTypeIdx,postChoiceWindow);

task1ChoiceActivity = cat(1,task1ChoiceActivity153,task1ChoiceActivity172);
task2ChoiceActivity = cat(1,task2ChoiceActivity153,task2ChoiceActivity172);
taskChoiceSelectivity = cat(1,taskChoiceSelectivity153,taskChoiceSelectivity172);
task1RewardActivity = cat(1,task1RewardActivity153,task1RewardActivity172);
task2RewardActivity = cat(1,task2RewardActivity153,task2RewardActivity172);
taskRewardSelectivity = cat(1,taskRewardSelectivity153,taskRewardSelectivity172);

% |d-prime| identifies either T1- or T2-preferring neurons. Multiplying it
% by activity strength favors well-driven neurons, while the percentile
% gate excludes near-silent neurons whose apparent selectivity may be noise.
[taskChoiceScore,taskChoiceSelectivity,taskChoiceActivityStrength,taskChoiceActivityThreshold] = ...
    scoreTaskSelectivity(task1ChoiceActivity,task2ChoiceActivity,taskChoiceSelectivity, ...
    minTaskActivityPercentile,taskActivityScalePercentile);
[taskRewardScore,taskRewardSelectivity,taskRewardActivityStrength,taskRewardActivityThreshold] = ...
    scoreTaskSelectivity(task1RewardActivity,task2RewardActivity,taskRewardSelectivity, ...
    minTaskActivityPercentile,taskActivityScalePercentile);
[taskChoiceInvScore,taskChoiceInvActivityStrength,taskChoiceInvActivityThreshold] = ...
    scoreTaskInvariance(task1ChoiceActivity,task2ChoiceActivity,taskChoiceSelectivity, ...
    minTaskActivityPercentile,maxTaskInvariantDPrime);
[taskRewardInvScore,taskRewardInvActivityStrength,taskRewardInvActivityThreshold] = ...
    scoreTaskInvariance(task1RewardActivity,task2RewardActivity,taskRewardSelectivity, ...
    minTaskActivityPercentile,maxTaskInvariantDPrime);

switch lower(exampleMode)
    case 'ramp'
        selectorScore = rampScore;
        selectorLabel = 'ramping';
    case 'reward'
        selectorScore = rewardScore;
        selectorLabel = 'reward/post-choice';
    case 'stimulus'
        selectorScore = stimulusScore;
        selectorLabel = 'stimulus response';
    case 'taskchoice'
        selectorScore = taskChoiceScore;
        selectorLabel = 'pre-choice task-selective';
    case 'taskreward'
        selectorScore = taskRewardScore;
        selectorLabel = 'post-choice task-selective';
    case 'taskchoiceinv'
        selectorScore = taskChoiceInvScore;
        selectorLabel = 'pre-choice task-invariant';
    case {'taskrewardinv','taskrewinv'}
        selectorScore = taskRewardInvScore;
        selectorLabel = 'post-choice task-invariant';
    otherwise
        error(['Unknown exampleMode: %s. Use ''ramp'', ''reward'', ' ...
            '''stimulus'', ''taskChoice'', ''taskReward'', ''taskChoiceInv'', ' ...
            '''taskRewardInv'', or ''taskRewInv''.'],exampleMode);
end

validSelectorIdx = find(isfinite(selectorScore));
if numel(validSelectorIdx) < exampleRank
    error('TCA_master_2026:NotEnoughExampleNeurons', ...
        'Only %d neurons passed the %s selection criteria; exampleRank is %d.', ...
        numel(validSelectorIdx),selectorLabel,exampleRank);
end
[~,examplePSTHNeuronOrder] = sort(selectorScore(validSelectorIdx),'descend');
examplePSTHNeuron = validSelectorIdx(examplePSTHNeuronOrder(exampleRank));
switch lower(exampleMode)
    case 'ramp'
        selectorMetricText = sprintf('ramp score %.3g, pre-choice gain %.3g', ...
            rampScore(examplePSTHNeuron),preChoiceGain(examplePSTHNeuron));
    case 'reward'
        selectorMetricText = sprintf('reward score %.3g, post-choice %.3g, baseline %.3g', ...
            rewardScore(examplePSTHNeuron),postChoiceActivity(examplePSTHNeuron), ...
            baselineActivity(examplePSTHNeuron));
    case 'stimulus'
        selectorMetricText = sprintf('stimulus score %.3g, stimulus %.3g, baseline %.3g', ...
            stimulusScore(examplePSTHNeuron),stimulusActivity(examplePSTHNeuron), ...
            stimulusBaselineActivity(examplePSTHNeuron));
    case 'taskchoice'
        selectorMetricText = taskMetricText(taskChoiceScore(examplePSTHNeuron), ...
            taskChoiceSelectivity(examplePSTHNeuron), ...
            task1ChoiceActivity(examplePSTHNeuron),task2ChoiceActivity(examplePSTHNeuron), ...
            taskChoiceActivityStrength(examplePSTHNeuron),taskChoiceActivityThreshold);
    case 'taskreward'
        selectorMetricText = taskMetricText(taskRewardScore(examplePSTHNeuron), ...
            taskRewardSelectivity(examplePSTHNeuron), ...
            task1RewardActivity(examplePSTHNeuron),task2RewardActivity(examplePSTHNeuron), ...
            taskRewardActivityStrength(examplePSTHNeuron),taskRewardActivityThreshold);
    case 'taskchoiceinv'
        selectorMetricText = taskInvariantMetricText( ...
            taskChoiceInvScore(examplePSTHNeuron),taskChoiceSelectivity(examplePSTHNeuron), ...
            task1ChoiceActivity(examplePSTHNeuron),task2ChoiceActivity(examplePSTHNeuron), ...
            taskChoiceInvActivityStrength(examplePSTHNeuron), ...
            taskChoiceInvActivityThreshold,maxTaskInvariantDPrime);
    case {'taskrewardinv','taskrewinv'}
        selectorMetricText = taskInvariantMetricText( ...
            taskRewardInvScore(examplePSTHNeuron),taskRewardSelectivity(examplePSTHNeuron), ...
            task1RewardActivity(examplePSTHNeuron),task2RewardActivity(examplePSTHNeuron), ...
            taskRewardInvActivityStrength(examplePSTHNeuron), ...
            taskRewardInvActivityThreshold,maxTaskInvariantDPrime);
end

isTaskMode = any(strcmpi(exampleMode, ...
    {'taskChoice','taskReward','taskChoiceInv','taskRewardInv','taskRewInv'}));
isRewardTaskMode = any(strcmpi(exampleMode, ...
    {'taskReward','taskRewardInv','taskRewInv'}));
try
    nNeuron153 = size(trialTypeInfo_zz153.dffChoice{stageIdx}{t1rIdx},1);
    if examplePSTHNeuron <= nNeuron153
        exampleSource = 'zz153';
        exampleLocalNeuron = examplePSTHNeuron;
        exampleTrialTypeInfo = trialTypeInfo_zz153;
        exampleUseChoiceAlignment = false;
    else
        exampleSource = 'zz172';
        exampleLocalNeuron = examplePSTHNeuron - nNeuron153;
        exampleTrialTypeInfo = trialTypeInfo_zz172;
        exampleUseChoiceAlignment = true;
    end
catch
    exampleSource = 'current animal';
    exampleLocalNeuron = examplePSTHNeuron;
    exampleTrialTypeInfo = trialTypeInfo;
    exampleUseChoiceAlignment = false;
end

exampleUnrewardedTrace = [];
exampleUnrewardedSem = [];
if isTaskMode
    exampleTrace1 = collectNeuronTrials( ...
        exampleTrialTypeInfo.dffChoice{stageIdx},task1TrialTypeIdx,exampleLocalNeuron);
    exampleTrace2 = collectNeuronTrials( ...
        exampleTrialTypeInfo.dffChoice{stageIdx},task2TrialTypeIdx,exampleLocalNeuron);
    try
    exampleWheel1 = collectTrialTypeTrials( ...
        exampleTrialTypeInfo.wheelChoice{stageIdx},task1TrialTypeIdx);
    exampleWheel2 = collectTrialTypeTrials( ...
        exampleTrialTypeInfo.wheelChoice{stageIdx},task2TrialTypeIdx);
    if isRewardTaskMode
        task1UnrewTrialTypeIdx = taskUnrewTrialTypeIdx(taskUnrewTrialTypeIdx <= 4);
        task2UnrewTrialTypeIdx = taskUnrewTrialTypeIdx(taskUnrewTrialTypeIdx >= 5);
        task1UnrewTrials = collectNeuronTrials( ...
            exampleTrialTypeInfo.dffChoice{stageIdx},task1UnrewTrialTypeIdx,exampleLocalNeuron);
        task2UnrewTrials = collectNeuronTrials( ...
            exampleTrialTypeInfo.dffChoice{stageIdx},task2UnrewTrialTypeIdx,exampleLocalNeuron);
        unrewardedTaskMeans = [];
        if ~isempty(task1UnrewTrials)
            unrewardedTaskMeans = cat(2,unrewardedTaskMeans,nanmean(task1UnrewTrials,2));
        end
        if ~isempty(task2UnrewTrials)
            unrewardedTaskMeans = cat(2,unrewardedTaskMeans,nanmean(task2UnrewTrials,2));
        end
        if ~isempty(unrewardedTaskMeans)
            exampleUnrewardedTrace = nanmean(unrewardedTaskMeans,2);
            if ~isempty(task1UnrewTrials) && ~isempty(task2UnrewTrials)
                task1UnrewSem = nanstd(task1UnrewTrials,0,2) ./ ...
                    sqrt(sum(isfinite(task1UnrewTrials),2));
                task2UnrewSem = nanstd(task2UnrewTrials,0,2) ./ ...
                    sqrt(sum(isfinite(task2UnrewTrials),2));
                exampleUnrewardedSem = ...
                    sqrt(task1UnrewSem.^2 + task2UnrewSem.^2) ./ 2;
            elseif ~isempty(task1UnrewTrials)
                exampleUnrewardedSem = nanstd(task1UnrewTrials,0,2) ./ ...
                    sqrt(sum(isfinite(task1UnrewTrials),2));
            else
                exampleUnrewardedSem = nanstd(task2UnrewTrials,0,2) ./ ...
                    sqrt(sum(isfinite(task2UnrewTrials),2));
            end
        end
    end
    catch
        exampleWheel1 = [];
        exampleWheel2 = [];
    end 
    trace1Label = 'T1';
    trace2Label = 'T2';
    trace1Color = multitaskColors('s1a1');
    trace2Color = multitaskColors('s3a1');
    exampleTitle = sprintf('Interleaved %s neuron: %s #%d', ...
        selectorLabel,exampleSource,exampleLocalNeuron);
else
    if exampleUseChoiceAlignment
        exampleTrace1 = collectNeuronTrials( ...
            exampleTrialTypeInfo.dffChoice{stageIdx},t1lIdx,exampleLocalNeuron);
        exampleTrace2 = collectNeuronTrials( ...
            exampleTrialTypeInfo.dffChoice{stageIdx},t1rIdx,exampleLocalNeuron);
        exampleWheel1 = collectTrialTypeTrials( ...
            exampleTrialTypeInfo.wheelChoice{stageIdx},t1lIdx);
        exampleWheel2 = collectTrialTypeTrials( ...
            exampleTrialTypeInfo.wheelChoice{stageIdx},t1rIdx);
    else
        exampleTrace1 = collectNeuronTrials( ...
            exampleTrialTypeInfo.dffStim{stageIdx},t1lIdx,exampleLocalNeuron);
        exampleTrace2 = collectNeuronTrials( ...
            exampleTrialTypeInfo.dffStim{stageIdx},t1rIdx,exampleLocalNeuron);
        exampleWheel1 = collectTrialTypeTrials( ...
            exampleTrialTypeInfo.wheelStim{stageIdx},t1lIdx);
        exampleWheel2 = collectTrialTypeTrials( ...
            exampleTrialTypeInfo.wheelStim{stageIdx},t1rIdx);
    end
    trace1Label = 'T1L';
    trace2Label = 'T1R';
    trace1Color = [0.34 0.72 0.88];
    trace2Color = [0.20 0.40 0.65];
    exampleTitle = sprintf('Stage %d T1 %s neuron: %s #%d', ...
        stageIdx,selectorLabel,exampleSource,exampleLocalNeuron);
end

if isempty(exampleTrace1) || isempty(exampleTrace2)
    error('TCA_master_2026:MissingExampleTrials', ...
        'No trials were found for %s or %s in stage %d.', ...
        trace1Label,trace2Label,stageIdx);
end

figure;
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

axWheel = nexttile;
hold(axWheel,'on');
plotWheelSpeedTicks(timeAxis,exampleWheel1,trace1Color,0.72);
plotWheelSpeedTicks(timeAxis,exampleWheel2,trace2Color,0.28);
xline(0,'k-','HandleVisibility','off');
xlim([-0.5 1]);
ylim([0 1]);
box off;
yticks([0.28 0.72]);
yticklabels({trace2Label,trace1Label});
xticklabels([]);
ylabel('Wheel');

axNeuron = nexttile;
hold(axNeuron,'on');
plotSingleNeuronWithSem(timeAxis,exampleTrace1,trace1Color,trace1Label);
plotSingleNeuronWithSem(timeAxis,exampleTrace2,trace2Color,trace2Label);
if ~isempty(exampleUnrewardedTrace)
    plotMeanTraceWithSem(timeAxis,exampleUnrewardedTrace,exampleUnrewardedSem, ...
        [0.45 0.45 0.45],'Unrewarded (T1/T2 average)');
end
xline(0,'k-','HandleVisibility','off');
xlim([-0.5 1]);
box off;
xlabel('Time from choice (s)');
ylabel('Activity');
title(exampleTitle);
legend('Location','northeast');
linkaxes([axWheel axNeuron],'x');
fprintf(['%s example selected from combined neuron row %d: ' ...
    '%s neuron %d, %s.\n'], ...
    selectorLabel,examplePSTHNeuron,exampleSource,exampleLocalNeuron,selectorMetricText);


%% check stimulus
tempDffStim = []; 
for i = 1:5
    tempAni= i;
    nNeuronIdx = cumsum([0;nNeuron]);
    tempNeuron = nNeuronIdx(tempAni)+1:nNeuronIdx(tempAni+1);
    tempDff = squeeze(nanmean(nanmean(outDffMat(tempNeuron,11:13,:,:),2),1));
    tempDffTask(i,:,:) = tempDff;
    if i == 1 
        tempDff = tempDff(:,[4 3 2 1]);
    elseif  i == 2
        tempDff = tempDff(:,[3 4 2 1]);
    elseif  i == 3
        tempDff = tempDff(:,[2 1 4 3]);
    end 
    tempDffStim(i,:,:) = tempDff;
end 
tempTitle = {'11.3','5.7','U','D'};
figure;
for i =1:4
    subplot(1,4,i)
    plot(tempDffStim(:,:,i)')
    title(tempTitle{i})

end 

tempTitle = {'1','2','3','4'};
figure;
for i =1:4
    subplot(1,4,i)
    plot(tempDffTask(:,:,i)')
    title(tempTitle{i})
end 

for i = 1:5
    tempAni= i;
    nNeuronIdx = cumsum([0;nNeuron]);
    tempNeuron = nNeuronIdx(tempAni)+1:nNeuronIdx(tempAni+1);
    for j =1:4
        % activity of all neurons at a given stage
        tempDff = squeeze(nanmean(outDffMat(tempNeuron,11:13,j,:),2));
        
        tempCorr(i,j,:,:) = corr(tempDff);
        
    end
end 

%% PCA in each animal's neural space across trial types and learning stages
% Each PCA is fitted independently. Observations are stage x trial type;
% features are that animal's neurons. Lines connect the same trial type as
% learning progresses from E -> M -> L -> Int.
pcaTimeWindow = 11:13;
nAnimalPCA = min(5,numel(nNeuron));
nStagePCA = size(outDffMat,3);
nTrialTypePCA = size(outDffMat,4);
nNeuronIdx = cumsum([0;nNeuron(:)]);

if nNeuronIdx(nAnimalPCA+1) > size(outDffMat,1)
    error('TCA_master_2026:PCAAnimalNeuronMismatch', ...
        ['The first %d entries of nNeuron require %d neurons, but ' ...
        'outDffMat contains only %d.'], ...
        nAnimalPCA,nNeuronIdx(nAnimalPCA+1),size(outDffMat,1));
end
pcaTimeWindow = pcaTimeWindow( ...
    pcaTimeWindow >= 1 & pcaTimeWindow <= size(outDffMat,2));
if isempty(pcaTimeWindow)
    error('TCA_master_2026:InvalidPCATimeWindow', ...
        'pcaTimeWindow does not overlap the %d available frames.',size(outDffMat,2));
end

if nStagePCA == 4
    pcaStageLabels = {'E','M','L','Int'};
else
    pcaStageLabels = arrayfun(@(x) sprintf('S%d',x),1:nStagePCA, ...
        'UniformOutput',false);
end
pcaTrialTypeLabels = arrayfun(@(x) sprintf('Trial type %d',x), ...
    1:nTrialTypePCA,'UniformOutput',false);
pcaTrialTypeColors = lines(nTrialTypePCA);
if nTrialTypePCA >= 4
    pcaTrialTypeColors(1,:) = multitaskColors('s1a1');
    pcaTrialTypeColors(2,:) = multitaskColors('s2a2');
    pcaTrialTypeColors(3,:) = multitaskColors('s3a1');
    pcaTrialTypeColors(4,:) = multitaskColors('s4a2');
end

pcaScoreByAnimal = cell(nAnimalPCA,1);
pcaExplainedByAnimal = cell(nAnimalPCA,1);
pcaFigureByAnimal = gobjects(nAnimalPCA,1);
for iAnimal = 1:nAnimalPCA
    tempNeuron = nNeuronIdx(iAnimal)+1:nNeuronIdx(iAnimal+1);
    animalActivity = nanmean(outDffMat(tempNeuron,pcaTimeWindow,:,:),2);
    animalActivity = reshape(animalActivity,numel(tempNeuron),nStagePCA,nTrialTypePCA);

    % Order observations as trial types 1:n within each successive stage.
    pcaInput = reshape(permute(animalActivity,[3 2 1]), ...
        nTrialTypePCA*nStagePCA,numel(tempNeuron));
    validNeuron = all(isfinite(pcaInput),1) & std(pcaInput,0,1) > 0;

    pcaFigureByAnimal(iAnimal) = figure('Color','w', ...
        'Name',sprintf('%s neural-space PCA',animalLabels{iAnimal}), ...
        'NumberTitle','off','Position',[120 120 700 600]);
    axPCA = axes('Parent',pcaFigureByAnimal(iAnimal));
    hold(axPCA,'on');
    if sum(validNeuron) < 3
        axis(axPCA,'off');
        title(axPCA,sprintf('%s: insufficient complete neurons',animalLabels{iAnimal}));
        warning('TCA_master_2026:InsufficientPCANeurons', ...
            '%s has only %d complete, nonconstant neurons for 3D PCA.', ...
            animalLabels{iAnimal},sum(validNeuron));
        continue
    end

    [~,pcaScore,~,~,pcaExplained] = pca(pcaInput(:,validNeuron), ...
        'NumComponents',3);
    pcaScore = reshape(pcaScore,nTrialTypePCA,nStagePCA,3);
    pcaScoreByAnimal{iAnimal} = pcaScore;
    pcaExplainedByAnimal{iAnimal} = pcaExplained;

    for iTrialType = 1:nTrialTypePCA
        pc1 = squeeze(pcaScore(iTrialType,:,1));
        pc2 = squeeze(pcaScore(iTrialType,:,2));
        pc3 = squeeze(pcaScore(iTrialType,:,3));
        trialColor = pcaTrialTypeColors(iTrialType,:);
        plot3(axPCA,pc1,pc2,pc3,'-o','Color',trialColor, ...
            'MarkerFaceColor',trialColor,'MarkerEdgeColor','w', ...
            'LineWidth',1.5,'MarkerSize',5, ...
            'DisplayName',pcaTrialTypeLabels{iTrialType});
        for iStage = 1:nStagePCA
            text(axPCA,pc1(iStage),pc2(iStage),pc3(iStage), ...
                [' ' pcaStageLabels{iStage}], ...
                'Color',trialColor,'FontSize',7,'Clipping','on');
        end
    end

    axis(axPCA,'equal');
    view(axPCA,3);
    grid(axPCA,'on');
    box(axPCA,'off');
    xlabel(axPCA,sprintf('PC1 (%.1f%%)',pcaExplained(1)));
    ylabel(axPCA,sprintf('PC2 (%.1f%%)',pcaExplained(2)));
    zlabel(axPCA,sprintf('PC3 (%.1f%%)',pcaExplained(3)));
    title(axPCA,sprintf('%s: top-3-PC neural projection, frames %s (n=%d neurons)', ...
        animalLabels{iAnimal},num2str(pcaTimeWindow),sum(validNeuron)), ...
        'Interpreter','none');
    legend(axPCA,'Location','best','Box','off');
    rotate3d(pcaFigureByAnimal(iAnimal),'on');
end

%% PCA after combining the neural spaces from all animals
combinedAnimalActivity = nanmean(outDffMat(:,pcaTimeWindow,:,:),2);
combinedAnimalActivity = reshape(combinedAnimalActivity, ...
    size(outDffMat,1),nStagePCA,nTrialTypePCA);
combinedPCAInput = reshape(permute(combinedAnimalActivity,[3 2 1]), ...
    nTrialTypePCA*nStagePCA,size(outDffMat,1));
combinedPCAValidNeuron = all(isfinite(combinedPCAInput),1) & ...
    std(combinedPCAInput,0,1) > 0;
if sum(combinedPCAValidNeuron) < 3
    error('TCA_master_2026:InsufficientCombinedPCANeurons', ...
        ['Only %d complete, nonconstant neurons are available after combining ' ...
        'all animals; at least 3 are required for 3D PCA.'], ...
        sum(combinedPCAValidNeuron));
end

[combinedPCACoeff,combinedPCAScore,~,~,combinedPCAExplained] = ...
    pca(combinedPCAInput(:,combinedPCAValidNeuron),'NumComponents',3);
combinedPCAScore = reshape(combinedPCAScore,nTrialTypePCA,nStagePCA,3);

combinedPCAFigure = figure('Color','w', ...
    'Name','All animals combined neural-space PCA', ...
    'NumberTitle','off','Position',[120 120 700 600]);
axCombinedPCA = axes('Parent',combinedPCAFigure);
hold(axCombinedPCA,'on');
for iTrialType = 1:nTrialTypePCA
    pc1 = squeeze(combinedPCAScore(iTrialType,:,1));
    pc2 = squeeze(combinedPCAScore(iTrialType,:,2));
    pc3 = squeeze(combinedPCAScore(iTrialType,:,3));
    trialColor = pcaTrialTypeColors(iTrialType,:);
    plot3(axCombinedPCA,pc1,pc2,pc3,'-o','Color',trialColor, ...
        'MarkerFaceColor',trialColor,'MarkerEdgeColor','w', ...
        'LineWidth',1.5,'MarkerSize',5, ...
        'DisplayName',pcaTrialTypeLabels{iTrialType});
    for iStage = 1:nStagePCA
        text(axCombinedPCA,pc1(iStage),pc2(iStage),pc3(iStage), ...
            [' ' pcaStageLabels{iStage}], ...
            'Color',trialColor,'FontSize',7,'Clipping','on');
    end
end
axis(axCombinedPCA,'equal');
view(axCombinedPCA,3);
grid(axCombinedPCA,'on');
box(axCombinedPCA,'off');
xlabel(axCombinedPCA,sprintf('PC1 (%.1f%%)',combinedPCAExplained(1)));
ylabel(axCombinedPCA,sprintf('PC2 (%.1f%%)',combinedPCAExplained(2)));
zlabel(axCombinedPCA,sprintf('PC3 (%.1f%%)',combinedPCAExplained(3)));
title(axCombinedPCA,sprintf( ...
    'All animals combined: top-3-PC projection, frames %s (n=%d neurons)', ...
    num2str(pcaTimeWindow),sum(combinedPCAValidNeuron)));
legend(axCombinedPCA,'Location','best','Box','off');
rotate3d(combinedPCAFigure,'on');

figure; tempStage = 3;
for i =1:5
    subplot(1,5,i)
    imagesc(squeeze(tempCorr(i,tempStage,:,:))); clim([-0.8 0.8])
    title(['stage ' int2str(tempStage)])
end 

%% PART 5.7 -- average activity of the top neurons in one TCA component
% Adapted from TCA_singleneuron_plot.m. Unlike the older code, which plots
% tempIdx(4), this section averages the top fraction of component neurons.
componentToPlot = 7;
topNeuronFraction = 20;

componentDataFile = fullfile(datapath, ...
    'outDffMat_zz153_159_172_PPC_spkNorm_stim.mat');
componentData = load(componentDataFile,'outDffMat');
if ~isfield(componentData,'outDffMat')
    error('TCA_master_2026:MissingOutDffMat', ...
        '%s does not contain outDffMat.',componentDataFile);
end

componentModel = M{nModel};
if componentToPlot < 1 || componentToPlot > size(componentModel.U{1},2)
    error('TCA_master_2026:InvalidComponent', ...
        'componentToPlot must be between 1 and %d.',size(componentModel.U{1},2));
end
if size(componentData.outDffMat,1) ~= size(componentModel.U{1},1)
    error('TCA_master_2026:NeuronCountMismatch', ...
        ['outDffMat contains %d neurons, but the fitted model contains %d. ' ...
        'Load activity and TCA results generated from the same neurons.'], ...
        size(componentData.outDffMat,1),size(componentModel.U{1},1));
end

neuralWeight = componentModel.U{1}(:,componentToPlot);
[~,bestComponentByNeuron] = max(componentModel.U{1},[],2);
componentNeuronIdx = find(bestComponentByNeuron==componentToPlot);
if isempty(componentNeuronIdx)
    error('TCA_master_2026:NoExclusiveNeurons', ...
        'No neuron has component %d as its strongest contributing component.', ...
        componentToPlot);
end
[sortedWeight,componentOrder] = sort( ...
    neuralWeight(componentNeuronIdx),'descend');
sortedNeuronIdx = componentNeuronIdx(componentOrder);
nTopNeuron = min(numel(sortedNeuronIdx),max(1,round(topNeuronFraction)));
topNeuronIdx = sortedNeuronIdx(1:nTopNeuron);
topNeuronWeight = sortedWeight(1:nTopNeuron);
topNeuronActivity = componentData.outDffMat(topNeuronIdx,:,:,:);
topNeuronActivity = smoothdata(topNeuronActivity,2,'movmean',3);

nStage = size(topNeuronActivity,3);
nTrialType = size(topNeuronActivity,4);
nTime = size(topNeuronActivity,2);
timeAxis = ((1:nTime)-10)/15;
stageLabels = {'E','M','L','Int'};
if nStage ~= numel(stageLabels)
    stageLabels = arrayfun(@(x) sprintf('Stage %d',x),1:nStage, ...
        'UniformOutput',false);
end

figure('Color','w','Name',sprintf('TC %d top-neuron average',componentToPlot), ...
    'NumberTitle','off');
componentPlotAxes = gobjects(2,nStage);
for stageIdx = 1:nStage
    componentPlotAxes(1,stageIdx) = ...
        subplot_tight(2,nStage,stageIdx,[0.035 0.025]);
    fn_plotMeanErrorbar(timeAxis,topNeuronActivity(:,:,stageIdx,1), ...
        multitaskColors('s1a1'),multitaskColors('s1a1'), ...
        {'LineWidth',2.5},{'FaceAlpha',0.25});
    hold on;
    if nTrialType >= 2
        fn_plotMeanErrorbar(timeAxis,topNeuronActivity(:,:,stageIdx,2), ...
            multitaskColors('s2a2'),multitaskColors('s2a2'), ...
            {'LineWidth',2.5},{'FaceAlpha',0.25});
    end
    xline(0,'k-'); xline(0.62,'k--');
    title(stageLabels{stageIdx});
    if stageIdx == 1
        ylabel('Task 1 activity');
    end
    xticklabels([]); box off;

    componentPlotAxes(2,stageIdx) = ...
        subplot_tight(2,nStage,stageIdx+nStage,[0.035 0.025]);
    if nTrialType >= 3
        fn_plotMeanErrorbar(timeAxis,topNeuronActivity(:,:,stageIdx,3), ...
            multitaskColors('s3a1'),multitaskColors('s3a1'), ...
            {'LineWidth',2.5},{'FaceAlpha',0.25});
    end
    hold on;
    if nTrialType >= 4
        fn_plotMeanErrorbar(timeAxis,topNeuronActivity(:,:,stageIdx,4), ...
            multitaskColors('s4a2'),multitaskColors('s4a2'), ...
            {'LineWidth',2.5},{'FaceAlpha',0.25});
    end
    xline(0,'k-'); xline(0.62,'k--');
    if stageIdx == 1
        ylabel('Task 2 activity');
    end
    xlabel('Time from stimulus (s)'); box off;
end

% Use the union of all automatically determined y-limits so every panel
% has exactly the same x- and y-axis scale.
allYLim = nan(numel(componentPlotAxes),2);
for axisIdx = 1:numel(componentPlotAxes)
    allYLim(axisIdx,:) = ylim(componentPlotAxes(axisIdx));
end
sharedYLim = [min(allYLim(:,1)) max(allYLim(:,2))];
if diff(sharedYLim)==0
    sharedYLim = sharedYLim + [-0.5 0.5];
end
linkaxes(componentPlotAxes(:),'xy');
set(componentPlotAxes,'XLim',[-0.5 1.4],'YLim',sharedYLim);

sgtitle(sprintf(['TC %d: top %d exclusive neurons ' ...
    '(3-frame smooth, mean weight = %.3g)'], ...
    componentToPlot,nTopNeuron,mean(topNeuronWeight)), ...
    'FontWeight','bold');

function [task1Mean,task2Mean,varianceNormalizedDifference] = ...
    taskVarianceNormalizedDifference(stageTrialTypes,task1TrialTypeIdx,task2TrialTypeIdx,timeWindow)
% d-prime: difference of task means divided by pooled trial SD. The pooled
% SD is the square root of pooled variance, keeping the metric dimensionless.
task1TrialActivity = collectTaskWindowActivity( ...
    stageTrialTypes,task1TrialTypeIdx,timeWindow);
task2TrialActivity = collectTaskWindowActivity( ...
    stageTrialTypes,task2TrialTypeIdx,timeWindow);

task1Mean = nanmean(task1TrialActivity,2);
task2Mean = nanmean(task2TrialActivity,2);
task1Variance = nanvar(task1TrialActivity,0,2);
task2Variance = nanvar(task2TrialActivity,0,2);
pooledTrialSD = sqrt(0.5 .* (task1Variance + task2Variance));
varianceNormalizedDifference = (task1Mean - task2Mean) ./ (pooledTrialSD + eps);

nTask1Trial = sum(isfinite(task1TrialActivity),2);
nTask2Trial = sum(isfinite(task2TrialActivity),2);
varianceNormalizedDifference(nTask1Trial < 3 | nTask2Trial < 3 | ...
    ~isfinite(varianceNormalizedDifference)) = nan;
end

function trialActivity = collectTaskWindowActivity(stageTrialTypes,trialTypeIdx,timeWindow)
trialActivity = [];
for iTrialType = trialTypeIdx
    trialBlock = stageTrialTypes{iTrialType};
    if isempty(trialBlock)
        continue
    end
    selectedWindow = timeWindow(timeWindow >= 1 & timeWindow <= size(trialBlock,2));
    if isempty(selectedWindow)
        continue
    end
    typeTrialActivity = nanmean(trialBlock(:,selectedWindow,:),2);
    typeTrialActivity = reshape(typeTrialActivity,size(trialBlock,1),size(trialBlock,3));
    trialActivity = cat(2,trialActivity,typeTrialActivity);
end
if isempty(trialActivity)
    error('TCA_master_2026:MissingTaskTrials', ...
        'No data were found for trial types [%s].',num2str(trialTypeIdx));
end
end

function [score,selectivity,activityStrength,activityThreshold] = ...
    scoreTaskSelectivity(task1Activity,task2Activity,selectivity,minActivityPercentile,scalePercentile)
% Signed d-prime is positive for T1 and negative for T2 preference.
validNeuron = isfinite(task1Activity) & isfinite(task2Activity) & isfinite(selectivity);
activityStrength = max([task1Activity task2Activity],[],2);

activeNeuron = validNeuron & isfinite(activityStrength) & activityStrength > 0;
score = -inf(size(task1Activity));
if ~any(activeNeuron)
    activityThreshold = nan;
    return
end

activityThreshold = prctile(activityStrength(activeNeuron),minActivityPercentile);
activityScale = prctile(activityStrength(activeNeuron),scalePercentile);
activityScale = max(activityScale,eps);
activityWeight = min(max(activityStrength ./ activityScale,0),1);
score(activeNeuron) = abs(selectivity(activeNeuron)) .* activityWeight(activeNeuron);
score(activityStrength < activityThreshold) = -inf;
end

function [score,activityStrength,activityThreshold] = ...
    scoreTaskInvariance(task1Activity,task2Activity,selectivity,minActivityPercentile,maxInvariantDPrime)
% First require similar T1/T2 activity (small |d-prime|), then rank the
% surviving neurons by their mean activity across both tasks.
validNeuron = isfinite(task1Activity) & isfinite(task2Activity) & isfinite(selectivity);
activityStrength = mean([task1Activity task2Activity],2);
activeNeuron = validNeuron & isfinite(activityStrength) & activityStrength > 0;
score = -inf(size(task1Activity));
if ~any(activeNeuron)
    activityThreshold = nan;
    return
end

activityThreshold = prctile(activityStrength(activeNeuron),minActivityPercentile);
invariantNeuron = activeNeuron & abs(selectivity) <= maxInvariantDPrime & ...
    activityStrength >= activityThreshold;
score(invariantNeuron) = activityStrength(invariantNeuron);
end

function metricText = taskMetricText(score,selectivity,task1Activity,task2Activity,activityStrength,activityThreshold)
if selectivity >= 0
    preferredTask = 'T1';
else
    preferredTask = 'T2';
end
metricText = sprintf([ '%s-preferring, combined score %.3g, d-prime %.3g, ' ...
    'T1 %.3g, T2 %.3g, activity %.3g (cutoff %.3g)'], ...
    preferredTask,score,selectivity,task1Activity,task2Activity, ...
    activityStrength,activityThreshold);
end

function metricText = taskInvariantMetricText(score,selectivity,task1Activity,task2Activity,activityStrength,activityThreshold,maxInvariantDPrime)
metricText = sprintf([ 'task-invariant, activity score %.3g, d-prime %.3g ' ...
    '(|d-prime| <= %.3g), T1 %.3g, T2 %.3g, mean activity %.3g (cutoff %.3g)'], ...
    score,selectivity,maxInvariantDPrime,task1Activity,task2Activity, ...
    activityStrength,activityThreshold);
end

function trialMat = collectNeuronTrials(stageTrialTypes,trialTypeIdx,neuronIdx)
trialMat = [];
for iTrialType = trialTypeIdx
    trialBlock = stageTrialTypes{iTrialType};
    if isempty(trialBlock)
        continue
    end
    if neuronIdx > size(trialBlock,1)
        error('TCA_master_2026:InvalidExampleNeuron', ...
            'Neuron %d exceeds the %d neurons in trial type %d.', ...
            neuronIdx,size(trialBlock,1),iTrialType);
    end
    neuronTrials = reshape(trialBlock(neuronIdx,:,:), ...
        size(trialBlock,2),size(trialBlock,3));
    trialMat = cat(2,trialMat,neuronTrials);
end
end

function trialMat = collectTrialTypeTrials(stageTrialTypes,trialTypeIdx)
trialMat = [];
for iTrialType = trialTypeIdx
    trialBlock = stageTrialTypes{iTrialType};
    if isempty(trialBlock)
        continue
    end
    if isvector(trialBlock)
        trialBlock = trialBlock(:);
    end
    trialMat = cat(2,trialMat,trialBlock);
end
end

function plotSingleNeuronWithSem(timeAxis,trialMat,lineColor,lineLabel)
trialMat = smoothdata(trialMat,1,'movmean',1);
meanTrace = nanmean(trialMat,2);
nTrial = sum(isfinite(trialMat),2);
semTrace = nanstd(trialMat,0,2) ./ sqrt(nTrial);
plotMeanTraceWithSem(timeAxis,meanTrace,semTrace,lineColor,lineLabel);
end

function plotMeanTraceWithSem(timeAxis,meanTrace,semTrace,lineColor,lineLabel)
validFrame = isfinite(meanTrace) & isfinite(semTrace);

x = timeAxis(validFrame);
y = meanTrace(validFrame)';
sem = semTrace(validFrame)';
fill([x fliplr(x)],[y-sem fliplr(y+sem)],lineColor, ...
    'FaceAlpha',0.2,'EdgeColor','none','HandleVisibility','off');
plot(x,y,'Color',lineColor,'LineWidth',2,'DisplayName',lineLabel);
end

function plotWheelSpeedTicks(timeAxis,wheelMat,lineColor,yCenter)
if isempty(wheelMat)
    return
end
wheelMat = wheelMat - repmat(wheelMat(1,:),[size(wheelMat,1) 1]);
speedTrace = [ abs(diff(wheelMat,1,1)); zeros(1,size(wheelMat,2))];
speedTrace = nanmean(speedTrace,2);
speedTrace = smoothdata(speedTrace,1,'movmean',2);
validFrame = isfinite(speedTrace) & speedTrace > 0;
if ~any(validFrame)
    return
end

speedNorm = speedTrace ./ prctile(speedTrace(validFrame),95);
speedNorm = min(max(speedNorm,0),1);
interpFactor = 2;
fineTimeAxis = linspace(timeAxis(1),timeAxis(end),numel(timeAxis) * interpFactor);
fineSpeedNorm = interp1(timeAxis(:),speedNorm(:),fineTimeAxis(:),'pchip','extrap');
fineSpeedNorm = min(max(fineSpeedNorm,0),1);
maxTickPerFrame = 4;
frameDt = median(diff(fineTimeAxis));
tickHeight = 0.16;
for iFrame = 1:length(fineTimeAxis)
    nTick = round(fineSpeedNorm(iFrame) * maxTickPerFrame);
    if nTick <= 0
        continue
    end
    xTick = fineTimeAxis(iFrame) + linspace(-0.35,0.35,nTick) * frameDt;
    for iTick = 1:nTick
        line([xTick(iTick) xTick(iTick)], ...
            [yCenter - tickHeight/2, yCenter + tickHeight/2], ...
            'Color',lineColor,'LineWidth',0.75);
    end
end
end

