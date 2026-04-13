%% load animal data
clear;
tic; ani = Animal('zz153_AC','actType','spk','tracking',false); 
%%
clear;
tic; ani = Animal('zz153_PPC','actType','spk','tracking',true); 
%% load animal data
clear; 
tic; ani = Animal('zz159_PPC','actType','spk','tracking',true); 

%% load animal data
clear; 
tic; ani = Animal('zz159_AC','actType','spk','tracking',true); 

%% load animal data
clear; 
tic; ani = Animal('zz170_AC','actType','spk','tracking',true); 

%% step 1.0 -- do two-step clustering, this help us select 
ani = fn_initialClustering(ani,'secondCluster',false);
trialTypeInfoChoice = ani.trialTypeInfo; 

%% step 1.1 -- check stimulus evoked activity

% reparse the activity to include miss trials
selTime = 11:45; 
[ani,~,trialTypeInfoStim] = ani.chunkDaysByTrialType({'dffStim','dffChoice','behSel'},'selTime',selTime,'stim',...
    [1,1,1,2,2,2,3,3,3,4,4,4],'choice',[1,2,0,1,2,0,1,2,0,1,2,0],'RTrange',[0.17 0.32]);

%[~,~,trialTypeInfoStim] = ani.chunkDaysByTrialType({'dffStim','dffChoice','behSel'},'selTime',selTime,'stim',...
%    [1,1,1,2,2,2,3,3,3,4,4,4],'choice',[1,2,0,1,2,0,1,2,0,1,2,0],'RTrange',[0.17 0.32]);
%% step 2.1 -- plot umap and spatial location of cluster
clusterLabel = ani.analysis.initialClustering.labelTracked; nCluster = max(clusterLabel);
clusterLabelAll = ani.analysis.initialClustering.labelAll; 

figure;
subplot(1,2,1);
for i = 1:nCluster
    scatter3(ani.analysis.initialClustering.proj(clusterLabel==i,1),...
        ani.analysis.initialClustering.proj(clusterLabel==i,2),ani.analysis.initialClustering.proj(clusterLabel==i,3),'filled'); hold on;
end 
title(['Clustering based on clustering in' newline 'corr/incorr trials, umap projection']);

roi = ani.sessionInfo.roi{5}(ani.ops.ishereAll);
subplot(1,2,2); hold on;
for i = 1:length(roi)
    try
        if clusterLabel(i)~=0; fill(roi{i}(:,2),roi{i}(:,1),matlabColors(clusterLabel(i)),'LineStyle','none');
        else; fill(roi{i}(:,2),roi{i}(:,1),[0.8 0.8 0.8],'LineStyle','none');end 
        catch; disp(i)
    end 
end
set(gca, 'YDir', 'reverse');
title('ROI location of neurons'); xlabel('P <---> A'); ylabel('V <---> D');

%%
tempAct = cellfun(@(x)(nanmean(x{1},3)+nanmean(x{4},3)), trialTypeInfoStim.dffStim,'UniformOutput',false);
subplot(2,3,3); 
imagesc(tempAct{3}(clusterLabel==1,:)); clim([0 prctile(tempAct{4}(:),99)]);
title('Cluster 1 actvity')
subplot(2,3,6);
imagesc(tempAct{3}(clusterLabel==2,:)); clim([0 prctile(tempAct{4}(:),99)])
title('Cluster 2 actvity')
%% 2.2 -- Plot task 1 activity between clusters, using imagesc

% Then plot task 2 activity 
selDay = [1 2 3 4 5 6]; selType = 4; % stim 2, correct trials 
figure;
for i  = 1:length(selDay)
    selAct = trialTypeInfoChoice.dffChoice{selDay(i)};
    selAct = cellfun(@(x)(nanmean(x,3)),selAct,'UniformOutput',false); selAct = fn_cell2mat(selAct,3);% take only task 1 trial types
    for j = 1:4
        subplot_tight(length(selDay),4,j+(i-1)*4,[0.01 0.01]); hold on; % plot task 1
        tempRT = nanmean(trialTypeInfoChoice.behSelTrialType{selDay(i)}{j}.RT);
        xline(20.5,'Color',[0.8 0.8 0.8],'LineWidth',2)
        xline(20-tempRT*15,'Color',[0.8 0.8 0.8],'LineWidth',2)
        for k = 1:3
            plot(nanmean(selAct(clusterLabel==k,:,j),1),'Color',matlabColors(k),'LineWidth',1.5); 
            
            %imagesc(selAct(clusterLabel==1,:,j+4)); hold on; 
            clim([0 0.01]); yticks([]); xticks([])
        end 
        
        
        
    end 

