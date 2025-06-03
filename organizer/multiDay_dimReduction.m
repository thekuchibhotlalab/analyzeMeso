%% load animal data
clear; 
tic; ani = Animal('zz153_PPC','spk'); ani = ani.getBehav; toc;
tic; ani = ani.parseTrial; toc; ani = ani.parseDay;

%% step 0.0 -- new session selection method
[ishereDay,sessionCount,sessionSel] = ani.selTracking();
ani = ani.parseDay('tracking');
figure; subplot(1,2,1);
plot(sessionCount); xline(ani.ops.trackingSessionSel);
subplot(1,2,2); 
daySel = unique(ani.sessionInfo.SessionDay(sessionSel{ani.ops.trackingSessionSel}));
scatter(1:length(daySel),daySel);

ani = fn_initialClustering(ani);
%% step 0.1 -- do two-step clustering, this help us select 



%% step 0.2 -- organize data, concatanate multi-trial-type, multi-day into  
% 
% [s2a1,selFlag21] = selTrialType(selAct, selBehav, 2, 1);
% [s2a2,selFlag22] = selTrialType(selAct, selBehav, 2, 2);
% [s1a1,selFlag11] = selTrialType(selAct, selBehav, 1, 1);
% [s1a2,selFlag12] = selTrialType(selAct, selBehav, 1, 2);
% 
% [s4a1,selFlag21] = selTrialType(selAct, selBehav, 4, 1);
% [s4a2,selFlag22] = selTrialType(selAct, selBehav, 4, 2);
% [s3a1,selFlag11] = selTrialType(selAct, selBehav, 3, 1);
% [s3a2,selFlag12] = selTrialType(selAct, selBehav, 3, 2);
% 
% tempRT = cellfun(@(x)(x.RT),selBehav,'UniformOutput',false);
% [rt21,selFlag21] = selTrialType(tempRT, selBehav, 2, 1);
% [rt22,selFlag22] = selTrialType(tempRT, selBehav, 2, 2);
% 
% [rt41,selFlag21] = selTrialType(tempRT, selBehav, 4, 1);
% [rt42,selFlag22] = selTrialType(tempRT, selBehav, 4, 2);

% %% check dPCA
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


