function [ani] = fn_initialClustering(ani,varargin)
    % Note: the ani input ideally should be well tracking -- i.e. passed
    % through tracking function ani = ani.parseDay('tracking')
    p = inputParser;
    addParameter(p, 'selDff', 'dffChoice');
    addParameter(p, 'selWheel', 'wheelChoice');
    addParameter(p, 'secondCluster', true);
    addParameter(p, 'secondClusterSelect', 1);
    parse(p, varargin{:});
    
    % step 0.1 -- chunk days and select behavior and dff days that allow tracking of 
    selTime = 11:45;
    [ani] = ani.chunkDaysByTrialType({p.Results.selDff,p.Results.selWheel,'behSel'},'selTime',selTime);
    %[ani] = ani.chunkDaysByTrialType({p.Results.selDff,'behSel'},'selTime',selTime);
    outmat = ani.trialTypeInfo;
    
    % step 1.0 -- do initial clusering based on the 
    
    dffChoice = cat(1,outmat.dffChoice{:}); 
    behSel = cat(1,outmat.behSelTrialType{:}); 
    
    selTrialType = dffChoice(:,:); selTrialCount = cellfun(@(x)(size(x,3)),selTrialType);
    selTrialType = cellfun(@(x)(nanmean(x,3)),selTrialType,'UniformOutput',false);
    selTrialTypeFlat = cat(3,selTrialType{:}); 
    outmatTrialMultiDay_umap = selTrialTypeFlat(:,:,selTrialCount(:)>5);

    outmatTrialMultiDay_umap = double(reshape(outmatTrialMultiDay_umap,size(outmatTrialMultiDay_umap,1), []));
    
    outmatTrialMultiDay_umap = normalize(outmatTrialMultiDay_umap,2);
    [reducedData_umap, umapStruct, clusterStruct] = run_umap(outmatTrialMultiDay_umap,...
        'n_neighbors', 50,'metric','euclidean', 'min_dist', 0.01, 'n_components', 3, 'n_epochs',600);

    [k, k_opt] = fn_hierarchicalClusteringGetK(outmatTrialMultiDay_umap, 2:10,'ward','euclidean');
    [labels, Z] = fn_hierarchicalClustering(outmatTrialMultiDay_umap, k,'ward','euclidean' ); xticks([]);
    
    clusterNum = max(labels);
    totalPlot = clusterNum+1; 
    figure;subplot(1,totalPlot,1);
    for i = 1:k
        scatter3(reducedData_umap(labels==i,1),reducedData_umap(labels==i,2),reducedData_umap(labels==i,3)); hold on;
    end 
    tempPlot = cat(3,selTrialType{:,4}); % plot rewarded stim 4
    for i = 1:clusterNum
        subplot(1,totalPlot,1+i);
        plot(squeeze(nanmean(tempPlot(labels==i,:,:),1))); hold on; xlabel('time from choice reached'); xline(20); 
        xticks([5 20 35]);xticklabels({'-1', '0','1'});
    end 

    ishereIdx = find(ani.ops.ishereAll);
    tempLabelFlag = zeros(size(ani.ops.ishereAll));
    for i = 1:max(labels)
        tempLabelFlag(ishereIdx(labels==i)) = i; 
    end 
    ani.analysis.initialClustering.labelTracked = labels;
    ani.analysis.initialClustering.labelAll = tempLabelFlag;
    ani.analysis.initialClustering.proj = reducedData_umap;
    ani.analysis.initialClustering.method = 'umap'; 

    % step 2.0 -- do second clusering

    if p.Results.secondCluster
        disp(['Doing 2nd clustering, using cluster ' int2str(p.Results.secondClusterSelect) ' from initial clustering'])
        outmatTrialMultiDay_umapnew = outmatTrialMultiDay_umap(labels==p.Results.secondClusterSelect,:);
        [reducedData_umapnew, umapStruct, clusterStruct] = run_umap(outmatTrialMultiDay_umapnew,...
            'n_neighbors', 10,'metric','euclidean', 'min_dist', 0.001, 'n_components', 3, 'n_epochs',1200);
        [k, k_opt] = fn_hierarchicalClusteringGetK(outmatTrialMultiDay_umapnew, 2:10,'ward','euclidean');
        [labelsnew, Z] = fn_hierarchicalClustering(outmatTrialMultiDay_umapnew, k,'ward','euclidean' ); xticks([])

        cluter1Idx = find(ani.analysis.initialClustering.labelTracked==p.Results.secondClusterSelect);
        tempLabelFlag2 = zeros(size(ani.analysis.initialClustering.labelTracked));

        for i = 1:max(labelsnew)
            tempLabelFlag2(cluter1Idx(labelsnew==i)) = i; 
        end 
        ani.analysis.secondClustering.labelTracked = tempLabelFlag2;

        cluter1Idx = find(ani.analysis.initialClustering.labelAll==p.Results.secondClusterSelect);
        tempLabelFlag2 = zeros(size(ani.analysis.initialClustering.labelAll));

        for i = 1:max(labelsnew)
            tempLabelFlag2(cluter1Idx(labelsnew==i)) = i; 
        end 
        ani.analysis.secondClustering.labelAll = tempLabelFlag2;

        ani.analysis.secondClustering.proj = reducedData_umapnew;
        ani.analysis.secondClustering.method = 'umap'; 

        figure;
        for i = 1:k
            scatter3(reducedData_umapnew(labelsnew==i,1),reducedData_umapnew(labelsnew==i,2),reducedData_umapnew(labelsnew==i,3),'filled'); hold on;
        end 
        tempData = tempPlot(labels==1,:,:);
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