end 

%% 2.3 -- Plot task 1 activity between clusters, using plot mean

% Then plot task 2 activity 
selDay = [4 5 6]; % stim 2, correct trials 
figure;
for i  = 1:length(selDay)
    selAct = trialTypeInfoChoice.dffChoice{selDay(i)};
    selAct = cellfun(@(x)(nanmean(x,3)),selAct,'UniformOutput',false); selAct = fn_cell2mat(selAct,3);% take only task 1 trial types
    for j = 1:4
        subplot(length(selDay),4,j+(i-1)*4); % plot task 1
        for k = 1:nCluster
            plot(nanmean(selAct(clusterLabel==k,:,j+4),1),'Color',matlabColors(k)); hold on; 
            xline(10.5)
            %imagesc(selAct(clusterLabel==1,:,j+4)); hold on; 
            clim([0 0.01]); title(['day ' int2str(i) ' trial type ' int2str(j)])
        end 
        
    end 

end


%%
 selType = 4;
selWheel = trialTypeInfoChoice.wheelChoice{selDay}{selType}(21:45,:);
selRT = trialTypeInfoChoice.behSelTrialType{selDay}{selType}.RT;

selActAvg = squeeze(nanmean(nanmean(selAct,1),3));
selWheel = selWheel - repmat(selWheel(1,:),[size(selWheel,1), 1]);
selWheelAvg = nanmean(selWheel,2);
figure; plot(selActAvg-selActAvg(1)); hold on; plot(-selWheelAvg*0.001-0.003)
ylim([-0.005 0.01])

figure; 
for i = 1:49
    subplot_tight(7,7,i,[0.01 0.01])
    plot(nanmean(selAct(:,:,i),1)); hold on; plot(-selWheel(:,i)*0.001-0.003);
    tempRT = 11 - 15*selRT(i); xline(tempRT);
    xline(11); xticks([]); yticks([]); xlim([0 25])
end 




%% step 1.3 -- check location of clustered neurons

roi = ani.sessionInfo.roi{33}(ani.ops.ishereAll);

figure; 

subplot(2,2,2); clusterNum = max(clusterLabel);
selDay = 7; selType = 6; % miss trial
selAct = nanmean(ani.trialTypeInfo.dffStim{selDay}{9},3)+...
    nanmean(ani.trialTypeInfo.dffStim{selDay}{12},3);
for i = 1:clusterNum

    plot(nanmean(nanmean(selAct(clusterLabel==i,:,:),1),3)); hold on; 

end 
xline(20.5)

subplot(2,2,1); hold on;
% miss trial, sum of Tone 1 and tone 2
selAct = nanmean(ani.trialTypeInfo.dffStim{selDay}{9},3)+nanmean(ani.trialTypeInfo.dffStim{selDay}{12},3);
selActTone = selAct(:,22) - selAct(:,19); % seleect the peak activity
selActTone = selActTone / prctile(selActTone(:),99); % normalize to 1
for i = 1:length(roi)
    try
        fill(roi{i}(:,1),roi{i}(:,2),matlabColors(1,selActTone(i)),'LineStyle','none');
    catch
        disp(i)
    end
end 
title('Tone-evoked activity');

selAct1 = nanmean(ani.trialTypeInfo.dffStim{selDay}{1}(:,12,:),3);
selAct2 = nanmean(ani.trialTypeInfo.dffStim{selDay}{4}(:,12,:),3);
selIdx = round(((selAct2-selAct1) ./ (selAct2+selAct1) *128)+128);
selIdx(selIdx<=0) = 1; selIdx(selIdx>256) = 256;
subplot(2,2,4); hold on;
rbmap = redblue;
for i = 1:length(roi)
    try
        fill(roi{i}(:,1),roi{i}(:,2),rbmap(selIdx(i),:),'LineStyle','none');
    catch
        disp(i)
    end
