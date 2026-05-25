load('TCA-nonneg_zz153_159PPC_spkNorm_cluster1.mat','M','VEpct');
M_all = M;
%% plot
nModel = 12; M = M_all{nModel};
TCs = [10 7 9];
%TCs = [3 4 5];
figure;
RTtemp = 0.6; %RTtemp = nanmean(matchedRT(:));

for i = 1:length(TCs)
    nTC = TCs(i);
    %subplot(length(TCs),4,1 + 4*(i-1));
    %[sortedW] = sort(M.U{1}(:,nTC),'ascend'); hold on;
    %plot((1:length(sortedW))/length(sortedW),sortedW,'LineWidth',2,'Color',matlabColors(1)); yline(0); 

    %title('Neural Weight');
    %title(['TC' int2str(nTC) ' lambda=' num2str(M{nModel}.lambda(nTC))]);
    %ylim([0 0.025])
    subplot(length(TCs),4,1 + 4*(i-1));hold on;
    bar(M.lambda,'EdgeColor','none',"FaceColor",[0.8 0.8 0.8]);  
    bar(nTC,M.lambda(nTC),'EdgeColor','none',"FaceColor",matlabColors(4,0.9)); 


    subplot(length(TCs),4,2 + 4*(i-1));hold on;
    nTime = size(M.U{2}(:,nTC),1); timeAxis = ((1:nTime)-10)/15;
    plot(timeAxis,M.U{2}(:,nTC),'Linewidth',2,'Color',matlabColors(4,0.9)); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    hold on; 
    ylim([0 0.5])
    xline(RTtemp,'--')

    subplot(length(TCs),4,3 + 4*(i-1));hold on;
    plot(M.U{3}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(4,0.9) ); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])
    hold on; xticks(1:4); xticklabels({'E','M','L','Int'}); title('Learning Phase'); ylim([0 1])


    subplot(length(TCs),4,4 + 4*(i-1));hold on;
    plot(M.U{4}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(4,0.9)); yline(0); title('Trial Type');xlim([0 5]); ylim([0 1.2])
    hold on; xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});ylim([0 1])
    xline(2.5)

end 

%% 
load('outDffMat_PPC_zz153_spkNorm.mat','outDffMat');
outDffMat1 = outDffMat;
load('outDffMat_PPC_zz159_spkNorm.mat','outDffMat');
outDffMat2 = outDffMat;
outDffMat = cat(1,outDffMat1,outDffMat2);outDffMat(isnan(outDffMat(:,1,1,1)),:,:,:) = [];
%%
load('outDffMat_zz153_zz159_PPC_complete_learning','outDffMat');

plotTC = 9; M1 = M_all{12};
neuralW = M1.U{1};
figure; subplot(1,2,1);imagesc(neuralW); caxis([0 0.004]);subplot(1,2,2); imagesc(corr(neuralW))
%bestTC = [];
%for i = 1:size(neuralW,1)
%    [~,bestTC(i)] = max(neuralW(i,:));
%end 
[tempW, tempIdx] = sort(neuralW(:,plotTC),'descend'); 
%selMat = outDffMat(bestTC==plotTC,:,:,:);
selMat = outDffMat(tempIdx(4),:,:,:);

timeAxis = ((1:30)-11)/15;
figure; 
for i = 1:7
    subplot(2,7,i);
    fn_plotMeanErrorbar(timeAxis,selMat(:,:,i,1),multitaskColors('s1a1'),multitaskColors('s1a1') ,...
        {'LineWidth',2.5},{'FaceAlpha',0.4}); hold on;
    fn_plotMeanErrorbar(timeAxis,selMat(:,:,i,2),multitaskColors('s2a2'),multitaskColors('s2a2') ,...
        {'LineWidth',2.5},{'FaceAlpha',0.4}); ylim([0 0.04])
    xline(0); xline(0.62); xticklabels(''); yticklabels('');
    subplot(2,7,i+7);
    fn_plotMeanErrorbar(timeAxis,selMat(:,:,i,3),multitaskColors('s3a1'),multitaskColors('s3a1') ,...
        {'LineWidth',2.5},{'FaceAlpha',0.4}); hold on;
    fn_plotMeanErrorbar(timeAxis,selMat(:,:,i,4),multitaskColors('s4a2'),multitaskColors('s4a2') ,...
        {'LineWidth',2.5},{'FaceAlpha',0.4}); ylim([0 0.04])
    xline(0);xline(0.62);
    xticklabels(''); yticklabels('');

end 

%% get data from all 7 days


datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);
load([datapath aniPPC filesep aniPPC '_trialTypeInfo.mat'], 'clusterLabel');

[outDff,~,outCounts,matchedRT] = RTmatch(dataPPC.trialTypeInfo);

outDff = cellfun(@(x)(nanmean(x,3)), outDff,'UniformOutput',false);
outDffMat= nan(size(outDff{1,1},1),size(outDff{1,1},2),size(outDff,1),size(outDff,2));

for i = 1:size(outDff,1)
    for j = 1:size(outDff,2)
        try
            outDffMat(:,:,i,j) = outDff{i,j};
        catch
        end 
    end 
