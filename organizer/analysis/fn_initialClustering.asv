function [ani] = fn_initialClustering(ani,varargin)
    % Note: the ani input ideally should be well tracking -- i.e. passed
    % through tracking function ani = ani.parseDay('tracking')
    p = inputParser;
    addParameter(p, 'secondCluster', true);
    addParameter(p, 'secondClusterSelect', 1);
    parse(p, varargin{:});
    
    % step 0.1 -- chunk days and select behavior and dff days that allow tracking of 
    timeSel = 21:45;
    outTable = ani.chunkDays({[1 2 3],[4 5],[6 8 9],[10 11 12],[13 14 15 16],[17 18 19],[20 21]},{'dffChoice','behSel'});
    selAct = cellfun(@(x)(x(ani.dayInfo.ishereAll{1},timeSel,:)),outTable.dffChoice,'UniformOutput',false);
    

    stim = {1,1,2,2,3,3,4,4}; choice = {1,2,1,2,1,2,1,2};
    [selActStim,selLabel,selFlag] = selTrialType(selAct, outTable.behSel, stim, choice);
    
    %selAct = cellfun(@(x,y)(x(y,timeSel,:)),ani.dayInfo.dffChoice,ani.dayInfo.ishereAll,'UniformOutput',false);
    %selWheel = cellfun(@(x)(x(timeSel,:)),ani.dayInfo.wheelChoice,'UniformOutput',false);
    %selBehav = ani.dayInfo.behSel;
    %T1acc = fn_cell2mat(ani.dayInfo.T1acc);
    %T2acc = fn_cell2mat(ani.dayInfo.T2acc); 

    %tempRT = cellfun(@(x)(x.RT),selBehav,'UniformOutput',false);
    %[rt21,selFlag21] = selTrialType(tempRT, selBehav, 2, 1);
    %[rt22,selFlag22] = selTrialType(tempRT, selBehav, 2, 2);
    
    %[rt41,selFlag21] = selTrialType(tempRT, selBehav, 4, 1);
    %[rt42,selFlag22] = selTrialType(tempRT, selBehav, 4, 2);
    
    % step 1.0 -- select behavior and dff days that allow tracking of 
    

    outmatTrialMultiDay_umap = cat(3,selActStim{:}); 
    outmatTrialMultiDay_umap = double(reshape(outmatTrialMultiDay_umap,size(outmatTrialMultiDay_umap,1), []));
    
    outmatTrialMultiDay_umap = normalize(outmatTrialMultiDay_umap,2);
    [reducedData_umap, umapStruct, clusterStruct] = run_umap(outmatTrialMultiDay_umap,...
        'n_neighbors', 50,'metric','euclidean', 'min_dist', 0.01, 'n_components', 3, 'n_epochs',600);

    [k, k_opt] = fn_hierarchicalClusteringGetK(outmatTrialMultiDay_umap, 2:10,'ward','euclidean');
    [labels, Z] = fn_hierarchicalClustering(outmatTrialMultiDay_umap, k,'ward','euclidean' ); xticks([]);
    
    figure;subplot(1,3,1);
    for i = 1:k
        scatter3(reducedData_umap(labels==i,1),reducedData_umap(labels==i,2),reducedData_umap(labels==i,3)); hold on;
    end 
    subplot(1,3,2);
    plot(squeeze(nanmean(selActStim{8}(labels==1,:,:),1))); hold on; xlabel('time from choice reached'); xline(10); 
    xticks([1 10 25]);xticklabels({'-0.66', '0','1'});
    subplot(1,3,3);
    plot(squeeze(nanmean(selActStim{8}(labels==2,:,:),1))); hold on; xlabel('time from choice reached'); xline(10);
    xticks([1 10 25]);xticklabels({'-0.66', '0','1'});

    ishereIdx = find(ani.dayInfo.ishereAll{1});
    tempLabelFlag = zeros(size(ani.dayInfo.ishereAll{1}));
    for i = 1:max(labels)
        tempLabelFlag(ishereIdx(labels==i)) = i; 
    end 
    ani.analysis.initialClustering.label = tempLabelFlag;
    ani.analysis.initialClustering.proj = reducedData_umap;
    ani.analysis.initialClustering.method = 'umap'; 

    

    if p.Results.secondCluster
        disp(['Doing 2nd clustering, using cluster ' int2str(p.Results.secondClusterSelect) ' from initial clustering'])
        outmatTrialMultiDay_umapnew = outmatTrialMultiDay_umap(labels==p.Results.secondClusterSelect,:);
        [reducedData_umapnew, umapStruct, clusterStruct] = run_umap(outmatTrialMultiDay_umapnew,...
            'n_neighbors', 10,'metric','euclidean', 'min_dist', 0.001, 'n_components', 3, 'n_epochs',1200);
        [k, k_opt] = fn_hierarchicalClusteringGetK(outmatTrialMultiDay_umapnew, 2:10,'ward','euclidean');
        [labelsnew, Z] = fn_hierarchicalClustering(outmatTrialMultiDay_umapnew, k,'ward','euclidean' ); xticks([])

        cluter1Idx = find(ani.analysis.initialClustering.label==p.Results.secondClusterSelect);
        tempLabelFlag2 = zeros(size(ani.dayInfo.ishereAll{1}));

        for i = 1:max(labelsnew)
            tempLabelFlag2(cluter1Idx(labelsnew==i)) = i; 
        end 
        ani.analysis.secondClustering.label = tempLabelFlag2;
        ani.analysis.initialClustering.proj = reducedData_umapnew;
        ani.analysis.initialClustering.method = 'umap'; 

        figure;
        for i = 1:k
            scatter3(reducedData_umapnew(labelsnew==i,1),reducedData_umapnew(labelsnew==i,2),reducedData_umapnew(labelsnew==i,3)); hold on;
        end 
        tempData = selActStim{4}(labels==1,:,:);
        figure; subplot(1,4,1);
        plot(squeeze(nanmean(tempData(labelsnew==1,:,:),1))); hold on; 
        subplot(1,4,2);
        plot(squeeze(nanmean(tempData(labelsnew==2,:,:),1))); hold on; 
        subplot(1,4,3);
        plot(squeeze(nanmean(tempData(labelsnew==3,:,:),1))); hold on; 
        subplot(1,4,4);
        plot(squeeze(nanmean(tempData(labelsnew==4,:,:),1))); hold on; 

    end 
end 

function [outmat,label,selFlag] = selTrialType(inmat, inbeh, stim, choice)
    if ~iscell(stim); stim = {stim}; end
    for i = 1:length(stim)
        selFlag = cellfun(@(x)(x.stimuli==stim{i} & x.choice==choice{i}), inbeh,'UniformOutput',false);
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
        for k = 1:length(selmat)
            if ndims(selmat{k}) == 3 & size(selmat{k},3) <5; emptyFlag = [emptyFlag k]; end 
            if isempty(selmat{k}); emptyFlag = [emptyFlag k]; end 
        end 
        selmat(emptyFlag) = []; 
        outmat{i} = fn_cell2mat(cellfun(@(x)(nanmean(x,3)),selmat,'UniformOutput',false),3);
        label{i} = ['s' int2str(stim{i}) 'a' int2str(choice{i})]; 
    end 
end