end 
title('Selectivity of tone 1 vs tone 2');
%% check dPCA
% 
% selDay = 6; 
% matS1 = cat(3,nanmean(s1a1{selDay},3),nanmean(s1a2{selDay},3) );
% matS2 = cat(3,nanmean(s2a1{selDay},3),nanmean(s2a2{selDay},3) );
% matFull = cat(4, matS1,matS2); matFull = matFull(:,13:50,:,:); matFull= double(permute(matFull,[1,3,4,2]));
% 
% combinedParams = {{1, [1 3]}, {2, [2 3]}, {3}, {[1 2], [1 2 3]}};
% margColours = [23 100 171; 187 20 25; 150 150 150; 114 97 171]/256;
% margNames = {'Stimulus', 'Decision', 'Condition-independent', 'S/D Interaction'};
% time = ((1:size(matFull,4)) - 18) / 15; timeEvents = 0; 
% [W, V, whichMarg] = dpca(matFull, 10,'lambda',1e-03,'combinedParams', combinedParams);
% 
% explVar = dpca_explainedVariance(matFull, W, V, ...
%     'combinedParams', combinedParams);
% 
% dpca_plot(matFull, W, V, @dpca_plot_default, ...
%     'explainedVar', explVar, ...
%     'marginalizationNames', margNames, ...
%     'marginalizationColours', margColours, ...
%     'whichMarg', whichMarg,                 ...
%     'time', time,                        ...
%     'timeEvents', timeEvents,               ...
%     'timeMarginalization', 3, ...
%     'legendSubplot', 16);
%% do pls-da
selDay = 16; 
outmatTrial = organizeDataInDay({s4a1,s4a2},selDay);

outmatTrialType = [zeros(1,size(outmatTrial{1},3)), ones(1,size(outmatTrial{2},3))];
outmatTrial_da = cat(3,outmatTrial{1}(:,1:50,:),outmatTrial{2}(:,1:50,:));
[Xscores, XL, PCTVAR,Xproj,XL_tensor] = runPLSDA(outmatTrial_da,outmatTrialType, 5);

figure; 
for i = 1:5
    subplot(2,3,i);hold on; 

    plot(nanmean(Xproj(i,:,outmatTrialType==0),3)); plot(nanmean(Xproj(i,:,outmatTrialType==1),3));
    xline(31); xline(31-round(nanmean(rt21{selDay})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{selDay})*15),'--','Color',matlabColors(2))
    xticks([16 31 46]); xticklabels({'-1s','0','1s'});
    xlabel('Time aligned to choice threshold reached')
end

%% do pls-da across days

[outmatTrialMultiDay, outmatTrialMultiDayLabel,outmatDayLabel] = organizeDataMultiDay({s1a1,s2a2},[2:17]);
outmatTrialMultiDay = fn_cell2mat(outmatTrialMultiDay,3);
outmatTrialMultiDayLabel = (fn_cell2mat(outmatTrialMultiDayLabel,2));

nanNeuron = squeeze(sum(sum(isnan(outmatTrialMultiDay),2),3)); nonanNeuron = nanNeuron==0; 
outmatTrial_da = outmatTrialMultiDay(nonanNeuron,1:50,:);
[Xscores, XL, PCTVAR,Xproj,XL_tensor] = runPLSDA(outmatTrial_da,outmatTrialMultiDayLabel, 5);

figure; 
for i = 1:5
    subplot(2,3,i);hold on; 
    plot(nanmean(Xproj(i,:,outmatTrialMultiDayLabel==0),3)); plot(nanmean(Xproj(i,:,outmatTrialMultiDayLabel==1),3));
    xline(31); xline(31-round(nanmean(rt21{selDay})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{selDay})*15),'--','Color',matlabColors(2))
    xticks([16 31 46]); xticklabels({'-1s','0','1s'});
    xlabel('Time aligned to choice threshold reached')
end

tempColor = jet; tempColor = tempColor(floor(linspace(1,size(tempColor,1),max(outmatDayLabel))),:);
figure;
for i = 1:max(outmatDayLabel)
    tempTrialLabel0 = find(outmatDayLabel == i & outmatTrialMultiDayLabel==0); 
    tempTrialLabel1 = find(outmatDayLabel == i & outmatTrialMultiDayLabel==1); 
    scatter(Xscores(tempTrialLabel0,1), Xscores(tempTrialLabel0,2), 50, tempColor(i,:), 'filled'); hold on;
    scatter(Xscores(tempTrialLabel1,1), Xscores(tempTrialLabel1,2), 50, tempColor(i,:));
    xlabel(['Component 1, exp. var: ' num2str(PCTVAR(2,1),'%.2f')]); 
    ylabel(['Component 2, exp.var: ' num2str(PCTVAR(2,2),'%.2f')]);
    legend('choice L','choice R');
    title('PLS-DA projection, stimR trials');
    grid on;
end 
%% look at pls-da weights

figure; imagesc(-XL_tensor(:,:,2)); clim([0 0.3])
choiceW = nanmean(-XL_tensor(:,25:30,1),2); 
rewardW = nanmean(-XL_tensor(:,32:36,1),2); 
neuronC = choiceW>0.04 & rewardW<0.02;
neuronR = rewardW>0.04 & choiceW<0.02;
neuronCR = rewardW>0.02 & choiceW>0.02;