end 
outDffMat = outDffMat(clusterLabel==1,:,:,:);
%% function
function [outDffnew,selected_flags,selected_counts,new_means] = RTmatch(trialTypeInfo)
    nPeriod = length(trialTypeInfo.behSelTrialType); 
    nTrialType = length(trialTypeInfo.behSelTrialType{1});
    RT = {}; outDff = {};  
    for i = 1:length(trialTypeInfo.behSelTrialType)
        RT(i,:) = cellfun((@(x)(x.RT)),trialTypeInfo.behSelTrialType{i},'UniformOutput',false);
        outDff(i,:) = cellfun((@(x)(x)),trialTypeInfo.dffStim{i},'UniformOutput',false);
    end
    RT_T1 = RT([1:6 7],[1 4]); RT_T2 = RT([1:6 7],[5 8]);

    outDffRaw = outDff;
    outDffSel1 = outDff([1:6 7],[1 4]); outDffSel2 = outDff([1:6 7],[5 8]);
    outDff = cat(2,outDffSel1,outDffSel2);

    RT_T = cat(2,RT_T1,RT_T2);
    options.min_trials_percentage = 0.2; 
    options.tolerance = 0.3; 
    [selected_flags, selected_counts, new_means] = selectMatchedTrials(RT_T,options);

    outDff = cellfun((@(x,y)(x(:,:,y))),outDff,selected_flags,'UniformOutput',false);
    %outDffnew = cell(7,4);
    %outDffnew([1:3 7],1:2) = outDff(1:4,1:2);
    %outDffnew(4:7,3:4) = outDff(1:4,3:4);
    %outDffnew(4:6,1:2) = outDffRaw(5:7,[1 4]);
    outDffnew = outDff;
end 

% HELPTER FUNCTION -- MATCH RT IN TRIALTYPEINFO
function [selected_flags, selected_counts, new_means] = selectMatchedTrials(rt_cell, options)
    % Selects a subset of trials from a cell matrix to match the global average reaction time.
    %
    % INPUTS:
    %   rt_cell - A cell matrix where each element is a vector of reaction times.
    %   options - A struct with fields:
    %             .min_trials_percentage (e.g., 0.5) - Minimum percentage of trials to keep.
    %             .tolerance (e.g., 0.05) - Allowed fractional deviation from the global mean.
    %
    % OUTPUTS:
    %   selected_flags  - Cell array of the same size as rt_cell, containing logical
    %                     vectors indicating which trials were selected.
    %   selected_counts - Matrix of the same size, showing the number of selected trials.
    %   new_means       - Matrix of the same size, showing the new mean reaction time.

    [rows, cols] = size(rt_cell);

    % --- Step 1: Calculate Global Mean Reaction Time ---
    % Concatenate all non-empty trial vectors into a single large vector
    all_trials = cat(1, rt_cell{:});
    if isempty(all_trials)
        error('Input cell array contains no data.');
    end
    global_mean_rt = mean(all_trials);
    fprintf('Global mean reaction time across all trials: %.2f ms\n', global_mean_rt);

    % Define the acceptable range for the new means
    tolerance_value = global_mean_rt * options.tolerance;
    lower_bound = global_mean_rt - tolerance_value;
    upper_bound = global_mean_rt + tolerance_value;
    fprintf('Target range for new means: [%.2f, %.2f] ms\n\n', lower_bound, upper_bound);

    % --- Step 2: Initialize Output Variables ---
    selected_flags = cell(rows, cols);
    selected_counts = NaN(rows, cols);
    new_means = NaN(rows, cols);

    % --- Step 3: Iterate Through Each Condition and Select Trials ---
    for r = 1:rows
        for c = 1:cols
            trials_vector = rt_cell{r, c};

            % Skip if the cell is empty (NaN condition)
            if isempty(trials_vector)
                continue;
            end

            n_original = length(trials_vector);
            min_trials_to_keep = ceil(n_original * options.min_trials_percentage);

            % Keep track of which trials are currently selected
            current_selection_indices = 1:n_original;
            current_trials = trials_vector;
            
            % --- Iterative Removal Loop ---
            % This loop removes one trial at a time to bring the cell's mean
            % closer to the global mean, until it's within tolerance or the
            % minimum number of trials is reached.
            while true
                current_mean = mean(current_trials);
                
                % Check stopping conditions
                if length(current_trials) <= min_trials_to_keep
                    % Stop if we've hit the minimum trial count
                    break; 
                end
                if current_mean >= lower_bound && current_mean <= upper_bound
                    % Stop if the mean is within the target range
                    break;
                end

                % Decide which trial to remove
                if current_mean > global_mean_rt
                    % If mean is too high, removing the LARGEST value will help most.
                    [~, idx_to_remove] = max(current_trials);
                else
                    % If mean is too low, removing the SMALLEST value will help most.
                    [~, idx_to_remove] = min(current_trials);
                end
                
                % Remove the trial from our current selection
                current_trials(idx_to_remove) = [];
                current_selection_indices(idx_to_remove) = []; % Keep original indices aligned
            end

            % --- Step 4: Store the Results for this Condition ---
            % Create the final logical flag vector
            flags = false(1, n_original);
            flags(current_selection_indices) = true;
            
            selected_flags{r, c} = flags;
            selected_counts(r, c) = length(current_trials);
            new_means(r, c) = mean(current_trials);
        end
    end
end