figure; histogram(choiceW);
figure; subplot(1,3,1); 
plot(nanmean(nanmean(outmatTrial{1}(neuronC,:,:),1),3)); hold on; 
plot(nanmean(nanmean(outmatTrial{2}(neuronC,:,:),1),3))
xline(31); xline(31-round(nanmean(rt21{selDay})*15),'--','Color',matlabColors(1)); 
xline(31-round(nanmean(rt22{selDay})*15),'--','Color',matlabColors(2));
title('Choice neuron')

subplot(1,3,2); 
plot(nanmean(nanmean(outmatTrial{1}(neuronR,:,:),1),3)); hold on; 
plot(nanmean(nanmean(outmatTrial{2}(neuronR,:,:),1),3))
xline(31); xline(31-round(nanmean(rt21{selDay})*15),'--','Color',matlabColors(1)); 
xline(31-round(nanmean(rt22{selDay})*15),'--','Color',matlabColors(2));
title('reward neuron')

subplot(1,3,3); 
plot(nanmean(nanmean(outmatTrial{1}(neuronCR,:,:),1),3)); hold on; 
plot(nanmean(nanmean(outmatTrial{2}(neuronCR,:,:),1),3))
xline(31); xline(31-round(nanmean(rt21{selDay})*15),'--','Color',matlabColors(1)); 
xline(31-round(nanmean(rt22{selDay})*15),'--','Color',matlabColors(2));
title('Choice+reward neuron')
 

figure; 
for i = 1:20
    subplot_tight(4,5,i,[0.02,0.02]); 
    plot(nanmean(nanmean(s2a1{i}(neuronR,:,:),1),3)); hold on; 
    plot(nanmean(nanmean(s2a2{i}(neuronR,:,:),1),3));

    xline(31); xline(31-round(nanmean(rt21{i})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{i})*15),'--','Color',matlabColors(2));  
    xticks([]); yticks([]);
end 

figure; 
for i = 1:20
    subplot_tight(4,5,i,[0.02,0.02]); 
    plot(nanmean(nanmean(s2a1{i}(neuronC,:,:),1),3)); hold on; 
    plot(nanmean(nanmean(s2a2{i}(neuronC,:,:),1),3));

    xline(31); xline(31-round(nanmean(rt21{i})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{i})*15),'--','Color',matlabColors(2));  
    xticks([]); yticks([]);
end 

figure; 
for i = 1:20
    subplot_tight(4,5,i,[0.02,0.02]); 
    plot(nanmean(nanmean(s2a1{i}(neuronCR,:,:),1),3)); hold on; 
    plot(nanmean(nanmean(s2a2{i}(neuronCR,:,:),1),3));

    xline(31); xline(31-round(nanmean(rt21{i})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{i})*15),'--','Color',matlabColors(2));  
    xticks([]); yticks([]);
end 
figure; 
for i = 1:20
    subplot_tight(4,5,i,[0.02,0.02]); 
    plot(nanmean(nanmean(s4a1{i}(neuronR,:,:),1),3)); hold on; 
    plot(nanmean(nanmean(s4a2{i}(neuronR,:,:),1),3));

    xline(31); xline(31-round(nanmean(rt21{i})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{i})*15),'--','Color',matlabColors(2));  
    xticks([]); yticks([]);
end 

figure; 
for i = 1:20
    subplot_tight(4,5,i,[0.02,0.02]); 
    plot(nanmean(nanmean(s4a1{i}(neuronC,:,:),1),3)); hold on; 
    plot(nanmean(nanmean(s4a2{i}(neuronC,:,:),1),3));

    xline(31); xline(31-round(nanmean(rt21{i})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{i})*15),'--','Color',matlabColors(2));  
    xticks([]); yticks([]);
end 

figure; 
for i = 1:20
    subplot_tight(4,5,i,[0.02,0.02]); 
    plot(nanmean(nanmean(s4a1{i}(neuronCR,:,:),1),3)); hold on; 
    plot(nanmean(nanmean(s4a2{i}(neuronCR,:,:),1),3));

    xline(31); xline(31-round(nanmean(rt21{i})*15),'--','Color',matlabColors(1)); 
    xline(31-round(nanmean(rt22{i})*15),'--','Color',matlabColors(2));  
    xticks([]); yticks([]);
end 


%% do PCA
outmat = cellfun(@(x)(nanmean(x,3)),outmatTrial, 'UniformOutput',false);
outmat = fn_cell2mat(outmat,3);
outmat = outmat(:,21:50,:);

outmat_pca = reshape(outmat,[size(outmat,1), size(outmat,2)*size(outmat,3)]);

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(outmat_pca);
figure; 
for k = 1:10
    subplot(2,5,k)
    plot(COEFF(1:30,k)); hold on; plot(COEFF(31:60,k)); xlim([1 30]);
    xline(11);% xline(nanmean(RTshift)); yticks([]);
end 


%% all functions

function outmat = organizeDataInDay(matCell,daySel)
    outmat = cellfun(@(x)(x{daySel}),matCell,'UniformOutput',false);
end 

function [outmat,outmatLabel,dayLabel] = organizeDataMultiDay(matCell,daySel)
    dayLabel = []; trialCount = 0; 
    for i =1:length(daySel)
        outmat{i} = cellfun(@(x)(x{daySel(i)}),matCell,'UniformOutput',false);
        outmatLabel{i} = [zeros(1,size(outmat{i}{1},3)), ones(1,size(outmat{i}{2},3))];
        outmat{i} = cat(3,outmat{i}{1},outmat{i}{2});
        dayLabel(trialCount+1:trialCount+length(outmatLabel{i})) = i;
        trialCount = trialCount + length(outmatLabel{i});
    end 
end 

function [selmat,selFlag] = selTrialType(inmat, inbeh, stim, choice)
    selFlag = cellfun(@(x)(x.stimuli==stim & x.choice==choice), inbeh,'UniformOutput',false);
    if size(inmat{1},3) == 1
        if size(inmat{1},2) ==1
            selmat = cellfun(@(x,y)(x(y)),inmat,selFlag,'UniformOutput',false);
        else
            selmat = cellfun(@(x,y)(x(:,y)),inmat,selFlag,'UniformOutput',false);
        end 
    else
        selmat = cellfun(@(x,y)(x(:,:,y)),inmat,selFlag,'UniformOutput',false);
    end 

    emptyFlag = [];
    for i = 1:length(selmat)
        if ndims(selmat{i}) == 3 & size(selmat{i},3) <5; emptyFlag = [emptyFlag i]; end 
        if isempty(selmat{i}); emptyFlag = [emptyFlag i]; end 
    end 
    selmat(emptyFlag) = []; 

end

function [Xscores, XL, PCTVAR, Xproj, XL_tensor] = runPLSDA(data, labels, nComponents)
% RUNPLSDA - Perform PLS-DA on neural data (neurons × time × trials)
%
% Inputs:
%   - data: [neurons × time × trials] neural activity
%   - labels: [1 × trials] binary labels (0 or 1)
%   - nComponents: number of components to extract
%
% Outputs:
%   - Xscores: [trials × components] projected latent variables
%   - XL: [features × components] original projection matrix (flat)
%   - PCTVAR: variance explained in X and Y
%   - Xproj: [components × time × trials] projected time courses
%   - XL_tensor: [neurons × time × components] reshaped weights

    [nNeurons, nTime, nTrials] = size(data);
    X = reshape(data, nNeurons * nTime, nTrials)';  % [trials × features]
    labels = labels(:);
    if ~all(ismember(labels, [0,1]))
        error('Labels must be binary (0 or 1).');
    end

    Y = dummyvar(labels + 1);  % Convert to [nTrials × 2]

    % Run PLS
    [XL, YL, Xscores, Yscores, beta, PCTVAR] = plsregress(X, Y, nComponents);

    % Reshape XL to [neurons × time × components]
    XL_tensor = reshape(XL, nNeurons, nTime, nComponents);

    % Project each trial’s data onto each component over time
    Xproj = zeros(nComponents, nTime, nTrials);
    for i = 1:nTrials
        trialData = squeeze(data(:,:,i));  % [neurons × time]
        for c = 1:nComponents
            weights = XL_tensor(:,:,c);    % [neurons × time]
            Xproj(c,:,i) = sum(trialData .* weights, 1);  % weighted sum across neurons
        end
    end

    % Optional: plot 2D scatter of latent projections
    figure;
    scatter(Xscores(labels==0,1), Xscores(labels==0,2), 50, 'b', 'filled'); hold on;
    scatter(Xscores(labels==1,1), Xscores(labels==1,2), 50, 'r', 'filled');
    xlabel(['Component 1, exp. var: ' num2str(PCTVAR(2,1),'%.2f')]); 
    ylabel(['Component 2, exp.var: ' num2str(PCTVAR(2,2),'%.2f')]);
    legend('choice L','choice R');
    title('PLS-DA projection, stimR trials');
    grid on;
end


