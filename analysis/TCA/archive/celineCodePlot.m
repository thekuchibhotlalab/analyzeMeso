% Default values
mice = {'cd017','cd036','cd019','cd042','cd041','cd044','cd037','zz033'};
exp = [1;1;2;1;2;1;1;2]; % 1=GNG, 2= PASSIVE
nR = 20; % number of ranks
pretone = 1; % for PSTH tone, in s
posttone = 4; % for PSTH tone, in s
gray = [0.8 0.8 0.8];
acq = 15.49;
fa_color = [255 159 25]/255; % orange
cr_color = [255 207 25]/255; % yellow
m_color = [47 122 182]/255;
h_color = [47 196 182]/255;
% colors_outcomes = {h_color,fa_color,cr_color};
% labels_outcomes = {'H','FA','CR'};
nComponents = nan(length(mice),1);
outcomes_comp = cell(length(mice),1);
weights_comp = cell(length(mice),1);
colors_mice = {'b','g','y','r',gray,'c','k'};
clear ndims
plotcomponents = true;
DAY = 1;
BLOC = 2;
TRIAL = 3;
CONTEXT = 4;
RESP = 5;
nPlanes = 2;
nframes_psth = pretone*round(acq) + posttone*round(acq);
x_psth = linspace(-pretone,posttone,nframes_psth);
path = 'M:\Celine\exci_variables\';
pathsave = 'H:\celine\TCA_variables\';

%% Load variables
       
% % DF/F, probe+reinf, 4D tensor (blocs + trial type), ALS decomposition
% fits = load([pathsave 'Allmice_TCA_ALS_acqexp_dff_negok_fits.mat'],'fits');
% scores_tobestfit = load([pathsave 'Allmice_TCA_ALS_acqexp_dff_negok_scores_tobestfit.mat'],'scores_tobestfit');
% inits = load([pathsave 'Allmice_TCA_ALS_acqexp_dff_negok_inits.mat'],'inits');
% models = load([pathsave 'Allmice_TCA_ALS_acqexp_dff_negok_models.mat'],'models');
% outputs = load([pathsave 'Allmice_TCA_ALS_acqexp_dff_negok_outputs.mat'],'outputs');
% fulltrace = true;
% nonnegative = false;
% dfftrace = true;

% % DF/F, probe+reinf, 4D tensor (blocs + trial type), ALS decomposition
% fits = load([pathsave 'AllGNG_TCA_ALS_acqexp_dff_negok_fits.mat'],'fits');
% scores_tobestfit = load([pathsave 'AllGNG_TCA_ALS_acqexp_dff_negok_scores_tobestfit.mat'],'scores_tobestfit');
% inits = load([pathsave 'AllGNG_TCA_ALS_acqexp_dff_negok_inits.mat'],'inits');
% models = load([pathsave 'AllGNG_TCA_ALS_acqexp_dff_negok_models.mat'],'models');
% outputs = load([pathsave 'AllGNG_TCA_ALS_acqexp_dff_negok_outputs.mat'],'outputs');
% fulltrace = true;
% nonnegative = false;
% dfftrace = true;
% passive = false;
    
% % DF/F, probe+reinf, 4D tensor (blocs + trial type), ALS decomposition
% fits = load([pathsave 'AllPASSIVE_TCA_ALS_acqexp_dff_negok_fits.mat'],'fits');
% scores_tobestfit = load([pathsave 'AllPASSIVE_TCA_ALS_acqexp_dff_negok_scores_tobestfit.mat'],'scores_tobestfit');
% inits = load([pathsave 'AllPASSIVE_TCA_ALS_acqexp_dff_negok_inits.mat'],'inits');
% models = load([pathsave 'AllPASSIVE_TCA_ALS_acqexp_dff_negok_models.mat'],'models');
% outputs = load([pathsave 'AllPASSIVE_TCA_ALS_acqexp_dff_negok_outputs.mat'],'outputs');
% fulltrace = true;
% nonnegative = false;
% dfftrace = true;
% passive = true;

% % DF/F, probe+reinf, 4D tensor (blocs + trial type), ALS decomposition
% fits = load([pathsave 'POOLED_TCA_ALS_acqexp_dff_negok_fits.mat'],'fits');
% scores_tobestfit = load([pathsave 'POOLED_TCA_ALS_acqexp_dff_negok_scores_tobestfit.mat'],'scores_tobestfit');
% inits = load([pathsave 'POOLED_TCA_ALS_acqexp_dff_negok_inits.mat'],'inits');
% models = load([pathsave 'POOLED_TCA_ALS_acqexp_dff_negok_models.mat'],'models');
% outputs = load([pathsave 'POOLED_TCA_ALS_acqexp_dff_negok_outputs.mat'],'outputs');
% fulltrace = true;
% nonnegative = false;
% dfftrace = true;
% passive = false;
% both = true;

% % DF/F, probe+reinf, 4D tensor (blocs + trial type), ALS decomposition
% fits = load([pathsave 'POOLED_TCA_ALS_zdff_negok_fits.mat'],'fits');
% scores_tobestfit = load([pathsave 'POOLED_TCA_ALS_zdff_negok_scores_tobestfit.mat'],'scores_tobestfit');
% inits = load([pathsave 'POOLED_TCA_ALS_zdff_negok_inits.mat'],'inits');
% models = load([pathsave 'POOLED_TCA_ALS_zdff_negok_models.mat'],'models');
% outputs = load([pathsave 'POOLED_TCA_ALS_zdff_negok_outputs.mat'],'outputs');
% fulltrace = true;
% nonnegative = false;
% dfftrace = true;
% passive = false;
% both = true;

% DF/F, probe+reinf, 4D tensor (blocs + trial type), ALS decomposition
% only H and FA (M and CR for Passive, 10 of each in each bloc
fits = load([pathsave 'AllGNG_TCA_ALS_noZero_10equal_dff_negok_fits.mat'],'fits');
scores_tobestfit = load([pathsave 'AllGNG_TCA_ALS_noZero_10equal_dff_negok_scores_tobestfit.mat'],'scores_tobestfit');
inits = load([pathsave 'AllGNG_TCA_ALS_noZero_10equal_dff_negok_inits.mat'],'inits');
models = load([pathsave 'AllGNG_TCA_ALS_noZero_10equal_dff_negok_models.mat'],'models');
outputs = load([pathsave 'AllGNG_TCA_ALS_noZero_10equal_dff_negok_outputs.mat'],'outputs');
fulltrace = true;
nonnegative = false;
dfftrace = true;
passive = false;
both = false;
both2 = true;

fits = fits.fits;
scores_tobestfit = scores_tobestfit.scores_tobestfit;
models = models.models;
inits = inits.inits;
outputs = outputs.outputs;
%%  
if passive
    colors_outcomes = {m_color,cr_color};
    labels_outcomes = {'MISS','CR'};
    outcomes = 2;
    PASSs = find(exp==2);
    nPASS = length(PASSs);
    nCellsPerMouse = [555;547;1197];
    nCellsPerMouse = [1;cumsum(nCellsPerMouse)];
    intervalsCells = [nCellsPerMouse(1:end-1) nCellsPerMouse(2:end)];
    tosave = {mat,nBlocTarget_acqui,nBlocTarget_expert,count_behavior};
    someresults = load([pathsave '-TCA_tensor_init_passive.mat']);
    someresults = someresults.tosave;
    mat = someresults{1};
    nBlocTarget_acqui = someresults{2};
    nBlocTarget_expert = someresults{3};
    count_behavior = someresults{4};
elseif both
    colors_outcomes = {h_color,fa_color,cr_color};
    labels_outcomes = {'Target','FA','CR'};
    outcomes = 3;
    nCellsPerMouse = [197;429;221;546;555;547;1197];
    nCellsPerMouse = [1;cumsum(nCellsPerMouse)];
    intervalsCells = [nCellsPerMouse(1:end-1) nCellsPerMouse(2:end)];
    intervalsCells(2:end,1) = intervalsCells(2:end,1)+1;
    someresults = load([pathsave '-TCA_tensor_init_GNG.mat']);
    someresults = someresults.tosave;
%     mat = someresults{1};
    total_nblocs = size(someresults{1},3);
    nBlocTarget_acqui = someresults{2};
    nBlocTarget_expert = total_nblocs-someresults{3};
    count_behavior = someresults{4};
    
    original_mat = load([pathsave '-TCA_tensor_init_POOLED.mat']);
    mat = original_mat.mat_concat;
    noZmat = mat;
    if ~dfftrace
        % zScore each trace in each trial bloc
        zmat_concat = mat;
        for b=1:size(mat,3)
            zmat_concat(:,:,b,:) = zscore(mat(:,:,b,:),0,2);
        end
        mat = zmat_concat;
    end    
elseif both2
    mat = load([pathsave '-TCA_tensor_noZero_10perBloc_POOLED.mat']);
    mat = mat.mat_full;
    colors_outcomes = {h_color,fa_color};
    labels_outcomes = {'H/M','FA/CR'};
    outcomes = 2;
    nCellsPerMouse = [197;429;221;546;555;547;1197];
    nCellsPerMouse = [1;cumsum(nCellsPerMouse)];
    intervalsCells = [nCellsPerMouse(1:end-1) nCellsPerMouse(2:end)];
    intervalsCells(2:end,1) = intervalsCells(2:end,1)+1;
    total_nblocs = size(mat,3);
    nBlocTarget_acqui = 140;
    nBlocTarget_expert = total_nblocs-10;
else
    colors_outcomes = {h_color,fa_color,cr_color};
    labels_outcomes = {'H','FA','CR'};
    outcomes = 3;
    GNGs = find(exp==1);
    GNGs(end) = []; % remove cd037
    nGNG = length(GNGs);
    nCellsPerMouse = [197;429;221;546];
    nCellsPerMouse = [1;cumsum(nCellsPerMouse)];
    intervalsCells = [nCellsPerMouse(1:end-1) nCellsPerMouse(2:end)];
    intervalsCells(2:end,1) = intervalsCells(2:end,1)+1;
    someresults = load([pathsave '-TCA_tensor_init_GNG.mat']);
    someresults = someresults.tosave;
    mat = someresults{1};
    nBlocTarget_acqui = someresults{2};
    nBlocTarget_expert = someresults{3};
    count_behavior = someresults{4};
end
bloc_size = 20;
% nfoilbloc = squeeze((count_behavior(:,2,:) + count_behavior(:,3,:))); % bloc x mice
% ntargetbloc = bloc_size - nfoilbloc; % bloc x mice
% score_outcome = nan(outcomes,length(mice));
%% Extract and save only cd036 mat

% matcd036 = mat(nCellsPerMouse(2)+1:nCellsPerMouse(3),:,:,:);
% path2save = 'R:\celine\exci_variables\';
% % zScore each trace in each trial bloc
% zmatcd036 = matcd036;
% for b=1:size(matcd036,3)
%     zmatcd036(:,:,b,:) = zscore(matcd036(:,:,b,:),0,2);
% end
% save([path2save 'TCA_tensor_cd036.mat'],'zmatcd036','-nocompression','-v7.3');


%% Analysis TCA all mice

% Determine nb of components to use
if nonnegative && ~dfftrace
    R = find(nanmedian(scores_tobestfit,2)>0.8,1,'last');
%         R = 14;
    [~,bestfit] = max(1-fits(R,:),[],2); % for non-negative algo
elseif ~nonnegative && dfftrace
    R = find(nanmedian(scores_tobestfit,2)>0.53,1,'last');
    R=6;
%     R=12;
    [~,bestfit] = sort(fits(R,:),'descend');
    bestfit = bestfit(1);
%     bestfit = find(bestfit==2);
%     [~,bestfit2] = sort();
elseif nonnegative && dfftrace
    R = find(nanmedian(scores_tobestfit,2)>0.78,1,'last');
%     R = 12;
    [~,bestfit] = max(1-fits(R,:),[],2); % for non-negative algo   
end
K = models{R,bestfit};
K = normalize(K);
ndim = ndims(K);    

figure;hold on;
subplot(2,2,1);hold on;
plot(nanmean(fits,2),'r','linewidth',2);
plot(fits,'k.');
ylabel('Fit'); % fraction of data described by model
xlabel('# of components');
title(['All mice, Model fit (als)']);

subplot(2,2,3);hold on;
plot(nanmean(1-fits,2),'r','linewidth',2);
plot(1-fits,'k.');
ylabel('Error'); % fraction of data described by model
xlabel('# of components');
title(['All mice , Model error (als)']);

subplot(2,2,4);hold on;
plot(scores_tobestfit,'k.');
plot(nanmedian(scores_tobestfit,2),'r.-','linewidth',2,'MarkerSize',15);    
ylabel('Scores');
xlabel('# of components');
title('Model similarity');
ylim([0 1]);xlim([0 nR]);
PlotHVLines(0.6,'h','k--');
PlotHVLines(0.8,'h','--','color', gray);
PlotIntervals([R-0.5 R+0.5]) ;

%%
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
ylims_min = nan(R,ndim);
ylims_max = nan(R,ndim);
% cell x time in trial x trial bloc av x trial type
for r=1:R
    for dim=1:ndim
        subplot(R,ndim,dim+(r-1)*ndim);hold on;      
        if dim==1
            bar(K.U{dim}(:,r));            
        elseif dim==2
            plot(x_psth,K.U{dim}(:,r),'k','linewidth',2);
            xlim([-1 4]);
        elseif dim==3
            plot(K.U{dim}(:,r),'k.');%,'linewidth',2
            plot(smoothdata(K.U{dim}(:,r),'movmean',10),'k','linewidth',2);
            ylimm = ylim;
            ylims_min(r,dim) = ylimm(1);
            ylims_max(r,dim) = ylimm(2);        
            xlim([0 length(K.U{dim}(:,r))+1]);
            yyaxis right
            plot(squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2),'-','color',colors_outcomes{1});
            plot(squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),'-','color',colors_outcomes{2});
            continue;
        elseif dim==4
            if passive
                for o=1:2
                    hb = bar(o,K.U{dim}(o,r));
                    hb.FaceColor = colors_outcomes{o};
                end
                set(gca,'xtick',1:2,'xticklabel',{'MISS','CR'});
            else
                for o=1:outcomes
                    hb = bar(o,K.U{dim}(o,r));
                    hb.FaceColor = colors_outcomes{o};
                end
                set(gca,'xtick',1:outcomes,'xticklabel',labels_outcomes);
            end
        end
        ylimm = ylim;
        ylims_min(r,dim) = ylimm(1);
        ylims_max(r,dim) = ylimm(2);            
    end        
    subplot(R,ndim,1+(r-1)*ndim);hold on;          
    ylabel(['GNG - ' num2str(r) ', w=' num2str(K.lambda(r))]);
end
xlabels = {'Cells','Time in trial (s)','20-trial Blocs','Outcomes'};
for dim=1:ndim
    subplot(R,ndim,dim+(r-1)*ndim);hold on; 
    xlabel(xlabels{dim});
end
ylimms_min = min(ylims_min);
ylimms_max = max(ylims_max);    
ylimms_max(1) = 0.04;
ylimms_min(1) = -0.04;
ylimms_min(4) = -1;
for r=1:R
    for dim=1:ndim
        subplot(R,ndim,dim+(r-1)*ndim);hold on;
        if dim==2
            ylim([ylimms_min(dim) ylimms_max(dim)]);
            PlotHVLines(0,'v','k');
            PlotHVLines(0,'h','k--');            
            continue
        end
        if dim==3
            yyaxis left
            nblocs_acqui = nBlocTarget_acqui;
            nblocs_expert = nBlocTarget_expert; 
            PlotHVLines([nblocs_acqui;nblocs_expert],'v','color',gray);
            ylim([ylimms_min(dim) ylimms_max(dim)]);
            PlotHVLines(0,'h','k--');                       
            continue;
        end
        ylim([ylimms_min(dim) ylimms_max(dim)]);
        if dim==1
            if passive
                for mm=1:nPASS
                    PlotIntervals(intervalsCells(mm,:),'color',colors_mice{mm},'alpha',0.2);
                end
            elseif both
                for mm=1:length(mice)-1
                    PlotIntervals(intervalsCells(mm,:),'color',colors_mice{mm},'alpha',0.2);
                end
            else
                for mm=1:nGNG
                    PlotIntervals(intervalsCells(mm,:),'color',colors_mice{mm},'alpha',0.2);
                end
            end
        end
    end
end
%% Plot component weights

figure;
stem(K.lambda/sum(K.lambda), 'k-o','filled');
% stem(K.lambda, 'k-o','filled');
xlim([0 R+1]);
ylabel('Norm. weights');
xlabel('# components');

%% Plot neuronal factor only
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.1 1]);
dim = 1;
for r=1:R
        subplot(R,1,r);hold on;  
%         stem(sort(K.U{dim}(:,r)),'filled');
        area(sort(K.U{dim}(:,r)));        
        xlim([0 size(K.U{dim}(:,r),1)+1]);
        ylim([-0.1 0.1]);
%         PlotHVLines(0,'v','k');
%         PlotHVLines(0,'h','k:');
end
xlabel('Time in trial (s)');
nCellsTot = size(K.U{dim}(:,r),1);
colorgng = [71 142 234]/255;
colorpassive = [147 15 77]/255;

figure;
area(sort(K.U{dim}(:,1)));
xlabel('Neurons');ylabel('Weights (a.u.)');
xlim([0 size(K.U{dim}(:,1),1)+1]);

figure;
subplot(2,2,1);hold on;
area(sort(K.U{dim}(:,1)));
xlabel('Neurons');ylabel('Weights (a.u.)');
xlim([1 nCellsTot]);
ylim([-0.04 0.08]);

figure;hold on;
area(1:nCellsGNG,sort(K.U{dim}(1:nCellsGNG,1)),'facecolor',colorgng);
area(nCellsGNG+1:nCellsTot,sort(K.U{dim}(nCellsGNG+1:end,1)),'facecolor',colorpassive);
PlotHVLines(limit,'h','color',gray);
PlotHVLines(nCellsGNG,'v','k');
xlabel('Neurons');ylabel('Weights (a.u.)');
xlim([1 nCellsTot]);

figure;hold on;
subplot(2,2,1);hold on;
area(1:nCellsTot-nCellsGNG,sort(K.U{dim}(nCellsGNG+1:end,5)),'facecolor',colorpassive);
area(nCellsTot-nCellsGNG+1:nCellsTot,sort(K.U{dim}(1:nCellsGNG,5)),'facecolor',colorgng);
PlotHVLines([-limit;limit],'h','color',gray);
PlotHVLines(nCellsTot-nCellsGNG,'v','k');
xlabel('Neurons');ylabel('Weights (a.u.)');
xlim([1 nCellsTot]);
ylim([-0.04 0.08]);

figure;hold on;
subplot(2,2,1);hold on;
area(1:nCellsGNG,sort(K.U{dim}(1:nCellsGNG,5)),'facecolor',colorgng);
PlotHVLines([-limit;limit],'h','color',gray);
xlabel('Neurons');ylabel('Weights (a.u.)');
xlim([1 nCellsGNG]);
ylim([-0.1 0.1]);

% fig=figure;
% set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.1 1]);
% dim = 1;
% for r=1:R
%         subplot(R,1,r);hold on; 
%         [dd,idx] = sort(K.U{dim}(:,r));
%         xG = find(ismember(idx,1:nCellsGNG));
%         stem(xG,K.U{dim}(idx(ismember(idx,1:nCellsGNG)),r),'filled','color',colorgng);
%         xP = find(ismember(idx,nCellsGNG+1:nCellsTot));
%         stem(xP,K.U{dim}(idx(nCellsGNG+1:end),r),'filled','color',colorpassive);
%         area(sort(K.U{dim}(:,r)));        
%         xlim([0 size(K.U{dim}(:,r),1)+1]);
%         ylim([-0.1 0.1]);
% %         PlotHVLines(0,'v','k');
% %         PlotHVLines(0,'h','k:');
% end
% xlabel('Time in trial (s)');
% nCellsTot = size(K.U{dim}(:,r),1);
% colorgng = [71 142 234]/255;
% colorpassive = [147 15 77]/255;

%% Plot time in trial only
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.1 1]);
dim = 2;
for r=1:R
        subplot(R,1,r);hold on;  
        plot(x_psth,K.U{dim}(:,r),'k','linewidth',2);
        xlim([-1 4]);
        ylim([-0.2 0.4]);
        PlotHVLines(0,'v','k');
        PlotHVLines(0,'h','k:');
end
xlabel('Time in trial (s)');

%% Plot trial factor only
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
dim = 3;
for r=1:R
        subplot(R,1,r);hold on;  
        plot(K.U{dim}(:,r),'k.','markersize',10);%,'linewidth',2
        PlotHVLines([nBlocTarget_acqui;nBlocTarget_expert],'v','color',gray);
        yyaxis right
        plot(squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2),'-','color',colors_outcomes{1});
        plot(squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),'-','color',colors_outcomes{2});
%         plot(smoothdata(squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2),0,'movmedian',10),'-','color',colors_outcomes{1});
%         plot(smoothdata(squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),0,'movmedian',10),'-','color',colors_outcomes{2});
end
xlabel('20-trial Blocs');

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
dim = 3;
for r=1:R
        subplot(R,1,r);hold on;  
        plot(K.U{dim}(:,r),'k.','markersize',10);%,'linewidth',2
        PlotHVLines([nBlocTarget_acqui;nBlocTarget_expert],'v','color',gray);
end
xlabel('20-trial Blocs');

if ~passive
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
    dim = 3;
    for r=1:R
            subplot(R,1,r);hold on;  
            plot(K.U{dim}(:,r),'k.','markersize',10);%,'linewidth',2
            PlotHVLines(0,'h','k:');
    %         ylim([-0.1 0.35]);
            PlotHVLines([nBlocTarget_acqui;nBlocTarget_expert],'v','color',gray);                               
            yyaxis right
    %         plot(squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2),'-','color',colors_outcomes{1});
            plot(squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),'-','color',colors_outcomes{2});
            plot(1-squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),'-','color',colors_outcomes{3});
    end
    xlabel('20-trial Blocs');
end

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
dim = 3;
for r=1:R
        subplot(R,1,r);hold on;  
        plot(K.U{dim}(:,r),'k.','markersize',10);%,'linewidth',2
        PlotHVLines(0,'h','k:');
        ylim([-0.2 0.35]);
        PlotHVLines([nBlocTarget_acqui;nBlocTarget_expert],'v','color',gray);                        
end
xlabel('20-trial Blocs');

%% Plot trial type factor only
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.1 1]);
dim = 4;
for r=1:R
        subplot(R,1,r);hold on;  
        for o=1:outcomes
            hb = bar(o,K.U{dim}(o,r));
            hb.FaceColor = colors_outcomes{o};
        end
        set(gca,'xtick',1:outcomes,'xticklabel',labels_outcomes);
        ylim([-0.1 1]); 
end
xlabel('Outcomes');

%% Loop trough component
ylims_min = nan(R,ndim);
ylims_max = nan(R,ndim);
% cell x time in trial x trial bloc av x trial type
for r=1:R
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0.25 0.25 0.5 0.25]);
    for dim=1:ndim
        subplot(1,ndim,dim);hold on;      
        if dim==1
            bar(K.U{dim}(:,r));            
        elseif dim==2
            plot(x_psth,K.U{dim}(:,r),'k','linewidth',2);
            xlim([-1 4]);
        elseif dim==3
            plot(K.U{dim}(:,r),'k.');%,'linewidth',2
            ylimm = ylim;
            ylims_min(r,dim) = ylimm(1);
            ylims_max(r,dim) = ylimm(2);        
            xlim([0 length(K.U{dim}(:,r))+1]);
            plot(smoothdata(K.U{dim}(:,r),'movmean',10),'k','linewidth',2);
%             yyaxis right
%             plot(squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2),'-','color',colors_outcomes{1});
%             plot(squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),'-','color',colors_outcomes{2});
            continue;
        elseif dim==4
            if passive
                for o=1:2
                    hb = bar(o,K.U{dim}(o,r));
                    hb.FaceColor = colors_outcomes{o};
                end
                set(gca,'xtick',1:2,'xticklabel',{'MISS','CR'});
            else
                for o=1:outcomes
                    hb = bar(o,K.U{dim}(o,r));
                    hb.FaceColor = colors_outcomes{o};
                end
                set(gca,'xtick',1:outcomes,'xticklabel',labels_outcomes);
            end
        end
        ylimm = ylim;
        ylims_min(r,dim) = ylimm(1);
        ylims_max(r,dim) = ylimm(2);            
    end        
    subplot(1,ndim,dim);hold on;          
    ylabel([num2str(r) ', w=' num2str(K.lambda(r))]);
    xlabels = {'Cells','Time in trial (s)','20-trial Blocs','Outcomes'};
    
    for dim=1:ndim
        subplot(1,ndim,dim);hold on; 
        xlabel(xlabels{dim});
    end
    ylimms_min = min(ylims_min);
    ylimms_max = max(ylims_max);  
    ylimms_max(1) = 0.05;
    ylimms_min(1) = -0.05;
    ylimms_max(2) = 0.4;
%     ylimms_min(2) = -0.2;
%     ylimms_min(3) = 0;
%     ylimms_max(3) = 0.25;
    ylimms_max(4) = 1;
    
    for dim=1:ndim
        subplot(1,ndim,dim);hold on;
        if dim==2
            ylim([ylimms_min(dim) ylimms_max(dim)]);
            PlotHVLines(0,'v','k');
            PlotHVLines(0,'h','k--');            
            continue
        end
        if dim==3
            yyaxis left
            ylim([ylimms_min(dim) ylimms_max(dim)]);
            PlotHVLines(0,'h','k--');
            nblocs_acqui = nBlocTarget_acqui;
            nblocs_expert = nBlocTarget_expert;
            PlotHVLines([nblocs_acqui;nBlocTarget_expert],'v','color',gray);
            continue;
        end
        ylim([ylimms_min(dim) ylimms_max(dim)]);
        if dim==1
            if passive
                for mm=1:nPASS
                    PlotIntervals(intervalsCells(mm,:),'color',colors_mice{mm},'alpha',0.2);
                end
            elseif both
                for mm=1:length(mice)-1
                    PlotIntervals(intervalsCells(mm,:),'color',colors_mice{mm},'alpha',0.2);
                end
            else
                for mm=1:nGNG
                    PlotIntervals(intervalsCells(mm,:),'color',colors_mice{mm},'alpha',0.2);
                end
            end
        end
    end
%     pause();
%     close(fig);
end

%% Representation component trough experimental groups
dim=1; % neuronal weight
nCellsGNG = nCellsPerMouse(1+4);
groups_vec = [ones(nCellsGNG,1);2*ones(nCellsPerMouse(end)-nCellsGNG,1)];
fig = figure;
for r=1:R
    subplot(4,4,r);hold on;
    pie([sum(abs(K.U{dim}(groups_vec==1,r)));sum(abs(K.U{dim}(groups_vec==2,r)))]);
end
legend({'GNG','Passive'});

nweight_GNG = nCellsGNG/nCellsPerMouse(end);
nweight_pass = (nCellsPerMouse(end)-nCellsGNG)/nCellsPerMouse(end);

fig = figure;
for r=1:R
%     wsumGNG = sum(abs(K.U{dim}(groups_vec==1,r)))*nweight_GNG;
%     wsumPass = sum(abs(K.U{dim}(groups_vec==2,r)))*nweight_pass;
%     wsum_global = wsumGNG+wsumPass;
    sum_global = sum(abs(K.U{dim}(:,r)));
    sumGNG = sum(abs(K.U{dim}(groups_vec==1,r)));
    sumPass = sum(abs(K.U{dim}(groups_vec==2,r)));
%     p_wsumGNG = sum(abs(K.U{dim}(groups_vec==1,r)))*nweight_GNG /wsum_global;
%     p_wsumPass = sum(abs(K.U{dim}(groups_vec==2,r)))*nweight_pass /wsum_global;
    psumGNG = sumGNG/sum_global;
    psumPass = sumPass/sum_global;
    subplot(4,4,r);hold on;
%     pie([p_wsumGNG;p_wsumPass]);
    pie([psumGNG;psumPass]);
    title(['#' num2str(r)]);
end
legend({'GNG','Passive'});

fig = figure;
for r=1:R
    subplot(4,4,r);hold on;
    sum_global = sum(abs(K.U{dim}(:,r)));
    sumGNG = sum(abs(K.U{dim}(groups_vec==1,r)));
    sumPass = sum(abs(K.U{dim}(groups_vec==2,r)));
    sgng = sumGNG / (sum_global*nweight_GNG);
    spass = sumPass / (sum_global*nweight_pass);
    globals = sgng+spass;
    pie([sgng;spass]);
    title(['#' num2str(r)]);
end
legend({'GNG','Passive'});
% 
% 
% wsum_global = sumGNG*nweight_GNG + sumPass*nweight_pass
% 
% sumGNG / ((sum_global*nweight_GNG)+(sum_global*nweight_pass))
% sumPass / ((sum_global*nweight_GNG)+(sum_global*nweight_pass))
% 
% sumGNG*nweight_GNG  / wsum_global
% sumPass*nweight_pass  / wsum_global
%%
fig = figure;
subplot(2,2,1);hold on;
tokeep = nan(R,3);
for r=1:R
    sum_global = sum(abs(K.U{dim}(:,r)));
    sumGNG = sum(abs(K.U{dim}(groups_vec==1,r)));
    sumPass = sum(abs(K.U{dim}(groups_vec==2,r)));
    sgng = sumGNG / (sum_global*nweight_GNG);
    spass = sumPass / (sum_global*nweight_pass);
    globals = sgng+spass;
    tokeep(r,:) = [sgng spass globals];
%     bar(r,[sgng;spass]/globals,'stacked');
%     title(['#' num2str(r)]);
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('Weight contribution');
xlabel('Components');

subplot(2,2,3);hold on;
tokeep = nan(R,3);
for r=1:R
    ok = K.U{dim}(:,r)>0;
    sum_global = sum(abs(K.U{dim}(ok,r)));
    sumGNG = sum(abs(K.U{dim}(groups_vec==1 & ok,r)));
    sumPass = sum(abs(K.U{dim}(groups_vec==2 & ok,r)));
    sgng = sumGNG / (sum_global*nweight_GNG);
    spass = sumPass / (sum_global*nweight_pass);
    globals = sgng+spass;
    tokeep(r,:) = [sgng spass globals];
%     bar(r,[sgng;spass]/globals,'stacked');
%     title(['#' num2str(r)]);
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('Positive weight contribution');
xlabel('Components');

subplot(2,2,4);hold on;
tokeep = nan(R,3);
for r=1:R
    ok = K.U{dim}(:,r)<0;
    sum_global = sum(abs(K.U{dim}(ok,r)));
    sumGNG = sum(abs(K.U{dim}(groups_vec==1 & ok,r)));
    sumPass = sum(abs(K.U{dim}(groups_vec==2 & ok,r)));
    sgng = sumGNG / (sum_global*nweight_GNG);
    spass = sumPass / (sum_global*nweight_pass);
    globals = sgng+spass;
    tokeep(r,:) = [sgng spass globals];
%     bar(r,[sgng;spass]/globals,'stacked');
%     title(['#' num2str(r)]);
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('Negative weight contribution');
xlabel('Components');
%% 
allweights = abs(K.U{1});
figure;histogram(sort(allweights(:)));
figure;
bar(diff(sort(allweights(:))));
allweightssorted = sort(allweights(:));
h=histogram(diff(sort(allweights(:))));
% threshold = min(find(diff(sort(allweights(:)))>=(10^-5)));
threshold = min(find(diff(sort(allweights(:)))>=h.BinEdges(5)));
limit = allweightssorted(threshold+1);
figure;bar(flip(sort(allweights(:))));
hold on; PlotHVLines(limit,'h','r');
% quantile(allweights(:),0.94)
% % 
fig = figure;
subplot(2,2,1);hold on;
tokeep = nan(R,3);
dim=1;
for r=1:R
    
%     idx_order = find(abs(K.U{dim}(:,r))>=quantile(abs(K.U{dim}(:,r)),0.95));
    idx_order = find(abs(K.U{dim}(:,r))>=limit);
    
    idx_Passive = idx_order > nCellsGNG;
    idx_GNG = idx_order <= nCellsGNG;

    sgng = sum(idx_GNG)/nCellsGNG;
    spass = sum(idx_Passive)/(nCellsPerMouse(end)-nCellsGNG);
    
    pgng = sgng/(sgng+spass);
    ppass = spass/(sgng+spass);
    globals = (sgng+spass);
    
    tokeep(r,:) = [sgng spass globals];
%     bar(r,[sgng;spass]/globals,'stacked');
%     title(['#' num2str(r)]);
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('Weight contribution');
xlabel('Components');
PlotHVLines(0.5,'h','k');
PlotHVLines([0.25;0.75],'h','k');
tokeep>0.05

subplot(2,2,3);hold on;
tokeep = nan(R,3);
for r=1:R
    
%     idx_order = find(abs(K.U{dim}(:,r))>=quantile(abs(K.U{dim}(:,r)),0.95));
    idx_order = find(K.U{dim}(:,r)>=limit);
    
    idx_Passive = idx_order > nCellsGNG;
    idx_GNG = idx_order <= nCellsGNG;

    sgng = sum(idx_GNG)/nCellsGNG;
    spass = sum(idx_Passive)/(nCellsPerMouse(end)-nCellsGNG);
    
    pgng = sgng/(sgng+spass);
    ppass = spass/(sgng+spass);
    globals = (sgng+spass);
    
    tokeep(r,:) = [sgng spass globals];
%     bar(r,[sgng;spass]/globals,'stacked');
%     title(['#' num2str(r)]);
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('Positive weight contribution');
xlabel('Components');
PlotHVLines(0.5,'h','k');
PlotHVLines([0.25;0.75],'h','k');
tokeep>0.05


subplot(2,2,4);hold on;
tokeep = nan(R,3);
for r=1:R
    
%     idx_order = find(abs(K.U{dim}(:,r))>=quantile(abs(K.U{dim}(:,r)),0.95));
    idx_order = find(K.U{dim}(:,r)<= -limit);
    
    idx_Passive = idx_order > nCellsGNG;
    idx_GNG = idx_order <= nCellsGNG;

    sgng = sum(idx_GNG)/nCellsGNG;
    spass = sum(idx_Passive)/(nCellsPerMouse(end)-nCellsGNG);
    
    pgng = sgng/(sgng+spass);
    ppass = spass/(sgng+spass);
    globals = (sgng+spass);
    
    tokeep(r,:) = [sgng spass globals];
%     bar(r,[sgng;spass]/globals,'stacked');
%     title(['#' num2str(r)]);
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('Negative weight contribution');
xlabel('Components');
PlotHVLines(0.5,'h','k');
PlotHVLines([0.25;0.75],'h','k');
tokeep>0.05

subplot(2,2,2);hold on;
tokeep = nan(R,3);
for r=1:R
    idx_orderpos = K.U{dim}(:,r)>= limit;
    idx_orderneg = K.U{dim}(:,r)<= -limit;
        
    tokeep(r,:) = [sum(idx_orderpos) sum(idx_orderneg) sum(idx_orderneg|idx_orderpos)];
end
bar(1:R,tokeep(:,[1 2])./tokeep(:,3),'stacked');
ylabel('weight contribution');
xlabel('Components');
PlotHVLines(0.5,'h','k');
PlotHVLines([0.25;0.75],'h','k');
title('Prop positive / negative');

figure;
tokeep = nan(R,3);
for r=1:R
    subplot(3,3,r);hold on;
    idx_orderpos = K.U{dim}(:,r)>= limit;
    idx_orderneg = K.U{dim}(:,r)<= -limit;
    pie([sum(idx_orderpos);sum(idx_orderneg)]);
    axis off;
end
%% save top positive and negative cells in each components
cellincomp = cell(R,2);
for r=1:R
    idx_orderpos = find(K.U{dim}(:,r)>= limit);
    idx_orderneg = find(K.U{dim}(:,r)<= -limit);
    cellincomp(r,:) = {idx_orderpos,idx_orderneg};
end
tosave = {cellincomp,nCellsPerMouse};
% save('A:\celine\exci_variables\TCA-top-cell-per-comp.mat','tosave');

cellincomp = cell(R,1);
for r=1:R
    idx_orderpos = find(K.U{dim}(:,r)>= limit);
    idx_orderneg = find(K.U{dim}(:,r)<= -limit);
    totselectedcells = length(idx_orderpos)+length(idx_orderneg);
    [~,lowidxcell] = sort(abs(K.U{dim}(:,r)));
    lowidxcell = lowidxcell(1:totselectedcells);
    cellincomp(r,:) = {lowidxcell};
end
tosave = {cellincomp,nCellsPerMouse};
% save('A:\celine\exci_variables\TCA-low-cell-per-comp.mat','tosave');

TCAneuronweights = K.U{1};
% save('A:\celine\exci_variables\TCA-all-cell-per-comp.mat','TCAneuronweights');
%% Plot behavioral weight (nb of H, FA and CR in each time window, i.e. 20-trial bloc)
nfoilbloc = squeeze((count_behavior(:,2,:) + count_behavior(:,3,:))); % bloc x mice
ntargetbloc = 20 - nfoilbloc; % bloc x mice
figure;hold on;
plot(smoothdata(squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2),1,'movmedian',4),...
    '-','color',colors_outcomes{1},...
    'linewidth',2);
plot(smoothdata(squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2),1,'movmedian',4),...
    '-','color',colors_outcomes{2},...
    'linewidth',2);
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');
legend({'HIT','FA'});

hitrate = squeeze(sum(count_behavior(:,1,:),3)) ./ sum(ntargetbloc,2);
farate = squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2);
hitrate(hitrate==0) = 1./(2*ntargetbloc(hitrate==0));
farate(farate==0) = 1./(2*nfoilbloc(farate==0));
hitrate(hitrate==1) = 1*(1-(1./(2*ntargetbloc(hitrate==1))));
farate(farate==1) = 1*(1-(1./(2*nfoilbloc(farate==1))));
dprime = norminv(hitrate) - norminv(farate);
figure;hold on;
plot(dprime,'linewidth',2);

figure;hold on;
for i=1:4
    nfoilbloc = count_behavior(:,2,i) + count_behavior(:,3,i); % bloc x mice
    ntargetbloc = 20 - nfoilbloc; % bloc x mice
    plot(smoothdata(count_behavior(:,1,i) ./ ntargetbloc,1,'movmedian',1),...
        '-','color',colors_outcomes{1},...
        'linewidth',2);
    plot(smoothdata(count_behavior(:,2,i) ./ nfoilbloc,1,'movmedian',1),...
        '-','color',colors_outcomes{2},...
        'linewidth',2);
end
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');

% weighted by the number of cells
weightcellfactor = (diff(intervalscellsGNG,[],2)+1)./nCellsGNG;
figure;hold on;
for i=1:4
    nfoilbloc = count_behavior(:,2,i) + count_behavior(:,3,i); % bloc x mice
    ntargetbloc = 20 - nfoilbloc; % bloc x mice
    plot(smoothdata(count_behavior(:,1,i) ./ ntargetbloc,1,'movmedian',4)*weightcellfactor(i),...
        '-.','color',colors_outcomes{1},...
        'linewidth',2);
    plot(smoothdata(count_behavior(:,2,i) ./ nfoilbloc,1,'movmedian',4)*weightcellfactor(i),...
        '-','color',colors_outcomes{2},...
        'linewidth',2);
end
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');

nfoilbloc = squeeze((count_behavior(:,2,:) + count_behavior(:,3,:))); % bloc x mice
ntargetbloc = 20 - nfoilbloc; % bloc x mice
weightcellfactor3 = zeros(1,1,4);
weightcellfactor3(1,1,:) = weightcellfactor;
weightcellfactor2 = zeros(1,4);
weightcellfactor2(1,:) = weightcellfactor;
figure;hold on;
plot(smoothdata(squeeze(sum(count_behavior(:,1,:).*weightcellfactor3,3))./ ...
    sum(ntargetbloc.*weightcellfactor2,2) ,1,'movmean',1),'.-','color',colors_outcomes{1},...
        'linewidth',2,'markersize',15);
plot(smoothdata(squeeze(sum(count_behavior(:,2,:).*weightcellfactor3,3))./ ...
    sum(nfoilbloc.*weightcellfactor2,2) ,1,'movmean',1),'.-','color',colors_outcomes{2},...
        'linewidth',2,'markersize',15);
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');
title('cell # weighted behavior');

plot(smoothdata(squeeze(sum(count_behavior(:,3,:).*weightcellfactor3,3))./ ...
    sum(nfoilbloc.*weightcellfactor2,2) ,1,'movmean',1),'.-','color',colors_outcomes{3},...
        'linewidth',2,'markersize',15);
    
tokeepFA = nan(97,4);
tokeepCR = nan(97,4);
for i=1:4
    nfoilbloc = count_behavior(:,2,i) + count_behavior(:,3,i); % bloc x mice
    tokeepFA(:,i) = count_behavior(:,2,i) ./ nfoilbloc;
    tokeepCR(:,i) = count_behavior(:,3,i) ./ nfoilbloc;
end
figure;
subplot(2,2,1);hold on;
plot(median(tokeepFA,2),'color',colors_outcomes{2},'linewidth',2);
plot(median(tokeepFA,2)+semedian(tokeepFA')','color',colors_outcomes{2});
plot(median(tokeepFA,2)-semedian(tokeepFA')','color',colors_outcomes{2});
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');
title('Median+-semedian');
subplot(2,2,2);hold on;
plot(mean(tokeepFA,2),'color',colors_outcomes{2},'linewidth',2);
plot(mean(tokeepFA,2)+sem(tokeepFA')','color',colors_outcomes{2});
plot(mean(tokeepFA,2)-sem(tokeepFA')','color',colors_outcomes{2});
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');
title('Mean+-sem');
subplot(2,2,3);hold on;
plot(tokeepCR,'color',gray);
plot(median(tokeepCR,2),'color',colors_outcomes{3},'linewidth',2);
plot(median(tokeepCR,2)+semedian(tokeepCR')','color',colors_outcomes{3});
plot(median(tokeepCR,2)-semedian(tokeepCR')','color',colors_outcomes{3});
ylim([0 1]);
PlotHVLines([nblocs_acqui;nblocs_expert],'v','k','linewidth',2);
ylabel('Action rate');
xlabel('20-trial blocs');
title('Median+-semedian');

subplot(2,2,4);hold on;cla
nfoilbloc = squeeze((count_behavior(:,2,:) + count_behavior(:,3,:))); % bloc x mice
ntargetbloc = 20 - nfoilbloc; % bloc x mice
a=1;
propCRacq = nan(length(1:2:17-1),2);
for i=1:2:17-1
    propCRacq(a,:) = [sum(sum(count_behavior(i:i+1,3,:),3)) sum(sum(nfoilbloc(i:i+1,:),2))];
    a=a+1;
end
bar(propCRacq(:,1)./propCRacq(:,2));
ylabel('CR rate');
xlabel('40-trial blocs');
ylim([0 1]);
d2compare = 1:8;
z = nan(8,8);
for i=1:8
    others = d2compare(~ismember(d2compare,i));
    for o=1:length(others)
        oo = others(o);
        z(i,oo) = zBinomialComparison(propCRacq(i,1),propCRacq(i,2),...
            propCRacq(oo,1),propCRacq(oo,2));
    end
end

z(z<1.96 & z>-1.96) = 0;
figure;PlotColorMap(z);
colormap(redbluecmap);
help zBinomialComparison

zp = z2p(z);
zp(zp<=0.05/(8-1)) = 0;
figure;PlotColorMap(zp);
colormap(redbluecmap);
clim([0 0.1]);




%% Plot input matrix

figure;hold on;
subplot(2,1,1);hold on;
PlotColorCurves(concat_av_psth_H); % plot flattened input matrix, HIT only
colormap jet;
clim([-0.1 0.1]);
nblocs_acqui = size(M_acqui{1},4);
PlotHVLines(nblocs_acqui*75,'v','w','linewidth',1);
subplot(2,1,2);hold on;
plot(nanmean(concat_av_psth_H));

%% plot PSTH reward component

r=5;
av_psth_H = squeeze(mat(:,:,:,1));  % cell x time in trial x trial bloc av x trial type
% concat_av_psth_H = reshape(av_psth_H,size(av_psth_H,1),size(av_psth_H,2)*size(av_psth_H,3));

dim=1;
[~,order1] = sort(K.U{dim}(:,r),'descend');

nblocs = size(av_psth_H,3);
sizegrouped = 5;
ntotgrouped = round(nblocs/sizegrouped)-1;

% fig=figure;
% set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
% for b = 1:ntotgrouped
%     subplot(1,ntotgrouped,b);hold on;
%     toplot = av_psth_H(:,:,1+(b-1)*5:5+(b-1)*5);
%     PlotColorCurves(nanmean(toplot(order1,:,:),3));
%     axis off;
%     clim([0 0.2]);
% end
% colormap jet;

% Plot only max contributor cells to reward component
% tresh = quantile(abs(K.U{dim}(:,r)),0.95);
tresh = limit;
npos = find(K.U{dim}(order1,r)>=tresh,1,'last');
nneg = find(K.U{dim}(order1,r)<=-tresh,1,'first');
nCellsTot = size(av_psth_H,1);
nneg = nCellsTot-nneg;

idx_order = [order1(1:npos);order1(end-nneg+1:end)];
fig=figure; % plot weigths
bar(K.U{dim}(order1,r));
hold on;
bar([1:npos nCellsTot-nneg+1:nCellsTot],K.U{dim}(idx_order,r));
PlotHVLines([-tresh;tresh],'h','k:');


fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
for b = 1:ntotgrouped
    subplot(1,ntotgrouped,b);hold on;
    toplot = av_psth_H(:,:,1+(b-1)*sizegrouped:sizegrouped+(b-1)*sizegrouped);
    PlotColorCurves(nanmean(toplot(idx_order,:,:),3));
    axis off;
    clim([0 0.2]);
    PlotHVLines(npos,'h','w','linewidth',3);
    PlotHVLines(15,'v','w');
end
colormap jet;

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
for b = 1:ntotgrouped
    toplot = av_psth_H(:,:,1+(b-1)*sizegrouped:sizegrouped+(b-1)*sizegrouped);
    
    subplot(2,ntotgrouped,b);hold on;
    mtoplot = nanmean(nanmean(toplot(idx_order,:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order,:,:),3));
    plot(mtoplot,'k','linewidth',2);
    plot(mtoplot+stoplot,'k');
    plot(mtoplot-stoplot,'k');
    ylim([-0.02 0.1]);
    PlotHVLines(0,'h','k:');
    
    subplot(2,ntotgrouped,ntotgrouped+b);hold on;
    mtoplot = nanmean(nanmean(toplot(idx_order(1:npos),:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order(1:npos),:,:),3));
    plot(mtoplot,'r','linewidth',2);
    plot(mtoplot+stoplot,'r');
    plot(mtoplot-stoplot,'r');
    mtoplot = nanmean(nanmean(toplot(idx_order(nneg+1:end),:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order(nneg+1:end),:,:),3));
    plot(mtoplot,'b','linewidth',2);
    plot(mtoplot+stoplot,'b');
    plot(mtoplot-stoplot,'b');
    ylim([-0.02 0.1]);
    PlotHVLines(0,'h','k:');
    
end


fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
for b = 1:ntotgrouped
    toplot = av_psth_H(:,:,1+(b-1)*sizegrouped:sizegrouped+(b-1)*sizegrouped);
    
    idx_GNG = idx_order <= nCellsGNG;
    idx_order_GNG_pos = idx_order(1:npos);idx_order_GNG_pos(idx_order_GNG_pos>nCellsGNG) = [];
    idx_order_GNG_neg = idx_order(nneg+1:end);idx_order_GNG_neg(idx_order_GNG_neg>nCellsGNG) = [];
    
    subplot(2,ntotgrouped,b);hold on;
    mtoplot = nanmean(nanmean(toplot(idx_order(idx_GNG),:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order(idx_GNG),:,:),3));
    plot(mtoplot,'k','linewidth',2);
    plot(mtoplot+stoplot,'k');
    plot(mtoplot-stoplot,'k');
    ylim([-0.02 0.1]);
    PlotHVLines(0,'h','k:');
    title(['n=' num2str(sum(idx_GNG))]);
    
    subplot(2,ntotgrouped,ntotgrouped+b);hold on;
    mtoplot = nanmean(nanmean(toplot(idx_order_GNG_pos,:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order_GNG_pos,:,:),3));
    plot(mtoplot,'r','linewidth',2);
    plot(mtoplot+stoplot,'r');
    plot(mtoplot-stoplot,'r');
    mtoplot = nanmean(nanmean(toplot(idx_order_GNG_neg,:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order_GNG_neg,:,:),3));
    plot(mtoplot,'b','linewidth',2);
    plot(mtoplot+stoplot,'b');
    plot(mtoplot-stoplot,'b');
    ylim([-0.02 0.1]);
    PlotHVLines(0,'h','k:');
    title(['npos=' num2str(length(idx_order_GNG_pos)) ', nneg=' num2str(length(idx_order_GNG_neg))]);
end

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
for b = 1:ntotgrouped
    toplot = av_psth_H(:,:,1+(b-1)*sizegrouped:sizegrouped+(b-1)*sizegrouped);
    
    idx_Passive = idx_order > nCellsGNG;
    idx_order_pass_pos = idx_order(1:npos);idx_order_pass_pos(idx_order_pass_pos<=nCellsGNG) = [];
    idx_order_pass_neg = idx_order(nneg+1:end);idx_order_pass_neg(idx_order_pass_neg<=nCellsGNG) = [];
    
    subplot(2,ntotgrouped,b);hold on;
    mtoplot = nanmean(nanmean(toplot(idx_order(idx_Passive),:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order(idx_Passive),:,:),3));
    plot(mtoplot,'k','linewidth',2);
    plot(mtoplot+stoplot,'k');
    plot(mtoplot-stoplot,'k');
    ylim([-0.02 0.22]);
    PlotHVLines(0,'h','k:');
    title(['n=' num2str(sum(idx_Passive))]);
    
    subplot(2,ntotgrouped,ntotgrouped+b);hold on;
    mtoplot = nanmean(nanmean(toplot(idx_order_pass_pos,:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order_pass_pos,:,:),3));
    plot(mtoplot,'r','linewidth',2);
    plot(mtoplot+stoplot,'r');
    plot(mtoplot-stoplot,'r');
    mtoplot = nanmean(nanmean(toplot(idx_order_pass_neg,:,:),3));
    stoplot = nansem(nanmean(toplot(idx_order_pass_neg,:,:),3));
    plot(mtoplot,'b','linewidth',2);
    plot(mtoplot+stoplot,'b');
    plot(mtoplot-stoplot,'b');
    ylim([-0.02 0.22]);
    PlotHVLines(0,'h','k:');
    title(['npos=' num2str(length(idx_order_pass_pos)) ', nneg=' num2str(length(idx_order_pass_neg))]);
end

%% plot PSTH all components
av_psth_H = squeeze(mat(:,:,:,1));  % cell x time in trial x trial bloc av x trial type
concat_av_psth_H = reshape(av_psth_H,size(av_psth_H,1),size(av_psth_H,2)*size(av_psth_H,3));
av_psth_FA = squeeze(mat(:,:,:,2));  % cell x time in trial x trial bloc av
if ~passive
    av_psth_CR = squeeze(mat(:,:,:,3));  % cell x time in trial x trial bloc av
end
%% compare FA and CR in trial blocs in GNG mice after acquisition
dim=1;r=5;
tresh = limit;
idxComp5 = find(K.U{dim}(:,r)<tresh);

toplotFA = av_psth_FA(ismember(idxComp5,1:nCellsGNG),:,nBlocTarget_acqui+1:nBlocTarget_acqui+5);
reshtoplotFA = reshape(permute(toplotFA,[2 3 1]),75*5,size(toplotFA,1));
figure;PlotColorCurves(reshtoplotFA');
clim([-0.1 0.4]);colormap jet;

toplotCR = av_psth_CR(ismember(idxComp5,1:nCellsGNG),:,nBlocTarget_acqui+1:nBlocTarget_acqui+5);
reshtoplotCR = reshape(permute(toplotCR,[2 3 1]),75*5,size(toplotCR,1));
figure;PlotColorCurves(reshtoplotCR');
clim([-0.1 0.4]);colormap jet;

idxComp5GNG = idxComp5(ismember(idxComp5,1:nCellsGNG));
[~,order] = sort(K.U{dim}(idxComp5GNG,r),'descend');
figure;PlotColorCurves((reshtoplotCR(:,order)-reshtoplotFA(:,order))');
clim([-0.2 0.2]);colormap(redbluecmap);

%%
for r=3%:R

    weight_trial_type = K.U{4}(:,r);
    w_psth_h = av_psth_H*weight_trial_type(1);
    w_psth_fa = av_psth_FA*weight_trial_type(2);
    if ~passive
        w_psth_cr = av_psth_CR*weight_trial_type(3);
    end
    w_psth = w_psth_h;
    w_psth(:,:,:,2) = w_psth_fa;
    if ~passive
        w_psth(:,:,:,3) = w_psth_cr;
    end
    w_av_psth = nanmean(w_psth,4); % weighted averaged
    
    dim=1; % neuronal factor
    [~,order1] = sort(K.U{dim}(:,r),'descend');

    nblocs = size(w_av_psth,3);
    togroup = 5;
    ntotgrouped = round(nblocs/togroup)-1;    
%     fig=figure;
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
%     for b = 1:ntotgrouped
%         subplot(1,ntotgrouped,b);hold on;
%         toplot = w_av_psth(:,:,1+(b-1)*5:5+(b-1)*5);
%         PlotColorCurves(nanmean(toplot(order1,:,:),3));
%         axis off;
%         clim([0 0.2]);
%     end
%     colormap jet;

    % Plot only max contributor cells to reward component
%     tresh = quantile(abs(K.U{dim}(:,r)),0.8);
    tresh = limit;
    npos = find(K.U{dim}(order1,r)>=tresh,1,'last');
    nneg = find(K.U{dim}(order1,r)<=-tresh,1,'first');
    nCellsTot = size(mat,1);
    nneg = nCellsTot-nneg;

    idx_order = [order1(1:npos);order1(end-nneg+1:end)];
    fig=figure; % plot weigths
    bar(K.U{dim}(order1,r));
    hold on;
    bar(1:npos,K.U{dim}(order1(1:npos),r));
    bar(nCellsTot-nneg+1:nCellsTot,K.U{dim}(order1(end-nneg+1:end),r));
    PlotHVLines([-tresh;tresh],'h','k:');
    title(['component #' num2str(r) ' (top ' num2str(length(idx_order)./length(order1)*100) '% selected)']);
    ylabel('Weight');xlabel('Cell');
    ylim([-0.1 0.1]);  

%     fig=figure;
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
%     for b = 1:ntotgrouped
%         subplot(1,ntotgrouped,b);hold on;
%         toplot = w_av_psth(:,:,1+(b-1)*5:5+(b-1)*5);
%         PlotColorCurves(nanmean(toplot(idx_order,:,:),3));
%         clim([0 0.2]);
%         PlotHVLines(npos,'h','w');
%         PlotHVLines(16,'v','w');
%         title(['Bloc ' num2str(b)]);
%         axis off;
%     end
%     colormap jet;
%     ylabel(['component #' num2str(r)]);

    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
    TP = nan(size(idx_order,1),size(w_av_psth,2),ntotgrouped);
    for b = 1:ntotgrouped
        toplot = w_av_psth(:,:,1+(b-1)*togroup:togroup+(b-1)*togroup);
        TP(:,:,b) = nanmean(toplot(idx_order,:,:),3);        
    end
    toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
    PlotColorCurves(toplot);
    clim([0 0.1]);
    PlotHVLines(75:75:size(toplot,2),'v','w');
    PlotHVLines(npos,'h','w');
    axis off;
    colormap jet;
    ylabel(['component #' num2str(r)]);
    if ~passive
        title(['Weighted average, comp #' num2str(r) ' (H=' num2str(weight_trial_type(1)) ', FA=' num2str(weight_trial_type(2))...
            ', CR=' num2str(weight_trial_type(3)) '), 100-trial bloc, n='...
            num2str(length(idx_order)) ' cells']);
    else
        title(['Weighted average, comp #' num2str(r) ' (H=' num2str(weight_trial_type(1)) ', FA=' num2str(weight_trial_type(2))...
            '), 100-trial bloc, n='...
            num2str(length(idx_order)) ' cells']);
    end
        
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
    if ~passive
        sigtypes = {av_psth_H,av_psth_FA,av_psth_CR};
        oend = 3;
    else
        sigtypes = {av_psth_H,av_psth_FA};
        oend = 2;
    end
    for o=1:oend
        TP = nan(size(idx_order,1),size(w_av_psth,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypes{o}(:,:,1+(b-1)*togroup:togroup+(b-1)*togroup);
            TP(:,:,b) = nanmean(toplot(idx_order,:,:),3);        
        end
        subplot(3,1,o);hold on;
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
        PlotColorCurves(toplot);
        clim([0 0.2]);
        PlotHVLines(75:75:size(toplot,2),'v','w');
        PlotHVLines(npos,'h','w');
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        colormap jet;
        if o==1
            title(['Weighted average, comp #' num2str(r) ', 100-trial bloc, n='...
            num2str(length(idx_order)) ' cells']);
        end
    end
    
    
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
    for b = 1:ntotgrouped
        toplot = w_av_psth(:,:,1+(b-1)*togroup:togroup+(b-1)*togroup);

        subplot(2,ntotgrouped,b);hold on;
        mtoplot = nanmean(nanmean(toplot(idx_order,:,:),3));
        stoplot = nansem(nanmean(toplot(idx_order,:,:),3));
        plot(mtoplot,'k','linewidth',2);
        plot(mtoplot+stoplot,'k');
        plot(mtoplot-stoplot,'k');
        ylim([-0.02 0.2]);
        PlotHVLines(0,'h','k:');
        axis off;

        subplot(2,ntotgrouped,ntotgrouped+b);hold on;
        mtoplot = nanmean(nanmean(toplot(idx_order(1:npos),:,:),3));
        stoplot = nansem(nanmean(toplot(idx_order(1:npos),:,:),3));
        plot(mtoplot,'r','linewidth',2);
        plot(mtoplot+stoplot,'r');
        plot(mtoplot-stoplot,'r');
        mtoplot = nanmean(nanmean(toplot(idx_order(end-nneg+1:end),:,:),3));
        stoplot = nansem(nanmean(toplot(idx_order(end-nneg+1:end),:,:),3));
        plot(mtoplot,'b','linewidth',2);
        plot(mtoplot+stoplot,'b');
        plot(mtoplot-stoplot,'b');
        ylim([-0.02 0.2]);
        PlotHVLines(0,'h','k:');
        axis off;
    end
    
    figure;
    others = find(~ismember(1:R,r));
    for rr = 1:R-1
        subplot(3,4,rr);hold on;
        o = others(rr);
        ylabel(['comp #' num2str(o)]);
        xlabel(['comp #' num2str(r)]);
        ylim([-0.1 0.1]);xlim([-0.1 0.1]);
        plot(-0.3:0.01:0.4,-0.3:0.01:0.4,'k');
        plot(-0.4:0.01:0.4,flip(-0.4:0.01:0.4),'k');
        PlotHVLines(0,'h','color',gray);
        PlotHVLines(0,'v','color',gray);        
        plot(K.U{1}(idx_order,r),K.U{1}(idx_order,o),'.','color','k');
%         plot(K.U{1}(idx_order,r),K.U{1}(idx_order,o),'.','color',gray);
%         for mm=1:nGNG
%             x = 1:nCellsTot;
%             in = InIntervals(idx_order,intervalsCells(mm,:));
%             here = idx_order(in);
%             plot(K.U{1}(here,r),K.U{1}(here,o),'.','color',colors_mice{mm});
%         end
        
%         [rho2,yfit] = LinearRegression(K.U{dim}(:,r),K.U{dim}(:,o));
%         plot(K.U{dim}(:,r),yfit,'r');        
    end
end

%% look evolution peak comp1
r=1;
dim=1;
ok = K.U{dim}(:,r)>=limit;
av_psth_H


%% look at data organization influence on bloc factor trajectory
dim=3;
foil_metamouse = squeeze(sum(count_behavior(:,2,:),3)) ./ sum(nfoilbloc,2);
figure;hold on;
for r=1:R
    subplot(3,3,r);hold on;
    plot(K.U{dim}(:,r)/max(K.U{dim}(:,r)),foil_metamouse,'.');
    ylabel('foil metamouse');
    xlabel('learning/time evolution');
%     xdata2fit = K.U{dim}(:,r)/max(K.U{dim}(:,r));
%     ydata2fit = foil_metamouse;
    
    [~,yfit] = LinearRegression(K.U{dim}(:,r)/max(K.U{dim}(:,r)),foil_metamouse);
    [rho,p] = corr(K.U{dim}(:,r)/max(K.U{dim}(:,r)),foil_metamouse,'type','spearman');
    if p<0.05
        plot(K.U{dim}(:,r)/max(K.U{dim}(:,r)),yfit,'r');
    end
    ylim([0 1]);
%     xlim([-0.05 0.3]);
    title(['comp #' num2str(r) ', p=' num2str(p)]);
end

dim=3;
figure;hold on;
for r=1:R
    subplot(3,3,r);hold on;
    plot(K.U{dim}(:,r)/max(K.U{dim}(:,r)),dprime,'.');
    ylabel('perfGNG metamouse');
    xlabel('learning/time evolution');
%     xdata2fit = K.U{dim}(:,r)/max(K.U{dim}(:,r));
%     ydata2fit = foil_metamouse;
    
    [~,yfit] = LinearRegression(K.U{dim}(:,r)/max(K.U{dim}(:,r)),dprime);
    [rho,p] = corr(K.U{dim}(:,r)/max(K.U{dim}(:,r)),dprime,'type','spearman');
    if p<0.05
        plot(K.U{dim}(:,r)/max(K.U{dim}(:,r)),yfit,'r');
    end
%     ylim([0 1]);
%     xlim([-0.05 0.3]);
    title(['comp #' num2str(r) ', p=' num2str(p)]);
end

%% look at neuronal factor correlation between components
dim=1;



[co,pco] = corr(K.U{dim});
co(logical(diag(ones(size(co,1),1)))) = nan;
figure;hold on;
subplot(2,2,1);hold on;
PlotColorMap(triu(co,1));
colormap(redbluecmap);clim([-1 1]);
title('All cells');
ylabel('Component');
xlabel('Component');

subplot(2,2,2);hold on;
[co,pco] = corr(K.U{dim}(1:nCellsGNG,:));
PlotColorMap(co);
colormap(redbluecmap);clim([-1 1]);
title('Learning cells');
ylabel('Component');
xlabel('Component');
subplot(2,2,3);hold on;
[co,pco] = corr(K.U{dim}(nCellsGNG+1:end,:));
PlotColorMap(co);
colormap(redbluecmap);clim([-1 1]);
title('Passive cells');
ylabel('Component');
xlabel('Component');
% fig2svg(['E:\KishoreLab\celine\exci\tensor_decomposition\pooled_zscored_5comps\' ...
%     'correlation_mat_neuronal_weights.svg']);

co = corr(K.U{dim}');
subplot(2,2,2);hold on;
PlotColorMap(co);
PlotHVLines(nCellsPerMouse(2:end-1),'h','w');
PlotHVLines(nCellsPerMouse(2:end-1),'v','w');

distmat = pdist(co);
% figure;hold on; histogram(distmat);PlotHVLines(median(distmat),'v','r');title(['mediane=' num2str(median(distmat))]);
Z = linkage(distmat,'complete');
% round(median(distmat)-std(distmat))
cutoff = 60; 
clu = cluster(Z,'cutoff',cutoff,'criterion','distance');
nClu = max(clu);
delimit_clu = Accumulate(clu);

figure;hold on;
xcells = (1:nCellsPerMouse(end))';
in1 = InIntervals(xcells(clu==1),[1 nCellsGNG]);
bar(1,sum(in1)/nCellsPerMouse(end));
in2 = InIntervals(xcells(clu==2),[1 nCellsGNG]);
bar(2,sum(in2)/nCellsPerMouse(end));
in3 = InIntervals(xcells(clu==3),[1 nCellsGNG]);
bar(3,sum(in3)/nCellsPerMouse(end));
in4 = InIntervals(xcells(clu==4),[1 nCellsGNG]);
bar(4,sum(in4)/nCellsPerMouse(end));

leafOrder = optimalleaforder(Z,distmat);
figure;PlotColorMap(co(leafOrder,leafOrder));colormap jet;
PlotHVLines(cumsum(delimit_clu([3;1;4;2])),'h','k');
PlotHVLines(cumsum(delimit_clu([3;1;4;2])),'v','k');
title('Reordered correlation matrix');
    
%     figure;dendrogram(Z,100,'colorthreshold',cutoff);PlotHVLines(cutoff,'h','k:');

%     figure
%     [~,T] = dendrogram(Z,40,'colorthreshold',cutoff);
    [~,pseudoorder] = sort(clu);
%     
%     cluorder = clu(leafOrder);
    
%     delimit_clu = delimit_clu(unique(cluorder,'stable'));
    xyids = 1:size(c,1);
    xyids = xyids(~transitoire);
    if plotfig
%         figure;dendrogram(Z,0,'colorthreshold',cutoff,'reorder',leafOrder,'Orientation','left');
        figure;dendrogram(Z,300,'colorthreshold',cutoff,'Orientation','left');
        figure;PlotColorCurves(reshapemat(xyids(pseudoorder),:));colormap(newmap);
        title(['D' num2str(d) ', nClu = ' num2str(nClu)]);
        PlotHVLines(cumsum(delimit_clu),'h','k');
    end

%% look at neuronal factor correlation between components  


xcells = (1:nCellsPerMouseCS0(end))';
% colorgng = [255 219 26]/255;
% colorpassive = [24 74 37]/255;
colorgng = [71 142 234]/255;
colorpassive = [147 15 77]/255;
for r=1%:R
%     [~,order1] = sort(K.U{dim}(:,r),'descend');
%     tresh = quantile(abs(K.U{dim}(:,r)),0.8);
%     npos = find(K.U{dim}(order1,r)>=tresh,1,'last');
%     nneg = find(K.U{dim}(order1,r)<=-tresh,1,'first');
%     nneg = nCellsTot-nneg;
%     idx_order = [order1(1:npos);order1(end-nneg+1:end)];
%         
    others = find(~ismember(1:R,r));
    figure;
    for rr = 1:R-1
        subplot(3,4,rr);hold on;
        o = others(rr);
        ylabel(['comp #' num2str(o)]);
        xlabel(['comp #' num2str(r)]);
%         ylim([-0.3 0.4]);xlim([-0.3 0.4]);
        ylim([-0.1 0.1]);xlim([-0.1 0.1]);
        plot(-0.3:0.01:0.4,-0.3:0.01:0.4,'k');
        plot(-0.4:0.01:0.4,flip(-0.4:0.01:0.4),'k');
        PlotHVLines(0,'h','color',gray);
        PlotHVLines(0,'v','color',gray);        
%         plot(K.U{1}(idx_order,r),K.U{1}(idx_order,o),'.','color','k');    
%         plot(K.U{1}(:,r),K.U{1}(:,o),'.','color','k');    

        ok_gng = xcells<=nCellsGNG;
        plot(K.U{1}(ok_gng,r),K.U{1}(ok_gng,o),'.','color',colorgng);   
        plot(K.U{1}(~ok_gng,r),K.U{1}(~ok_gng,o),'.','color',colorpassive);   
        
%         [rho2,yfit] = LinearRegression(K.U{1}(:,r),K.U{1}(:,o));
%         [rho,p] = corr(K.U{1}(:,r),K.U{1}(:,o),'type','pearson');
%         plot(K.U{1}(:,r),yfit,'r');
        [rho2,yfit] = LinearRegression(K.U{1}(ok_gng,r),K.U{1}(ok_gng,o));
        [rho,pG] = corr(K.U{1}(ok_gng,r),K.U{1}(ok_gng,o),'type','pearson');
        plot(K.U{1}(ok_gng,r),yfit,'r');
        [rho2,yfit] = LinearRegression(K.U{1}(~ok_gng,r),K.U{1}(~ok_gng,o));
        [rho,pP] = corr(K.U{1}(~ok_gng,r),K.U{1}(~ok_gng,o),'type','pearson');
        plot(K.U{1}(~ok_gng,r),yfit,'k');
        title(['pG=' num2str(pG) ' pP=' num2str(pP)]);
    end
end
%% look at mice representation in each comp
intervalscellsGNG = intervalscells(1:4,:);
nC = diff(intervalscellsGNG,[],2)+1;
figure;
for r=1:R
    subplot(2,3,r);hold on;
    ok_gng = xcells<=nCellsGNG;
    ok_high_pos = K.U{1}(:,r)>= limit;
    ok_high_neg = K.U{1}(:,r)<= -limit;
    [inP,wInP] = InIntervals(find(ok_high_pos),intervalscellsGNG);
    [inN,wInN] = InIntervals(find(ok_high_neg),intervalscellsGNG);
    nP = Accumulate(wInP(inP));
    bar(1:length(nP),nP./nC(1:length(nP)),'facecolor','r');
    nN = Accumulate(wInN(inN));
    bar(5:5+length(nN)-1,nN./nC(1:length(nN)),'facecolor','b');
    xlim([0 9]);
    set(gca,'xtick',1:8,'xticklabel',[1:4 1:4]);
    title(['Learning, comp #' num2str(r)]);
end

figure;
for r=1:R
    subplot(2,3,r);hold on;
    ok_gng = xcells<=nCellsGNG;
    ok_high_pos = K.U{1}(:,r)>= limit;
    ok_high_neg = K.U{1}(:,r)<= -limit;
    pH = sum(ok_high_pos&ok_gng)/sum(ok_gng);
    bar(1,pH,'facecolor','r');
    pN = sum(ok_high_neg&ok_gng)/sum(ok_gng);
    bar(2,pN,'facecolor','b');
    xlim([0 3]);
    ylim([0 0.45]);
    set(gca,'xtick',1:2,'xticklabel',{'+','-'});
    title(['Learning, comp #' num2str(r)]);
end

intervalscellsPassive = intervalscells(5:7,:);
nC = diff(intervalscellsPassive,[],2)+1;
figure;
for r=1:R
    subplot(2,3,r);hold on;
    ok_high_pos = K.U{1}(:,r)>= limit;
    ok_high_neg = K.U{1}(:,r)<= -limit;
    [inP,wInP] = InIntervals(find(ok_high_pos),intervalscellsPassive);
    [inN,wInN] = InIntervals(find(ok_high_neg),intervalscellsPassive);
    nP = Accumulate(wInP(inP));
    bar(1:length(nP),nP./nC(1:length(nP)),'facecolor','r');
    nN = Accumulate(wInN(inN));
    bar(5:5+length(nN)-1,nN./nC(1:length(nN)),'facecolor','b');
    xlim([0 9]);
    set(gca,'xtick',1:8,'xticklabel',[1:4 1:4]);
    title(['Passive, comp #' num2str(r)]);
end

figure;
for r=1:R
    subplot(2,3,r);hold on;
    ok_high_pos = K.U{1}(:,r)>= limit;
    ok_high_neg = K.U{1}(:,r)<= -limit;
    pH = sum(ok_high_pos&~ok_gng)/sum(~ok_gng);
    bar(1,pH,'facecolor','r');
    pN = sum(ok_high_neg&~ok_gng)/sum(~ok_gng);
    bar(2,pN,'facecolor','b');
    xlim([0 3]);
    ylim([0 0.45]);
    set(gca,'xtick',1:2,'xticklabel',{'+','-'});
    title(['Passive - comp #' num2str(r)]);
end
%%
dim=1;
for r=5%1:R
%     [~,order1] = sort(K.U{dim}(:,r),'descend');
    tresh = limit;
%     npos = find(K.U{dim}(order1,r)>=tresh,1,'last');
%     nneg = find(K.U{dim}(order1,r)<=-tresh,1,'first');
%     nneg = nCellsTot-nneg;
%     idx_order = [order1(1:npos);order1(end-nneg+1:end)];

%     ok = abs(K.U{1}(:,r))>=tresh;
    ok = K.U{1}(:,r)<=-tresh;
    others = find(~ismember(1:R,r));
    figure;
    for rr = 1:R-1
        subplot(3,4,rr);hold on;
        o = others(rr);
        
%         % plot best neurons weights of this other comp
%         ok_o = abs(K.U{1}(:,o))>=tresh;
        plot(K.U{1}(:,r),K.U{1}(:,o),'.','color',[0.8 0.8 0.8]);  
        
%         ok2 = abs(K.U{1}(:,o))>=tresh;
        ylabel(['comp #' num2str(o)]);
        xlabel(['comp #' num2str(r)]);
%         ylim([-0.3 0.4]);xlim([-0.3 0.4]);
        ylim([-0.1 0.1]);xlim([-0.1 0.1]);
        plot(-0.3:0.01:0.4,-0.3:0.01:0.4,'k');
        plot(-0.4:0.01:0.4,flip(-0.4:0.01:0.4),'k');
        PlotHVLines(0,'h','color',gray);
        PlotHVLines(0,'v','color',gray);        
%         plot(K.U{1}(idx_order,r),K.U{1}(idx_order,o),'.','color','k');      
%         plot(K.U{1}(ok,r),K.U{1}(ok,o),'.','color','k');   
        ok_gng = xcells<=nCellsGNG;
          
        plot(K.U{1}(ok & ~ok_gng,r),K.U{1}(ok & ~ok_gng,o),'.','color',[24 74 37]/255);  
        plot(K.U{1}(ok & ok_gng,r),K.U{1}(ok & ok_gng,o),'.','color',[255 219 26]/255);
%         plot(K.U{1}(ok & ok2,r),K.U{1}(ok & ok2,o),'.','color','r');    

        % regression positive
        okpos = K.U{1}(:,r)>=tresh;
        [rho2,yfit] = LinearRegression(K.U{1}(okpos & ok_gng,r),K.U{1}(okpos & ok_gng,o));
        [rho,pposG] = corr(K.U{1}(okpos & ok_gng,r),K.U{1}(okpos & ok_gng,o),'type','pearson');
        plot(K.U{1}(okpos & ok_gng,r),yfit,'r');
        [rho2,yfit] = LinearRegression(K.U{1}(okpos & ~ok_gng,r),K.U{1}(okpos & ~ok_gng,o));
        [rho,pposP] = corr(K.U{1}(okpos & ~ok_gng,r),K.U{1}(okpos & ~ok_gng,o),'type','pearson');
        plot(K.U{1}(okpos & ~ok_gng,r),yfit,'k');
        
        okneg = K.U{1}(:,r)<=-tresh;
        [rho2,yfit] = LinearRegression(K.U{1}(okneg & ok_gng,r),K.U{1}(okneg & ok_gng,o));
        [rho,pnegG] = corr(K.U{1}(okneg & ok_gng,r),K.U{1}(okneg & ok_gng,o),'type','pearson');
        plot(K.U{1}(okneg & ok_gng,r),yfit,'r');
        [rho2,yfit] = LinearRegression(K.U{1}(okneg & ~ok_gng,r),K.U{1}(okneg & ~ok_gng,o));
        [rho,pnegP] = corr(K.U{1}(okneg & ~ok_gng,r),K.U{1}(okneg & ~ok_gng,o),'type','pearson');
        plot(K.U{1}(okneg & ~ok_gng,r),yfit,'k');
        title([num2str(pposG) ' ' num2str(pnegG) ' ' num2str(pposP) ' ' num2str(pnegP)]);
        
        subplot(3,4,rr+4);hold on;
        xbins = -0.1:0.005:0.1;
        histogram(K.U{1}(ok & ok_gng,o),xbins);
        PlotHVLines(0,'v','k');
        xlabel(['weight comp #' num2str(o)]);
        ylabel(['nb cell comp #' num2str(r)]);
        PlotHVLines([-limit;limit],'v','b');
        title([num2str(sum(K.U{1}(ok & ok_gng,o)<=-limit)/sum(ok & ok_gng)*100) '% neg, '...
            num2str(sum(K.U{1}(ok & ok_gng,o)>limit)/sum(ok & ok_gng)*100) '% pos']);
    end
    drawnow;
end

%% Load tone selectivity
nblocacqui40trial = round(nblocs_acqui/2);
hereH = [];
hereFA=[];
hereCR=[];
path2var = 'A:\celine\exci_variables\';
for m=1:length(mice)
    if exp(m)~=1 || m==7, continue; end
    mouse = mice{m};
%     r_trials = load([path2 mouse '-responsive-tone-trials.mat']);
    r_trials = load([path2var mouse '-responsiveness-ttest-day.mat']);
    r_trials = r_trials.r_trials;
    
    cellselection = load([path mouse '-cellselection.mat']);
    cellselection = cellselection.cellselection;
    takenCells = cellselection{1,1};
    findgooddays = cellselection{1,2};
    nKeptCells = sum(takenCells);
    disp([mouse ', cell selection loaded']);
        
    hereH = [hereH;r_trials{1}(takenCells,1:nblocacqui40trial)];
    hereFA = [hereFA;r_trials{2}(takenCells,1:nblocacqui40trial)];
    hereCR = [hereCR;r_trials{2}(takenCells,1:nblocacqui40trial)];    
%     save([path2 mouse '-responsive-tone-trials-x.mat'], 'x_trials','-nocompression','-v7.3');
%     save([path2 mouse '-responsive-tone-trials-n.mat'], 'n_trials','-nocompression','-v7.3');
end
r_days = {targetsignif_pos,foilsignif_pos,hitsignif_pos,misssignif_pos,fasignif_pos,...
        crsignif_pos;targetsignif_neg,foilsignif_neg,hitsignif_neg,misssignif_neg,fasignif_neg,...
        crsignif_neg};
for m=1:length(mice)
    if exp(m)~=2, continue; end
    mouse = mice{m};
%     r_trials = load([path2 mouse '-responsive-tone-trials.mat']);
    r_trials = load([path2var mouse '-responsiveness-ttest-day.mat']);
    r_trials = r_trials.r_trials;
    
    cellselection = load([path mouse '-cellselection.mat']);
    cellselection = cellselection.cellselection;
    takenCells = cellselection{1,1};
    findgooddays = cellselection{1,2};
    nKeptCells = sum(takenCells);
    disp([mouse ', cell selection loaded']);
        
    hereH = [hereH;r_trials{1}(takenCells,1:nblocacqui40trial)];
    hereFA = [hereFA;r_trials{2}(takenCells,1:nblocacqui40trial)];
    hereCR = [hereCR;r_trials{2}(takenCells,1:nblocacqui40trial)];    
%     save([path2 mouse '-responsive-tone-trials-x.mat'], 'x_trials','-nocompression','-v7.3');
%     save([path2 mouse '-responsive-tone-trials-n.mat'], 'n_trials','-nocompression','-v7.3');
end
%% Compare cell weight in comp. 10 (reward)
% with evolution of tone responsivity
r=5;
dim=1;
% tresh = quantile(abs(K.U{1}(:,r)),0.9);% 1) get cell ID of top 10% for each components
tresh = limit;
okpos = abs(K.U{dim}(:,r))>=tresh;

figure;
subplot(2,2,1);hold on;
bar(sum(hereH(okpos,:))/sum(okpos),'facecolor',h_color);hold on;
set(gca,'xtick',1:nblocacqui40trial,'xticklabel',40:40:nblocacqui40trial*40);
subplot(2,2,2);hold on;
bar(sum(hereFA(okpos,:))/sum(okpos),'facecolor',fa_color);

subplot(2,2,3);hold on;
plot(K.U{3}(:,r),'.');
plot(smoothdata(K.U{3}(:,r),'movmean',2),'k');
PlotHVLines(nblocs_acqui,'v','color',gray);
PlotHVLines(nblocs_expert,'v','color',gray);
downsampledevol = smoothdata(K.U{3}(:,r),'movmean',2);
downsampledevol = downsampledevol(1:2:end);
plot(1:2:2*size(downsampledevol,1), downsampledevol,'r');

subplot(2,2,4);hold on;
plot(sum(hereH(okpos,:))/sum(okpos),downsampledevol(1:nblocacqui40trial),'k.');


%% order neuronal factor in exclusive way
x = 1:nCellsTot;
neuronal_factor = nan(nCellsTot,R);
for r=1:R
    neuronal_factor(:,r) = abs(K.U{1}(:,r));
end
[~,which] = max(neuronal_factor,[],2);
[~,ordermax] = sort(which);
neuronal_factor = neuronal_factor(ordermax,:);
nPerComp = [0;Accumulate(which)];
nPerComp = cumsum(nPerComp);
fig=figure;
for r=1:R
    subplot(R,1,r);hold on;
    in = ismember(x,nPerComp(r)+1:nPerComp(r+1));
    thiscomporder = sort(K.U{1}(in,r));
%     thiscomporder = sort(neuronal_factor(in,r));
    rest = neuronal_factor(~in,r);
    vartoplot = x;
    vartoplot(in) = thiscomporder;
    vartoplot(~in) = rest;
    bar(vartoplot);
%     ylim([-0.1 0.2]);
    ylim([-0.05 0.06]);
    PlotIntervals([nPerComp(r)+1 nPerComp(r+1)],'color','b','alpha',0.3);
end

% fig=figure;
% set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
% nCellsPerMouseCS0 = [0;nCellsPerMouseCS(2:end)];
% for r=1:R
%     subplot(R,1,r);hold on;
%     for j=1:nGNG
%         in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
%         thiscomporder = sort(K.U{1}(in,r),'descend');
%         x_in = x(in);
%         if isempty(x_in), continue;end
%         plot(x_in,thiscomporder,'k.','markersize',7);        
%         for l=1:nCellsPerMouse(j)
%              plot([x_in(l) x_in(l)],[0 thiscomporder(l)],'k');
%         end 
%     end
%     ylim([-0.4 0.4]);
%     for j=1:nGNG
%         PlotIntervals(intervalsCells(j,:),'color',colors_mice{j},'alpha',0.2);
%     end
%     axis off;
% end


fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
for r=1:R
    subplot(R,1,r);hold on;
    in = ismember(x,nPerComp(r)+1:nPerComp(r+1));
    thiscomporder = sort(neuronal_factor(in,r),'descend');
    rest = neuronal_factor(~in,r);
    vartoplot = x;
    vartoplot(in) = thiscomporder;
    vartoplot(~in) = rest;
%     bar(vartoplot);
    ylim([-0.1 0.2]);
    stem(vartoplot,'filled','k')
%     PlotIntervals([nPerComp(r)+1 nPerComp(r+1)],'color','b','alpha',0.3);
%     plot(vartoplot,'k.','markersize',7);
%     for l=1:nCellsTot
%          plot([x(l) x(l)],[0 vartoplot(l)],'k');
%     end 
%     PlotHVLines(0,'h','k');
%     ylabel(['#' num2str(r)]);
    axis off;
end

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
for r=1:R
    subplot(R,1,r);hold on;
    in = ismember(x,nPerComp(r)+1:nPerComp(r+1));
    thiscomporder = sort(neuronal_factor(in,r),'descend');
    rest = neuronal_factor(~in,r);
    vartoplot = x;
    vartoplot(in) = thiscomporder;
    vartoplot(~in) = rest;
%     bar(vartoplot);
    ylim([-0.1 0.2]);
    stem(vartoplot,'filled','k')
%     PlotIntervals([nPerComp(r)+1 nPerComp(r+1)],'color','b','alpha',0.3);
%     plot(vartoplot,'k.','markersize',7);
%     for l=1:nCellsTot
%          plot([x(l) x(l)],[0 vartoplot(l)],'k');
%     end 
%     PlotHVLines(0,'h','k');
%     ylabel(['#' num2str(r)]);
    axis off;
end

%% Looking at cell cluster

% sne = tsne(K.U{1});
figure;
subplot(2,2,1);hold on;
plot(sne(:,1),sne(:,2),'.');
subplot(2,2,2);hold on; % color by mouse
nCellsPerMouseCS0 = [0;nCellsPerMouse(2:end)];
symbols = {'o','x','+','*','.','o','x'};
x = (1:nCellsPerMouse(end))';
for j=1:length(mice)-1
    in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
    plot(sne(in,1),sne(in,2),symbols{j},'color',colors_mice{j});    
end
if both
    micepooled = [mice(exp==1) mice(exp==2)];
    micepooled(5) = [];
    legend(micepooled);
end
subplot(2,2,3);hold on; % color by components
plot(sne(:,1),sne(:,2),'.','color',gray);
colors_comp = {'k','b','g','y','c',h_color,fa_color,cr_color,m_color,'r','k','b'};
for r=1:R
    tresh = quantile(abs(K.U{1}(:,r)),0.8);
    in = abs(K.U{1}(:,r))>=tresh;
    plot(sne(in,1),sne(in,2),'.','color',colors_comp{r});
end
legend([' 0';num2str((1:R)')]);
subplot(2,2,4);hold on; % color by selectivity (exclusive vs mix)
idx = nan(nCellsTot,R);
for r=1:R    
    tresh = quantile(abs(K.U{1}(:,r)),0.8);% 1) get cell ID of top 20% for each components
    ok = K.U{1}(:,r)>=tresh;
    idx(:,r) = ok;
end
plot(sne(:,1),sne(:,2),'.','color',gray);
colors_selectivity = {'k','b','g','y'};%,'c',h_color,fa_color,cr_color,m_color};
for j=1:4
    if j>3
        these = sum(idx,2)>=j;
    else
        these = sum(idx,2)==j;
    end
    plot(sne(these,1),sne(these,2),'.','color',colors_selectivity{j});
end
% legend(['0';num2str((1:9)')]);
legend({'data','exclu','mix2','mix3','mix >3'});
%%
figure;
subplot(2,2,1);hold on;
plot(abssne(:,1),abssne(:,2),'.');
C = colormap('jet');
r=2;
uniqueW = unique(abs(K.U{1}(:,r)));
colormapIndex = round(linspace(1,size(C,1),length(uniqueW)));
for w=1:length(uniqueW)
    in = abs(K.U{1}(:,r))==uniqueW(w); 
    plot(abssne(in,1),abssne(in,2),'.','color',C(colormapIndex(w),:));
end
%%
% keepabssne = abssne;
sne3 = tsne(K.U{1},'NumDimensions',3);
abssne = sne3;
% abssne = keepabssne;

% abssne = tsne(abs(K.U{1}));
%%
figure;
subplot(2,2,1);hold on;
plot(abssne(:,1),abssne(:,2),'.');
subplot(2,2,2);hold on; % color by mouse
nCellsPerMouseCS0 = [0;nCellsPerMouse(2:end)];
% nCellsPerMouseCS0 = [0;nCellsPerMouseCS(2:end)];
for j=1:length(mice)-1
    in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
    plot(abssne(in,1),abssne(in,2),'.','color',colors_mice{j});
end
% legend(mice(GNGs));
if both
    micepooled = [mice(exp==1) mice(exp==2)];
    micepooled(5) = [];
    legend(micepooled);
end
subplot(2,2,3);hold on; % color by components
% plot(abssne(:,1),abssne(:,2),'.','color',gray);
% % colors_comp = {'k','b','g','y','c',h_color,fa_color,cr_color,m_color};
% topcomp = nan(nCellsTot,R);
% for r=1:R
%     tresh = quantile(abs(K.U{1}(:,r)),0.8);
%     in = abs(K.U{1}(:,r))>=tresh;
%     plot(abssne(in,1),abssne(in,2),'.','color',colors_comp{r});
%     topcomp(:,r) = in;
% end
% legend([' 0';num2str((1:R)')]);

figure;
np=0;ng=0;
figure;hold on;
x = 1:nCellsPerMouse(end)';
colorgng = [71 142 234]/255;
colorpassive = [147 15 77]/255;
for j=1:length(mice)-1
    in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
    if j<5
        scatter1 = scatter(abssne(in,1),abssne(in,2),'MarkerFaceColor',colorgng,...
            'MarkerEdgeColor',colorgng);
        ng = ng+sum(in);
    else
        scatter1 = scatter(abssne(in,1),abssne(in,2),'MarkerFaceColor',colorpassive,...
            'MarkerEdgeColor',colorpassive);
        np = np+sum(in);
    end
    scatter1.MarkerFaceAlpha = .2;
    scatter1.MarkerEdgeAlpha = .2;
end
axis off;

nCellsTot = size(K.U{1},1);
subplot(2,2,4);hold on; % color by selectivity (exclusive vs mix)
idx = nan(nCellsTot,R);
dim=1;
for r=1:R    
%     tresh = quantile(abs(K.U{1}(:,r)),0.8);% 1) get cell ID of top 10% for each components
    tresh = limit;
    ok = abs(K.U{dim}(:,r))>=tresh;
    idx(:,r) = ok;
end
plot(abssne(:,1),abssne(:,2),'.','color',gray);
colors_selectivity = {'k','b','g','y'};%,'c',h_color,fa_color,cr_color,m_color};
for j=1:4
    if j>3
        these = sum(idx,2)>=j;
    else
        these = sum(idx,2)==j;
    end
    plot(abssne(these,1),abssne(these,2),'.','color',colors_selectivity{j});
end
% legend(['0';num2str((1:9)')]);
legend({'data','exclu','mix2','mix3','mix >3'});

figure;
if R<=7    
    colors_comps = {'k','b','g','y','c','r',fa_color};%,h_color,fa_color,cr_color,m_color};
    for r=1:R
        subplot(3,3,r);hold on; % color by components (if low number)
        plot(abssne(:,1),abssne(:,2),'.','color',gray);

        okpos = K.U{dim}(:,r)>=tresh;
        plot(abssne(okpos,1),abssne(okpos,2),'.','color','g');
        okneg = K.U{dim}(:,r)<=-tresh;
        plot(abssne(okneg,1),abssne(okneg,2),'.','color','r');
    end
end

figure;
if R<=7    
    for r=1:R
        subplot(3,3,r);hold on; % color by components (if low number)
        plot(abssne(:,1),abssne(:,2),'.','color',gray);
        ok = abs(K.U{dim}(:,r))>=tresh;
        plot(abssne(ok,1),abssne(ok,2),'.','color',colors_comps{r});
        title(['Comp. #' num2str(r)]);
    end
end

figure;
if R<=7    
    for r=1:R
        subplot(3,3,r);hold on; % color by components (if low number)
        plot(abssne(:,1),abssne(:,2),'.','color',gray);
        ok = abs(K.U{dim}(:,r))>=tresh;
        plot(abssne(ok,1),abssne(ok,2),'.','color',colors_comps{r});
        title(['Comp. #' num2str(r)]);
    end
end

figure;
figure;hold on;
x = (1:nCellsTot)';
rr=1;
for r=1:R
%     subplot(3,3,r);hold on;
    ok = K.U{dim}(:,r)>=tresh;
    in = ismember(x,1:nCellsGNG); 
    scatter1 = scatter(abssne(in&ok,1),abssne(in&ok,2),'MarkerFaceColor',colors_comps{rr},...
        'MarkerEdgeColor',colors_comps{rr});
    rr=rr+1;
    scatter1.MarkerFaceAlpha = .2;
    scatter1.MarkerEdgeAlpha = .2;
    if ismember(r,[3;5])
        ok = K.U{dim}(:,r)<=-tresh;
        scatter1 = scatter(abssne(in&ok,1),abssne(in&ok,2),'MarkerFaceColor',colors_comps{rr},...
            'MarkerEdgeColor',colors_comps{rr});
        rr=rr+1;
        scatter1.MarkerFaceAlpha = .2;
        scatter1.MarkerEdgeAlpha = .2;
    end      
end
axis off;

figure;hold on;
x = (1:nCellsTot)';
rr=1;
inp = ismember(x,nCellsGNG+1:nCellsTot); 
in = ismember(x,1:nCellsGNG); 
scatter1 = scatter3(abssne(inp,1),abssne(inp,2),abssne(inp,3),...
    'MarkerFaceColor',gray,...
    'MarkerEdgeColor',gray);
scatter1.MarkerFaceAlpha = .2;
scatter1.MarkerEdgeAlpha = .2;
for r=1:R
%     subplot(3,3,r);hold on;
    ok = K.U{dim}(:,r)>=tresh;
    scatter1 = scatter3(abssne(in&ok,1),abssne(in&ok,2),abssne(in&ok,3),...
        'MarkerFaceColor',colors_comps{rr},...
        'MarkerEdgeColor',colors_comps{rr});
    rr=rr+1;
    scatter1.MarkerFaceAlpha = .2;
    scatter1.MarkerEdgeAlpha = .2;
%     pause();
    if ismember(r,[3;5])
        ok = K.U{dim}(:,r)<=-tresh;
        scatter1 = scatter3(abssne(in&ok,1),abssne(in&ok,2),abssne(in&ok,3),...
            'MarkerFaceColor',colors_comps{rr},...
            'MarkerEdgeColor',colors_comps{rr});
        rr=rr+1;
        scatter1.MarkerFaceAlpha = .2;
        scatter1.MarkerEdgeAlpha = .2;
    end      
%     pause();
end

figure;
np=0;ng=0;
figure;hold on;
x = 1:nCellsPerMouse(end)';
colorgng = [71 142 234]/255;
colorpassive = [147 15 77]/255;
for j=1:length(mice)-1
    in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
    if j<5
        scatter1 = scatter3(abssne(in,1),abssne(in,2),abssne(in,3),...
            'MarkerFaceColor',colorgng,...
            'MarkerEdgeColor',colorgng);
        ng = ng+sum(in);
    else
        scatter1 = scatter3(abssne(in,1),abssne(in,2),abssne(in,3),...
            'MarkerFaceColor',colorpassive,...
            'MarkerEdgeColor',colorpassive);
        np = np+sum(in);
    end
    scatter1.MarkerFaceAlpha = .2;
    scatter1.MarkerEdgeAlpha = .2;
end

% vartotry = [topcomp idx];
% nop = sum(vartotry,2) == 0;
% % clu = tsne([topcomp sum(idx,2)]);
% % clu2 = tsne(vartotry(~nop,:));
% figure;
% % subplot(2,2,1);hold on;
% % plot(clu(:,1),clu(:,2),'.');
% % colors_selectivity = {'k','b','g','y'};%,'c',h_color,fa_color,cr_color,m_color};
% % for j=1:4
% %     if j>3
% %         these = sum(idx,2)>=j;
% %     else
% %         these = sum(idx,2)==j;
% %     end
% %     plot(clu(these,1),clu(these,2),'.','color',colors_selectivity{j});
% % end
% subplot(2,2,1);hold on;
% plot(clu2(:,1),clu2(:,2),'.');
% for j=1:length(mice)-1
%     in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
%     in = in(~nop);
%     plot(clu2(in,1),clu2(in,2),'.','color',colors_mice{j});
% end
% 
% subplot(2,2,2);hold on;
% plot(clu2(:,1),clu2(:,2),'.');
% colors_selectivity = {'k','b','g','y'};%,'c',h_color,fa_color,cr_color,m_color};
% for j=1:4
%     if j>3
%         these = sum(idx,2)>=j;
%     else
%         these = sum(idx,2)==j;
%     end
%     plot(clu2(these(~nop),1),clu2(these(~nop),2),'.','color',colors_selectivity{j});
% end
% subplot(2,2,4);hold on;
% plot(clu2(:,1),clu2(:,2),'.');
% colors_comp = {'k','b','g','r','c',h_color,fa_color,cr_color,m_color};
% for r=1:R
%     tresh = quantile(abs(K.U{1}(:,r)),0.8);
%     in = abs(K.U{1}(:,r))>=tresh;
%     in = in(~nop);
%     plot(clu2(in,1),clu2(in,2),'.','color',colors_comp{r});
% end
% 
% subplot(2,2,3);hold on;
% for j=1:length(mice)-1
%     in = ismember(x,nCellsPerMouseCS0(j)+1:nCellsPerMouseCS0(j+1)); 
%     in = in(~nop);
%     if j<5
%         plot(clu2(in,1),clu2(in,2),'.','color','b');
%     else
%         plot(clu2(in,1),clu2(in,2),'.','color','k');
%     end
% end

%% quatif trial over time comp5
r = 5;

weight_time = K.U{3}(:,5);
% LEARNING cells only
fig=figure;hold on;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
nGroupBloc=1;
ntotgrouped = round(nblocs/nGroupBloc)-1;   
dim3w = nan(ntotgrouped,1);
dim3wsem = nan(ntotgrouped,1);
for b = 1:ntotgrouped
    dim3w(b) = median(K.U{3}(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,r)); 
    dim3wsem(b) = semedian(K.U{3}(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,r)); 
end
figure;plot(K.U{3}(:,r),'.');

groups = zeros(ntotgrouped,1);
groups(1:8) = 1;
groups(9:16) = 2;
figure;
subplot(2,2,1);hold on;
anovabar([dim3w(groups==1) dim3w(groups==2)]);


%% Save top cells in 'reward' cluster

dim=1;
r=5;
ok = abs(K.U{dim}(:,r))>=limit;
reward_cells_idx = find(ok);
nRewCells = length(reward_cells_idx);
reward_cells_GNG_idx = reward_cells_idx(reward_cells_idx<nCellsGNG);
nRewCellsGNG = length(reward_cells_GNG_idx);
  
% [psthr,psthp] = PlotThatCellActivities(reward_cells_GNG_idx,false,false);
% [~,order] = sort(K.U{dim}(reward_cells_GNG_idx,r),'descend');
% separationsign = find(diff(sign(K.U{dim}(reward_cells_GNG_idx(order),r)))~=0);
% % save these mat if wanted
% tosave = {psthr,psthp,order,separationsign,reward_cells_GNG_idx};
% path2save = 'A:\celine\exci_variables\';
% save([path2save 'psthComp5zTCA_reinfprobe.mat'],'tosave');

psthComp5 = load('A:\celine\exci_variables\psthComp5zTCA_reinfprobe.mat');
psthComp5 = psthComp5.tosave;
psthr = psthComp5{1};
psthp = psthComp5{2};
order = psthComp5{3};
separationsign = psthComp5{4};
reward_cells_GNG_idx = psthComp5{5};
% colors_outcomes2 = {h_color,m_color,fa_color,cr_color};
% figure;hold on;
% for o=1%:2
% %     subplot(4,1,o);hold on;
%     towrap = @(x) nanmean(x,2);
%     toplotav = cellfun(towrap, toplot(o,:),'uniformoutput',false);
%     plotav2 = cell2mat(toplotav);
%     plot(plotav2(:),'color',colors_outcomes2{o});
%     PlotHVLines(76:75:size(plotav2(:),1),'v','color',gray);
%     PlotHVLines(15:75:size(plotav2(:),1),'v','k');
% end


figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthr{o,d})
            PlotColorCurves(psthr{o,d}(:,order(ismember(order,1:size(psthr{o,d},2))))');
            PlotHVLines(separationsign,'h','w');
        end
        clim([-0.1 0.1]);
        axis off;
    end    
end
colormap parula;
    
figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthp{o,d})
            PlotColorCurves(psthp{o,d}(:,order(ismember(order,1:size(psthp{o,d},2))))');
            if size(psthp{o,d},2)==320, PlotHVLines(separationsign,'h','w'); end
        end
        clim([-0.1 0.1]);
        axis off;
    end    
end
colormap parula;

% compute df/f value
later = posttonewind(1):posttonewind(2);
% later = 30:45;
values = nan(131,4,15);
for d=1:15
    for o=1:4       
        values(:,o,d) = squeeze(nanmean(psthr{o,d}(later,order(ismember(order,separationsign+1:size(psthp{o,d},2))))));
    end    
end
ylimm = [-0.01 0.03];

figure;
subplot(2,2,1);hold on;
plot(squeeze(nanmean(values(:,1,:))),'color',h_color);
ylim(ylimm);
subplot(2,2,2);hold on;
plot(nanmean(squeeze(values(:,2,:))),'color',m_color);
ylim(ylimm);
subplot(2,2,3);hold on;
plot(nanmean(squeeze(values(:,3,:))),'color',fa_color);
ylim(ylimm);
subplot(2,2,4);hold on;
plot(nanmean(squeeze(values(:,4,:))),'color',cr_color);
ylim(ylimm);
xlabel('Days');
ylabel('df/f');
title('late in trial (frames 30-45)');

figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthp{o,d})
            m = nanmean(psthp{o,d}(:,order(1:separationsign)),2);
            s = nansem(psthp{o,d}(:,order(1:separationsign))')';
            plot(m,'b','linewidth',2);
            plot(m+s,'b');plot(m-s,'b');
            m = nanmean(psthp{o,d}(:,order(separationsign+1:size(psthp{o,d},2))),2);
            s = nansem(psthp{o,d}(:,order(separationsign+1:size(psthp{o,d},2)))')';
            plot(m,'r','linewidth',2);
            plot(m+s,'r');plot(m-s,'r');
        end
        ylim([-0.1 0.1]);
        axis off;
    end    
end


figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthr{o,d})
            m = nanmean(psthr{o,d}(:,order(1:separationsign)),2);
            s = nansem(psthr{o,d}(:,order(1:separationsign))')';
            plot(m,'b','linewidth',2);
            plot(m+s,'b');plot(m-s,'b');
            m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
            s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
            plot(m,'r','linewidth',2);
            plot(m+s,'r');plot(m-s,'r');
        end
        ylim([-0.1 0.1]);
        axis off;
    end    
end

TP = cell(4,1);
TP_probe = cell(4,1);
figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthp{o,d})
            m = nanmean(psthp{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
            s = nansem(psthp{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
            plot(m,'color',gray,'linewidth',2);
            plot(m+s,'color',gray);plot(m-s,'color',gray);
            m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
            s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
            plot(m,'b','linewidth',2);
            plot(m+s,'b');plot(m-s,'b');  
            PlotHVLines(0,'h','k:');
            TP{o}(:,:,d) = psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))';
            TP_probe{o}(:,:,d) = psthp{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))';
        end
        ylim([-0.1 0.1]);
        axis off;        
    end    
end

TP = cell(4,1);
TP_probe = cell(4,1);
figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthp{o,d})
            m = nanmean(psthp{o,d}(:,order(1:separationsign)),2);
            s = nansem(psthp{o,d}(:,order(1:separationsign))')';
            plot(m,'color',gray,'linewidth',2);
            plot(m+s,'color',gray);plot(m-s,'color',gray);
            m = nanmean(psthr{o,d}(:,order(1:separationsign)),2);
            s = nansem(psthr{o,d}(:,order(1:separationsign))')';
            plot(m,'b','linewidth',2);
            plot(m+s,'b');plot(m-s,'b');  
            PlotHVLines(0,'h','k:');
            TP{o}(:,:,d) = psthr{o,d}(:,order(1:separationsign))';
            TP_probe{o}(:,:,d) = psthp{o,d}(:,order(1:separationsign))';
        end
        ylim([-0.1 0.1]);
        axis off;        
    end    
end

dd = TP{o}(:,:,8);
[~,idxs] = sort(mean(dd(:,tonewin),2));
figure;hold on;
PlotColorCurves(dd(idxs,:));
colormap jet;
PlotHVLines(15,'v','w');
clim([-0.05 0.05]);

for o=1:4
    tp = TP{o};
    tp = reshape(tp,size(tp,1),size(tp,2)*size(tp,3));
%     figure;PlotColorCurves(tp);clim([-0.1 0.1]);
    c = corr(tp');
%     figure;PlotColorMap(c);colormap jet;
    corrMat = c - eye(size(c));
    distmat = pdist(corrMat);
    % figure;hold on; histogram(distmat);PlotHVLines(median(distmat),'v','r');title(['mediane=' num2str(median(distmat))]);
    Z = linkage(distmat,'complete');
    cutoff = 4.5; %4.5
    clu = cluster(Z,'cutoff',cutoff,'criterion','distance');
    nClu = max(clu);
%     figure;dendrogram(Z,length(clu),'colorthreshold',cutoff);PlotHVLines(cutoff,'h','k:');
%     [~,i] = unique(cluorder);
%     [~,ii] = sort(i);
%     hold on; PlotHVLines(cumsum(delimit_clu(ii)),'v','r');
%     hold on; PlotHVLines(cumsum(delimit_clu(ii)),'h','r');
    
    leafOrder = optimalleaforder(Z,distmat);
    cluorder = clu(leafOrder);
    delimit_clu = Accumulate(clu);
    delimit_clu = delimit_clu(unique(cluorder,'stable'));
    figure;PlotColorMap(c(leafOrder,leafOrder));colormap jet;
    hold on;PlotHVLines(cumsum(delimit_clu),'v','k');
    hold on;PlotHVLines(cumsum(delimit_clu),'h','k');
    
    figure;
    for cl = 1:max(clu)
        subplot(max(clu),1,cl);hold on;
        if sum(clu==cl) == 1, plot(tp(clu==cl,:));
        else, plot(nanmean(tp(clu==cl,:))); end
        ylim([-0.1 0.05]);
        PlotHVLines(75:75:size(tp,2),'v','color',gray);
        PlotHVLines(15:75:size(tp,2),'v','k');
        PlotHVLines(0,'h','k:');
        lookin = order(1:separationsign);
        mW = mean(abs(K.U{1}(reward_cells_GNG_idx(lookin(clu==cl)),r)));
        title(['n=' num2str(sum(clu==cl)) ' (' num2str(sum(clu==cl)/length(clu)*100) ...
            '%) - w=' num2str(mW)]);     
    end
    
    figure;hold on;
%     [~,ord] = sort(clu);
    PlotColorCurves(tp(leafOrder,:));
    colormap jet;
    clim([-0.1 0.05]);
    PlotHVLines(75:75:size(tp,2),'v','color',gray);
    PlotHVLines(15:75:size(tp,2),'v','k');
    [~,i] = unique(cluorder);
    [~,ii] = sort(i);
    hold on; PlotHVLines(cumsum(delimit_clu),'h','r');
    
    colors_outcomesfull = {h_color,m_color,fa_color,cr_color};
    tpProbe = TP_probe{o};
    tpProbe = reshape(tpProbe,size(tpProbe,1),size(tpProbe,2)*size(tpProbe,3));
    figure;
    for cl = 1:max(clu)
        subplot(max(clu),1,cl);hold on;
        if sum(clu==cl) == 1
            plot(tp(clu==cl,:),'color',colors_outcomesfull{o},'linewidth',2);
        else
            plot(nanmean(tp(clu==cl,:)),'color',colors_outcomesfull{o},'linewidth',2); 
            plot(nanmean(tp(clu==cl,:))+sem(tp(clu==cl,:)),'color',colors_outcomesfull{o}); 
            plot(nanmean(tp(clu==cl,:))-sem(tp(clu==cl,:)),'color',colors_outcomesfull{o}); 
        end
        ylim([-0.1 0.05]);
        for oo=2:4
            tpp = TP{oo};
            tpp = reshape(tpp,size(tpp,1),size(tpp,2)*size(tpp,3));
            plot(nanmean(tpp(clu==cl,:)),'color',colors_outcomesfull{oo},'linewidth',2);
            plot(nanmean(tpp(clu==cl,:))+sem(tpp(clu==cl,:)),'color',colors_outcomesfull{oo});
            plot(nanmean(tpp(clu==cl,:))-sem(tpp(clu==cl,:)),'color',colors_outcomesfull{oo});
        end 
        if sum(clu==cl) == 1
            plot(tpProbe(clu==cl,:),'color',gray,'linewidth',2);
        else
            plot(nanmean(tpProbe(clu==cl,:)),'color',gray,'linewidth',2); 
            plot(nanmean(tpProbe(clu==cl,:))+sem(tpProbe(clu==cl,:)),'color',gray); 
            plot(nanmean(tpProbe(clu==cl,:))-sem(tpProbe(clu==cl,:)),'color',gray); 
        end
        PlotHVLines(75:75:size(tp,2),'v','color',gray);
        PlotHVLines(15:75:size(tp,2),'v','k');
        PlotHVLines(0,'h','k:');
        lookin = order(1:separationsign);
        mW = mean(abs(K.U{1}(reward_cells_GNG_idx(lookin(clu==cl)),r)));
        title(['n=' num2str(sum(clu==cl)) ' (' num2str(sum(clu==cl)/length(clu)*100) ...
            '%) - w=' num2str(mW)]);        
    end
        
    figure;hold on;
    for cl = 1:max(clu)  
        subplot(2,4,cl);hold on;
        plot(squeeze(mean(mean(TP{o}(clu==cl,posttonewind(1):posttonewind(2),:),2))));
        ylim([-0.1 0]);
    end
    
%     interV_days = [13:15;7:9;4:6;13:15];
%     interV_days = [13:15;[7 9 11];[2 4 6];13:15];
    interV_days = [13:15;[7 9 11];1:3;13:15];
%     interV_days = [15;7;2;15];
    clu2consider = [1;2;3;5];    
    figure;
    for j = 1:length(clu2consider)
        cl = clu2consider(j);
        
        tpp = nanmean(TP{o}(:,:,interV_days(j,:)),3);
%         tpp = TP{o}(:,:,interV_days(j));
        subplot(2,2,j);hold on;
        if sum(clu==cl) == 1
            plot(tpp(clu==cl,:),'color',colors_outcomesfull{o},'linewidth',2);
        else
            plot(nanmean(tpp(clu==cl,:)),'color',colors_outcomesfull{o},'linewidth',2); 
            plot(nanmean(tpp(clu==cl,:))+sem(tpp(clu==cl,:)),'color',colors_outcomesfull{o}); 
            plot(nanmean(tpp(clu==cl,:))-sem(tpp(clu==cl,:)),'color',colors_outcomesfull{o}); 
        end
        ylim([-0.1 0.08]);
        for oo=2:4
            tpp = nanmean(TP{oo}(:,:,interV_days(j,:)),3);
            tpp = reshape(tpp,size(tpp,1),size(tpp,2)*size(tpp,3));
            if sum(clu==cl) == 1
                plot(tpp(clu==cl,:),'color',colors_outcomesfull{o},'linewidth',2);
            else
                plot(nanmean(tpp(clu==cl,:)),'color',colors_outcomesfull{oo},'linewidth',2);
                plot(nanmean(tpp(clu==cl,:))+sem(tpp(clu==cl,:)),'color',colors_outcomesfull{oo});
                plot(nanmean(tpp(clu==cl,:))-sem(tpp(clu==cl,:)),'color',colors_outcomesfull{oo});
            end
        end 
        tpProbe = nanmean(TP_probe{o}(:,:,interV_days(j,:)),3);
%         tpProbe = TP_probe{o}(:,:,interV_days(j));
        if sum(clu==cl) == 1
            plot(tpProbe(clu==cl,:),'color',gray,'linewidth',2);
        else
            plot(nanmean(tpProbe(clu==cl,:)),'color',gray,'linewidth',2); 
            plot(nanmean(tpProbe(clu==cl,:))+sem(tpProbe(clu==cl,:)),'color',gray); 
            plot(nanmean(tpProbe(clu==cl,:))-sem(tpProbe(clu==cl,:)),'color',gray); 
        end
%         PlotHVLines(75:75:size(tp,2),'v','color',gray);
        PlotIntervals(posttonewind);
        PlotHVLines(15,'v','k');
        PlotHVLines(0,'h','k:');
        lookin = order(1:separationsign);
        mW = mean(abs(K.U{1}(reward_cells_GNG_idx(lookin(clu==cl)),r)));
        title(['n=' num2str(sum(clu==cl)) ' (' num2str(sum(clu==cl)/length(clu)*100) ...
            '%) - w=' num2str(mW)]);        
    end
    
     subplot(2,2,j);hold on;
        if sum(clu==cl) == 1
            plot(tpp(clu==cl,:),'color',colors_outcomesfull{o},'linewidth',2);
        else
            plot(nanmean(tpp(clu==cl,:)),'color',colors_outcomesfull{o},'linewidth',2); 
            plot(nanmean(tpp(clu==cl,:))+sem(tpp(clu==cl,:)),'color',colors_outcomesfull{o}); 
            plot(nanmean(tpp(clu==cl,:))-sem(tpp(clu==cl,:)),'color',colors_outcomesfull{o}); 
        end
        ylim([-0.1 0.08]);
        for oo=2:4
            tpp = nanmean(TP{oo}(:,:,interV_days(j,:)),3);
            tpp = reshape(tpp,size(tpp,1),size(tpp,2)*size(tpp,3));
            if sum(clu==cl) == 1
                plot(tpp(clu==cl,:),'color',colors_outcomesfull{o},'linewidth',2);
            else
                plot(nanmean(tpp(clu==cl,:)),'color',colors_outcomesfull{oo},'linewidth',2);
                plot(nanmean(tpp(clu==cl,:))+sem(tpp(clu==cl,:)),'color',colors_outcomesfull{oo});
                plot(nanmean(tpp(clu==cl,:))-sem(tpp(clu==cl,:)),'color',colors_outcomesfull{oo});
            end
        end 
%         tpProbe = nanmean(TP_probe{o}(:,:,interV_days(j,:)),3);
        tpProbe = TP_probe{o}(:,:,interV_days(j));
        if sum(clu==cl) == 1
            plot(tpProbe(clu==cl,:),'color',gray,'linewidth',2);
        else
            plot(nanmean(tpProbe(clu==cl,:)),'color',gray,'linewidth',2); 
            plot(nanmean(tpProbe(clu==cl,:))+sem(tpProbe(clu==cl,:)),'color',gray); 
            plot(nanmean(tpProbe(clu==cl,:))-sem(tpProbe(clu==cl,:)),'color',gray); 
        end
%         PlotHVLines(75:75:size(tp,2),'v','color',gray);
        PlotIntervals(posttonewind);
        PlotHVLines(15,'v','k');
        PlotHVLines(0,'h','k:');
        lookin = order(1:separationsign);
        mW = mean(abs(K.U{1}(reward_cells_GNG_idx(lookin(clu==cl)),r)));
        title(['n=' num2str(sum(clu==cl)) ' (' num2str(sum(clu==cl)/length(clu)*100) ...
            '%) - w=' num2str(mW)]);        
    end
           
    figure;hold on;
    bins = 0.02:0.001:0.1;
    val = nan(length(bins)-1,1);
    for cl=1:max(clu)
        W = K.U{1}(reward_cells_GNG_idx(lookin(clu==cl)),r);
        h = histogram(W,bins);
        xb = linspace(h.BinLimits(1),h.BinLimits(2),h.NumBins);
        val(:,cl) = h.Values;
%         plot(xb,h.Values);
    end
    cla;
    plot(xb,smoothdata(val,1,'movmean',10));
    legend(num2str(1:max(clu))');
    
    figure;hold on;
    bins = 0.02:0.001:0.1;
    val = nan(length(bins)-1,1);
    for cl=1:max(clu)
        W = K.U{1}(reward_cells_GNG_idx(lookin(clu==cl)),r);
        h = histogram(W,bins,'normalization','cdf');
        xb = linspace(h.BinLimits(1),h.BinLimits(2),h.NumBins);
        val(:,cl) = h.Values;
%         plot(xb,h.Values);
    end
    cla;
    plot(xb,val);
    plot(xb,smoothdata(val,1,'movmean',10));
    legend(num2str(1:max(clu))');
    
    % cell from how many GNG mice in each cluster?
    intervCellMiceGNG = [1;cumsum(nCellsPerMouse(1:4))];
    intervCellMiceGNG = [intervCellMiceGNG(1:end-1) intervCellMiceGNG(2:end)];
    intervCellMiceGNG(2:end,1) = intervCellMiceGNG(2:end,1)+1;
    figure;
    for cl=1:max(clu)
        [~,wI] = InIntervals(reward_cells_GNG_idx(lookin(clu==cl)),intervCellMiceGNG);
        subplot(2,4,cl);hold on;
        bar(Accumulate(wI)/nCellsPerMouse(1:4)*100);
    end


    
interV_days = [13:15;[7 9 11];1:3;13:15];
clu2consider = [1;2;3;5];    
figure;
vals = [];
vals2 = [];
vals3 = [];
mid = 29:47;
subplot(2,2,1);hold on;
for o=1:4
    tpp = [];
    for j = 1:length(clu2consider)
        cl = clu2consider(j);
        thisdat = TP{o}(clu==cl,:,interV_days(j,:))- ...
            nanmean(TP{o}(clu==cl,13:15,interV_days(j,:)),2);
        tpp = [tpp;nanmean(thisdat,3)];
    end        
    plot(nanmean(tpp),'color',colors_outcomesfull{o},'linewidth',2); 
    plot(nanmean(tpp)+sem(tpp),'color',colors_outcomesfull{o}); 
    plot(nanmean(tpp)-sem(tpp),'color',colors_outcomesfull{o}); 
    vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) o*ones(size(tpp,1),1)]];
    vals2 = [vals2; [nanmean(tpp(:,tonewin),2) o*ones(size(tpp,1),1)]];
    vals3 = [vals3; [nanmean(tpp(:,mid),2) o*ones(size(tpp,1),1)]];
    if o==1
        tpp = [];
        for j = 1:length(clu2consider)
            cl = clu2consider(j);
            thisdat = TP_probe{o}(clu==cl,:,interV_days(j,:))- ...
            nanmean(TP_probe{o}(clu==cl,13:15,interV_days(j,:)),2);
            tpp = [tpp;nanmean(thisdat,3)];
        end 
        plot(nanmean(tpProbe),'color',gray,'linewidth',2); 
        plot(nanmean(tpProbe)+sem(tpProbe),'color',gray); 
        plot(nanmean(tpProbe)-sem(tpProbe),'color',gray); 
        vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) 5*ones(size(tpp,1),1)]];
        vals2 = [vals2; [nanmean(tpp(:,tonewin),2) 5*ones(size(tpp,1),1)]];
        vals3 = [vals3; [nanmean(tpp(:,mid),2) 5*ones(size(tpp,1),1)]];
    end
end
PlotIntervals([mid(1) mid(end)],'color','b','alpha',0.3);
PlotIntervals(posttonewind);
PlotIntervals([tonewin(1) tonewin(end)]);
PlotHVLines(15,'v','k');
PlotHVLines(0,'h','k:');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
xlabel('Time fron tone onset (s)');
subplot(2,2,2);hold on;
title('late window');
kruskalbar(vals(:,1),vals(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});
subplot(2,2,3);hold on;
title('tone window');
kruskalbar(vals2(:,1),vals2(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});
subplot(2,2,4);hold on;
title('mid window');
kruskalbar(vals3(:,1),vals3(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});

interV_days = [13:15;[7 9 11];1:3;13:15];
clu2consider = [1;2;3;5];    
figure;
mid = 29:47;
vals = [];
vals2 = [];
vals3 = [];
subplot(2,2,1);hold on;
for o=1:4
    tpp = [];
    for j = 1:length(clu2consider)
        cl = clu2consider(j);
        thisdat = TP_probe{o}(clu==cl,:,interV_days(j,:))- ...
            nanmean(TP_probe{o}(clu==cl,13:15,interV_days(j,:)),2);
        tpp = [tpp;nanmean(thisdat,3)];
    end        
    plot(nanmean(tpp),'color',colors_outcomesfull{o},'linewidth',2); 
    plot(nanmean(tpp)+sem(tpp),'color',colors_outcomesfull{o}); 
    plot(nanmean(tpp)-sem(tpp),'color',colors_outcomesfull{o}); 
    vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) o*ones(size(tpp,1),1)]];
    vals2 = [vals2; [nanmean(tpp(:,tonewin),2) o*ones(size(tpp,1),1)]];
    vals3 = [vals3; [nanmean(tpp(:,mid),2) o*ones(size(tpp,1),1)]];
end
PlotIntervals([mid(1) mid(end)],'color','b','alpha',0.3);
PlotIntervals(posttonewind);
PlotIntervals([tonewin(1) tonewin(end)]);
PlotHVLines(15,'v','k');
PlotHVLines(0,'h','k:');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
xlabel('Time fron tone onset (s)');
title('Probe');
subplot(2,2,2);hold on;
title('late window');
kruskalbar(vals(:,1),vals(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});
subplot(2,2,3);hold on;
title('tone window');
kruskalbar(vals2(:,1),vals2(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});
subplot(2,2,4);hold on;
title('mid window');
kruskalbar(vals3(:,1),vals3(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});

%take all days  
figure;
vals = [];
vals2 = [];
vals3 = [];
mid = 29:47;
subplot(2,2,1);hold on;
for o=1:4
    thisdat = TP{o}(ismember(clu,clu2consider),:,:)- ...
        nanmean(TP{o}(ismember(clu,clu2consider),13:15,:),2);
    tpp = nanmean(thisdat,3);
    plot(nanmean(tpp),'color',colors_outcomesfull{o},'linewidth',2); 
    plot(nanmean(tpp)+sem(tpp),'color',colors_outcomesfull{o}); 
    plot(nanmean(tpp)-sem(tpp),'color',colors_outcomesfull{o}); 
    vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) o*ones(size(tpp,1),1)]];
    vals2 = [vals2; [nanmean(tpp(:,tonewin),2) o*ones(size(tpp,1),1)]];
    vals3 = [vals3; [nanmean(tpp(:,mid),2) o*ones(size(tpp,1),1)]];
    if o==1
        thisdat = TP_probe{o}(ismember(clu,clu2consider),:,:)- ...
            nanmean(TP_probe{o}(ismember(clu,clu2consider),13:15,:),2);
        tpp = nanmean(thisdat,3);        
        plot(nanmean(tpp),'color',gray,'linewidth',2); 
        plot(nanmean(tpp)+sem(tpp),'color',gray); 
        plot(nanmean(tpp)-sem(tpp),'color',gray); 
        vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) 5*ones(size(tpp,1),1)]];
        vals2 = [vals2; [nanmean(tpp(:,tonewin),2) 5*ones(size(tpp,1),1)]];
        vals3 = [vals3; [nanmean(tpp(:,mid),2) 5*ones(size(tpp,1),1)]];
    end
end
PlotIntervals([mid(1) mid(end)],'color','b','alpha',0.3);
PlotIntervals(posttonewind);
PlotIntervals([tonewin(1) tonewin(end)]);
PlotHVLines(15,'v','k');
PlotHVLines(0,'h','k:');
xlim([0 75]);
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
xlabel('Time fron tone onset (s)');
subplot(2,2,2);hold on;
title('late window');
kruskalbar(vals(:,1),vals(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});
subplot(2,2,3);hold on;
title('tone window');
kruskalbar(vals2(:,1),vals2(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});
subplot(2,2,4);hold on;
title('mid window');
kruskalbar(vals3(:,1),vals3(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});

%take all days, probe only  
figure;
vals = [];
vals2 = [];
vals3 = [];
mid = 29:47;
subplot(2,2,1);hold on;
for o=1:4
    thisdat = TP_probe{o}(ismember(clu,clu2consider),:,:)- ...
        nanmean(TP_probe{o}(ismember(clu,clu2consider),13:15,:),2);
    tpp = nanmean(thisdat,3);
    plot(nanmean(tpp),'color',colors_outcomesfull{o},'linewidth',2); 
    plot(nanmean(tpp)+sem(tpp),'color',colors_outcomesfull{o}); 
    plot(nanmean(tpp)-sem(tpp),'color',colors_outcomesfull{o}); 
    vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) o*ones(size(tpp,1),1)]];
    vals2 = [vals2; [nanmean(tpp(:,tonewin),2) o*ones(size(tpp,1),1)]];
    vals3 = [vals3; [nanmean(tpp(:,mid),2) o*ones(size(tpp,1),1)]];    
end
PlotIntervals([mid(1) mid(end)],'color','b','alpha',0.3);
PlotIntervals(posttonewind);
PlotIntervals([tonewin(1) tonewin(end)]);
PlotHVLines(15,'v','k');
PlotHVLines(0,'h','k:');
xlim([0 75]);
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
xlabel('Time fron tone onset (s)');
title('Probe');
subplot(2,2,2);hold on;
title('late window');
kruskalbar(vals(:,1),vals(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});
subplot(2,2,3);hold on;
title('tone window');
kruskalbar(vals2(:,1),vals2(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});
subplot(2,2,4);hold on;
title('mid window');
kruskalbar(vals3(:,1),vals3(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});


%%
% day 6
figure;hold on;
for d=1
subplot(2,15,d);hold on;
% d=7;
title(['Day ' num2str(d)]);
o=1; %hit
m = nanmean(psthr{o,d}(:,order(1:separationsign)),2);
s = nansem(psthr{o,d}(:,order(1:separationsign))')';
plot(m,'color',h_color,'linewidth',2);
plot(m+s,'color',h_color);plot(m-s,'color',h_color); 
m = nanmean(psthp{o,d}(:,order(1:separationsign)),2);
s = nansem(psthp{o,d}(:,order(1:separationsign))')';
plot(m,'color',gray,'linewidth',2);
plot(m+s,'color',gray);plot(m-s,'color',gray);
o=2; %miss
m = nanmean(psthr{o,d}(:,order(1:separationsign)),2);
s = nansem(psthr{o,d}(:,order(1:separationsign))')';
plot(m,'color',m_color,'linewidth',2);
plot(m+s,'color',m_color);plot(m-s,'color',m_color); 
o=3; %fa
m = nanmean(psthr{o,d}(:,order(1:separationsign)),2);
s = nansem(psthr{o,d}(:,order(1:separationsign))')';
plot(m,'color',fa_color,'linewidth',2);
plot(m+s,'color',fa_color);plot(m-s,'color',fa_color); 
o=4; %cr
m = nanmean(psthr{o,d}(:,order(1:separationsign)),2);
s = nansem(psthr{o,d}(:,order(1:separationsign))')';
plot(m,'color',cr_color,'linewidth',2);
plot(m+s,'color',cr_color);plot(m-s,'color',cr_color); 
ylim([-0.06 0.1]);
% window2consider = [30 50];
window2consider = posttonewind;
PlotHVLines(0,'h','k');
PlotHVLines(15,'v','k');
PlotIntervals(window2consider);
set(gca,'xtick',0:15:75,'xticklabel',-1:4);

data = [nanmean(psthr{1,d}(window2consider,order(1:separationsign)))' ...
    nanmean(psthp{1,d}(window2consider,order(1:separationsign)))' ...
    nanmean(psthr{2,d}(window2consider,order(1:separationsign)))' ...
    nanmean(psthr{3,d}(window2consider,order(1:separationsign)))' ...
    nanmean(psthr{4,d}(window2consider,order(1:separationsign)))'];
if any(isnan(data(1,:)),2)
    data = data(:,~isnan(data(1,:)));
    subplot(2,15,15+d);hold on;
    kruskalbar(data);
    p = friedman(data(~any(isnan(data),2),:),1,'off');
    title(['Friedman p=' num2str(p)]);
    set(gca,'xtick',1:4,'xticklabel',{'HIT','HIT Probe','FA','CR'});
    PlotHVLines(0,'h','k:');
else
subplot(2,15,15+d);hold on;
% hold on;boxplot(data);
kruskalbar(data);
% ylim([-0.07 0.15]);
[p,~,stats] = friedman(data(~any(isnan(data),2),:),1,'off');
title(['Friedman p=' num2str(p)]);
p12 = signrank(data(~any(isnan(data),2),1),data(~any(isnan(data),2),2));
p13 = signrank(data(~any(isnan(data),2),1),data(~any(isnan(data),2),3));
p14 = signrank(data(~any(isnan(data),2),1),data(~any(isnan(data),2),4));
p23 = signrank(data(~any(isnan(data),2),2),data(~any(isnan(data),2),3));
p24 = signrank(data(~any(isnan(data),2),2),data(~any(isnan(data),2),4));
p34 = signrank(data(~any(isnan(data),2),3),data(~any(isnan(data),2),4));
set(gca,'xtick',1:5,'xticklabel',{'HIT','HIT Probe','MISS','FA','CR'});
PlotHVLines(0,'h','k:');
end
end
%%
TP = cell(4,1);
TP_probe = cell(4,1);
figure;
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthr{o,d})
            m = nanmean(psthp{o,d}(:,order(separationsign+1:size(psthp{o,d},2))),2);
            s = nansem(psthp{o,d}(:,order(separationsign+1:size(psthp{o,d},2)))')';
            plot(m,'color',gray,'linewidth',2);
            plot(m+s,'color',gray);plot(m-s,'color',gray);
            m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
            s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
            plot(m,'r','linewidth',2);
            plot(m+s,'r');plot(m-s,'r');  
            TP{o}(:,:,d) = psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))';
            TP_probe{o}(:,:,d) = psthp{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))';
        end
        ylim([-0.1 0.1]);
        axis off;
    end    
end

%take all days  
figure;
vals = [];
vals2 = [];
vals3 = [];
mid = 29:47;
subplot(2,2,1);hold on;
for o=1:4
    thisdat = TP{o}(:,:,:)- ...
        nanmean(TP{o}(:,13:15,:),2);
    tpp = nanmean(thisdat,3);
    plot(nanmean(tpp),'color',colors_outcomesfull{o},'linewidth',2); 
    plot(nanmean(tpp)+sem(tpp),'color',colors_outcomesfull{o}); 
    plot(nanmean(tpp)-sem(tpp),'color',colors_outcomesfull{o}); 
    vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) o*ones(size(tpp,1),1)]];
    vals2 = [vals2; [nanmean(tpp(:,tonewin),2) o*ones(size(tpp,1),1)]];
    vals3 = [vals3; [nanmean(tpp(:,mid),2) o*ones(size(tpp,1),1)]];
    if o==1
        thisdat = TP_probe{o}(:,:,:)- ...
            nanmean(TP_probe{o}(:,13:15,:),2);
        tpp = nanmean(thisdat,3);        
        plot(nanmean(tpp),'color',gray,'linewidth',2); 
        plot(nanmean(tpp)+sem(tpp),'color',gray); 
        plot(nanmean(tpp)-sem(tpp),'color',gray); 
        vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) 5*ones(size(tpp,1),1)]];
        vals2 = [vals2; [nanmean(tpp(:,tonewin),2) 5*ones(size(tpp,1),1)]];
        vals3 = [vals3; [nanmean(tpp(:,mid),2) 5*ones(size(tpp,1),1)]];
    end
end
PlotIntervals([mid(1) mid(end)],'color','b','alpha',0.3);
PlotIntervals(posttonewind);
PlotIntervals([tonewin(1) tonewin(end)]);
PlotHVLines(15,'v','k');
PlotHVLines(0,'h','k:');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
xlabel('Time fron tone onset (s)');
subplot(2,2,2);hold on;
title('late window');
kruskalbar(vals(:,1),vals(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});
subplot(2,2,3);hold on;
title('tone window');
kruskalbar(vals2(:,1),vals2(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});
subplot(2,2,4);hold on;
title('mid window');
kruskalbar(vals3(:,1),vals3(:,2));
set(gca,'xtick',1:5,'xticklabel',{'H','M','FA','CR','Hp'});

%take all days, probe only  
figure;
vals = [];
vals2 = [];
vals3 = [];
mid = 29:47;
subplot(2,2,1);hold on;
for o=1:4
    thisdat = TP_probe{o}(:,:,:)- ...
        nanmean(TP_probe{o}(:,13:15,:),2);
    tpp = nanmean(thisdat,3);
    plot(nanmean(tpp),'color',colors_outcomesfull{o},'linewidth',2); 
    plot(nanmean(tpp)+sem(tpp),'color',colors_outcomesfull{o}); 
    plot(nanmean(tpp)-sem(tpp),'color',colors_outcomesfull{o}); 
    vals = [vals; [nanmean(tpp(:,posttonewind(1):posttonewind(2)),2) o*ones(size(tpp,1),1)]];
    vals2 = [vals2; [nanmean(tpp(:,tonewin),2) o*ones(size(tpp,1),1)]];
    vals3 = [vals3; [nanmean(tpp(:,mid),2) o*ones(size(tpp,1),1)]];    
end
PlotIntervals([mid(1) mid(end)],'color','b','alpha',0.3);
PlotIntervals(posttonewind);
PlotIntervals([tonewin(1) tonewin(end)]);
PlotHVLines(15,'v','k');
PlotHVLines(0,'h','k:');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
xlabel('Time fron tone onset (s)');
title('Probe');
subplot(2,2,2);hold on;
title('late window');
kruskalbar(vals(:,1),vals(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});
subplot(2,2,3);hold on;
title('tone window');
kruskalbar(vals2(:,1),vals2(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});
subplot(2,2,4);hold on;
title('mid window');
kruskalbar(vals3(:,1),vals3(:,2));
set(gca,'xtick',1:4,'xticklabel',{'H','M','FA','CR'});

% day 7, reward prediction (neg sign)
figure;hold on;
subplot(2,2,1);hold on;
title('Day7');
d=8;
o=1; %hit
m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
plot(m,'color',h_color,'linewidth',2);
plot(m+s,'color',h_color);plot(m-s,'color',h_color); 
m = nanmean(psthp{o,d}(:,order(separationsign+1:size(psthp{o,d},2))),2);
s = nansem(psthp{o,d}(:,order(separationsign+1:size(psthp{o,d},2)))')';
plot(m,'color',gray,'linewidth',2);
plot(m+s,'color',gray);plot(m-s,'color',gray);
o=2; %miss
m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
plot(m,'color',m_color,'linewidth',2);
plot(m+s,'color',m_color);plot(m-s,'color',m_color); 
o=3; %fa
m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
plot(m,'color',fa_color,'linewidth',2);
plot(m+s,'color',fa_color);plot(m-s,'color',fa_color); 
o=4; %cr
m = nanmean(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2))),2);
s = nansem(psthr{o,d}(:,order(separationsign+1:size(psthr{o,d},2)))')';
plot(m,'color',cr_color,'linewidth',2);
plot(m+s,'color',cr_color);plot(m-s,'color',cr_color); 
window2consider = [30 50];
PlotHVLines(0,'h','k');
PlotHVLines(15,'v','k');
PlotIntervals([30 50]);
set(gca,'xtick',0:15:75,'xticklabel',-1:4);

data = [nanmean(psthr{1,d}(window2consider,order(separationsign+1:size(psthr{o,d},2))))' ...
    nanmean(psthp{1,d}(window2consider,order(separationsign+1:size(psthr{o,d},2))))' ...
    nanmean(psthr{2,d}(window2consider,order(separationsign+1:size(psthr{o,d},2))))' ...
    nanmean(psthr{3,d}(window2consider,order(separationsign+1:size(psthr{o,d},2))))' ...
    nanmean(psthr{4,d}(window2consider,order(separationsign+1:size(psthr{o,d},2))))'];
subplot(2,2,2);hold on;
% hold on;boxplot(data);
hold on;kruskalbar(data);

ylim([-0.07 0.15]);
[p,~,stats] = friedman(data(~any(isnan(data),2),:));
title(['Friedman p=' num2str(p)]);
p12 = signrank(data(~any(isnan(data),2),1),data(~any(isnan(data),2),2));
p13 = signrank(data(~any(isnan(data),2),1),data(~any(isnan(data),2),3));
p14 = signrank(data(~any(isnan(data),2),1),data(~any(isnan(data),2),4));
p23 = signrank(data(~any(isnan(data),2),2),data(~any(isnan(data),2),3));
p24 = signrank(data(~any(isnan(data),2),2),data(~any(isnan(data),2),4));
p34 = signrank(data(~any(isnan(data),2),3),data(~any(isnan(data),2),4));
set(gca,'xtick',1:4,'xticklabel',{'HIT','HIT Probe','MISS','FA'});

%% Example neuron with positive weight (negative activity)
for or=10:separationsign
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0.5 1 0.5]);
for d=1:15
    for o=1:4
        subplot(4,15,d+(o-1)*15);hold on;
        if o==1
            title(['D' num2str(d)]);
            if d==1
                title(['Cell ' num2str(reward_cells_GNG_idx(order(or)))]);
            end
        end
        if d==1 
            if o==1
                ylabel('HIT');
            elseif o==2
                ylabel('MISS');
            elseif o==3
                ylabel('FA');
            else
                ylabel('CR');
            end
        end
%         if d==1 && o==1
%             [~,order] = sort(mean(psthr{o,d}));
%         end
        if ~isempty(psthr{o,d})
            m = psthp{o,d}(:,order(or));
            plot(m,'color',gray,'linewidth',2);
            m = psthr{o,d}(:,order(or));
            plot(m,'b','linewidth',2);
            PlotIntervals(posttonewind);
        end
        ylim([-0.2 0.2]);
        axis off;
    end    
end
pause();
close(fig);
end
%% correlation TCA weights with peak tone-evoked activity

figure;
for comp=1:5
    tav = av_psth_H-mean(av_psth_H(:,10:14,:),2);
    avP = mean(mean(tav(1:nCellsGNG,tonewin,nblocs_expert-3:nblocs_expert),3),2);
    wP = K.U{dim}(1:nCellsGNG,comp);
    subplot(3,3,comp);hold on;
    scatter(wP,avP,'.');
    PlotHVLines(0,'h','k');
    PlotHVLines(0,'v','k');
end

figure;
for comp=1:5
    tav = av_psth_H-mean(av_psth_FA(:,10:14,:),2);
    avP = mean(mean(tav(1:nCellsGNG,tonewin,nblocs_expert-3:nblocs_expert),3),2);
    wP = K.U{dim}(1:nCellsGNG,comp);
    subplot(3,3,comp);hold on;
    scatter(wP,avP,'.');
    PlotHVLines(0,'h','k');
    PlotHVLines(0,'v','k');
end

figure;
histogram(wP(avP<0),'normalization','probability');
PlotHVLines(0,'v','k');
PlotHVLines(median(wP(avP<0)),'v','r');

%%
dim=1;
r=5;
ok = K.U{dim}(:,r)<=-limit;
pos_reward_cells_idx = find(ok);
pos_reward_cells_GNG_idx = pos_reward_cells_idx(pos_reward_cells_idx<nCellsGNG);
nPosRewCellsGNG = length(pos_reward_cells_GNG_idx);

[psthshort,psthlong] = PlotThatCellActivitiesFAlicks(pos_reward_cells_GNG_idx,true);

figure;
diffshortlong = psthshort-psthlong;
[~,order] = sort(mean(diffshortlong(16:end,:)),'descend');
PlotColorCurves(diffshortlong(:,order)');
clim([-0.08 0.08]);
colormap parula;
PlotHVLines(15,'v','w');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
ylabel('(-)-weights comp #5');
xlabel('Relative time from tone onset (s)');
title('short - long FA lick latencies');

%% plot activity based on exclusive groups

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
for r=1:R
    subplot(R,1,r);hold on;
    weight_trial_type = K.U{4}(:,r);
    w_psth_h = av_psth_H*weight_trial_type(1);
    w_psth_fa = av_psth_FA*weight_trial_type(2);
    w_psth_cr = av_psth_CR*weight_trial_type(3);
    w_psth = w_psth_h;
    w_psth(:,:,:,2) = w_psth_fa;
    w_psth(:,:,:,3) = w_psth_cr;
    w_av_psth = nanmean(w_psth,4); % weighted averaged
    
    w_av_psth = w_av_psth(ordermax,:,:); % reorder trace
    in = ismember(x,nPerComp(r)+1:nPerComp(r+1));
    
    nblocs = size(w_av_psth,3);
    togroup = 6;
    ntotgrouped = round(nblocs/togroup)-1;    
    TP = nan(size(idx_order,1),size(w_av_psth,2),ntotgrouped);
    for b = 1:ntotgrouped
        toplot = w_av_psth(:,:,1+(b-1)*togroup:togroup+(b-1)*togroup);
        TP(:,:,b) = nanmean(toplot(idx_order,:,:),3);        
    end
    toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
    toplot = toplot(in,:);
    [~,thiscomporder] = sort(neuronal_factor(in,r),'descend');
    PlotColorCurves(toplot(thiscomporder,:));
%     PlotColorCurves(w_av_psth(in,:));
    clim([0 0.2]);
    PlotHVLines(75:75:ntotgrouped*75,'v','w');
    axis off;
    colormap jet;
    ylabel(['component #' num2str(r)]);
%     title(['Weighted average, comp #' num2str(r) ' (H=' num2str(weight_trial_type(1)) ', FA=' num2str(weight_trial_type(2))...
%         ', CR=' num2str(weight_trial_type(3)) '), 100-trial bloc, n='...
%         num2str(length(idx_order)) ' cells']);
end


fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
for r=1:R
    subplot(R,1,r);hold on;
    weight_trial_type = K.U{4}(:,r);
    w_psth_h = av_psth_H*weight_trial_type(1);
    w_psth_fa = av_psth_FA*weight_trial_type(2);
    w_psth_cr = av_psth_CR*weight_trial_type(3);
    w_psth = w_psth_h;
    w_psth(:,:,:,2) = w_psth_fa;
    w_psth(:,:,:,3) = w_psth_cr;
    w_av_psth = nanmean(w_psth,4); % weighted averaged
    
    w_av_psth = w_av_psth(ordermax,:,:); % reorder trace
    in = ismember(x,nPerComp(r)+1:nPerComp(r+1));
    
    nblocs = size(w_av_psth,3);
    togroup = 6;
    ntotgrouped = round(nblocs/togroup)-1;    
    TP = nan(size(idx_order,1),size(w_av_psth,2),ntotgrouped);
    for b = 1:ntotgrouped
        toplot = w_av_psth(:,:,1+(b-1)*togroup:togroup+(b-1)*togroup);
        TP(:,:,b) = nanmean(toplot(idx_order,:,:),3);        
    end
    toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
    plot(nanmean(toplot(in,:)));
    vec_bloc_lim = 75:75:ntotgrouped*75;
    ylim([-0.005 0.04]);
    PlotHVLines(vec_bloc_lim,'v','color',gray);
    nblocacqui = size(M_acqui{1},4);
    threshold_acqui = nblocacqui*75/togroup;
    threshold_acq = find(vec_bloc_lim<threshold_acqui,1,'last');
    PlotHVLines(vec_bloc_lim(threshold_acq),'v','r');
    PlotHVLines(0,'h','k');
    ylabel(['component #' num2str(r)]);
%     title(['Weighted average, comp #' num2str(r) ' (H=' num2str(weight_trial_type(1)) ', FA=' num2str(weight_trial_type(2))...
%         ', CR=' num2str(weight_trial_type(3)) '), 100-trial bloc, n='...
%         num2str(length(idx_order)) ' cells']);
end

%% look at mix cells

% a mix cell is a cell having high weight in multiple components
% high weight = top 20% of positive weight

% 1) get cell ID of top 20% for each components
dim = 1; % neuronal factor
idx = nan(nCellsTot,R);
for r=1:R    
%     tresh = quantile(K.U{dim}(:,r),0.8);
    tresh = limit;
    ok = abs(K.U{dim}(:,r))>=tresh;
%     tresh = quantile(K.U{dim}(:,r),0.2);
%     ok = K.U{dim}(:,r)<=tresh;
    idx(:,r) = ok;
%     figure;bar(neuronal_f);
%     hold on;PlotHVLines(tresh,'h','k:');
end
    
% 2) identify exclusive vs mix cells, 2 vs 3 vs more components
celltype = nan(nCellsTot,R);
for r=1:R
    celltype(:,r) = sum(idx,2)==r;
end
ncelltype = sum(celltype);
figure;
subplot(2,2,1);hold on;
bar(ncelltype/sum(ncelltype));
ylabel('Proportion of cells');xlabel('Cell category');
subplot(2,2,2);hold on;
pie(ncelltype/sum(ncelltype));
axis off;
ylimm = [0 1];
subplot(2,5,6);hold on;
bar(sum(idx(sum(idx,2)==1,:))./sum(idx));
ylim(ylimm);
subplot(2,5,7);hold on;
bar(sum(idx(sum(idx,2)==2,:))./sum(idx));
ylim(ylimm);
subplot(2,5,8);hold on;
bar(sum(idx(sum(idx,2)==3,:))./sum(idx));
ylim(ylimm);
subplot(2,5,9);hold on;
bar(sum(idx(sum(idx,2)==4,:))./sum(idx));
ylim(ylimm);
subplot(2,5,10);hold on;
bar(sum(idx(sum(idx,2)==5,:))./sum(idx));
ylim(ylimm);


% 3) look at which components are associated
% first, only 2 associations
r=2;
these = sum(idx,2)==r;
associations = nan(sum(these),r);
a = 0;
for c=1:nCellsTot
    if these(c)
        a = a+1;
        associations(a,:) = find(idx(c,:));
    end
end
associations = sortrows(associations);
[u_associations,~,ii] = unique(associations,'rows');
count = Accumulate(ii);
mat = Accumulate(associations);
figure;
subplot(2,2,1);hold on;
PlotColorMap(mat);colormap jet;
clim([0 80]);
mat = Accumulate([associations;flip(associations,2)]);
subplot(2,2,2);hold on;
circularGraph(mat);

[~,order] = sort(count,'descend');
order_assoc = u_associations(order,:);
alltog = [order_assoc,sort(count,'descend')];
subplot(2,2,3);hold on;
bar(alltog(:,3)/nCellsTot);

fig2svg(['E:\KishoreLab\celine\exci\tensor_decomposition\pooled_zscored_5comps\' ...
    'repartition_percent_cells_comps_participation3.svg']);
     
% 
% % find all the 6+9 comp association cell and plot them
% thesecells = find(sum(idx(:,[10 9]),2)==2);
% av_psth = nanmean(original_mat,4);  % cell x time in trial x trial bloc av
% nblocs = size(av_psth,3);
% togroup = 6;
% ntotgrouped = round(nblocs/togroup)-1;    
% TP = nan(length(thesecells),size(av_psth,2),ntotgrouped);
% for b = 1:ntotgrouped
%     toplot = av_psth(:,:,1+(b-1)*togroup:togroup+(b-1)*togroup);
%     TP(:,:,b) = nanmean(toplot(thesecells,:,:),3);        
% end
% toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
% figure;
% subplot(2,1,1);hold on;
% PlotColorCurves(toplot);
% clim([0 0.2]);
% PlotHVLines(75:75:size(toplot,2),'v','w');
% axis off;
% colormap jet;
% % PlotHVLines(vec_bloc_lim(nblocs_acqui),'v','r');    
%     
% subplot(2,1,2);hold on;
% plot(nanmean(toplot),'k','linewidth',2);
% plot(nanmean(toplot)+nansem(toplot),'k');
% plot(nanmean(toplot)-nansem(toplot),'k');
% PlotHVLines(75:75:size(toplot,2),'v','k');
% xlim([0 size(toplot,2)]);
% 
% rtoplot = reshape(toplot,size(toplot,1),75,size(toplot,2)/75);
% for j=19:length(thesecells)
%     fig=figure;
% %     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
% %     plot(toplot(j,:));
% %     title(num2str(j));
% %     PlotHVLines(75:75:size(toplot,2),'v','k');
% %     PlotHVLines(vec_bloc_lim(threshold_acq),'v','r');  
% 
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
%     PlotColorCurves(squeeze(rtoplot(j,:,:))');
%     clim([0 0.2]);
%     colormap jet;
%     PlotHVLines(15,'v','w');
%     PlotHVLines(threshold_acq+0.5,'h','r');    
%     title(num2str(j));
%     pause();
%     close(fig);
% end
% 
% % plot activity selected cells
% selectedcells = [19;22;24;26;27;34;43;44;47;49;59;67];
% nsc = length(selectedcells);
% fig=figure;
% set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
% for j=1:nsc
%     k = selectedcells(j);
%     subplot(1,nsc,j);hold on;
%     PlotColorCurves(squeeze(rtoplot(k,:,:))');
%     clim([0 0.2]);
%     colormap jet;
%     PlotHVLines(15,'v','w');
%     PlotHVLines(threshold_acq+0.5,'h','r');    
%     title(num2str(k));
% end
% fig=figure;
% set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
% subplot(2,1,1);hold on;
% PlotColorCurves(toplot(selectedcells,:));
% clim([0 0.2]);
% colormap jet;
% PlotHVLines(75:75:size(toplot,2),'v','w');
% subplot(2,1,2);hold on;
% plot(nanmedian(toplot(selectedcells,:)));
% xlim([0 size(toplot,2)]);
% PlotHVLines(75:75:size(toplot,2),'v','k');
% 
% % plot image of the selected cells
% selectedcells = thesecells([19;22;24;26;27;34;43;44;47;49;59;67]);
% for j=1:nsc
%     PlotThatCell(selectedcells(j));
% end
% 
% % for cell comp6, find the comp with which they associate the most
% nbofallies = sum(idx(idx(:,6)==1,~ismember(1:R,6)));
% x = [1;2;3;4;5;7;8;9];
% [~,ord] = sort(nbofallies,'descend');
% figure;bar(nbofallies(ord));
% set(gca,'xticklabels',{num2str(x(ord))});

%% plot PSTH all components, top 10% only, positive separated from negative
% mat_acqui = cell2mat(M_acqui);
% mat_acqui = permute(mat_acqui,[1 2 4 3]); % cell x time in trial x trial bloc av x trial type
% mat_exp = cell(nGNG,1);
% for m=1:nGNG
%     mat_exp{m} = M_exp{m}(:,:,:,end-nBlocTarget_exp+1:end);
% end
% mat_exp = cell2mat(mat_exp);
% mat_exp = permute(mat_exp,[1 2 4 3]); % cell x time in trial x trial bloc av x trial type
% mat = mat_acqui;
% n3_acqui = size(mat,3);
% n3_exp = size(mat_exp,3);
% mat(:,:,n3_acqui+1:n3_acqui+n3_exp,:) = mat_exp;

av_psth = squeeze(nanmean(original_mat,4));
nCellsTot = size(av_psth,1);
nGroupBloc = 2;
dim=1; % neuronal factor
%%
for r=10
% for r=10
    % Select positive 10%
    tresh = quantile(abs(K.U{dim}(:,r)),0.90); % plot only 10% positive population 
    idx = K.U{dim}(:,r)>=tresh;
    
    % Select NEGATIVE 10%
%     tresh = quantile(K.U{dim}(:,r),0.1); % plot only 10% negative population
%     idx = K.U{dim}(:,r)<=tresh;
    
    
    
%     disp(['comp #' num2str(r) ', n=' num2str(sum(idx))]);
         
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
    
    limacqui = (37/nGroupBloc)*75;
    nblocs = size(av_psth,3);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    TP = nan(sum(idx),size(av_psth,2),ntotgrouped);
    for b = 1:ntotgrouped
        toplot = av_psth(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
        TP(:,:,b) = nanmean(toplot(idx,:,:),3);        
    end
    toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
    subplot(2,1,1);hold on;
    [~,order] = sort(K.U{dim}(idx,r),'descend');
    PlotColorCurves(toplot(order,:));
    clim([0 0.2]);
    PlotHVLines(75:75:size(toplot,2),'v','w');
    colormap jet;
    ylabel(['component #' num2str(r)]);
    title(['Av trial type, comp #' num2str(r) ', ' num2str(20*nGroupBloc) '-trial bloc, n='...
        num2str(sum(idx)) ' cells']);
    
    subplot(2,1,2);hold on;
    mtoplot = nanmean(toplot);
    stoplot = nansem(toplot);
    plot(mtoplot,'k','linewidth',2);
    plot(mtoplot+stoplot,'k');
    plot(mtoplot-stoplot,'k');
    ylim([-0.05 0.3]);
    PlotHVLines(75:75:size(toplot,2),'v','k');
    xlim([0 size(toplot,2)]);    
    PlotHVLines(0,'h','k:');  
    PlotHVLines([nblocs_acqui*20*75/(nGroupBloc*20);nblocs_expert*20*75/(nGroupBloc*20)],'v','color','r');
    
    drawnow
end
%% Plot indiv cell comp #7
dim=1;
r=7;
tresh = quantile(K.U{dim}(:,r),0.95); % plot only 10% positive population 
cellIDs = find(K.U{dim}(:,r)>=tresh);
for i=7:length(cellIDs)
    PlotThatCell(cellIDs(i));
    drawnow;
end
%% Plot activity back in time
% select your component
toplotsign = 'neg';
% toplotsign = 'pos';
for r=5    
    tresh = limit;
    if strcmp(toplotsign,'neg')
        idx = K.U{dim}(:,r)<=-tresh;
    elseif strcmp(toplotsign,'pos')
        idx = K.U{dim}(:,r)>=tresh;
    end  
    
    idxcells = find(idx);
    [~,morder] = InIntervals(idxcells,nCellsPerMouseintervals);
    
    idcells = idxcells(morder==2)-(nCellsPerMouseintervals(2,1)-1);
    tonepsth = tonepsth_cd036;
    tonepsthr = tonepsth(:,1);
    tonepsthp = tonepsth(:,2);
    mouse = mice{2};
    
    % Organize data and build tensor
    results = load([path mouse '-results_nosignals.mat']);
    results = results.results;
    nFrames_oneplane = results{1};
    matrix = results{3};
    ishere = results{4};
    ks = results{5};
    ks2 = results{6};
    ctx = results{7};
    acq = results{8};
    TONEF = results{9};
    REWF = results{10};
    dayss_behav = results{12};
    startfrom = results{13};
    nDays_behav = length(dayss_behav);
    if strcmp(mouse,'cd017')
        nop = matrix(:,BLOC)==4; % remove bad trials
    else
        nop = ~ismember(matrix(:,BLOC),matrix(:,BLOC)); % take everything
    end
    
    figure;
    for d=1:nDays_behav
        subplot(4,4,d);hold on;
        okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);        
        toplot = squeeze(nanmean(tonepsthr{d}(:,ks(okreinf,1),idcells),2));
        ztoplot = zscore(toplot,[],1);
        stoplot = smoothdata(ztoplot,1,'movmean',5);
        stoplot = stoplot-mean(stoplot(1:14,:));
        plot(stoplot);
    end
    
    figure;
    for d=1:nDays_behav
        subplot(4,4,d);hold on;
        okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);        
        toplot = squeeze(nanmean(tonepsthr{d}(:,ks(okreinf,1),idcells),2));
        ztoplot = zscore(toplot,[],1);
        stoplot = smoothdata(ztoplot,1,'movmean',5);
        stoplot = stoplot-mean(stoplot(1:14,:));
        PlotColorCurves(stoplot');
        clim([-2 2]);
    end
    colormap jet;
    
    for c=1:length(idcells)
        figure;
        for d=1:nDays_behav
            subplot(4,4,d);hold on;
            okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);        
            toplot = squeeze(nanmean(tonepsthr{d}(:,ks(okreinf,1),idcells(c)),2));
            ztoplot = zscore(toplot,[],1);
            stoplot = smoothdata(ztoplot,1,'movmean',5);
            stoplot = stoplot-mean(stoplot(1:14,:));
            plot(stoplot);
            ylim([-2 3]);
            PlotHVLines(0,'h','k');
            PlotHVLines(15,'v','k');
            if d==1, title([mouse ', #' num2str(idcells(c))]); end
        end
        drawnow;
    end
    
    indexglobal = idxcells(morder==2);
    imgs = PlotThatCell(indexglobal(find(idcells==22)));
    figure;
    for i=1:16
        subplot(2,8,i); hold on;
        imagesc(imgs{i,1});colormap gray;
%         pout_imadjust = imadjust(imgs{i,1});
        pout_histeq = histeq(imgs{i,1});
%         pout_adapthisteq = adapthisteq(imgs{i,1});
%         axis off;
    end
    c = find(idcells==22);
    
    
    figure;
    for d=1:nDays_behav
        for o=1:4
            subplot(4,nDays_behav,d + (o-1)*nDays_behav);hold on;
            okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);        
            toplot = squeeze(nanmean(tonepsthr{d}(:,ks(okreinf,o),idcells(c)),2));
            s = squeeze(nansem(tonepsthr{d}(:,ks(okreinf,o),idcells(c))'));
%             ztoplot = zscore(toplot,[],1);
            ss = smoothdata(s',1,'movmean',5);
            ss = ss-mean(stoplot(1:14,:));
            stoplot = smoothdata(toplot,1,'movmean',5);
            stoplot = stoplot-mean(stoplot(1:14,:));
            plot(stoplot,'color',outcome_colors{o},'linewidth',2);
            plot(stoplot+ss,'color',outcome_colors{o});
            plot(stoplot-ss,'color',outcome_colors{o});
%             ylim([-2 3]);
            ylim([-0.1 0.1]);
            PlotHVLines(0,'h','k');
            PlotHVLines(15,'v','k');
            if d==1, title([mouse ', #' num2str(idcells(c)) '(' num2str(sum(ks(okreinf,o))) ')']);
            else, title(num2str(sum(ks(okreinf,o)))); end     
            axis off;
        end
    end
    drawnow;
    
    figure;
    for d=1:nDays_behav
        for o=1:4
            subplot(4,nDays_behav,d + (o-1)*nDays_behav);hold on;
            okprobe = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,2);        
            toplot = squeeze(nanmean(tonepsthp{d}(:,ks(okprobe,o),idcells(c)),2));
            s = squeeze(nansem(tonepsthp{d}(:,ks(okprobe,o),idcells(c))'));
%             ztoplot = zscore(toplot,[],1);
            ss = smoothdata(s',1,'movmean',5);
            ss = ss-mean(stoplot(1:14,:));
            stoplot = smoothdata(toplot,1,'movmean',5);
            stoplot = stoplot-mean(stoplot(1:14,:));
            plot(stoplot,'k','linewidth',2);
            plot(stoplot+ss,'k');
            plot(stoplot-ss,'k');
%             ylim([-2 3]);
            ylim([-0.1 0.1]);
            PlotHVLines(0,'h','k');
            PlotHVLines(15,'v','k');
            if d==1, title([mouse ', #' num2str(idcells(c)) '(' num2str(sum(ks(okprobe,o))) ')']);
            else, title(num2str(sum(ks(okprobe,o)))); end
        end
    end
    drawnow;
    
    % focus on this cell, day 2
    figure;
    d=2;
    okprobe = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,2);    
    for o=1:4
        subplot(2,2,o);hold on;
        if sum(ks(okprobe,o))==0, continue; end
        toplot = tonepsthp{d}(:,ks(okprobe,o),idcells(c));
        stoplot = smoothdata(toplot,1,'movmean',5);
        stoplot = stoplot-mean(stoplot(1:14,:));
        PlotColorCurves(stoplot');
        PlotHVLines(15,'v','k');
        clim([-0.15 0.15]);
    end
    colormap jet;
    
    d=2;
    okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);   
%     for d=1:nDays_behav
        outcomesnames = {'H','M','FA','CR'};
        fig=figure;  
        for o=1:4
            subplot(2,2,o);hold on;
            toplot = tonepsthr{d}(:,ks(okreinf,o),idcells(c));
            stoplot = smoothdata(toplot,1,'movmean',5);
            stoplot = stoplot-mean(stoplot(1:14,:));
            PlotColorCurves(stoplot');
            PlotHVLines(15,'v','k');
            clim([-0.15 0.15]);
            title(['D' num2str(d) ' - Reinf ' outcomesnames{o}]);
            set(gca,'xtick',0:15:75,'xticklabel',-1:4); 
        end
        colormap jet;
%         pause();
%         close(fig)
%     end
    
    d=1;
    okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);  
    o=1;
    hittrials = ks(okreinf,o);
    thispsth = tonepsthr{d}(:,hittrials,idcells(c));
    for t=1:length(hittrials)
        fig=figure;          
        toplot = thispsth(:,t);
        stoplot = smoothdata(toplot,1,'movmean',5);
    %     stoplot = stoplot-mean(stoplot(1:14,:));
        plot(stoplot,'k','linewidth',2);
        ylim([-0.1 0.1]);
        PlotHVLines(15,'v','k');
        title(['Trial ' num2str(t)]);
        pause();
        close(fig);
    end
    
%     lickpsth_den = load('M:\Celine\exci_variables\cd036-lickpsth_denoised.mat');
%     lpsth = lickpsth_den.lickpsth_den;
    figure;
    d=1;
    okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1); 
    okreinflick = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1) & (ks(:,1)|ks(:,3)); 
    o=3;
    hittrials = ks(okreinf,o);
    idxhit = find(hittrials);
    subplot(1,2,1);hold on;
    toplot = tonepsthr{d,1}(:,hittrials,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',5);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    clim([-0.2 0.2]);
    PlotHVLines(15,'v','k');
    subplot(1,2,2);hold on;
    lhittrials = ks(okreinflick,o);
    idxlhit = find(lhittrials);
    PlotColorCurves(lpsth{d,1}(:,lhittrials,idcells(c))');
    PlotHVLines(15,'v','k');
    clim([0 0.5]);
    colormap jet;
    
    figure;
    subplot(2,2,1);hold on;
    toplot = nanmean(tonepsthr{d}(:,hittrials,idcells(c)),2);
    s = nansem(tonepsthr{d}(:,hittrials,idcells(c))');
    ss = smoothdata(s',1,'movmean',5);
    ss = ss-mean(stoplot(1:14,:));
    stoplot = smoothdata(toplot,1,'movmean',5);
    stoplot = stoplot-mean(stoplot(1:14,:));
    plot(stoplot,'k','linewidth',2);
    plot(stoplot+ss,'k');
    plot(stoplot-ss,'k');    
    set(gca,'xtick',0:15:75, 'xticklabel',-1:4);
    ylabel('Time from tone onset');
%     plot(mean(tonepsthr{d,1}(:,hittrials,idcells(c)),2));
    PlotHVLines(15,'v','k');
    title(['HIT Reinf, av']);    
    subplot(2,2,2);hold on;
    plot(mean(lpsth{d,1}(:,lhittrials,idcells(c)),2),'k','linewidth',2);
    plot(mean(lpsth{d,1}(:,lhittrials,idcells(c)),2)+...
        sem(lpsth{d,1}(:,lhittrials,idcells(c))')','k');
    plot(mean(lpsth{d,1}(:,lhittrials,idcells(c)),2)-...
        sem(lpsth{d,1}(:,lhittrials,idcells(c))')','k');
    PlotHVLines(15,'v','k');
    title(['HIT Reinf, av']);
    set(gca,'xtick',0:15:75, 'xticklabel',-1:4);
    ylabel('Time from 1st lick');
    
    t=125; % trial to plot
    subplot(2,2,3);hold on;
    plot(mean(tonepsthr{d,1}(:,idxhit(t),idcells(c)),2));
    title(['HIT Reinf, trial ' num2str(t)]);
    PlotHVLines(15,'v','k');
    set(gca,'xtick',0:15:75, 'xticklabel',-1:4);
    ylabel('Time from tone onset');
    subplot(2,2,4);hold on;
    plot(mean(lpsth{d,1}(:,idxlhit(t),idcells(c)),2));
    PlotHVLines(15,'v','k');
    title(['HIT Reinf, trial ' num2str(t)]);
    set(gca,'xtick',0:15:75, 'xticklabel',-1:4);
    ylabel('Time from 1st lick');
    
%     toplot = tonepsthr{d}(:,,idcells(c));
    for o=1:4
        subplot(2,2,o);hold on;
        
        stoplot = smoothdata(toplot,1,'movmean',5);
        stoplot = stoplot-mean(stoplot(1:14,:));
        PlotColorCurves(stoplot');
        PlotHVLines(15,'v','k');
        clim([-0.15 0.15]);
        title(['D' num2str(d) ' - Reinf ' outcomesnames{o}]);
        set(gca,'xtick',0:15:75,'xticklabel',-1:4); 
    end
    colormap jet;

    figure;
    d=2;
    okprobe = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,2);   
    okreinf = ismember(matrix(:,DAY),startfrom-1+d) & ~nop & ctx(:,1);   
    subplot(1,2,2);hold on;
    toplot = tonepsthp{d}(:,:,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',5);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    PlotHVLines(15,'v','k');
    clim([-0.2 0.2]);
    
    subplot(1,2,1);hold on;
    toplot = tonepsthr{d}(:,:,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',5);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    PlotHVLines(15,'v','k');
    clim([-0.2 0.2]);
    colormap jet;
    end
    
    
    %%
    figure;    
    hitid = find(ks(okreinf,1));
    theseoutcomes = ks(okreinf,:);
    tocheck = hitid-1;tocheck(tocheck==0)=[];
    haftermistake = logical(sum(theseoutcomes(tocheck,[2 3]),2));
    hit_mistakebefore = tocheck(haftermistake)+1;
    tocheck = hitid+1;
    if tocheck(end)>length(theseoutcomes), tocheck(end)=[]; end
    beforemistake = logical(sum(theseoutcomes(tocheck,[2 3]),2));
    hit_mistakeafter = tocheck(beforemistake)-1;
    
    
    beforemiss = logical(sum(theseoutcomes(tocheck,2),2));
    hit_missafter = tocheck(beforemiss)-1;
    
    tocheck = hitid-1;tocheck(tocheck==0)=[];
    hitbis = logical(sum(theseoutcomes(tocheck,1),2));
    hit_hit = tocheck(hitbis)+1;
    
    subplot(2,2,1);hold on;
    toplot = tonepsthr{d}(:,hit_mistakebefore,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',7);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    PlotHVLines(15,'v','k');
    clim([-0.2 0.2]);
    title('HIT preceeded by MorFA');
    subplot(2,2,2);hold on;
    toplot = tonepsthr{d}(:,hit_mistakeafter,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',7);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    PlotHVLines(15,'v','k');
    clim([-0.2 0.2]);
    title('HIT followed by MorFA');
    
    subplot(2,2,3);hold on;
    toplot = tonepsthr{d}(:,hit_missafter,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',7);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    PlotHVLines(15,'v','k');
    clim([-0.2 0.2]);
    title('HIT followed by M');
    
    subplot(2,2,4);hold on;
    toplot = tonepsthr{d}(:,hit_hit,idcells(c));
    stoplot = smoothdata(toplot,1,'movmean',7);
    stoplot = stoplot-mean(stoplot(1:14,:));
    PlotColorCurves(stoplot');
    PlotHVLines(15,'v','k');
    clim([-0.2 0.2]);
    title('HIT - HIT');
    colormap jet;
    
% end
%% plot separatly H, FA and CR
if ~passive
    sigtypes = {av_psth_H,av_psth_FA,av_psth_CR};    
    av_psth_HnoZ = squeeze(noZmat(:,:,:,1));
    av_psth_FAnoZ = squeeze(noZmat(:,:,:,2));
    av_psth_CRnoZ = squeeze(noZmat(:,:,:,3));
%     av_psth_HnoZ(av_psth_HnoZ==0) = nan;
%     av_psth_FAnoZ(av_psth_FAnoZ==0) = nan;
%     av_psth_CRnoZ(av_psth_CRnoZ==0) = nan;

    for j=1:size(av_psth_CRnoZ,3)
        theese = av_psth_HnoZ(:,:,j);
        thesenull = sum(theese,2)==0;
        av_psth_HnoZ(thesenull,:,j) = nan;
        theese = av_psth_FAnoZ(:,:,j);
        thesenull = sum(theese,2)==0;
        av_psth_FAnoZ(thesenull,:,j) = nan;
        theese = av_psth_CRnoZ(:,:,j);
        thesenull = sum(theese,2)==0;
        av_psth_CRnoZ(thesenull,:,j) = nan;
    end
    
    mmH = [];mmFA = [];mmCR = [];
    for j=1:size(intervalsCells,1)
        mmH = [mmH; mean(av_psth_HnoZ(intervalsCells(j,1):intervalsCells(j,2),:,:))];
        mmFA = [mmFA; mean(av_psth_FAnoZ(intervalsCells(j,1):intervalsCells(j,2),:,:))];
        mmCR = [mmCR; mean(av_psth_CRnoZ(intervalsCells(j,1):intervalsCells(j,2),:,:))];
    end
    nbFA = squeeze(sum(mmFA,2)==0);
    nbCR = squeeze(sum(mmCR,2)==0);
    nbH = squeeze(sum(mmH,2)==0);
    figure;
    subplot(2,2,1);hold on;
    imagesc(nbFA);
    subplot(2,2,2);hold on;
    imagesc(nbCR);
    subplot(2,2,3);hold on;
    imagesc(nbH);
%     av_psth_HnoZ(av_psth_HnoZ==0) = nan;
%     av_psth_FAnoZ(av_psth_FAnoZ==0) = nan;
%     av_psth_CRnoZ(av_psth_CRnoZ==0) = nan;
    sigtypesNoZ = {av_psth_HnoZ,av_psth_FAnoZ,av_psth_CRnoZ};
else
    sigtypes = {av_psth_H,av_psth_FA};
end
nGroupBloc = 2;
xcells = (1:size(av_psth_HnoZ,1))';
% focus = 'positive'; % negative or positive
% for r=1:R
ylimm = [-0.05 0.18];
% ylimm = [-2 4];
ylimmex = [-0.1 1.5];
% ylimmex = [-2 4];
dim = 1;
% toplotsign = 'neg';
toplotsign = 'pos';
% close all hidden;
% savecolormapsvg = true;
savecolormapsvg = false;
nblocs = size(av_psth_H,3);
for r=2
    weight_trial_type = K.U{4}(:,r);
    
    tresh = limit;
%     tresh = quantile(K.U{dim}(:,r),0.85);
%     tresh = quantile(abs(K.U{dim}(:,r)),0.90); % plot only 10% population 
    
%     % Select positive 10%
%     tresh = quantile(K.U{dim}(:,r),0.90); % plot only 10% positive population 
    
    if strcmp(toplotsign,'neg')
        idx = K.U{dim}(:,r)<=-tresh;
    elseif strcmp(toplotsign,'pos')
        idx = K.U{dim}(:,r)>=tresh;
    end  
    
%         idx = K.U{dim}(:,3)<=-tresh & K.U{dim}(:,5)>=tresh;
%     idx = K.U{dim}(:,3)>=tresh & K.U{dim}(:,5)<=-tresh;
%     idx = K.U{dim}(:,3)<=-tresh & K.U{dim}(:,5)<=-tresh;
%     idx = K.U{dim}(:,4)>=tresh & K.U{dim}(:,5)<=-tresh;
    
%     figure;hold on;
%     plot(K.U{dim}(idx,3),K.U{dim}(idx,5),'k.');
%     plot(K.U{dim}(:,3),K.U{dim}(:,5),'.','color',gray);
%     idx = K.U{dim}(:,5)>=tresh;
%     sum(idx)/length(idx)
    
    propGNG = sum(find(idx)<=nCellsGNG)/sum(idx~=0)*100;
    propGNGamongGNG = sum(find(idx)<=nCellsGNG)/nCellsGNG*100;
    propPASSIVE = sum(find(idx)>nCellsGNG)/sum(idx~=0)*100;
    propPASSIVEamongPASSIVE = sum(find(idx)>nCellsGNG)/(nCellsPerMouse(end)-nCellsGNG)*100;
        
    [~,order1] = sort(K.U{dim}(:,r),'descend');
    fig=figure; % plot weigths
    bar(1:length(idx),K.U{dim}(order1,r));
    hold on;%ylim([-0.2 0.4]);  
    if strcmp(toplotsign,'pos')
        PlotHVLines(sum(idx),'v','r');
    elseif strcmp(toplotsign,'neg')
        PlotHVLines(length(idx)-sum(idx),'v','r');
    end
    title(['component #' num2str(r) ' (n=' num2str(sum(idx)) ' selected)']);
    ylabel('Weight');xlabel('Cell');
%      
    % Select NEGATIVE 10%
%     tresh = quantile(K.U{dim}(:,r),0.10); % plot only 10% negative population
%     idx = K.U{dim}(:,r)<=tresh;
%     [~,order1] = sort(K.U{dim}(:,r),'ascend');  
%     weights = flip(K.U{dim}(order1,r));
%     h=histogram(weights,'BinWidth',0.01);
%     [~,wmax] = max(h.Values);
%     notaken = [h.BinEdges(wmax-1) h.BinEdges(wmax+1)];
%     weights_taken = weights(weights<notaken(1) | weights>notaken(2));
%     fig=figure;hold on;stem(weights,'filled','k');
%     stem(find(weights<notaken(1) | weights>notaken(2)),weights_taken,'filled','r');
%     diffweights = diff(weights);
%     h = histogram(diffweights,'BinWidth',0.0005);
%     idx_higher = find(diffweights<h.BinEdges(end-1));
%     idx_higher = [1;idx_higher+1];
% %     figure;histogram(diffweights);
%     fig=figure; % plot weigths
% %     bar(1:length(idx),flip(K.U{dim}(order1,r)));
%     stem(flip(K.U{dim}(order1,r)),'filled','k');
%     hold on;
% %     ylim([-0.2 0.4]);
%     ylabel('Weight');xlabel('Cell'); 
%     stem(idx_higher,weights(idx_higher),'filled','r');
%     % identify the gap
%     [~,wmax] = max(diff(idx_higher));
%     interval_high = [1 idx_higher(wmax)];
%     interval_low = [idx_higher(wmax+1) length(weights)];
%     if strcmp(focus,'negative')
%         idx = interval_low(1):interval_low(end);
%         PlotHVLines(min(idx),'v','r');
%     elseif strcmp(focus,'positive')
%         idx = interval_high(1):interval_high(end);
%         PlotHVLines(max(idx),'v','r');
%     end
%     title(['component #' num2str(r) ' (n=' num2str(length(idx)) ')']);
%     order1flip = flip(order1);
%     idx = order1flip(idx);
    
    
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);    
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    for o=1:outcomes
%         TP = nan(length(idx),size(av_psth_H,2),ntotgrouped);
        TP = nan(sum(idx~=0),size(av_psth_H,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
            TP(:,:,b) = nanmean(toplot(idx,:,:),3);        
        end
        subplot(3,1,o);hold on;
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
        [~,order] = sort(K.U{dim}(idx,r),'descend');
                 
%         PlotColorCurves(toplot(order,:));
%         clim([0 0.25]);
%         PlotHVLines(75:75:size(toplot,2),'v','w');
% %         PlotHVLines(npos,'h','w');
%         colormap jet;
        plot(nanmean(toplot(order,:)),'color',colors_outcomes{o},'linewidth',2);
        plot(nanmean(toplot(order,:))+nansem(toplot(order,:)),'color',colors_outcomes{o});
        plot(nanmean(toplot(order,:))-nansem(toplot(order,:)),'color',colors_outcomes{o});
        xlim([0 size(toplot,2)]);
%         ylim([-0.05 0.3]);
        ylim(ylimm);
        PlotHVLines(75:75:size(toplot,2),'v','k');
        PlotHVLines(0,'h','k:');
%         
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        if o==1
            title(['Average, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
                '-trial bloc, n='...
            num2str(sum(idx(idx~=0))) ' cells']);
        end        
%         nblocs_acqui = nBlocTarget_acqui;
%         nblocs_expert = size(K.U{3},1)-nBlocTarget_expert;
        PlotHVLines([nblocs_acqui*20*75/(nGroupBloc*20);nblocs_expert*20*75/(nGroupBloc*20)],...
            'v','color','r','linewidth',2);            
    end
    drawnow;
    
    % find posttone window according to comp 5 trace
    xx = find(K.U{2}(:,5)<-0.1);
    posttonewind = [xx(1) xx(end)];

    % LEARNING cells only
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
    nGroupBloc=2;
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    ok = xcells<=nCellsGNG;
    for o=1:3
        for b = 1:ntotgrouped
            subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
            toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
            data = nanmean(toplot(idx & ok,:,:),3);
            data_bas = data-mean(data(:,10:14),2);
            plot(nanmean(data_bas),'color',colors_outcomes{o},'linewidth',2);
            plot(nanmean(data_bas)+nansem(data_bas),'color',colors_outcomes{o});
            plot(nanmean(data_bas)-nansem(data_bas),'color',colors_outcomes{o});
            xlim([0 size(toplot,2)]);
%             ylim(ylimm);
%             ylim([-0.08 0.09]);
            ylim([-0.08 0.3]);
            PlotHVLines(0,'h','k:');
            PlotHVLines(15,'v','k');
            axis off;
%             PlotIntervals([posttonewind(1) posttonewind(end)]);
        end
    end
    if r==5 % pos weights
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
%         posttonewind = posttonewind(1):posttonewind(end);
        ok = xcells<=nCellsGNG;
        ylimm = [-0.05 0.05];
        namesOutcomes = {'H','FA','CR'};
        for o=1:3
            subplot(3,1,o);hold on;
            d2compare = nan(sum(idx&ok),ntotgrouped);
            for b = 1:ntotgrouped                
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,b) = median(squeeze(mean(toplot(idx & ok,posttonewind,:),2)),2);
            end
            kruskalbar(d2compare);
            ylim(ylimm);
            PlotHVLines([nBlocTarget_acqui/nGroupBloc;nBlocTarget_expert/nGroupBloc],...
            'v','r');
            xlim([0 ntotgrouped+1]);
            title(namesOutcomes{o});
            set(gca,'xtick',1:ntotgrouped);xlabel([num2str(nGroupBloc*20) '-trial blocs']);
        end
        
        % only acquisition
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=4;
        ntotgrouped = round(nBlocTarget_acqui/nGroupBloc)-1;   
%         posttonewind = posttonewind(1):posttonewind(end);
        ok = xcells<=nCellsGNG;
        ylimm = [-0.05 0.05];
        for o=1:3
            subplot(3,3,3*(o-1)+1);hold on;
            d2compare = nan(sum(idx&ok),ntotgrouped);
            for b = 1:ntotgrouped                
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,b) = median(squeeze(mean(toplot(idx & ok,posttonewind,:),2)),2);
            end
            kruskalbar(d2compare);
%             PlotHVLines([nBlocTarget_acqui/nGroupBloc;nBlocTarget_expert/nGroupBloc],...
%             'v','r');
            ylim(ylimm);
            xlim([0 ntotgrouped+1]);
            title(['Acquisition - ' namesOutcomes{o}]);
            set(gca,'xtick',1:ntotgrouped);xlabel([num2str(nGroupBloc*20) '-trial blocs']);
        end
        
        % only expression 
%         fig=figure;hold on;
%         set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=6;
        ntotgrouped = round((nBlocTarget_expert-nBlocTarget_acqui)/nGroupBloc);   
%         posttonewind = posttonewind(1):posttonewind(end);
        ok = xcells<=nCellsGNG;
        ylimm = [-0.05 0.05];
        for o=1:3
            subplot(3,3,3*(o-1)+2);hold on;
            d2compare = nan(sum(idx&ok),ntotgrouped);
            a=1;
            for b = round(nBlocTarget_acqui/nGroupBloc)+1:round(nBlocTarget_acqui/nGroupBloc)+ntotgrouped                
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,a) = median(squeeze(mean(toplot(idx & ok,posttonewind,:),2)),2);
                a=a+1;
            end            
            kruskalbar(d2compare);
%             PlotHVLines([nBlocTarget_acqui/nGroupBloc;nBlocTarget_expert/nGroupBloc],...
%             'v','r');
            ylim(ylimm);
            xlim([0 a]);
            title(['Expression - ' namesOutcomes{o}]);
            set(gca,'xtick',1:a-1);xlabel([num2str(nGroupBloc*20) '-trial blocs']);
        end
        
        % only expert 
%         fig=figure;hold on;
%         set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=6;
        ntotgrouped = round((97-nBlocTarget_expert)/nGroupBloc)-1;   
%         posttonewind = posttonewind(1):posttonewind(end);
        ok = xcells<=nCellsGNG;
        ylimm = [-0.05 0.05];
        for o=1:3
            subplot(3,3,3*(o-1)+3);hold on;
            d2compare = nan(sum(idx&ok),ntotgrouped);
            a=1;
            for b = round(nBlocTarget_expert/nGroupBloc):round(nBlocTarget_expert/nGroupBloc)+ntotgrouped                
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,a) = median(squeeze(mean(toplot(idx & ok,posttonewind,:),2)),2);
                a=a+1;
            end            
            kruskalbar(d2compare);
%             PlotHVLines([nBlocTarget_acqui/nGroupBloc;nBlocTarget_expert/nGroupBloc],...
%             'v','r');
            ylim(ylimm);
            xlim([0 a]);
            title(['Expert - ' namesOutcomes{o}]);
            set(gca,'xtick',1:a-1);xlabel([num2str(nGroupBloc*20) '-trial blocs']);
        end
        
%         6*20
%         17*20
%         (97-nBlocTarget_expert)*20
        
        % IDX 
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]); 
        nnblocs = [0;17;74;nblocs];
        ylimm = [-0.04 0.04];
        for o=1:3
            subplot(1,3,o);hold on;
            d2compare = nan(sum(idx&ok),length(nnblocs)-1);
            for b = 1:length(nnblocs)-1
                toplot = sigtypesNoZ{o}(:,:,nnblocs(b)+1:nnblocs(b+1));
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,b) = median(squeeze(mean(toplot(idx & ok,posttonewind,:),2)),2);
            end
            kruskalbar(d2compare);
            ylim(ylimm);
            set(gca,'xtick',1:3,'xticklabel',{'Acq','Expr','Expe'});
            title(['High pos - ' namesOutcomes{o}]);
        end
        
        % IDX LOW
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]); 
        nnblocs = [0;17;74;nblocs];
        idxlow = K.U{dim}(:,r)>-0.001 & K.U{dim}(:,r)<0.001;
%         idxlow = K.U{dim}(:,r)<=-tresh;
%         sum(idxlow)
%         figure;histogram(K.U{dim}(:,r))
        for o=1:3
            subplot(1,3,o);hold on;
            d2compare = nan(sum(idxlow&ok),length(nnblocs)-1);
            for b = 1:length(nnblocs)-1
                toplot = sigtypesNoZ{o}(:,:,nnblocs(b)+1:nnblocs(b+1));
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,b) = median(squeeze(mean(toplot(idxlow & ok,posttonewind,:),2)),2);
            end
            kruskalbar(d2compare);
            ylim(ylimm);
            set(gca,'xtick',1:3,'xticklabel',{'Acq','Expr','Expe'});
            title(['Low - ' namesOutcomes{o}]);
        end
        
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=1;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
%         posttonewind = posttonewind(1):posttonewind(end);
        ylimm = [-0.05 0.05];
        for o=1:3
            subplot(3,1,o);hold on;
            d2compare = nan(sum(idx&ok),ntotgrouped);
            for b = 1:ntotgrouped                
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                toplot = toplot-mean(toplot(:,10:14,:),2);
                d2compare(:,b) = median(squeeze(mean(toplot(idx & ok,posttonewind,:),2)),2);
            end
            kruskalbar(d2compare);
            ylim(ylimm);
            PlotHVLines([nBlocTarget_acqui/nGroupBloc;nBlocTarget_expert/nGroupBloc],...
            'v','r');
            xlim([0 ntotgrouped+1]);
            title(namesOutcomes{o});
            set(gca,'xtick',1:ntotgrouped+1);xlabel([num2str(nGroupBloc*20) '-trial blocs']);
        end
    end
        
    if r==3
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]); 
        for o=1:3
            for b = 1:ntotgrouped
                subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(idx & ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                if o==1 && b==1
    %                 [~,order] = sort(mean(data_bas(:,18:26),2));
                    [~,order] = sort(abs(K.U{dim}(idx & ok,r)),'ascend');
                end                
                PlotColorCurves(data_bas(order,:));
                clim([-0.1 0.15]);            
                axis off;
            end
        end
        colormap(jet);
        fig2svg(['E:\KishoreLab\celine\exci\tensor_decomposition\pooled_zscored_5comps\' ...
            'trace_comp3_neg_GNGcells_colormap.svg'],fig);
        figure;subplot(2,1,1);hold on;
        toplot = abs(K.U{dim}(idx & ok,r));
        stem(toplot(order));

        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        ok = xcells<=nCellsGNG;
        for o=1:3
            for b = 1:ntotgrouped
                subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(idx & ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                plot(nanmean(data_bas.*abs(K.U{dim}(idx & ok,r))),'color',colors_outcomes{o},'linewidth',2);
                xlim([0 size(toplot,2)]);
    %             ylim(ylimm);
                ylim([-0.008 0.001]);
                axis off;
            end
        end  
        % correlation with other comp weights
        figure;
        comps = 1:5;
        other = comps(~ismember(comps,r));
        for j=1:length(other)
            subplot(2,2,j);hold on;
            plot(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other(j)),'.','color',colorgng);
            ylim([-0.1 0.1]);
            PlotHVLines(0,'h','color',gray);
    %         xlim([-0.1 0.1]);
            ylabel(['comp. ' num2str(other(j))]);
            [rho, yfit] = LinearRegression(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other(j)));
            plot(K.U{1}(idx & ok,r),yfit,'r');
            [c,p] = corr(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other(j)));
            title(['GNG, r2=' num2str(c) ', p=' num2str(p)]);
        end
        c = corr(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other));
        figure;PlotColorCurves(c);
        colormap(redbluecmap);    
        set(gca,'xtick',linspace(0,4,4),'xticklabel',{'1','2','4','5'});
        set(gca,'ytick',1,'yticklabel',{'3 neg passive'});
        clim([-0.8 0.8]);
    end
    
    % PASSIVE cells only
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
    nGroupBloc=4;
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    ok = xcells>nCellsGNG;
    for o=1:3
        for b = 1:ntotgrouped
            subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
            toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
            data = nanmean(toplot(idx & ok,:,:),3);
            data_bas = data-mean(data(:,10:14),2);
            plot(nanmean(data_bas),'color',colors_outcomes{o},'linewidth',2);
            plot(nanmean(data_bas)+nansem(data_bas),'color',colors_outcomes{o});
            plot(nanmean(data_bas)-nansem(data_bas),'color',colors_outcomes{o});
%             ylim([-0.1 0.3]);
            ylim([-0.08 0.2]);
            PlotHVLines(0,'h','k:');
            PlotHVLines(15,'v','k');
            xlim([0 size(toplot,2)]);
%             ylim(ylimm);
            
            axis off;
        end
    end
    if r==3
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]); 
        for o=1:3
            for b = 1:ntotgrouped
                subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(idx & ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                if o==1 && b==1
    %                 [~,order] = sort(mean(data_bas(:,18:26),2));
                    [~,order] = sort(abs(K.U{dim}(idx & ok,r)),'ascend');
                end                
                PlotColorCurves(data_bas(order,:));
                clim([-0.1 0.15]);            
                axis off;
            end
        end
        colormap(jet);
        fig2svg(['E:\KishoreLab\celine\exci\tensor_decomposition\pooled_zscored_5comps\' ...
            'trace_comp3_neg_Passivecells_colormap.svg'],fig);
        figure;subplot(2,1,1);hold on;
        toplot = abs(K.U{dim}(idx & ok,r));
        stem(toplot(order));
    
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
        nGroupBloc=4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        ok = xcells>nCellsGNG;
        for o=1:3
            for b = 1:ntotgrouped
                subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(idx & ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                plot(nanmean(data_bas.*abs(K.U{dim}(idx & ok,r))),'color',colors_outcomes{o},'linewidth',2);
                xlim([0 size(toplot,2)]);
    %             ylim(ylimm);
                ylim([-0.008 0.001]);
                axis off;
            end
        end  
    
        % correlation with other comp weights
        figure;
        comps = 1:5;
        other = comps(~ismember(comps,r));
        for j=1:length(other)
            subplot(2,2,j);hold on;
            plot(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other(j)),'.','color',colorpassive);
            ylim([-0.1 0.1]);
    %         xlim([-0.1 0.1]);
            PlotHVLines(0,'h','color',gray);
            ylabel(['comp. ' num2str(other(j))]);
            [rho, yfit] = LinearRegression(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other(j)));
            plot(K.U{1}(idx & ok,r),yfit,'r');
            [c,p] = corr(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other(j)));
            title(['Passive, r2=' num2str(c) ', p=' num2str(p)]);
        end
        c = corr(K.U{1}(idx & ok,r),K.U{1}(idx & ok,other));
        figure;PlotColorCurves(c);
        colormap(redbluecmap);    
        set(gca,'xtick',linspace(0,4,4),'xticklabel',{'1','2','4','5'});
        set(gca,'ytick',1,'yticklabel',{'3 neg passive'});
        clim([-0.8 0.8]);
    end
    
    if r==3 % look at difference in peak evolution and weight over time
        nGroupBloc=4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;  
        tonepeak = [18 26];
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);
        subplot(2,2,1);hold on;
        okGNG = xcells<=nCellsGNG;
        okPass = xcells>nCellsGNG;
        for o=1:3
            peaks = nan(sum(okGNG & idx),ntotgrouped);
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(okGNG & idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = median(data_bas(:,18:26),2);
            end
            plot(median(peaks),'color',colors_outcomes{o},'linewidth',2);
            plot(median(peaks)-semedian(peaks),'color',colors_outcomes{o});
            plot(median(peaks)+semedian(peaks),'color',colors_outcomes{o});
            peaks = nan(sum(okPass & idx),ntotgrouped);
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(okPass & idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = median(data_bas(:,18:34),2);
            end
            plot(median(peaks),'--','color',colors_outcomes{o},'linewidth',2);
            plot(median(peaks)-semedian(peaks),'--','color',colors_outcomes{o});
            plot(median(peaks)+semedian(peaks),'--','color',colors_outcomes{o});
        end
        ylim([-0.02 0.13]);
        PlotHVLines([nblocs_acqui/nGroupBloc;nblocs_expert/nGroupBloc],'v','k');
        dim3w = nan(ntotgrouped,1);
        dim3wsem = nan(ntotgrouped,1);
        for b = 1:ntotgrouped
            dim3w(b) = median(K.U{3}(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,r)); 
            dim3wsem(b) = semedian(K.U{3}(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,r)); 
        end
        yyaxis right;
        plot(dim3w,'color','k','linewidth',2);
        plot(dim3w+dim3wsem,'color','k');
        plot(dim3w-dim3wsem,'color','k');
        ylim([0.05 0.15]);

        for o=1:3            
            subplot(2,4,2+o);hold on; 
            nnblocs = [0;17;74;nblocs];
            peaks = nan(sum(okPass & idx),length(nnblocs)-1);
            for b = 1:length(nnblocs)-1
                toplot = sigtypesNoZ{o}(:,:,nnblocs(b)+1:nnblocs(b+1));
                data = nanmean(toplot(okPass & idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = mean(data_bas(:,18:34),2);
            end
%             if sum([jbtest(peaks(:,1));jbtest(peaks(:,2));jbtest(peaks(:,3))])==0
            boxplot(peaks);
%             kruskalbar(peaks);
%             hold on;plotSpread(peaks);
            ylim([-0.05 0.3]);
%             plot(median(peaks),'color',colors_outcomes{o},'linewidth',2);
%             plot(median(peaks)-semedian(peaks),'color',colors_outcomes{o});
%             plot(median(peaks)+semedian(peaks),'color',colors_outcomes{o});
        end
        for o=1:3            
            subplot(2,4,5+o);hold on; 
            nnblocs = [0;17;74;nblocs];
            peaks = nan(sum(okGNG & idx),length(nnblocs)-1);
            for b = 1:length(nnblocs)-1
                toplot = sigtypesNoZ{o}(:,:,nnblocs(b)+1:nnblocs(b+1));
                data = nanmean(toplot(okGNG & idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = mean(data_bas(:,18:34),2);
            end
%             if sum([jbtest(peaks(:,1));jbtest(peaks(:,2));jbtest(peaks(:,3))])==0
            boxplot(peaks);
%             kruskalbar(peaks);
%             hold on;plotSpread(peaks);
            ylim([-0.05 0.3]);
%             plot(median(peaks),'color',colors_outcomes{o},'linewidth',2);
%             plot(median(peaks)-semedian(peaks),'color',colors_outcomes{o});
%             plot(median(peaks)+semedian(peaks),'color',colors_outcomes{o});
        end
%         figure;plot(K.U{2}(:,r));
        dim3w = cell(length(nnblocs)-1,1);
        for b = 1:length(nnblocs)-1
            dim3w{b} = K.U{3}(nnblocs(b)+1:nnblocs(b+1),r); 
        end
        subplot(2,4,6);hold on; 
        nn = cellfun(@length,dim3w,'uniformoutput', false);
        boxplot(cell2mat(dim3w),repelem((1:3)',cell2mat(nn),1));
        ylim([0.05 0.15]);
%         kruskalbar(cell2mat(dim3w),repelem((1:3)',cell2mat(nn),1));
        
        okGNG = xcells<=nCellsGNG;
        okPass = xcells>nCellsGNG;
        for o=1:3
            peaks = nan(sum(okGNG & idx),ntotgrouped);
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(okGNG & idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = median(data_bas(:,18:26),2);
            end
            plot(median(peaks),'color',colors_outcomes{o},'linewidth',2);
            plot(median(peaks)-semedian(peaks),'color',colors_outcomes{o});
            plot(median(peaks)+semedian(peaks),'color',colors_outcomes{o});
            peaks = nan(sum(okPass & idx),ntotgrouped);
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(okPass & idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = median(data_bas(:,18:26),2);
            end
            plot(median(peaks),'--','color',colors_outcomes{o},'linewidth',2);
            plot(median(peaks)-semedian(peaks),'--','color',colors_outcomes{o});
            plot(median(peaks)+semedian(peaks),'--','color',colors_outcomes{o});
        end
        
        
    end
    
    % ALL cells
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
    nGroupBloc=4;
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    for o=1:3
        for b = 1:ntotgrouped
            subplot(3,ntotgrouped,b+(o-1)*ntotgrouped);hold on;
            toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
            data = nanmean(toplot(idx,:,:),3);
            data_bas = data-mean(data(:,10:14),2);
            plot(nanmean(data_bas),'color',colors_outcomes{o},'linewidth',2);
%             plot(nanmean(data_bas)+nansem(data_bas),'color',colors_outcomes{o});
%             plot(nanmean(data_bas)-nansem(data_bas),'color',colors_outcomes{o});
            xlim([0 size(toplot,2)]);
%             ylim(ylimm);
            ylim([-0.1 0.2]);
            axis off;
        end
    end
         
    if r==1        
        nGroupBloc=4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;  
        tonepeak = [17 26];
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);
        subplot(2,2,1);hold on;
        for o=1:3
            peaks = nan(sum(idx),ntotgrouped);
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = median(data_bas(:,18:26),2);
            end
            plot(median(peaks),'color',colors_outcomes{o},'linewidth',2);
            plot(median(peaks)-semedian(peaks),'color',colors_outcomes{o});
            plot(median(peaks)+semedian(peaks),'color',colors_outcomes{o});
        end
        dim3w = nan(ntotgrouped,1);
        dim3wsem = nan(ntotgrouped,1);
        for b = 1:ntotgrouped
            dim3w(b) = median(K.U{3}(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,r)); 
            dim3wsem(b) = semedian(K.U{3}(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,r)); 
        end
        yyaxis right;
        plot(dim3w,'color','k','linewidth',2);
        plot(dim3w+dim3wsem,'color','k');
        plot(dim3w-dim3wsem,'color','k');
        ylim([0.05 0.15]);
                       
        for o=1:3            
            subplot(2,4,2+o);hold on; 
            nnblocs = [0;17;74;nblocs];
            peaks = nan(sum(idx),length(nnblocs)-1);
            for b = 1:length(nnblocs)-1
                toplot = sigtypesNoZ{o}(:,:,nnblocs(b)+1:nnblocs(b+1));
                data = nanmean(toplot(idx,:,:),3);
                data_bas = data-mean(data(:,6:14),2);
                peaks(:,b) = median(data_bas(:,18:26),2);
            end
            boxplot(peaks);
%             hold on;plotSpread(peaks);
            ylim([-0.05 0.20]);
%             plot(median(peaks),'color',colors_outcomes{o},'linewidth',2);
%             plot(median(peaks)-semedian(peaks),'color',colors_outcomes{o});
%             plot(median(peaks)+semedian(peaks),'color',colors_outcomes{o});
        end
        dim3w = cell(length(nnblocs)-1,1);
        for b = 1:length(nnblocs)-1
            dim3w{b} = K.U{3}(nnblocs(b)+1:nnblocs(b+1),r); 
        end
        subplot(2,4,6);hold on; 
        nn = cellfun(@length,dim3w,'uniformoutput', false);
        boxplot(cell2mat(dim3w),repelem((1:3)',cell2mat(nn),1));
        ylim([0.04 0.15]);
%         kruskalbar(cell2mat(dim3w),repelem((1:3)',cell2mat(nn),1));
%         yyaxis right;
%         plot(dim3w,'color','k','linewidth',2);
%         plot(dim3w+dim3wsem,'color','k');
%         plot(dim3w-dim3wsem,'color','k');
%         ylim([0.05 0.16]);          
    end
    
    fig=figure;hold on;
    nGroupBloc = 2;
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);  
    for o=1:3
%         nb = length(1:25);
        a=1;
        for b = 1:ntotgrouped
            subplot(3,ntotgrouped,a+(o-1)*ntotgrouped);hold on;
            toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
            data = nanmean(toplot(idx,:,:),3);
            data_bas = data-mean(data(:,10:14),2);
            plot(nanmean(data_bas),'color',colors_outcomes{o},'linewidth',2);
%             plot(nanmean(data_bas)+nansem(data_bas),'color',colors_outcomes{o});
%             plot(nanmean(data_bas)-nansem(data_bas),'color',colors_outcomes{o});
            xlim([0 size(toplot,2)]);
            ylim([-0.1 0.4]);
            PlotHVLines(0,'h','k');
            axis off;
            a=a+1;
        end
    end
       
    if r==2
%         nGroupBloc = 2;
%         ntotgrouped = round(nblocs/nGroupBloc)-1;   
%         tonepeak = 20:26;
%         ok = xcells<=nCellsGNG;
%         data_bas_peak = nan(sum(idx~=0&ok),ntotgrouped,2);    
%         dim3w2 = cell(ntotgrouped,1);
%         dim3w4 = cell(ntotgrouped,1);
%         normW2 = (K.U{3}(:,r)+min(K.U{3}(:,r)))/max(K.U{3}(:,r)+min(K.U{3}(:,r)));
%         normW4 = (K.U{3}(:,4)+min(K.U{3}(:,4)))/max(K.U{3}(:,4)+min(K.U{3}(:,4)));
%         for o=[2 3]       
%             for b = 1:ntotgrouped
%                 toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%                 data = nanmean(toplot(idx&ok,:,:),3);
%                 data_bas = data-mean(data(:,10:14),2);
%                 data_bas_peak(:,b,o-1) = mean(data_bas(:,tonepeak),2);                
%                 dim3w2{b} = normW2(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc); 
%                 dim3w4{b} = normW4(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc); 
%             end
%         end
        
        % before only these cells, restriction on all cells
        nGroupBloc = 2;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        tonepeak = 16:26;
        ok = xcells<=nCellsGNG;
        data_bas_peak = nan(sum(ok),ntotgrouped,2);          
        for o=[2 3]       
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                data_bas_peak(:,b,o-1) = mean(data_bas(:,tonepeak),2);              
                data_bas_peak(data_bas_peak(:,b,o-1)==0,b,o-1) = nan;
            end
        end
        diffFACR = squeeze(data_bas_peak(:,:,2)-data_bas_peak(:,:,1));
        subplot(2,2,1);hold on;
        kruskalbar(diffFACR);
        
        data_bas_peak37 = nan(size(mat_cd037,1),ntotgrouped,2); 
        for o=[2 3]       
            for b = 1:ntotgrouped
                toplot = mat_cd037(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc,o);
                data = nanmean(toplot,3);
                data_bas = data-mean(data(:,10:14),2);
                data_bas_peak37(:,b,o-1) = mean(data_bas(:,tonepeak),2);              
                data_bas_peak37(data_bas_peak37(:,b,o-1)==0,b,o-1) = nan;
            end
        end
        diffFACR37 = squeeze(data_bas_peak37(:,:,2)-data_bas_peak37(:,:,1));
%           o=3;
%             figure;
%             for b = 1:8
%                 subplot(1,8,b);hold on;
%                 toplot = sigtypesNoZ{o}(ok,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%                 data = nanmean(toplot(in,:,:),3);
%                 data_bas = data-mean(data(:,10:14),2);
% %                 plot(nanmean(data_bas),'color',fa_color)
%                 PlotColorCurves(data_bas);
%                 clim([-0.2 0.2]);
%             end
%             colormap jet;
%         end


%             figure;hold on;
%             dd = data_bas_peak(in,1:round(nblocs_acqui/nGroupBloc)-1,2);
%             plot(mean(dd),'color',cr_color);
%             dd = data_bas_peak(in,1:round(nblocs_acqui/nGroupBloc)-1,1);
%             plot(mean(dd),'color',fa_color);

        % increasing = sum sign > 0
        figure;
        nShuffle = 2000;
        Ds = [];
        for j=1:5  
            if j<5
                in = InIntervals(find(ok),intervalscellsGNG(j,:));            
%                 FAnb = count_behavior(:,2,j);
%                 CRnb = count_behavior(:,3,j);
%                 FAnb_acq = FAnb(1:round(nblocs_acqui/nGroupBloc)-1);
%                 CRnb_acq = CRnb(1:round(nblocs_acqui/nGroupBloc)-1);

                d = diffFACR(in,1:round(nblocs_acqui/nGroupBloc)-1);
                dall = diffFACR(in,:);
                % find cells with choice decoding expert CR>FA
    %             expertdiffFACR = diffFACR(in,round(nblocs_acqui/nGroupBloc)+1:end);
    %             choiceselec = nanmean(expertdiffFACR,2)>0;
    %             increasing = choiceselec;
    %             increasing = sum(sign(diff(diffFACR(in,5:round(nblocs_acqui/nGroupBloc)-1),[],2)),2)==3;
            else
                d = diffFACR37(:,1:round(nblocs_acqui/nGroupBloc)-1);
                dall = diffFACR37;
                in = logical(ones(size(diffFACR37,1),1));
            end
            increasing = nansum(sign(diff(d,[],2)),2)>0;
            
            subplot(2,5,j);hold on;
            xcol = 1:size(dall,2);
            xcol = xcol(~ismember(sum(isnan(dall)),size(d,1)));
            groups = repelem(xcol,sum(increasing),1);
            dd = dall(logical(increasing),~ismember(sum(isnan(dall)),size(d,1)));
            kruskalbar(dd(:),groups(:));
%             xlim([0 8+1]);
            p = sum(increasing)/sum(in)*100;
            title([num2str(p) '% (' num2str(sum(increasing)) '/' num2str(sum(in)) ')']);

            dnonans = d(:,~ismember(sum(isnan(d)),size(d,1)));
            subplot(2,5,5+j);hold on;
            pshuffle = nan(nShuffle,1);
            for s=1:nShuffle
                [~,shuffleidx] = sort(randn(size(dnonans,2),size(dnonans,1)));        
                shuffle_d = nan(size(dnonans));
                for k=1:size(dnonans,1)
                    shuffle_d(k,:) = dnonans(k,shuffleidx(:,k));
                end    
                increasing_shuffle = sum(sign(diff(shuffle_d,[],2)),2)>0;
%                 increasing_shuffle = sum(sign(diff(shuffle_d(:,5:end),[],2)),2)==3;            
                pshuffle(s) = sum(increasing_shuffle)/size(increasing_shuffle,1)*100;
            end
            histogram(pshuffle);
            PlotHVLines(p,'v','r');    
            title(['p=' num2str(sum(pshuffle>p)/size(pshuffle,1))]);    
            drawnow;
            Ds = [Ds;dall(logical(increasing),:)];
        end
        
%         figure;
        nShuffle = 2000;
        incr = nan(4,2);
        ps = cell(4,1);
        for j=1:4    
            in = InIntervals(find(ok),intervalscellsGNG(j,:));                        
            d = diffFACR(in,1:round(nblocs_acqui/nGroupBloc)-1);            
            increasing = nansum(sign(diff(d,[],2)),2)>0;
            incr(j,:) = [sum(increasing) size(increasing,1)];

            dnonans = d(:,~isnan(d(1,:)));
            pshuffle = nan(nShuffle,2);
            for s=1:nShuffle
                [~,shuffleidx] = sort(randn(size(dnonans,2),size(dnonans,1)));        
                shuffle_d = nan(size(dnonans));
                for k=1:size(dnonans,1)
                    shuffle_d(k,:) = dnonans(k,shuffleidx(:,k));
                end    
                increasing_shuffle = sum(sign(diff(shuffle_d,[],2)),2)>0;
                pshuffle(s,:) = [sum(increasing_shuffle) size(increasing_shuffle,1)];
            end            
            ps{j} = pshuffle;   
        end

        psh = cell2mat(ps');
%         figure;
        subplot(2,2,2);hold on;
        pshu = sum(psh(:,1:2:end),2)./sum(psh(:,2:2:end),2)*100;
        pdata = sum(incr(:,1))/sum(incr(:,2))*100;
        histogram(pshu);
        PlotHVLines(pdata,'v','r');
        title(['p=' num2str(sum(pshu>pdata)/length(pshu))]);
        xlabel('% of cells with increasing pref for CR over acquisition');
        ylabel('count');
        
        % increasing = choiceselec expert
        figure;
        nShuffle = 2000;
        Ds = [];
        for j=1:5   
            % find cells with choice decoding expert CR>FA
            if j<5
                in = InIntervals(find(ok),intervalscellsGNG(j,:)); 
                d = diffFACR(in,1:round(nblocs_acqui/nGroupBloc)-1);
                dall = diffFACR(in,:);
                expertdiffFACR = diffFACR(in,round(nblocs_expert/nGroupBloc)+1:end);
            else
                d = diffFACR37(:,1:round(nblocs_acqui/nGroupBloc)-1);
                dall = diffFACR37;
                in = logical(ones(size(diffFACR37,1),1));
                expertdiffFACR = diffFACR37(in,round(nblocs_acqui/nGroupBloc):...
                    round(nblocs_acqui/nGroupBloc)+10);
            end
            increasing = ttest(expertdiffFACR(:,~ismember(sum(isnan(expertdiffFACR)),size(d,1)))',0,'tail','right');
            increasing = increasing';
            increasing(isnan(increasing)) = 0;
            
            subplot(2,5,j);hold on;
            xcol = 1:8;
            xcol = xcol(~ismember(sum(isnan(d)),size(d,1)));
            groups = repelem(xcol,sum(increasing),1);
            dd = d(logical(increasing),~ismember(sum(isnan(d)),size(d,1)));
            kruskalbar(dd(:),groups(:));
            xlim([0 8+1]);
            p = sum(increasing)/sum(in)*100;
            title([num2str(p) '% (' num2str(sum(increasing)) '/' num2str(sum(in)) ')']);

            dnonans = dall(:,~ismember(sum(isnan(dall)),size(dall,1)));
            ncoltaken = sum(~ismember(sum(isnan(expertdiffFACR)),size(d,1)));
            subplot(2,5,5+j);hold on;
            pshuffle = nan(nShuffle,1);
            for s=1:nShuffle
                [~,shuffleidx] = sort(randn(size(dnonans,2),size(dnonans,1))); 
                shuffleidx = shuffleidx(1:ncoltaken,:);
                shuffle_d = nan(size(dnonans,1),ncoltaken);
                for k=1:size(dnonans,1)
                    shuffle_d(k,:) = dnonans(k,shuffleidx(:,k));
                end    
                expertdiffFACR_shu = shuffle_d(:,end-ncoltaken+1:end);
                increasing_shuffle = ttest(expertdiffFACR_shu',0,'tail','right');
                increasing_shuffle = increasing_shuffle';
                increasing_shuffle(isnan(increasing_shuffle)) = 0;
                pshuffle(s) = sum(increasing_shuffle)/size(increasing_shuffle,1)*100;
            end
            histogram(pshuffle);
            PlotHVLines(p,'v','r');    
            title(['p=' num2str(sum(pshuffle>p)/size(pshuffle,1))]);    
            drawnow;
            Ds = [Ds;d(logical(increasing),:)];
        end
        
        figure;subplot(2,2,1);
        kruskalbar(Ds);
        
        nShuffle = 2000;
        incr = nan(4,2);
        ps = cell(4,1);
        for j=1:4    
            in = InIntervals(find(ok),intervalscellsGNG(j,:)); 
            d = diffFACR(in,1:round(nblocs_acqui/nGroupBloc)-1);
            dall = diffFACR(in,:);
            % find cells with choice decoding expert CR>FA
            expertdiffFACR = diffFACR(in,round(nblocs_expert/nGroupBloc)+1:end);
            increasing = ttest(expertdiffFACR(:,~isnan(expertdiffFACR(1,:)))',0,'tail','right');
            increasing = increasing';
            incr(j,:) = [sum(increasing) size(increasing,1)];

            xcol = 1:8;
            xcol = xcol(~isnan(d(1,:)));
            groups = repelem(xcol,sum(increasing),1);
            dnonans = dall(:,~isnan(dall(1,:)));
            ncoltaken = sum(~isnan(expertdiffFACR(1,:)));
            pshuffle = nan(nShuffle,2);
            for s=1:nShuffle
                [~,shuffleidx] = sort(randn(size(dnonans,2),size(dnonans,1))); 
                shuffleidx = shuffleidx(1:ncoltaken,:);
                shuffle_d = nan(size(dnonans,1),ncoltaken);
                for k=1:size(dnonans,1)
                    shuffle_d(k,:) = dnonans(k,shuffleidx(:,k));
                end    
                expertdiffFACR_shu = shuffle_d(:,end-ncoltaken+1:end);
                increasing_shuffle = ttest(expertdiffFACR_shu',0,'tail','right');
                increasing_shuffle = increasing_shuffle';
                pshuffle(s,:) = [sum(increasing_shuffle) size(increasing_shuffle,1)];                
            end       
            ps{j} = pshuffle;   
        end
        psh = cell2mat(ps');
        subplot(2,2,2);hold on;cla
        pshu = sum(psh(:,1:2:end),2)./sum(psh(:,2:2:end),2)*100;
        pdata = sum(incr(:,1))/sum(incr(:,2))*100;
        histogram(pshu);
        PlotHVLines(pdata,'v','r');
        title(['p=' num2str(sum(pshu>pdata)/length(pshu))]);
        xlabel('% of cells with choice decoding CR>FA expert');
        ylabel('count');
        
        nShuffle = 2000;
        incr = nan(4,2);
        ps = cell(4,1);
        for j=1:4    
            in = InIntervals(find(ok),intervalscellsGNG(j,:)); 
            d = diffFACR(in,1:round(nblocs_acqui/nGroupBloc)-1);
            dall = diffFACR(in,:);
            % find cells with choice decoding expert CR>FA
            expertdiffFACR = diffFACR(in,round(nblocs_expert/nGroupBloc)+1:end);
            choice = ttest(expertdiffFACR(:,~isnan(expertdiffFACR(1,:)))',0,'tail','right');
            choice = choice';
            increasing = nansum(sign(diff(d(logical(choice),:),[],2)),2)>0;
            incr(j,:) = [sum(increasing) sum(choice)];
            
            pshuffle = nan(nShuffle,2);
            for s=1:nShuffle
                [~,shuffleidx] = sort(randn(size(d,2),size(d,1))); 
                shuffle_d = nan(size(d));
                for k=1:size(d,1)
                    shuffle_d(k,:) = d(k,shuffleidx(:,k));
                end    
                increasing_shuffle = nansum(sign(diff(shuffle_d(logical(choice),:),[],2)),2)>0;
                pshuffle(s,:) = [sum(increasing_shuffle) size(increasing_shuffle,1)];                
            end       
            ps{j} = pshuffle;   
        end
        psh = cell2mat(ps');
        subplot(2,2,3);hold on;
        pshu = sum(psh(:,1:2:end),2)./sum(psh(:,2:2:end),2)*100;
        pdata = sum(incr(:,1))/sum(incr(:,2))*100;
        histogram(pshu);
        PlotHVLines(pdata,'v','r');
        title(['p=' num2str(sum(pshu>pdata)/length(pshu))]);
        xlabel('% of choice cells with increasing delta peak acqui');
        ylabel('count');

        % only these cells
        nGroupBloc = 4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        tonepeak = 20:26;
        ok = xcells<=nCellsGNG;
        data_bas_peak = nan(sum(ok&idx),ntotgrouped,2);    
        dim3w2 = cell(ntotgrouped,1);
        dim3w4 = cell(ntotgrouped,1);
        normW2 = (K.U{3}(:,r)+min(K.U{3}(:,r)))/max(K.U{3}(:,r)+min(K.U{3}(:,r)));
        normW4 = (K.U{3}(:,4)+min(K.U{3}(:,4)))/max(K.U{3}(:,4)+min(K.U{3}(:,4)));
        for o=[2 3]       
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(ok & idx,:,:),3);
                data_bas = data-nanmean(data(:,10:14),2);
                data_bas_peak(:,b,o-1) = nanmean(data_bas(:,tonepeak),2);                
                dim3w2{b} = normW2(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc); 
                dim3w4{b} = normW4(1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc); 
            end
        end
                
        figure;hold on;
        subplot(2,2,1);hold on;
%         kruskalbar(data_bas_peak(:,:,1));
        plot(nanmedian(data_bas_peak(:,:,1)),'k');
        errorbar(1:ntotgrouped,nanmedian(data_bas_peak(:,:,1)),semedian(data_bas_peak(:,:,1)),'k.');
        title('FA');
        ylim([0 0.21]);
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
        subplot(2,2,2);hold on;
%         kruskalbar(data_bas_peak(:,:,2));
        plot(nanmedian(data_bas_peak(:,:,2)),'k');
        errorbar(1:ntotgrouped,nanmedian(data_bas_peak(:,:,2)),semedian(data_bas_peak(:,:,2)),'k.');
        title('CR');
        ylim([0 0.21]);
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
        subplot(2,2,3);hold on;
        plot(nanmedian(data_bas_peak(:,:,1)),'color',colors_outcomes{2});
        errorbar(1:ntotgrouped,nanmedian(data_bas_peak(:,:,1)),...
            semedian(data_bas_peak(:,:,1)),'.','color',colors_outcomes{2});
        plot(nanmedian(data_bas_peak(:,:,2)),'color',colors_outcomes{3});
        errorbar(1:ntotgrouped,nanmedian(data_bas_peak(:,:,2)),...
            semedian(data_bas_peak(:,:,2)),'.','color',colors_outcomes{3});
        ylim([0 0.25]);
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
        subplot(2,2,4);hold on;
        blocs = 1:ntotgrouped;        
        p0 = nan(length(blocs),1);
        for b=1:length(blocs)       
            diffFACR = squeeze(data_bas_peak(:,blocs(b),2)-data_bas_peak(:,blocs(b),1));
            p0(b) = signrank(diffFACR);
        end
        diffFACR = squeeze(data_bas_peak(:,blocs,2)-data_bas_peak(:,blocs,1));
        plot(find(nanmedian(diffFACR)'>0 & p0<0.05),0.09,'k*');
        plot(find(nanmedian(diffFACR)'<0 & p0<0.05),-0.09,'k*');
        bar(1:ntotgrouped,nanmedian(diffFACR));
        errorbar(1:ntotgrouped,nanmedian(diffFACR),semedian(diffFACR),'k.');
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
        
        
        figure;
        bins = linspace(-0.3,0.2,100);
        for b=1:8
            subplot(2,4,b);hold on;
            histogram(diffFACR(:,blocs(b)),bins);
        end
        
        figure;
        bins = linspace(-0.3,0.2,100);
        for b=1:8
            subplot(2,4,b);hold on;
            histogram(data_bas_peak(:,blocs(b),2),bins);
        end
        
        fig=figure;hold on;
        subplot(2,2,1);hold on;
        blocs = 1:ntotgrouped;
    %     plot(squeeze(data_bas_peak(:,:,1)-data_bas_peak(:,:,2))');
        plotSpread(squeeze(data_bas_peak(:,blocs,2)-data_bas_peak(:,blocs,1)),'distributionidx',...
            repelem((blocs)',sum(idx~=0 &ok),1));
        PlotHVLines(0,'h','k');
        ylim([-1 1]);
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
        p0 = nan(length(blocs),1);
        for b=1:length(blocs)       
            diffFACR = squeeze(data_bas_peak(:,blocs(b),2)-data_bas_peak(:,blocs(b),1));
            p0(b) = signrank(diffFACR);
        end
        diffFACR = squeeze(data_bas_peak(:,blocs,2)-data_bas_peak(:,blocs,1));
        plot(find(median(diffFACR)'>0 & p0<0.05),0.9,'k*');
        plot(find(median(diffFACR)'<0 & p0<0.05),-0.9,'k*');
        
        subplot(2,2,2);hold on;
        blocs = 1:ntotgrouped;
        groups = repelem(1:ntotgrouped,size(diffFACR,1),1);
        bar(1:ntotgrouped,median(diffFACR));
        errorbar(1:ntotgrouped,median(diffFACR),semedian(diffFACR),'k.');
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
        plot(find(median(diffFACR)'>0 & p0<0.05),0.09,'k*');
        plot(find(median(diffFACR)'<0 & p0<0.05),-0.09,'k*');
        
        subplot(2,2,3);hold on;
        groups = repelem(1:8,size(diffFACR,1),1);
        bar(1:8,median(diffFACR(:,1:8)));
        errorbar(1:8,median(diffFACR(:,1:8)),semedian(diffFACR(:,1:8)),'k.');
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        plot(find(median(diffFACR(:,1:8))'>0 & p0(1:8)<0.05),0.09,'k*');
        plot(find(median(diffFACR(:,1:8))'<0 & p0(1:8)<0.05),-0.09,'k*');
        ylim([-0.12 0.12]);
figure;
        subplot(2,2,4);hold on;
        groups = repelem(1:8,size(diffFACR,1),1);
        boxplot(diffFACR(:,1:8));
        ylim([-0.3 0.2]);
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        plot(find(median(diffFACR(:,1:8))'>0 & p0(1:8)<0.05),0.09,'k*');
        plot(find(median(diffFACR(:,1:8))'<0 & p0(1:8)<0.05),-0.09,'k*');
        
        % check that it's true accross mice
        nGroupBloc = 4;
        ntotgrouped = round(nblocs/nGroupBloc)-1; 
        blocs = 1:ntotgrouped;
        tonepeak = 20:26;
        figure;
        diffFACR00 = [];
        for j=1:4
            in = InIntervals(find(idx),intervalscellsGNG(j,:));
            id_idx = find(idx);
            inidx = zeros(size(idx));
            inidx(id_idx(in)) = 1;
            inidx = logical(inidx);
            data_bas_peak0 = nan(sum(in),ntotgrouped,2);       
            DB = nan(75,ntotgrouped,2);
            for o=[2 3]       
                for b = 1:ntotgrouped
                    toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                    data = nanmean(toplot(inidx,:,:),3);
                    data_bas = data-mean(data(:,10:14),2);
                    data_bas_peak0(:,b,o-1) = mean(data_bas(:,tonepeak),2);  
                    DB(:,b,o-1) = nanmean(data_bas)';
                end
            end
            diffFACR0 = squeeze(data_bas_peak0(:,blocs,2)-data_bas_peak0(:,blocs,1));
            subplot(2,2,j);hold on;
            kruskalbar(diffFACR0);
            ylim([-0.2 0.1])
            PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
            title(['mouse ' num2str(j) ', n=' num2str(sum(in))]);            
            diffFACR00 = [diffFACR00;diffFACR0];
        end
        figure;hold on;plot(DB(:,1:8,1),'color',fa_color);
        dbb = DB(:,1:8,1);
        figure;hold on;plot(dbb(:),'color',fa_color);
        dbbCR = DB(:,1:8,2);
        hold on;plot(dbbCR(:),'color',cr_color);

        figure;
        subplot(2,2,4);hold on;
        boxplot(diffFACR00(:,1:8));
        
        figure;
        subplot(2,2,1);hold on;
        nn2 = cellfun(@length,dim3w2,'uniformoutput', false); %CR
        nn4 = cellfun(@length,dim3w4,'uniformoutput', false); %FA
        boxplot(cell2mat(dim3w2(1:8))-cell2mat(dim3w4(1:8)),...
            repelem((1:8)',cell2mat(nn4(1:8)),1));
%         ylim([0.04 0.15]);
        
        nGroupBloc = 17;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        tonepeak = 20:26;
        ok = xcells<=nCellsGNG;
        data_bas_peak = nan(sum(idx~=0&ok),ntotgrouped,2);   
        blocs = 1:ntotgrouped;
        for o=[2 3]       
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                
                data = nanmean(toplot(idx&ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                data_bas_peak(:,b,o-1) = mean(data_bas(:,tonepeak),2);
            end
        end
        diffFACR = squeeze(data_bas_peak(:,blocs,2)-data_bas_peak(:,blocs,1));        
        
        subplot(2,2,2);hold on;
        groups = repelem(1:ntotgrouped,size(diffFACR,1),1);
        bar(1:ntotgrouped,median(diffFACR(:,1:ntotgrouped)));
        errorbar(2:ntotgrouped,median(diffFACR(:,2:ntotgrouped)),semedian(diffFACR(:,2:ntotgrouped)),'k.');
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        PlotHVLines(nblocs_expert/nGroupBloc,'v','r'); 
%         plot(find(median(diffFACR(:,2:ntotgrouped))'>0 & p0(2:ntotgrouped)<0.05),0.09,'k*');
%         plot(find(median(diffFACR(:,2:ntotgrouped))'<0 & p0(2:ntotgrouped)<0.05),-0.09,'k*');
        ylim([-0.12 0.12]);       
        
        nGroupBloc = 4;
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        tonepeak = 20:26;
        ok = xcells<=nCellsGNG;
        blocs = 1:ntotgrouped;
        data_bas_peak = nan(sum(idx~=0&ok),ntotgrouped,2);    
        for o=[2 3]       
            for b = 1:ntotgrouped
                toplot = sigtypesNoZ{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                data = nanmean(toplot(idx&ok,:,:),3);
                data_bas = data-mean(data(:,10:14),2);
                data_bas_peak(:,b,o-1) = mean(data_bas(:,tonepeak),2);
            end
        end
        diffFACR = squeeze(data_bas_peak(:,blocs,2)-data_bas_peak(:,blocs,1)); 
        p0 = nan(length(blocs),1);
        for b=1:length(blocs)       
            diffFACR2 = squeeze(data_bas_peak(:,blocs(b),2)-data_bas_peak(:,blocs(b),1));
            p0(b) = signrank(diffFACR2);
        end
        figure;
        subplot(2,2,1);hold on;
        boxplot(diffFACR);
        ylim([-0.2 0.2]);
        PlotHVLines(nblocs_acqui/nGroupBloc,'v','r'); 
        plot(find(median(diffFACR)'>0 & p0<0.05),0.09,'k*');
        plot(find(median(diffFACR)'<0 & p0<0.05),-0.09,'k*');
        
        nnblocs = [0;17;74;nblocs];
        data_bas_peak = nan(sum(idx~=0&ok),ntotgrouped,2);
        for o=[2 3]  
            for b = 1:length(nnblocs)-1
                toplot = sigtypesNoZ{o}(:,:,nnblocs(b)+1:nnblocs(b+1));
                data = nanmean(toplot(idx~=0&ok,:,:),3);
                data_bas = data-nanmean(data(:,10:14),2);
                data_bas_peak(:,b,o-1) = nanmean(data_bas(:,tonepeak),2);
            end
        end
        blocs = 1:length(nnblocs)-1;
        diffFACR = squeeze(data_bas_peak(:,blocs,2)-data_bas_peak(:,blocs,1)); 
        p0 = nan(length(blocs),1);
        for b=1:length(blocs)       
            diffFACR2 = squeeze(data_bas_peak(:,blocs(b),2)-data_bas_peak(:,blocs(b),1));
            p0(b) = signrank(diffFACR2);
        end
        subplot(2,2,2);hold on;
        boxplot(diffFACR);
        ylim([-0.3 0.2]);        
        plot(find(median(diffFACR)'>0 & p0<0.05),0.09,'k*');
        plot(find(median(diffFACR)'<0 & p0<0.05),-0.09,'k*');
        
    end
%     pdiff = nan(length(blocs),1);
%     diffFACRs = nan(sum(idx~=0 &ok),length(blocs));
%     for b=1:length(blocs)
% %         subplot(2,2,3);hold on; 
% %         plot([1 2]+(b-1)*2,[data_bas_peak(:,blocs(b),1) data_bas_peak(:,blocs(b),2)],'k-');
%         diffFACR = squeeze(data_bas_peak(:,blocs(b),1)-data_bas_peak(:,blocs(b),2));
%         if jbtest(diffFACR)==1
%             p0(b) = signrank(diffFACR);
%             subplot(2,2,1);hold on; 
%             plot(b,median(diffFACR),'r.','markersize',15);
%             median(diffFACR)
%             pdiff(b) = signrank(data_bas_peak(:,blocs(b),1),data_bas_peak(:,blocs(b),2));
%         end
%         diffFACRs(:,b) = diffFACR;
%     end
%     PlotHVLines(0,'h','k');
%     PlotHVLines(nblocs_acqui*20/(nGroupBloc*20),'v','r');
    
%     figure;
%     subplot(2,2,2);hold on; 
%     kruskalbar(diffFACRs);
    
    
%     boxplot(squeeze(data_bas_peak(:,1:8,1)-data_bas_peak(:,1:8,2)));

%     ntotgrouped = round(nblocs/nGroupBloc)-1;   
%     tonepeak = 17:26;
%     data_bas_peak = nan(sum(idx~=0),ntotgrouped,2);
%     for o=[2 3]        
%         for b = 1:ntotgrouped
%             toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%             data = nanmean(toplot(idx,:,:),3);
%             data_bas = data-mean(data(:,10:14),2);
%             zdata_bas = zscore(data_bas,[],2);
%             data_bas_peak(:,b,o-1) = mean(zdata_bas(:,20:26),2);
%         end
%     end    
%     subplot(2,2,2);hold on;    
%     plotSpread(squeeze(data_bas_peak(:,blocs,1)-data_bas_peak(:,blocs,2)),'distributionidx',...
%         repelem((blocs)',sum(idx~=0),1));
%     p0 = nan(length(blocs),1);
%     pdiff = nan(length(blocs),1);
%     for b=1:length(blocs)
%         diffFACR = squeeze(data_bas_peak(:,blocs(b),1)-data_bas_peak(:,blocs(b),2));
%         if jbtest(diffFACR)==1
%             p0(b) = signrank(diffFACR);
%             plot(b,median(diffFACR),'r.','markersize',15);
%             median(diffFACR)
%             pdiff(b) = signrank(data_bas_peak(:,blocs(b),1),data_bas_peak(:,blocs(b),2));
%         end
%     end
%     PlotHVLines(0,'h','k');
% end

    if r==2
        fig=figure;hold on;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);   
        [~,maxweightintrial] = max(K.U{2}(:,r));
        ntotgrouped = round(nblocs/nGroupBloc)-1;   
        for o=1:outcomes
            TP = nan(sum(idx~=0),ntotgrouped);
            for b = 1:ntotgrouped
                toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
                TP(:,b) = squeeze(nanmean(toplot(idx,maxweightintrial,:),3));        
            end
            subplot(1,3,o);hold on;
    %         [~,order1_2] = sort(K.U{dim}(idx,r),'ascend');
            [~,sorted] = sortrows(mean(smoothdata(zscore(TP,[],2),2,'movmean',2),2));
            PlotColorCurves(smoothdata(zscore(TP(sorted,:),[],2),2,'movmean',2));
            colormap jet;
            clim([-1.5 1.5]);
        end
    end
    
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    xcells = (1:nCellsPerMouse(end))';
    ylimm = [-0.08 0.08];
    for o=1:outcomes
        ok = xcells<=nCellsGNG;
        TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);    
            toplot = nanmean(toplot(idx & ok,:,:),3);
            toplot_bas = toplot-nanmean(toplot(:,10:14),2);
            TP(:,:,b) = toplot_bas;        
        end
        subplot(3,1,o);hold on;
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
        [~,order] = sort(K.U{dim}(idx & ok,r),'descend');              
        plot(nanmean(toplot(order,:)),'color',colors_outcomes{o},'linewidth',2);
        plot(nanmean(toplot(order,:))+nansem(toplot(order,:)),'color',colors_outcomes{o});
        plot(nanmean(toplot(order,:))-nansem(toplot(order,:)),'color',colors_outcomes{o});
        xlim([0 size(toplot,2)]);
%         ylim([-0.05 0.25]);
        ylim(ylimm);
        PlotHVLines(75:75:size(toplot,2),'v','k');
        PlotHVLines(0,'h','k:');%         
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        if o==1
            title(['Average GNG, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
                '-trial bloc, n='...
            num2str(sum(idx~=0 & ok)) ' cells']);
        end
        PlotHVLines([nblocs_acqui*20*75/(nGroupBloc*20);nblocs_expert*20*75/(nGroupBloc*20)],...
            'v','color','r','linewidth',2);            
    end
    drawnow;
%     fig=figure;hold on;
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
%     ntotgrouped = round(nblocs/nGroupBloc)-1;   
%     xcells = (1:nCellsPerMouse(end))';
%     for o=1:outcomes
%         ok = xcells<=nCellsGNG;
%         TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
%         for b = 1:ntotgrouped
%             toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);            
%             TP(:,:,b) = nanmean(toplot(idx & ok,:,:),3);        
%         end
%         subplot(3,1,o);hold on;
%         datatoplot = squeeze(max(TP(order,tonewin,:),[],2));
%         [~,wm] = max(datatoplot,[],2);
%         [~,order] = sort(wm);
%         PlotColorCurves(smoothdata(zscore(datatoplot(order,:),[],2),2,'movmean',2));
%         colormap jet;
%         
%         ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
%         if o==1
%             title(['Average GNG, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
%                 '-trial bloc, n='...
%             num2str(sum(idx~=0 & ok)) ' cells']);
%         end   
%         clim([-2 4]);
%     end
%     drawnow;
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    xcells = (1:nCellsPerMouse(end))';
    for o=1:outcomes
        ok = xcells<=nCellsGNG;
        TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);  
            toplot = nanmean(toplot(idx & ok,:,:),3);
            toplot_bas = toplot-nanmean(toplot(:,10:14),2);
            TP(:,:,b) = toplot_bas;        
        end
        subplot(3,1,o);hold on;
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
        [~,order] = sort(K.U{dim}(idx & ok,r),'descend');   
        PlotColorCurves(smoothdata(toplot(order,:),2,'movmean',7));
        colormap jet;
        PlotHVLines(75:75:size(toplot,2),'v','k');
        PlotHVLines(15:75:size(toplot,2),'v','w');
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        if o==1
            title(['Average GNG, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
                '-trial bloc, n='...
            num2str(sum(idx~=0 & ok)) ' cells']);
        end   
%         clim([-0.1 0.2]);
%         clim([-1 2]);
        clim([-0.08 0.08]);
    end
    drawnow;
    if savecolormapsvg
        fig2svg(['E:\KishoreLab\celine\exci\tensor_decomposition\pooled_zscored_5comps\trace_comp' num2str(r)...
         '_gng_' toplotsign '_noaxis_grouped' num2str(nGroupBloc) '.svg'],fig);
    end
%     saveas(fig,['E:\KishoreLab\celine\exci\tensor_decomposition\pooled_zscored_5comps\trace_comp' num2str(r)...
%          '_gng_' toplotsign '_noaxis_grouped' num2str(nGroupBloc) '.pdf']);
    
    % again, with different order
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    xcells = (1:nCellsPerMouse(end))';
    for o=1:outcomes
        ok = xcells<=nCellsGNG;
        TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);  
            toplot = nanmean(toplot(idx & ok,:,:),3);
            toplot_bas = toplot-nanmean(toplot(:,10:14),2);
            TP(:,:,b) = toplot_bas;        
        end
        subplot(3,1,o);hold on;
        [~,order] = sort(squeeze(mean(TP(:,posttonewind(1):posttonewind(2),17),2)),'descend');  
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));         
        PlotColorCurves(smoothdata(toplot(order,:),2,'movmean',7));
        colormap jet;
        PlotHVLines(75:75:size(toplot,2),'v','k');
        PlotHVLines(15:75:size(toplot,2),'v','w');
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        if o==1
            title(['Average GNG, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
                '-trial bloc, n='...
            num2str(sum(idx~=0 & ok)) ' cells']);
        end   
%         clim([-0.1 0.2]);
%         clim([-1 2]);
        clim([-0.08 0.08]);
    end
    drawnow;
    
    
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    xcells = (1:nCellsPerMouse(end))';
    nb = 1; % th cell
    for o=1:outcomes
        ok = xcells<=nCellsGNG;
        TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);            
            TP(:,:,b) = nanmean(toplot(idx & ok,:,:),3);        
        end
        subplot(3,1,o);hold on;
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
        if strcmp(toplotsign,'neg')
            [~,order] = sort(K.U{dim}(idx & ok,r),'ascend');         
        elseif strcmp(toplotsign,'pos')
            [~,order] = sort(K.U{dim}(idx & ok,r),'descend');         
        end               
        plot(toplot(order(nb),:),'color',colors_outcomes{o},'linewidth',2);
        xlim([0 size(toplot,2)]);
%         ylim([-0.05 0.25]);
        ylim(ylimmex);
        PlotHVLines(75:75:size(toplot,2),'v','color',gray);
        PlotHVLines(15:75:size(toplot,2),'v','color','k');
        PlotHVLines(0,'h','k:');%         
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        if o==1
            tow = K.U{dim}(idx & ok,r);
            title(['GNG, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
                '-trial bloc, n=1 cell, ' num2str(nb) 'th (w=' num2str(tow(order(nb))) ')']);
        end
        PlotHVLines([nblocs_acqui*20*75/(nGroupBloc*20);nblocs_expert*20*75/(nGroupBloc*20)],...
            'v','color','r','linewidth',2);            
    end
    drawnow;
    
%     fig=figure;hold on;
%     set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
%     ntotgrouped = round(nblocs/nGroupBloc)-1;   
%     xcells = (1:nCellsPerMouse(end))';
%     nb = 1; % th cell
%     for o=1:outcomes
%         ok = xcells>nCellsGNG;
%         TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
%         for b = 1:ntotgrouped
%             toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);            
%             TP(:,:,b) = nanmean(toplot(idx & ok,:,:),3);        
%         end
%         subplot(3,1,o);hold on;
%         toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
%         [~,order] = sort(K.U{dim}(idx & ok,r),'descend');              
%         plot(toplot(order(nb),:),'color',colors_outcomes{o},'linewidth',2);
%         xlim([0 size(toplot,2)]);
% %         ylim([-0.05 0.25]);
%         ylim(ylimmex);
%         PlotHVLines(75:75:size(toplot,2),'v','k');
%         PlotHVLines(0,'h','k:');%         
%         ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
%         if o==1
%             tow = K.U{dim}(idx & ok,r);
%             title(['PASSIVE, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
%                 '-trial bloc, n=1 cell, ' num2str(nb) 'th (w=' num2str(tow(order(nb))) ')']);
%         end
%         PlotHVLines([nblocs_acqui*20*75/(nGroupBloc*20);nblocs_expert*20*75/(nGroupBloc*20)],...
%             'v','color','r','linewidth',2);            
%     end
%     drawnow;
%     
    fig=figure;hold on;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.5]);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    xcells = (1:nCellsPerMouse(end))';
    for o=1:outcomes
        ok = xcells>nCellsGNG;
        TP = nan(sum(idx~=0 & ok),size(av_psth_H,2),ntotgrouped);
        for b = 1:ntotgrouped
            toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);            
            TP(:,:,b) = nanmean(toplot(idx & ok,:,:),3);        
        end
        subplot(3,1,o);hold on;
        toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
        [~,order] = sort(K.U{dim}(idx & ok,r),'descend');              
        plot(nanmean(toplot(order,:)),'color',colors_outcomes{o},'linewidth',2);
        plot(nanmean(toplot(order,:))+nansem(toplot(order,:)),'color',colors_outcomes{o});
        plot(nanmean(toplot(order,:))-nansem(toplot(order,:)),'color',colors_outcomes{o});
        xlim([0 size(toplot,2)]);
%         ylim([-0.05 0.25]);
        ylim(ylimm);
        PlotHVLines(75:75:size(toplot,2),'v','k');
        PlotHVLines(0,'h','k:');%         
        ylabel([labels_outcomes{o} ' (' num2str(weight_trial_type(o)) ')']);
        if o==1
            title(['Average PASSIVE, comp #' num2str(r) ', ' num2str(nGroupBloc*20) ...
                '-trial bloc, n='...
            num2str(sum(idx~=0 & ok)) ' cells']);
        end
        PlotHVLines([nblocs_acqui*20*75/(nGroupBloc*20);nblocs_expert*20*75/(nGroupBloc*20)],...
            'v','color','r','linewidth',2);            
    end
    drawnow;
    
    
    
%     %% plot indiv cell
%     for k=1:length(idx)
%         thiscell = idx(k);
%         fig=figure;hold on;
%         set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);    
%         ntotgrouped = round(nblocs/nGroupBloc)-1;   
%         for o=1:outcomes
%             TP = nan(size(av_psth_H,2),ntotgrouped);
%             for b = 1:ntotgrouped
%                 toplot = sigtypes{o}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%                 TP(:,b) = nanmean(toplot(thiscell,:,:),3);        
%             end
%             subplot(3,1,o);hold on;
%             toplot = TP(:);            
%             plot(toplot,'color',colors_outcomes{o},'linewidth',2);
%             xlim([0 size(toplot,1)]);
%             ylim([-0.2 0.7]);
%             PlotHVLines(75:75:size(toplot,1),'v','k');
%             PlotHVLines(0,'h','k:');            
%         end   
%         pause();
%         close(fig);
%     end
        
%     if r==6
%         fig=figure;hold on;
%         set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
%         TP = nan(sum(idx),size(av_psth_H,2),ntotgrouped);
%         for b = 1:ntotgrouped
%             toplot = sigtypes{1}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%             TP(:,:,b) = nanmean(toplot(idx,:,:),3);        
%         end
%         toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));        
%         for j=1:10
%             subplot(10,1,j);hold on;
%             plot(toplot(order==j,:));
%             PlotHVLines(75:75:size(toplot,2),'v','k');
%             axis off;
%         end
%         
%         fig=figure;hold on;
%         set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
%         TP = nan(sum(idx),size(av_psth_H,2),ntotgrouped);
%         for b = 1:ntotgrouped
%             toplot = sigtypes{2}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%             TP(:,:,b) = nanmean(toplot(idx,:,:),3);        
%         end
%         toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));        
%         for j=1:10
%             subplot(10,1,j);hold on;
%             plot(toplot(order==j,:));
%             PlotHVLines(75:75:size(toplot,2),'v','k');
%             axis off;
%         end
%         
%         fig=figure;hold on;
%         set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
%         TP = nan(sum(idx),size(av_psth_H,2),ntotgrouped);
%         for b = 1:ntotgrouped
%             toplot = sigtypes{3}(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
%             TP(:,:,b) = nanmean(toplot(idx,:,:),3);        
%         end
%         toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));        
%         for j=1:10
%             subplot(10,1,j);hold on;
%             plot(toplot(order==j,:));
%             PlotHVLines(75:75:size(toplot,2),'v','k');
%             axis off;
%         end
%         
%     end
end
%% plot comp #6 cell in probe

% 1) create matrix cell activity probe with all cells

for m = 1:nGNG
    thismouse = GNGs(m);
    mouse = mice{thismouse}; 
        
    % Organize data and build tensor
    results = load([path mouse '-results_nosignals.mat']);
    results = results.results;
    nFrames_oneplane = results{1};
    matrix = results{3};
    ishere = results{4};
    ks = results{5};
    ks2 = results{6};
    ctx = results{7};
    acq = results{8};
    TONEF = results{9};
    REWF = results{10};
    dayss_behav = results{12};
    startfrom = results{13};
    nDays_behav = length(dayss_behav);
    if strcmp(mouse,'cd017')
        nop = matrix(:,BLOC)==4; % remove bad trials
    else
        nop = ~ismember(matrix(:,BLOC),matrix(:,BLOC)); % take everything
    end
    
    cellselection = load([path mouse '-cellselection.mat']);
    cellselection = cellselection.cellselection;
    takenCells = cellselection{1,1};
    findgooddays = cellselection{1,2};
    nKeptCells = sum(takenCells);   
    
    nframes_psth = pretone*round(acq) + posttone*round(acq);       
    tonepsth = load([path mouse '-alltonepsth.mat']);
    tonepsth = tonepsth.alltonepsth;       
    wrapper = @(x) permute(x,[2 1 3]);
    perm_tonepsth = cellfun(wrapper,tonepsth,'uniformoutput',false);
    ptone_psth = cell2mat(perm_tonepsth); % reinf + probe
        
    [phases,align_acqui] = GetBehavioralPhases(mouse);
    
    endofexpression = phases{2}(end);  
    daytoconsider = endofexpression-6:endofexpression+2;    
    ok = ~nop & ctx(:,2); % probe context
    all_selected_trials = matrix(ok & ismember(matrix(:,DAY),daytoconsider),TRIAL);
    nST = length(all_selected_trials);
    idx = matrix(ismember(matrix(:,TRIAL),all_selected_trials),RESP);    
    dayss = unique(matrix(ismember(matrix(:,TRIAL),all_selected_trials),DAY));
    
    data = permute(squeeze(ptone_psth(thesetrials(idx==H),:,:)),[2 1]);   
    
end


for r=1:R
    
    % Select positive 10%
    tresh = quantile(K.U{dim}(:,r),0.95); % plot only 10% positive population 
    idx = K.U{dim}(:,r)>=tresh;
    
    % Select NEGATIVE 10%
%     tresh = quantile(K.U{dim}(:,r),0.15); % plot only 10% negative population
%     idx = K.U{dim}(:,r)<=tresh;
    
%     disp(['comp #' num2str(r) ', n=' num2str(sum(idx))]);
         
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 0.5]);
    
    limacqui = (37/nGroupBloc)*75;
    nblocs = size(av_psth,3);
    ntotgrouped = round(nblocs/nGroupBloc)-1;   
    TP = nan(sum(idx),size(av_psth,2),ntotgrouped);
    for b = 1:ntotgrouped
        toplot = av_psth(:,:,1+(b-1)*nGroupBloc:nGroupBloc+(b-1)*nGroupBloc);
        TP(:,:,b) = nanmean(toplot(idx,:,:),3);        
    end
    toplot = reshape(TP,size(TP,1),size(TP,2)*size(TP,3));
    subplot(2,1,1);hold on;
    [~,order] = sort(K.U{dim}(idx,r),'descend');
    PlotColorCurves(toplot(order,:));
end


%% plot PSTH reward component by days

% r=5; % reward component
% r=10; % inhibitory lick component
% r=1; 
r=5; % inhibitory lick component

cellfactor = K.U{1}(:,r);
% [~,order] = sort(cellfactor,'descend');
% top10pos = order(1:0.025*size(cellfactor,1));
top10pos = find(cellfactor>limit);
% top10pos = find(cellfactor<-limit);
% top10neg = order(end-0.20*size(cellfactor,1):end);
% top10pos = order(end-0.20*size(cellfactor,1):end);
tokeep = cell(nGNG,3);
plotexamplecell = true;

figure;stem(sort(cellfactor,'descend'),'filled','color','k');
hold on;PlotHVLines(length(top10pos),'v','r');
axis off
%%
for m=1:nGNG
% for m=1
    thismouse = GNGs(m);
    mouse = mice{thismouse}; 
        
    % Organize data and build tensor
    results = load([path mouse '-results_nosignals.mat']);
    results = results.results;
    nFrames_oneplane = results{1};
    matrix = results{3};
    ishere = results{4};
    ks = results{5};
    ks2 = results{6};
    ctx = results{7};
    acq = results{8};
    TONEF = results{9};
    REWF = results{10};
    LICKF = results{10};
    dayss_behav = results{12};
    startfrom = results{13};
    nDays_behav = length(dayss_behav);
    if strcmp(mouse,'cd017')
        nop = matrix(:,BLOC)==4; % remove bad trials
    else
        nop = ~ismember(matrix(:,BLOC),matrix(:,BLOC)); % take everything
    end
    ok = ~nop & ctx(:,1);
    
    cellselection = load([path mouse '-cellselection.mat']);
    cellselection = cellselection.cellselection;
    takenCells = cellselection{1,1};
    findgooddays = cellselection{1,2};
    nKeptCells = sum(takenCells);   
    
    [these,~,whereinintervals] = InIntervals(top10pos,intervalsCells(m,:));
%     [these,~,whereinintervals] = InIntervals(top10neg,intervalsCells(m,:));
    nThese = sum(these);
    if nThese==0, disp(['no cell for mouse ' mice{thismouse}]); continue; end
    if m>1
        thesecells = top10pos(these)-intervalsCells(m-1,end);
        theseweights = cellfactor(top10pos(these));
    else
        thesecells = top10pos(these);
        theseweights = cellfactor(thesecells);
    end
%     if m>1
%         thesecells = top10neg(these)-intervalsCells(m-1,end);
%         theseweights = cellfactor(top10neg(these));
%     else
%         thesecells = top10neg(these);
%         theseweights = cellfactor(thesecells);
%     end
    
    nframes_psth = pretone*round(acq) + posttone*round(acq);       
    tonepsth = load([path mouse '-tonepsth.mat']);
    tonepsth = tonepsth.tonepsth;

%     tonepsth = load([path mouse '-tonepsth_denoised.mat']);
%     tonepsth = tonepsth.tonepsth_den; 
%     tonepsth_reinf = tonepsth(:,1);
    
%     lickpsth = load([path mouse '-lickpsth.mat']);
%     tonepsth = lickpsth.lickpsth; 
    tonepsth_reinf = tonepsth(:,1);
    
    wrapper = @(x) permute(x,[2 1 3]);
    perm_tonepsth = cellfun(wrapper,tonepsth_reinf,'uniformoutput',false);
    avtrace = cell(nDays_behav,1);
    avtrace_hit = cell(nDays_behav,1);
    avtrace_fa = cell(nDays_behav,1);
    avtrace_cr = cell(nDays_behav,1);
%     oklicks = ks(:,1) | ks(:,3);
    for d=1:nDays_behav
        avtrace{d} = perm_tonepsth{d}(:,:,thesecells);
        okk = matrix(:,DAY)==d+1;        
        avtrace_hit{d} = perm_tonepsth{d}(ks(ok & okk,1),:,thesecells);
        avtrace_fa{d} = perm_tonepsth{d}(ks(ok & okk,3),:,thesecells);
        avtrace_cr{d} = perm_tonepsth{d}(ks(ok & okk,4),:,thesecells);
%         avtrace_hit{d} = perm_tonepsth{d}(ks(ok & okk & oklicks,1),:,thesecells);
%         avtrace_fa{d} = perm_tonepsth{d}(ks(ok & okk & oklicks,3),:,thesecells);
%         avtrace_cr{d} = perm_tonepsth{d}(ks(ok & okk & oklicks,4),:,thesecells);
    end
    
    towrap = @(x) mean(x,3);
    mavtrace = cellfun(towrap,avtrace,'uniformoutput',false);
    mavtrace = cellfun(@squeeze,mavtrace,'uniformoutput',false);
    mavtrace_mat = cell2mat(mavtrace);
    mavtrace_hit = cellfun(towrap,avtrace_hit,'uniformoutput',false);
    mavtrace_hit = cellfun(@squeeze,mavtrace_hit,'uniformoutput',false);
    mavtrace_hit_mat = cell2mat(mavtrace_hit);
    mavtrace_fa = cellfun(towrap,avtrace_fa,'uniformoutput',false);
    mavtrace_fa = cellfun(@squeeze,mavtrace_fa,'uniformoutput',false);
    mavtrace_fa_mat = cell2mat(mavtrace_fa);
    mavtrace_cr = cellfun(towrap,avtrace_cr,'uniformoutput',false);
    mavtrace_cr = cellfun(@squeeze,mavtrace_cr,'uniformoutput',false);
    mavtrace_cr_mat = cell2mat(mavtrace_cr);
    
    
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 0.75]);
    climm = [0 0.25];
    subplot(4,1,1);hold on;
    PlotColorCurves(mavtrace_mat);
    PlotHVLines(75:75:size(mavtrace_mat,1),'v','w');
    title([mouse ', all trials']);
    clim(climm);
    subplot(4,1,2);hold on;
    PlotColorCurves(mavtrace_hit_mat);
    PlotHVLines(75:75:size(mavtrace_hit_mat,1),'v','w');
    title('HIT');
    clim(climm);
    subplot(4,1,3);hold on;
    PlotColorCurves(mavtrace_fa_mat);
    PlotHVLines(75:75:size(mavtrace_mat,1),'v','w');    
    title('FA');
    clim(climm);
    subplot(4,1,4);hold on;
    PlotColorCurves(mavtrace_cr_mat);
    PlotHVLines(75:75:size(mavtrace_mat,1),'v','w');    
    title('CR');
    clim(climm);
    colormap jet;
    
    if plotexamplecell
        % Plot in example the cell in this mouse with the highest weight.
        avtrace_hit_max = cell(nDays_behav,1);
        avtrace_fa_max = cell(nDays_behav,1);
        avtrace_cr_max = cell(nDays_behav,1);
        nhittrials = nan(nDays_behav,1);
        for d=1:nDays_behav
            okk = matrix(:,DAY)==d+1;
    %         avtrace_hit_max{d} = perm_tonepsth{d}(ks(ok & okk  & oklicks,1),:,thesecells(1));
            avtrace_hit_max{d} = perm_tonepsth{d}(ks(ok & okk,1),:,thesecells(1));
            avtrace_fa_max{d} = perm_tonepsth{d}(ks(ok & okk,3),:,thesecells(1));
            avtrace_cr_max{d} = perm_tonepsth{d}(ks(ok & okk,4),:,thesecells(1));
    %         nhittrials(d) =  sum(ks(ok & okk  & oklicks,1));
            nhittrials(d) =  sum(ks(ok & okk,1));
        end

        fig=figure;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
        subplot(1,3,1);hold on;
        avtrace_hit_max = cell2mat(avtrace_hit_max);
        PlotColorCurves(Smooth(avtrace_hit_max,[5 2]));
        colormap jet;
        clim([0 0.2]);
        PlotHVLines(16,'v','w');    
        PlotHVLines(cumsum(nhittrials),'h','w');    
        ylabel('HIT trials');xlabel('Frame');
        title([mouse ', cell ' num2str(thesecells(1))]);
        subplot(1,3,2);hold on;
        avtrace_fa_max = cell2mat(avtrace_fa_max);
        PlotColorCurves(Smooth(avtrace_fa_max,[5 2]));
        colormap jet;
        clim([0 0.2]);
        PlotHVLines(16,'v','w');    
        subplot(1,3,3);hold on;
        avtrace_cr_max = cell2mat(avtrace_cr_max);
        PlotColorCurves(Smooth(avtrace_cr_max,[5 2]));
        colormap jet;
        clim([0 0.2]);
        PlotHVLines(16,'v','w');    
    
        avtrace_hit_max = cell(nDays_behav,1);
        nhittrials = nan(nDays_behav,1);
        for d=1:nDays_behav
            okk = matrix(:,DAY)==d+1;
    %         avtrace_hit_max{d} = perm_tonepsth{d}(ks(ok & okk  & oklicks,1),:,thesecells(2));
            avtrace_hit_max{d} = perm_tonepsth{d}(ks(ok & okk,1),:,thesecells(2));
    %         nhittrials(d) =  sum(ks(ok & okk  & oklicks,1));
            nhittrials(d) =  sum(ks(ok & okk,1));
        end

        fig=figure;
        set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
        avtrace_hit_max = cell2mat(avtrace_hit_max);
    %     PlotColorCurves(smoothdata(avtrace_hit_max,'movmean',1));
        PlotColorCurves(Smooth(avtrace_hit_max,[5 2]));
        colormap jet;
        clim([0 0.2]);
        PlotHVLines(16,'v','w');    
        PlotHVLines(cumsum(nhittrials),'h','w');    
        ylabel('HIT trials');xlabel('Frame');
        title([mouse ', cell ' num2str(thesecells(2))]);

        toplot = top10pos(these);
    %     toplot = top10neg(these);
        PlotThatCell(toplot(1));
        PlotThatCell(toplot(2));
    end
    
    
    drawnow;
    
%     tok = cell2mat(avtrace_hit);
%     tokeep{m,1} = tok(1:1000,:,:);    
%     tok = cell2mat(avtrace_fa);
%     if size(tok,1)<1000
%         n = size(tok,1);
%         tofill = nan(1000,size(tok,2),size(tok,3));
%         tok = [tok;tofill];
%         tokeep{m,2} = tok(1:1000,:,:);  
%     else
%         tokeep{m,2} = tok(1:1000,:,:);  
%     end
%     tok = cell2mat(avtrace_cr);
%     tokeep{m,3} = tok(1:1000,:,:);  
    tok = cell2mat(avtrace_hit);
    tokeep{m,1} = tok;    
    tok = cell2mat(avtrace_fa);    
    tokeep{m,2} = tok;  
    tok = cell2mat(avtrace_cr);
    tokeep{m,3} = tok;  
end
    
%% Plot example cells

for thiscell = 1:length(thesecells)
% for thiscell = 1:2
%     if thesecells(thiscell)~=286, continue;end
%     if ~ismember(thesecells(thiscell),[32;75;103;215;52]), continue;end %
%     mouse cd042, r=5
    
    avtrace_hit_max = cell(nDays_behav,1);
    avtrace_fa_max = cell(nDays_behav,1);
    avtrace_cr_max = cell(nDays_behav,1);
    nhittrials = nan(nDays_behav,1);
    nfatrials = nan(nDays_behav,1);
    ncrtrials = nan(nDays_behav,1);
    framefirstlick = cell(nDays_behav,1);
    for d=1:nDays_behav
        okk = matrix(:,DAY)==d+1;
    %         avtrace_hit_max{d} = perm_tonepsth{d}(ks(ok & okk  & oklicks,1),:,thesecells(2));
        avtrace_hit_max{d} = perm_tonepsth{d}(ks(ok & okk,1),:,thesecells(thiscell));
        avtrace_fa_max{d} = perm_tonepsth{d}(ks(ok & okk,3),:,thesecells(thiscell));
        avtrace_cr_max{d} = perm_tonepsth{d}(ks(ok & okk,4),:,thesecells(thiscell));
    %         nhittrials(d) =  sum(ks(ok & okk  & oklicks,1));
        nhittrials(d) =  sum(ks(ok & okk,1));
        nfatrials(d) =  sum(ks(ok & okk,3));
        ncrtrials(d) =  sum(ks(ok & okk,4));
        framefirstlick{d} = matrix(ok & okk & ks(:,1), LICKF)-matrix(ok & okk & ks(:,1), TONEF);
    end
    framefirstlick = cell2mat(framefirstlick) +15;
        
    fig=figure;
    set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.5 1]);
    avtrace_hit_max = cell2mat(avtrace_hit_max);
%     PlotColorCurves(smoothdata(avtrace_hit_max,'movmean',1));
    subplot(1,3,1);hold on;
        PlotColorCurves(Smooth(avtrace_hit_max,[5 2]));
    colormap jet;
    clim([0 0.1]);
    PlotHVLines(15,'v','w');    
    PlotHVLines(cumsum(nhittrials),'h','w');    
    ylabel('HIT trials');xlabel('Frame');
    title([mouse ', cell ' num2str(thesecells(thiscell))]);
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);
%     plot(framefirstlick(:,1),1:sum(nhittrials),'w.');
%     plot(framefirstlick(:,2),1:sum(nhittrials),'g.');
    
    subplot(1,3,2);hold on;
    avtrace_fa_max = cell2mat(avtrace_fa_max);
    PlotColorCurves(Smooth(avtrace_fa_max,[5 2]));
    colormap jet;
    clim([0 0.1]);
    PlotHVLines(15,'v','w');    
    PlotHVLines(cumsum(nfatrials),'h','w');
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);
    subplot(1,3,3);hold on;
    avtrace_cr_max = cell2mat(avtrace_cr_max);
    PlotColorCurves(Smooth(avtrace_cr_max,[5 2]));
    colormap jet;
    clim([0 0.1]);
    PlotHVLines(15,'v','w');    
    PlotHVLines(cumsum(ncrtrials),'h','w');
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);
    
    % for r=5
%     toplot = top10pos(these);
%     if strcmp(mouse,'cd036') && ismember(thesecells(thiscell),[3;99;100;102;205;217])
%         PlotThatCell(toplot(thiscell));
%     elseif strcmp(mouse,'cd042') && ismember(thesecells(thiscell),[29;32;52;75;81;103;195;216;104;159;215])
%         PlotThatCell(toplot(thiscell));
%     elseif strcmp(mouse,'cd044') && ismember(thesecells(thiscell),[94;274;276;106;481;531;481])
%         PlotThatCell(toplot(thiscell));
%     else
%         close(fig);
%     end

%     % for r=1
%     toplot = top10pos(these);
%     if strcmp(mouse,'cd044') && ismember(thesecells(thiscell),[179])
%         PlotThatCell(toplot(thiscell));
%     elseif strcmp(mouse,'cd036') && ismember(thesecells(thiscell),[116;45;372;6;42;161;225])
%         PlotThatCell(toplot(thiscell));
%     elseif strcmp(mouse,'cd017') && ismember(thesecells(thiscell),[130])
%         PlotThatCell(toplot(thiscell));
%     else
%         close(fig);
%     end
    
%     % for r=3
%     toplot = top10pos(these);
%     if strcmp(mouse,'cd017') && ismember(thesecells(thiscell),[23;57;186])
%         PlotThatCell(toplot(thiscell));
%     elseif strcmp(mouse,'cd044') && ismember(thesecells(thiscell),[363;469;403;279;393;142;389;286;55;309;311;66;371])
%         PlotThatCell(toplot(thiscell));
%     else
%         close(fig);
%     end

%     % for r=10
%     toplot = top10pos(these);
%     if strcmp(mouse,'cd044') && ismember(thesecells(thiscell),[483;437;452;395;364;235;460;49;27;247;193])
%         PlotThatCell(toplot(thiscell));
%     else
%         close(fig);
%     end

    % mix target + reward = cd044, cell 307, 247
    % reward then target = cd044, cell 455, 460

%     toplot = top10pos(these);
%     %     toplot = top10neg(these);
%     PlotThatCell(toplot(1));
%     PlotThatCell(toplot(2));
    drawnow;
end


%% Looking at overall 15% (or 10%) top cell in very first trials of each animals
figure;
% trials = 1:200;
trials = 1:423;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,1),'uniformoutput',false);
% perm_tokeep = perm_tokeep([1 2 4],:);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
% smoothfactor = max(trials)*0.05;
% smoothfactor = [5 1];
smoothfactor = [2 1];
% smoothfactor = [1 1];

subplot(1,3,1);hold on;
% PlotColorCurves(smoothdata(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),'movmean',smoothfactor));
PlotColorCurves(Smooth(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),smoothfactor));
clim([0 0.05]);
PlotHVLines(15,'v','w','linewidth',2);
colormap jet;
ylabel('Trials');
xlabel('Time from tone onset (s)');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
title(['HIT (n=' num2str(nGNG) ')']);

trials = 1:423;
% trials = 1:200;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,2),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
subplot(1,3,2);hold on;
% PlotColorCurves(smoothdata(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),'movmean',smoothfactor));
PlotColorCurves(Smooth(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),smoothfactor));
clim([0 0.05]);
PlotHVLines(15,'v','w','linewidth',2);
xlabel('Time from tone onset (s)');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
title(['FA (n=' num2str(nGNG) ')']);

trials = 1:423;
% trials = 1:200;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,3),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
subplot(1,3,3);hold on;
% PlotColorCurves(smoothdata(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),'movmean',smoothfactor));
PlotColorCurves(Smooth(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),smoothfactor));
clim([0 0.05]);
colormap jet;
PlotHVLines(15,'v','w','linewidth',2);
xlabel('Time from tone onset (s)');
set(gca,'xtick',0:15:75,'xticklabel',-1:4);
title(['CR (n=' num2str(nGNG) ')']);

%% compare significance to zero
figure;plot(K.U{2}(:,5));
xx = find(K.U{2}(:,5)<-0.1);
posttonewind = [xx(1) xx(end)];
hold on;PlotIntervals(posttonewind);

figure;hold on;
trials = 1:200;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,1),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
a=1;
for i=1:20:200
    subplot(4,4,a);hold on;
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+19,:,:),3))),'color',h_color,'linewidth',2);    
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+19,:,:),3)))+...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+19,:,:),3))),'color',h_color);
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+19,:,:),3)))-...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+19,:,:),3))),'color',h_color);
    xlabel('Time from tone onset (s)');
%     set(gca,'xtick',0:15:75,'xticklabel',-1:4);
%     title(['HIT (n=' num2str(nGNG) ')']);
%     PlotHVLines(15,'v','k');
    a=a+1;
end

figure;hold on;
a=1;
blocsize = 40;
endtrial = 423;
trials = 1:endtrial;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,3),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
pz = nan(length(1:blocsize:endtrial),1);
d2compare = nan(size(perm_tokeep_mat,3),length(1:blocsize:endtrial-blocsize));
for i=1:blocsize:endtrial-blocsize
    d2compare0 = squeeze(mean(perm_tokeep_mat(i:i+blocsize-1,posttonewind,:),2));
    ps = nan(size(d2compare0,2),1);
    for c=1:size(d2compare0,2)
        [~,ps(c)] = ttest(d2compare0(:,c));
    end
    d2compare(:,a) = squeeze(mean(mean(perm_tokeep_mat(i:i+blocsize-1,posttonewind,:),2)));
    pz(a) = signrank(d2compare(:,a));
%     boxplot(d2compare,a); hold on;   
    a=a+1;
end
% boxplot(d2compare);
kruskalbar(d2compare);

a=1;
blocsize = 40;
endtrial = 1000;
trials = 1:endtrial;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,3),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
pz = nan(length(1:blocsize:endtrial),1);
d2compare = nan(size(perm_tokeep_mat,3),length(1:blocsize:endtrial));
for i=1:blocsize:1000
    d2compare0 = squeeze(mean(perm_tokeep_mat(i:i+blocsize-1,posttonewind,:),2));
    ps = nan(size(d2compare0,2),1);
    for c=1:size(d2compare0,2)
        [~,ps(c)] = ttest(d2compare0(:,c));
    end
    d2compare(:,a) = squeeze(mean(mean(perm_tokeep_mat(i:i+blocsize-1,posttonewind,:),2)));
    pz(a) = signrank(d2compare(:,a));
%     boxplot(d2compare,a); hold on;   
    a=a+1;
end
% boxplot(d2compare);
kruskalbar(d2compare);



%% compare first bloc of 40-trial

figure;hold on;

trials = 1:300;
wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
perm_tokeep = cellfun(wrapper,tokeep(:,1),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
a=1;
for i=1:40:200
    subplot(4,4,a);hold on;
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',h_color,'linewidth',2);    
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3)))+...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',h_color);
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3)))-...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',h_color);
    xlabel('Time from tone onset (s)');
%     set(gca,'xtick',0:15:75,'xticklabel',-1:4);
%     title(['HIT (n=' num2str(nGNG) ')']);
%     PlotHVLines(15,'v','k');
    a=a+1;
end
perm_tokeep = cellfun(wrapper,tokeep(:,3),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
a=1;
for i=1:40:200
    subplot(4,4,a);hold on;
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',cr_color,'linewidth',2);    
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3)))+...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',cr_color);
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3)))-...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',cr_color);
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);
%     title(['HIT (n=' num2str(nGNG) ')']);
    PlotHVLines(15,'v','k');
    a=a+1;
end
perm_tokeep = cellfun(wrapper,tokeep(:,2),'uniformoutput',false);
perm_tokeep_mat = cell2mat(perm_tokeep);
perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
a=1;
for i=1:40:200
    subplot(4,4,a);hold on;
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',fa_color,'linewidth',2);    
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3)))+...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',fa_color);
    plot(nanmean(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3)))-...
        nansem(squeeze(nanmean(perm_tokeep_mat(i:i+39,:,:),3))),'color',fa_color);
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);
%     title(['HIT (n=' num2str(nGNG) ')']);
    PlotHVLines(15,'v','k');
    a=a+1;
end

%% Compare FA to CR in each animals
trials = 1:400;
inhib = nan(max(trials),75,nGNG);
for m=1:nGNG
    
    figure;    
    wrapper = @(x) permute(x(trials,:,:),[3 1 2]);
    perm_tokeep = cellfun(wrapper,tokeep(m,2),'uniformoutput',false);
    perm_tokeep_mat = cell2mat(perm_tokeep);
    perm_tokeep_matFA = permute(perm_tokeep_mat,[2 3 1]);
    perm_tokeep = cellfun(wrapper,tokeep(m,3),'uniformoutput',false);
    perm_tokeep_mat = cell2mat(perm_tokeep);
    perm_tokeep_matCR = permute(perm_tokeep_mat,[2 3 1]);
    
    dif = perm_tokeep_matCR-perm_tokeep_matFA;
    inhib(:,:,m) = squeeze(nanmean(dif,3));
    PlotColorCurves(Smooth(inhib(:,:,m),smoothfactor)); 
    clim([-0.02 0.02]);
    colormap jet;
       
end


figure;
PlotColorCurves(Smooth(squeeze(nanmean(inhib,3)),smoothfactor)); 
clim([-0.02 0.02]);
colormap jet;



%% load 20-trial binned matrix
for m=1:nGNG
    thismouse = GNGs(m);
    mouse = mice{thismouse}; 
    mat20 = load([path mouse '-array_20trials_blocs.mat']);
    mat20 = mat20.tosave;
    
    [these,~,whereinintervals] = InIntervals(top10pos,intervalsCells(m,:));
    nThese = sum(these);
    if nThese==0, disp(['no cell for mouse ' mice{thismouse}]); continue; end
    if m>1
        thesecells = top10pos(these)-intervalsCells(m-1,end);
        theseweights = cellfactor(top10pos(these));
    else
        thesecells = top10pos(these);
        theseweights = cellfactor(thesecells);
    end
    mat20here = mat20{1};
    
    x = 1:size(mat20here,2);
    start_idx_HIT = (1:3*75:size(mat20here,2))';
    in_HIT = InIntervals(x,[start_idx_HIT start_idx_HIT+75-1]);
    matHIT = mat20here(:,in_HIT);
    matHITT = reshape(matHIT,197,75,size(matHIT,2)/75);
    matHITT = matHITT - mean(matHITT(:,2:13,:),2);
    matHIT = matHITT;
    matHIT = reshape(matHIT,197,75*size(matHIT,3));
    figure;hold on;
    plot(mean(matHIT));
    PlotHVLines(75:75:size(matHIT,3),'v','color',gray);
    PlotHVLines(15:75:size(matHIT,3),'v','k');
    
    x = 1:size(mat20here,2);
    start_idx_FA = (1+75:3*75:size(mat20here,2))';
    in_FA = InIntervals(x,[start_idx_FA start_idx_FA+75-1]);
    matFA = mat20here(:,in_FA);
    matFAT = reshape(matFA,197,75,size(matFA,2)/75);
    matFAT = matFAT - mean(matFAT(:,2:13,:),2);
    matFA = matFAT;
    matFA = reshape(matFA,197,75*size(matFA,3));
    
    start_idx_CR = (1+2*75:3*75:size(mat20here,2))';
    in_CR = InIntervals(x,[start_idx_CR start_idx_CR+75-1]);
    matCR = mat20here(:,in_CR);
    matCRT = reshape(matCR,197,75,size(matCR,2)/75);
    matCRT = matCRT - mean(matCRT(:,2:13,:),2);
    matCR = matCRT;
    matCR = reshape(matCR,197,75*size(matCR,3));
    
    diffFACR = matCR-matFA;
    diffFACR = reshape(diffFACR,size(diffFACR,1),75,size(diffFACR,2)/75);
    these_diffFACR = squeeze(nanmean(diffFACR(thesecells,:,:)));
    all_diffFACR = squeeze(nanmean(diffFACR));
    figure;PlotColorCurves(these_diffFACR');
    clim([-0.02 0.02]);
    colormap(redbluecmap);
    PlotHVLines(15,'v','w','linewidth',2);
    
    stacksize = 20;
    stack_grouped = round(size(these_diffFACR,2)/stacksize);
    all_stack = nan(stack_grouped,75);
    stack = nan(stack_grouped,75);
    for k=1:stack_grouped
        stack(k,:) = nanmean(these_diffFACR(:,(k-1)*stacksize+1:stacksize+(k-1)*stacksize-1),2);
        all_stack(k,:) = nanmean(all_diffFACR(:,(k-1)*stacksize+1:stacksize+(k-1)*stacksize-1),2);
    end
    figure;
    PlotColorCurves(smoothdata(stack,2,'movmean',3));    
    clim([-0.02 0.02]);
    colormap(redbluecmap);
    PlotHVLines(15,'v','w','linewidth',2);
    figure;
    PlotColorCurves(smoothdata(all_stack,2,'movmean',3));    
    clim([-0.02 0.02]);
    colormap(redbluecmap);
    PlotHVLines(15,'v','w','linewidth',2);
    
    count_behavior_here = mat20{4};
    hnfoilbloc = squeeze((count_behavior_here(:,2,:) + count_behavior_here(:,3,:))); % bloc x mice
    hntargetbloc = bloc_size - hnfoilbloc; % bloc x mice
    percent = nan(stack_grouped,1);
    for k=1:stack_grouped
        idx_bloc = (k-1)*stacksize+1:stacksize+(k-1)*stacksize-1;
        hhitrate = sum(squeeze(sum(count_behavior_here(idx_bloc,1,:),3))) ./ sum(sum(hntargetbloc(idx_bloc),2));
        hfarate = sum(squeeze(sum(count_behavior_here(idx_bloc,2,:),3))) ./ sum(sum(hnfoilbloc(idx_bloc),2));
        percent(k) = (hhitrate - hfarate) * 100;
    end
    figure;
    plot(mean(stack(:,15:70),2),percent,'rx');
    ylim([0 100]);
    xlim([-0.02 0.02]);    
    hold on;plot(mean(all_stack(:,15:70),2),percent,'kx');
    PlotHVLines(0,'v','k');
    
%     mmatCR = reshape(matCR,size(matCR,1),75,size(matCR,2)/75);
%     mmatFA = reshape(matFA,size(matFA,1),75,size(matFA,2)/75);
%     diffFACR = max(mmatCR(:,15:30,:),[],2)-max(mmatFA(:,15:30,:),[],2);
% %     a = squeeze(max(mmatCR(:,15:30,:),[],2));
% %     a = a(thesecells,:);
% %     b = squeeze(max(mmatFA(:,15:30,:),[],2));
% %     b = b(thesecells,:);
% %     figure;plot([a(:) b(:)]','ko-');
%     these_diffFACR = squeeze(nanmean(diffFACR(thesecells,:,:)));
%     figure;plot(these_diffFACR');
%     clim([-0.02 0.02]);
%     colormap jet;    
end





%     tosave = {mat,trial_selected,bloc_vec,count_behavior,target_foil};
    
    

%% 
climm = [0 0.1];
smoothfactor = [2 1];
for m=1:nGNG
% for m=4
    thismouse = GNGs(m);
    mouse = mice{thismouse}; 
    
    % Organize data and build tensor
    results = load([path mouse '-results_nosignals.mat']);
    results = results.results;
    nFrames_oneplane = results{1};
    matrix = results{3};
    ishere = results{4};
    ks = results{5};
    ks2 = results{6};
    ctx = results{7};
    acq = results{8};
    TONEF = results{9};
    LICKF = results{10};
    dayss_behav = results{12};
    startfrom = results{13};
    nDays_behav = length(dayss_behav);
    if strcmp(mouse,'cd017')
        nop = matrix(:,BLOC)==4; % remove bad trials
    else
        nop = ~ismember(matrix(:,BLOC),matrix(:,BLOC)); % take everything
    end   
    ok = ~nop & ctx(:,1);
    
    nhittrials = nan(nDays_behav,1);
    nfatrials = nan(nDays_behav,1);
    ncrtrials = nan(nDays_behav,1);
    framefirstlick_fa = cell(nDays_behav,1);
    framefirstlick_hit = cell(nDays_behav,1);
    for d=1:nDays_behav
        okk = matrix(:,DAY)==d+1;
        nhittrials(d) =  sum(ks(ok & okk,1));
        nfatrials(d) =  sum(ks(ok & okk,3));
        ncrtrials(d) =  sum(ks(ok & okk,4));
        framefirstlick_hit{d} = matrix(ok & okk & ks(:,1), LICKF)-matrix(ok & okk & ks(:,1), TONEF);
        framefirstlick_fa{d} = matrix(ok & okk & ks(:,3), LICKF)-matrix(ok & okk & ks(:,3), TONEF);
    end
    framefirstlick_hit = cell2mat(framefirstlick_hit) +15;
    framefirstlick_fa = cell2mat(framefirstlick_fa) +15;
    
%     licks_behavior = load([path mouse '-licks-trials.mat'],'lickvector');
%     licks_behavior = licks_behavior.lickvector;
%     [in,trial_hit_licks] = ismember(licks_behavior(:,1),matrix(ok & ks(:,1),TRIAL));
%     licks_hit = licks_behavior(in,:);
%     trial_hit_licks(trial_hit_licks==0)=[];
%     [in,trial_fa_licks] = ismember(licks_behavior(:,1),matrix(ok & ks(:,3),TRIAL));
%     licks_fa = licks_behavior(in,:);
%     trial_fa_licks(trial_fa_licks==0) = [];
    
%     intervals_hit = [1;cumsum(nhittrials)];
%     figure;
%     for j=1:length(intervals_hit)-1
%         subplot(8,2,j);hold on;
%         title(['D' num2str(j)]);
%         in = InIntervals(trial_hit_licks,[intervals_hit(j) intervals_hit(j+1)]);
%         histogram(licks_hit(in,2),500);
%         xlim([-1 4]);
%     end
%     
%     intervals_fa = [1;cumsum(nfatrials)];
%     figure;
%     for j=1:length(intervals_fa)-1
%         subplot(8,2,j);hold on;
%         title(['D' num2str(j)]);
%         in = InIntervals(trial_fa_licks,[intervals_fa(j) intervals_fa(j+1)]);
%         histogram(licks_fa(in,2),500);
%         xlim([-1 4]);
%     end
    
    figure;

    wrapper = @(x) permute(x,[3 1 2]);
    perm_tokeep = cellfun(wrapper,tokeep(m,1),'uniformoutput',false);
    perm_tokeep_mat = cell2mat(perm_tokeep);
    perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
%     trials = 1:420;
%     smoothfactor = max(trials)*0.05;
    subplot(1,3,1);hold on;
%     PlotColorCurves(smoothdata(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),'movmean',smoothfactor));
    PlotColorCurves(Smooth(squeeze(nanmean(perm_tokeep_mat(:,:,:),3)),smoothfactor));
    clim(climm);
    title(mouse);
    PlotHVLines(16,'v','w');
    PlotHVLines(cumsum(nhittrials),'h','w');
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);  
%     plot((licks_hit(:,2)+1)*15,trial_hit_licks,'w.');
%     plot(framefirstlick_hit(:,2),1:sum(nhittrials),'w.');
    
    

    perm_tokeep = cellfun(wrapper,tokeep(m,2),'uniformoutput',false);
    perm_tokeep_mat = cell2mat(perm_tokeep);
    perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
    subplot(1,3,2);hold on;
%     PlotColorCurves(smoothdata(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),'movmean',smoothfactor));
    PlotColorCurves(Smooth(squeeze(nanmean(perm_tokeep_mat(:,:,:),3)),smoothfactor));
    clim(climm);
    PlotHVLines(16,'v','w');
    PlotHVLines(cumsum(nfatrials),'h','w');
    xlabel('Time from tone onset (s)');
%     plot(framefirstlick_fa(:,2),1:sum(nfatrials),'w.');
%     plot((licks_fa(:,2)+1)*15,trial_fa_licks,'w.');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);

    perm_tokeep = cellfun(wrapper,tokeep(m,3),'uniformoutput',false);
    perm_tokeep_mat = cell2mat(perm_tokeep);
    perm_tokeep_mat = permute(perm_tokeep_mat,[2 3 1]);
    subplot(1,3,3);hold on;
%     PlotColorCurves(smoothdata(squeeze(nanmean(perm_tokeep_mat(trials,:,:),3)),'movmean',smoothfactor));
    PlotColorCurves(Smooth(squeeze(nanmean(perm_tokeep_mat(:,:,:),3)),smoothfactor));
    clim(climm);
    colormap jet;
    PlotHVLines(16,'v','w');
    PlotHVLines(cumsum(ncrtrials),'h','w');
    xlabel('Time from tone onset (s)');
    set(gca,'xtick',0:15:75,'xticklabel',-1:4);
    
    drawnow;
    
end


%% Look at 'baseline' components

baseline_comps = [2;4;8;11];
ncelltoselect = round(0.01*nCellsTot);
for r=baseline_comps'
    [~,orderneuronfac] = sort(K.U{1}(:,r),'descend');
    these = orderneuronfac(1:ncelltoselect);
    for t=1:length(these)
        PlotThatCell(these(t));
        drawnow;
    end
end

%% look at repartition of animals in top 10-15-20% of weights
fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
for r=1:R
    cellfactor = K.U{1}(:,r);
    [~,order] = sort(cellfactor,'descend');
    top10pos = order(1:0.10*size(cellfactor,1));
    [~,whichInterval,~] = InIntervals(top10pos,intervalsCells);
    subplot(R,3,1+(r-1)*3);hold on;
    pie(Accumulate(whichInterval))
    axis off
    top15pos = order(1:0.15*size(cellfactor,1));
    [~,whichInterval,~] = InIntervals(top15pos,intervalsCells);
    subplot(R,3,2+(r-1)*3);hold on;
    pie(Accumulate(whichInterval))
    axis off
    top20pos = order(1:0.20*size(cellfactor,1));
    [~,whichInterval,~] = InIntervals(top20pos,intervalsCells);
    subplot(R,3,3+(r-1)*3);hold on;
    pie(Accumulate(whichInterval));
    axis off
end
legend(mice(GNGs))

fig=figure;
set(fig, 'Units', 'Normalized', 'OuterPosition', [0 0 0.25 1]);
for r=1:R
    cellfactor = K.U{1}(:,r);
    [~,order] = sort(cellfactor,'descend');
    top10neg = order(end-0.10*size(cellfactor,1):end);
    [~,whichInterval,~] = InIntervals(top10neg,intervalsCells);
    subplot(R,3,1+(r-1)*3);hold on;
    pie(Accumulate(whichInterval))
    axis off
    top15neg = order(end-0.15*size(cellfactor,1):end);
    [~,whichInterval,~] = InIntervals(top15neg,intervalsCells);
    subplot(R,3,2+(r-1)*3);hold on;
    pie(Accumulate(whichInterval))
    axis off
    top20neg = order(end-0.20*size(cellfactor,1):end);
    [~,whichInterval,~] = InIntervals(top20neg,intervalsCells);
    subplot(R,3,3+(r-1)*3);hold on;
    pie(Accumulate(whichInterval));
    axis off
end
legend(mice(GNGs))

%% In reward component, look at proportion of target responsive cells 
% and reward responsive cells

maxtrial = 400;
trials_intervals = 0:40:maxtrial;
trials_intervals = [trials_intervals(1:end-1)' trials_intervals(2:end)'];
trials_intervals(:,1) = trials_intervals(:,1)+1;

r=5; % reward comp
cellfactor = K.U{1}(:,r);
[~,order] = sort(cellfactor,'descend');
topNpos = order(1:0.10*size(cellfactor,1));
% topNpos = order(1:end);
bas = 1:14;
tone = 15:22;
rew = 0;
method = 'sd';plotcell = false;
tresp = cell(nGNG,1);
rresp = cell(nGNG,1);
TRACES = nan(nGNG,75*size(trials_intervals,1));
TRACESFA = nan(nGNG,75*size(trials_intervals,1));
TRACESCR = nan(nGNG,75*size(trials_intervals,1));
TRACESM = nan(nGNG,75*size(trials_intervals,1));
PROBE_HIT = cell(nGNG,1);
%%
for m=1:nGNG
    thismouse = GNGs(m);
    mouse = mice{thismouse}; 
        
    % Organize data and build tensor
    results = load([path mouse '-results_nosignals.mat']);
    results = results.results;
    nFrames_oneplane = results{1};
    matrix = results{3};
    ishere = results{4};
    ks = results{5};
    ks2 = results{6};
    ctx = results{7};
    acq = results{8};
    TONEF = results{9};
    REWF = results{10};
    dayss_behav = results{12};
    startfrom = results{13};
    nDays_behav = length(dayss_behav);
    if strcmp(mouse,'cd017')
        nop = matrix(:,BLOC)==4; % remove bad trials
    else
        nop = ~ismember(matrix(:,BLOC),matrix(:,BLOC)); % take everything
    end
    ok = ~nop & ctx(:,1);
    
    cellselection = load([path mouse '-cellselection.mat']);
    cellselection = cellselection.cellselection;
    takenCells = cellselection{1,1};
    findgooddays = cellselection{1,2};
    nKeptCells = sum(takenCells);   
    
    [these,~,whereinintervals] = InIntervals(topNpos,intervalsCells(m,:));
    nThese = sum(these);
    if nThese==0, disp(['no cell for mouse ' mice{thismouse}]); continue; end
    if m>1
        thesecells = topNpos(these)-intervalsCells(m-1,end);
        theseweights = cellfactor(topNpos(these));
    else
        thesecells = topNpos(these);
        theseweights = cellfactor(thesecells);
    end    
    nframes_psth = pretone*round(acq) + posttone*round(acq);       
    tonepsth = load([path mouse '-tonepsth.mat']);
    tonepsth = tonepsth.tonepsth;
    tonepsth_reinf = tonepsth(:,1);
    tonepsth_probe = tonepsth(:,2);
    
    wrapper = @(x) permute(x,[2 1 3]);
    perm_tonepsth = cellfun(wrapper,tonepsth_reinf,'uniformoutput',false);
    perm_tonepsth_probe = cellfun(wrapper,tonepsth_probe,'uniformoutput',false);
    avtrace = cell(nDays_behav,1);
    avtrace_hit = cell(nDays_behav,1);
    avtrace_fa = cell(nDays_behav,1);
    avtrace_cr = cell(nDays_behav,1);
    avtrace_m = cell(nDays_behav,1);
    avtrace_PROBE_hit = cell(nDays_behav,1);
    for d=1:nDays_behav
        avtrace{d} = perm_tonepsth{d}(:,:,thesecells);
        okk = matrix(:,DAY)==d+1;        
        avtrace_hit{d} = perm_tonepsth{d}(ks(ok & okk,1),:,thesecells);
        avtrace_fa{d} = perm_tonepsth{d}(ks(ok & okk,3),:,thesecells);
        avtrace_cr{d} = perm_tonepsth{d}(ks(ok & okk,4),:,thesecells);
        avtrace_m{d} = perm_tonepsth{d}(ks(ok & okk,2),:,thesecells);
        avtrace_PROBE_hit{d} = perm_tonepsth_probe{d}(ks(ctx(:,2) & ~nop & okk,1),:,thesecells);
    end
    avtrace_hit = cell2mat(avtrace_hit);
    avtrace_hit_200restric = avtrace_hit(1:maxtrial,:,:);
    avtrace_fa = cell2mat(avtrace_fa);
    avtrace_fa_200restric = avtrace_fa(1:maxtrial,:,:);
    avtrace_cr = cell2mat(avtrace_cr);
    avtrace_cr_200restric = avtrace_cr(1:maxtrial,:,:);
    avtrace_m = cell2mat(avtrace_m);
    PROBE_HIT{m} = avtrace_PROBE_hit;
%     avtrace_m_200restric = avtrace_m(1:maxtrial,:,:);
    trials200 = (1:maxtrial)';
    signif_pos = nan(75,nThese,size(trials_intervals,1));
    signif_neg = nan(75,nThese,size(trials_intervals,1));
    x_real_hit = matrix(ok & ismember(matrix(:,DAY),(1:nDays_behav)+1) & ks(:,1),TRIAL);

    TRACE = nan(75,size(trials_intervals,1));
    TRACEFA = nan(75,size(trials_intervals,1));
    TRACECR = nan(75,size(trials_intervals,1));
    TRACEM = nan(75,size(trials_intervals,1));
    for ti=1:size(trials_intervals,1)
        in = InIntervals(trials200,trials_intervals(ti,:));
        dav = avtrace_hit_200restric(in,:,:);
        TRACE(:,ti) = nanmean(nanmean(dav,3));
        davfa = avtrace_fa_200restric(in,:,:);
        TRACEFA(:,ti) = nanmean(nanmean(davfa,3));
        davcr = avtrace_cr_200restric(in,:,:);
        TRACECR(:,ti) = nanmean(nanmean(davcr,3));
        in = InIntervals((1:size(avtrace_m,1))',trials_intervals(ti,:));
        davm = avtrace_m(in,:,:);
        TRACEM(:,ti) = nanmean(nanmean(davm,3));
        for c=1:nThese
            davc = dav(:,:,c);
            
            if strcmp(method,'shuffle')
                nshuffle = 500;
                nsample = size(davc,1);
                [~,shuffle_idx] = sort(rand(size(davc,2),nshuffle));
                shuffle_idx = shuffle_idx(1:nsample,:); % 40 * 500
                idx_mat = repmat(1:75,nsample*nshuffle,1);
                idx = idx_mat + repelem(shuffle_idx(:),1,75); 

                shuffletrace = repmat([davc davc],nshuffle,1); % 40(*500) * 75*2 
                shuffletrace = shuffletrace'; % 75, 40(*500)
                ind_shuffletrace = shuffletrace(:);

                ix = 0:size(davc,2)*2:size(davc,2)*2*size(davc,1)*nshuffle;
                toadd = repelem(ix(1:end-1)',1,75);
                ind = idx + toadd;
                ind = ind';
                ind = ind(:);

                circshiftedtrace = ind_shuffletrace(ind);
                circshiftedtrace = reshape(circshiftedtrace,size(davc,2),nsample,nshuffle);
                circshiftedtrace = squeeze(mean(circshiftedtrace,2));
                upperlim = quantile(circshiftedtrace',0.99);
                smoothmean = smoothdata(mean(davc),'movmedian',3);
                signif_pos(:,c,ti) = smoothmean>upperlim;
                lowerlim = quantile(circshiftedtrace',0.01);
                signif_neg(:,c,ti) = smoothmean<lowerlim;
                
                if plotcell
                    fig=figure;hold on;
                    plot(circshiftedtrace,'color',gray);
                    plot(smoothmean);
                    if sum(signif_pos(:,c,ti))~=0
                        plot(find(signif_pos(:,c,ti)),max(smoothmean)+0.02,'k*');
                    end
                    if sum(signif_neg(:,c,ti))~=0
                        plot(find(signif_neg(:,c,ti)),min(smoothmean)-0.02,'k*');
                    end
                    title(['cell #' num2str(c)]);
                    pause()
                    close(fig);
                end
            
            elseif strcmp(method,'sd')
                smoothmean = smoothdata(mean(davc),'movmedian',3);
                baselinevar = std(mean(davc(:,bas),2));
                baselinemean = mean(mean(davc(:,bas)));
                upperlim = baselinemean+baselinevar;
                lowerlim = baselinemean-baselinevar;
                signif_pos(:,c,ti) = smoothmean>upperlim;
                signif_neg(:,c,ti) = smoothmean<lowerlim;
                
                if plotcell
                    fig=figure;hold on;
                    plot(smoothmean);
                    PlotHVLines(baselinemean,'h','r');
                    PlotHVLines(baselinevar,'h','k');
                    PlotHVLines([upperlim;lowerlim],'h','g');
                    if sum(signif_pos(:,c,ti))~=0
                        plot(find(signif_pos(:,c,ti)),max(smoothmean)+0.02,'k*');
                    end
                    if sum(signif_neg(:,c,ti))~=0
                        plot(find(signif_neg(:,c,ti)),min(smoothmean)-0.02,'k*');
                    end
                    PlotIntervals([bas(1) bas(end)]);
                    PlotHVLines(15,'v','k');
                    title(['cell #' num2str(c)]);
                    pause()
                    close(fig);
                end
            end
        end
    end
    
    tonewin = [15;27];
%     rewwin = [45;57];
    rewwin = 40;
%     figure;
%     for ti=1:size(trials_intervals,1)
%         subplot(1,size(trials_intervals,1),ti);hold on;
%         PlotColorMap(signif_pos(:,:,ti)');
%         PlotHVLines(tonewin,'v','w');
%         PlotHVLines(rewwin,'v','c');
%         ylabel('Cell');
%         if ti==1
%             title('Trials 1-40');
%         end
%     end
        
    
    toneresp = logical(squeeze(sum(signif_pos(tonewin(1):tonewin(end),:,:),1)));
    rewresp = logical(squeeze(sum(signif_pos(rewwin(1):end,:,:),1))) & squeeze(any(signif_pos(tonewin(end)+1:rewwin(1)-1,:,:)==0));
        
    figure;hold on;
    plot(sum(toneresp),'bo-');
    plot(sum(rewresp),'go-');    
    plot(sum(toneresp & rewresp),'ro-');
    ylabel('nb of cells');
    xlabel('40-trial bloc');
    legend({'target','reward','target+reward'});
    title([mouse ', TCA comp# ' num2str(r) ', evolution of significance']); 
    
    figure;hold on;
    plot(sum(toneresp)/nThese,'bo-');
    plot(sum(rewresp)/nThese,'go-');    
    plot(sum(toneresp & rewresp)/nThese,'ro-');
    ylabel('proportion of cells');
    xlabel('40-trial bloc');
    legend({'target','reward','target+reward'});
    title([mouse ', TCA comp# ' num2str(r) ', evolution of significance']); 
    
    tresp{m}= toneresp;
    rresp{m} = rewresp;
    drawnow;
    TRACES(m,:) = TRACE(:);
    TRACESFA(m,:) = TRACEFA(:);
    TRACESCR(m,:) = TRACECR(:);
    TRACESM(m,:) = TRACEM(:);
end
%%

figure;
for m=1:nGNG
    subplot(nGNG,1,m);hold on;
    plot(TRACES(m,:),'k','linewidth',2);
    ylim([-0.02 0.1]);
    PlotHVLines(75:75:75*nwinds,'v','color',gray);
    xlim([0 75*nwinds+1]);
end

figure;
for m=1:nGNG
    subplot(nGNG,1,m);hold on;
    plot(TRACES(m,:)-baselines(m,:),'k','linewidth',2);
    ylim([-0.05 0.1]);
    PlotHVLines(75:75:75*nwinds,'v','color',gray);
    xlim([0 75*nwinds+1]);
end

figure;
for m=1:nGNG
    subplot(nGNG,1,m);hold on;
    plot(TRACESM(m,:)-baselinesm(m,:),'k','linewidth',2);
    ylim([-0.05 0.1]);
    PlotHVLines(75:75:75*nwinds,'v','color',gray);
    xlim([0 75*nwinds+1]);
end

figure;hold on;
plot(nanmean(TRACES-baselines),'k','linewidth',2);
plot(nanmean(TRACES-baselines)+nansem(TRACES-baselines),'k');
plot(nanmean(TRACES-baselines)-nansem(TRACES-baselines),'k');
PlotHVLines(75:75:75*nwinds,'v','color',gray);
xlim([0 75*nwinds+1]);
PlotHVLines(0,'h','k');

%%
traces = cell(nGNG,20);
for k=1:nGNG
    data = PROBE_HIT{k};
    for d=1:size(data,1)
        if size(data{d},1)>1
            trac = squeeze(nanmean(data{d}));
        elseif size(data{d},1)==1
            trac = squeeze(data{d});
        else
            continue
        end
        traces{k,d} = trac;
    end
end
traces = traces(:,1:15);

figure;
for d=1:15
    ns = cellfun(@length,traces(:,d),'uniformoutput',false);
    ns = cell2mat(ns);
    wrapper = @(x) mean(x,2);
    mtraces = cellfun(wrapper,traces(logical(ns),d),'uniformoutput',false);
    act = cell2mat(mtraces');
    subplot(1,15,d);hold on;
    plot(mean(act,2),'color',h_color,'linewidth',2);
    sact = sem(act')';
    plot(mean(act,2)+sact,'color','k');
    plot(mean(act,2)-sact,'color','k');
    ylim([-0.02 0.1]);
end

figure;
for d=1:15
    ns = cellfun(@length,traces(3,d),'uniformoutput',false);
    ns = cell2mat(ns);
%     wrapper = @(x) mean(x,2);
%     mtraces = cellfun(wrapper,traces(logical(ns),d),'uniformoutput',false);
%     act = cell2mat(mtraces');
    if ns==0, continue, end
    act = cell2mat(traces(logical(ns),d));
    subplot(1,15,d);hold on;
    plot(act);
    ylim([-0.05 0.5]);
end
%%
nwinds = size(trials_intervals,1);
baseline_intervals = [1 10];
baseline_intervals = repelem(baseline_intervals,nwinds,1);
baseline_intervals = baseline_intervals + repelem((0:nwinds-1)',1,2)*75;
indx_frame = 1:nwinds*75;
baselines = nan(nGNG,nwinds);
for ti=1:size(baseline_intervals,1)
    in = InIntervals(indx_frame,baseline_intervals(ti,:));
    baselines(:,ti) = mean(TRACES(:,in),2);
end
baselines = repelem(baselines,1,75);

figure;hold on;
selected = (1:75)';
nw = nwinds;
for k=1:nw
    subplot(1,nw,k);hold on;
    plot(nanmean(TRACES(:,selected+(k-1)*75)-baselines(:,selected+(k-1)*75)),'color',h_color,'linewidth',2);
    plot(nanmean(TRACES(:,selected+(k-1)*75)-baselines(:,selected+(k-1)*75))+nansem(TRACES(:,selected+(k-1)*75)-baselines(:,selected+(k-1)*75)),'k');
    plot(nanmean(TRACES(:,selected+(k-1)*75)-baselines(:,selected+(k-1)*75))-nansem(TRACES(:,selected+(k-1)*75)-baselines(:,selected+(k-1)*75)),'k');
    xlim([0 75+1]);
    PlotHVLines(0,'h','k');
    ylim([-0.02 0.05]);
end

baselinesfa = nan(nGNG,nwinds);
for ti=1:size(baseline_intervals,1)
    in = InIntervals(indx_frame,baseline_intervals(ti,:));
    baselinesfa(:,ti) = mean(TRACESFA(:,in),2);
end
baselinesfa = repelem(baselinesfa,1,75);
figure;hold on;
selected = (1:75)';
for k=1:nw
    subplot(1,nw,k);hold on;
    plot(nanmean(TRACESFA(:,selected+(k-1)*75)-baselinesfa(:,selected+(k-1)*75)),'color',fa_color,'linewidth',2);
    plot(nanmean(TRACESFA(:,selected+(k-1)*75)-baselinesfa(:,selected+(k-1)*75))+nansem(TRACESFA(:,selected+(k-1)*75)-baselinesfa(:,selected+(k-1)*75)),'k');
    plot(nanmean(TRACESFA(:,selected+(k-1)*75)-baselinesfa(:,selected+(k-1)*75))-nansem(TRACESFA(:,selected+(k-1)*75)-baselinesfa(:,selected+(k-1)*75)),'k');
    xlim([0 75+1]);
    PlotHVLines(0,'h','k');
    ylim([-0.02 0.6]);
end


baselinescr = nan(nGNG,nwinds);
for ti=1:size(baseline_intervals,1)
    in = InIntervals(indx_frame,baseline_intervals(ti,:));
    baselinescr(:,ti) = mean(TRACESCR(:,in),2);
end
baselinescr = repelem(baselinescr,1,75);
figure;hold on;
selected = (1:75)';
for k=1:nw
    subplot(1,nw,k);hold on;
    plot(nanmean(TRACESCR(:,selected+(k-1)*75)-baselinescr(:,selected+(k-1)*75)),'color',cr_color,'linewidth',2);
    plot(nanmean(TRACESCR(:,selected+(k-1)*75)-baselinescr(:,selected+(k-1)*75))+nansem(TRACESCR(:,selected+(k-1)*75)-baselinescr(:,selected+(k-1)*75)),'k');
    plot(nanmean(TRACESCR(:,selected+(k-1)*75)-baselinescr(:,selected+(k-1)*75))-nansem(TRACESCR(:,selected+(k-1)*75)-baselinescr(:,selected+(k-1)*75)),'k');
    xlim([0 75+1]);
    PlotHVLines(0,'h','k');
    ylim([-0.02 0.6]);
end

baselinesm = nan(nGNG,nwinds);
for ti=1:size(baseline_intervals,1)
    in = InIntervals(indx_frame,baseline_intervals(ti,:));
    baselinesm(:,ti) = mean(TRACESM(:,in),2);
end
baselinesm = repelem(baselinesm,1,75);
figure;hold on;
selected = (1:75)';
for k=1:nw
    subplot(1,nw,k);hold on;
    plot(nanmean(TRACESM(:,selected+(k-1)*75)-baselinesm(:,selected+(k-1)*75)),'color',m_color,'linewidth',2);
    plot(nanmean(TRACESM(:,selected+(k-1)*75)-baselinesm(:,selected+(k-1)*75))+nansem(TRACESM(:,selected+(k-1)*75)-baselinesm(:,selected+(k-1)*75)),'k');
    plot(nanmean(TRACESM(:,selected+(k-1)*75)-baselinesm(:,selected+(k-1)*75))-nansem(TRACESM(:,selected+(k-1)*75)-baselinesm(:,selected+(k-1)*75)),'k');
    xlim([0 75+1]);
    PlotHVLines(0,'h','k');
    ylim([-0.02 0.05]);
end
bas_m_trace = baselinesm';
bas_m_trace = bas_m_trace(:);
bas_m_trace = reshape(bas_m_trace,75,nGNG*size(TRACESM,2)/75);

one_m_trace = TRACESM';
one_m_trace = one_m_trace(:);
one_m_trace = reshape(one_m_trace,75,nGNG*size(TRACESM,2)/75);
figure;hold on;
plot(nanmean(one_m_trace-bas_m_trace,2));
plot(nanmean(one_m_trace-bas_m_trace,2)-nansem((one_m_trace-bas_m_trace)')');
plot(nanmean(one_m_trace-bas_m_trace,2)+nansem((one_m_trace-bas_m_trace)')');
ylim([-0.02 0.05]);
PlotHVLines(0,'h','k');

%%
faaresp = cell(nGNG,1);
crrresp = cell(nGNG,1);
gresp = cell(nGNG,1);
ngresp = cell(nGNG,1);
    %%
for m=1:nGNG
    thismouse = GNGs(m);
    mouse = mice{thismouse}; 
        
    % Organize data and build tensor
    results = load([path mouse '-results_nosignals.mat']);
    results = results.results;
    nFrames_oneplane = results{1};
    matrix = results{3};
    ishere = results{4};
    ks = results{5};
    ks2 = results{6};
    ctx = results{7};
    acq = results{8};
    TONEF = results{9};
    REWF = results{10};
    dayss_behav = results{12};
    startfrom = results{13};
    nDays_behav = length(dayss_behav);
    if strcmp(mouse,'cd017')
        nop = matrix(:,BLOC)==4; % remove bad trials
    else
        nop = ~ismember(matrix(:,BLOC),matrix(:,BLOC)); % take everything
    end
    ok = ~nop & ctx(:,1);
    
    cellselection = load([path mouse '-cellselection.mat']);
    cellselection = cellselection.cellselection;
    takenCells = cellselection{1,1};
    findgooddays = cellselection{1,2};
    nKeptCells = sum(takenCells);   
    
    [these,~,whereinintervals] = InIntervals(topNpos,intervalsCells(m,:));
    nThese = sum(these);
    if nThese==0, disp(['no cell for mouse ' mice{thismouse}]); continue; end
    if m>1
        thesecells = topNpos(these)-intervalsCells(m-1,end);
        theseweights = cellfactor(topNpos(these));
    else
        thesecells = topNpos(these);
        theseweights = cellfactor(thesecells);
    end    
    nframes_psth = pretone*round(acq) + posttone*round(acq);       
    tonepsth = load([path mouse '-tonepsth.mat']);
    tonepsth = tonepsth.tonepsth;
    tonepsth_reinf = tonepsth(:,1);
    
    wrapper = @(x) permute(x,[2 1 3]);
    perm_tonepsth = cellfun(wrapper,tonepsth_reinf,'uniformoutput',false);
    avtrace = cell(nDays_behav,1);
    avtrace_hit = cell(nDays_behav,1);
    avtrace_fa = cell(nDays_behav,1);
    avtrace_cr = cell(nDays_behav,1);
    for d=1:nDays_behav
        avtrace{d} = perm_tonepsth{d}(:,:,thesecells);
        okk = matrix(:,DAY)==d+1;        
        avtrace_hit{d} = perm_tonepsth{d}(ks(ok & okk,1),:,thesecells);
        avtrace_fa{d} = perm_tonepsth{d}(ks(ok & okk,3),:,thesecells);
        avtrace_cr{d} = perm_tonepsth{d}(ks(ok & okk,4),:,thesecells);
    end    
    avtrace_fa = cell2mat(avtrace_fa);
    avtrace_cr = cell2mat(avtrace_cr);
%     avtrace_fa_200restric = avtrace_fa(1:maxtrial,:,:);
%     avtrace_cr_200restric = avtrace_cr(1:maxtrial,:,:);
    trialsfa = (1:size(avtrace_fa,1))';
    trialscr = (1:size(avtrace_cr,1))';
    fasignif_pos = nan(75,nThese,size(trials_intervals,1));
    fasignif_neg = nan(75,nThese,size(trials_intervals,1));
    crsignif_pos = nan(75,nThese,size(trials_intervals,1));
    crsignif_neg = nan(75,nThese,size(trials_intervals,1));
    x_real_fa = matrix(ok & ismember(matrix(:,DAY),(1:nDays_behav)+1) & ks(:,3),TRIAL);
    x_real_cr = matrix(ok & ismember(matrix(:,DAY),(1:nDays_behav)+1) & ks(:,4),TRIAL);
    for ti=1:size(trials_intervals,1)
        in = InIntervals(trialsfa,trials_intervals(ti,:));
%         davfa = avtrace_fa_200restric(in,:,:);
%         davcr = avtrace_cr_200restric(in,:,:);
        davfa = avtrace_fa(in,:,:);
        in = InIntervals(trialscr,trials_intervals(ti,:));
        davcr = avtrace_cr(in,:,:);
        
        for c=1:nThese
            davcfa = davfa(:,:,c);
            smoothmean = smoothdata(mean(davcfa),'movmedian',3);
            baselinevar = std(mean(davcfa(:,bas),2));
            baselinemean = mean(mean(davcfa(:,bas)));
            upperlim = baselinemean+baselinevar;
            lowerlim = baselinemean-baselinevar;
            fasignif_pos(:,c,ti) = smoothmean>upperlim;
            fasignif_neg(:,c,ti) = smoothmean<lowerlim;
            
            davccr = davcr(:,:,c);
            smoothmean = smoothdata(mean(davccr),'movmedian',3);
            baselinevar = std(mean(davccr(:,bas),2));
            baselinemean = mean(mean(davccr(:,bas)));
            upperlim = baselinemean+baselinevar;
            lowerlim = baselinemean-baselinevar;
            crsignif_pos(:,c,ti) = smoothmean>upperlim;
            crsignif_neg(:,c,ti) = smoothmean<lowerlim;
                
            if plotcell
                fig=figure;hold on;
                plot(smoothmean);
                PlotHVLines(baselinemean,'h','r');
                PlotHVLines(baselinevar,'h','k');
                PlotHVLines([upperlim;lowerlim],'h','g');
                if sum(crsignif_pos(:,c,ti))~=0
                    plot(find(crsignif_pos(:,c,ti)),max(smoothmean)+0.02,'k*');
                end
                if sum(crsignif_neg(:,c,ti))~=0
                    plot(find(crsignif_neg(:,c,ti)),min(smoothmean)-0.02,'k*');
                end
                PlotIntervals([bas(1) bas(end)]);
                PlotHVLines(15,'v','k');
                title(['cell #' num2str(c)]);
                pause()
                close(fig);
            end
        end
    end
    
    tonewin = [15;27];
    rewwin = 40;      
    
    faresp = logical(squeeze(sum(fasignif_pos(tonewin(1):tonewin(end),:,:),1)));
    crresp = logical(squeeze(sum(crsignif_pos(tonewin(1):tonewin(end),:,:),1)));
    goresp = logical(squeeze(sum(fasignif_pos(rewwin(1):end,:,:),1))) & squeeze(any(fasignif_pos(tonewin(end)+1:rewwin(1)-1,:,:)==0));
    nogoresp = logical(squeeze(sum(crsignif_pos(rewwin(1):end,:,:),1))) & squeeze(any(crsignif_pos(tonewin(end)+1:rewwin(1)-1,:,:)==0));
        
    figure;hold on;
    plot(sum(faresp),'o-','color',fa_color);
    plot(sum(crresp),'o-','color',cr_color);
    plot(sum(goresp),'bo-');    
    plot(sum(nogoresp),'ko-');  
    plot(sum(faresp & goresp),'o-','color','c');
    plot(sum(crresp & nogoresp),'o-','color',gray);
    ylabel('nb of cells');
    xlabel('40-trial bloc');
    legend({'FA','CR','GO','NOGO','FA+GO'});
    title([mouse ', TCA comp# ' num2str(r) ', evolution of significance']); 
    
    figure;hold on;
    plot(sum(faresp)/nThese,'o-','color',fa_color);
    plot(sum(crresp)/nThese,'o-','color',cr_color);
    plot(sum(goresp)/nThese,'bo-');    
    plot(sum(nogoresp)/nThese,'ko-');  
    plot(sum(faresp & goresp)/nThese,'o-','color','c');
    plot(sum(crresp & nogoresp)/nThese,'o-','color',gray);
    ylabel('proportion of cells');
    xlabel('40-trial bloc');
    legend({'FA','CR','GO','NOGO','FA+GO','CR+NOGO'});
    title([mouse ', TCA comp# ' num2str(r) ', evolution of significance']); 
    
    faaresp{m}= faresp;
    crrresp{m} = crresp;
    gresp{m}= goresp;
    ngresp{m} = nogoresp;
    drawnow;
end
    
%% look at correlation between learning weights and performance

pathsave = 'H:\celine\TCA_variables\';
data_GNG = load([pathsave '-TCA_tensor_init_GNG.mat']); % tosave = {mat,nBlocTarget_acqui,nBlocTarget_expert,count_behavior};
mat_GNG = data_GNG.tosave{1};
nblocs_stages = [data_GNG.tosave{2};0;data_GNG.tosave{3}];
nblocs_stages(2) = size(mat_GNG,3)-(nblocs_stages(1)+nblocs_stages(3));

count_behav_GNG = data_GNG.tosave{4};
bloc_size = 20;
fa_color = [255 159 25]/255; % orange
cr_color = [255 207 25]/255; % yellow
m_color = [47 122 182]/255;
h_color = [47 196 182]/255;
colors_outcomes = {h_color,m_color,fa_color,cr_color};

nfoilbloc = squeeze((count_behav_GNG(:,2,:) + count_behav_GNG(:,3,:))); % bloc x mice
ntargetbloc = bloc_size - nfoilbloc; % bloc x mice
fig=figure;hold on;
subplot(2,2,1);hold on;
plot(squeeze(sum(count_behav_GNG(:,1,:),3)) ./ sum(ntargetbloc,2),'-','color',colors_outcomes{1});
plot(squeeze(sum(count_behav_GNG(:,2,:),3)) ./ sum(nfoilbloc,2),'-','color',colors_outcomes{3});
ylim([0 1]);
PlotHVLines(cumsum(nblocs_stages),'v','k:');
ylabel('Action rate');
xlabel('20-trial blocs');

hitrate = squeeze(sum(count_behav_GNG(:,1,:),3)) ./ sum(ntargetbloc,2);
farate = squeeze(sum(count_behav_GNG(:,2,:),3)) ./ sum(nfoilbloc,2);
hitrate(hitrate==0) = 1./(2*ntargetbloc(hitrate==0));
farate(farate==0) = 1./(2*nfoilbloc(farate==0));
hitrate(hitrate==1) = 1*(1-(1./(2*ntargetbloc(hitrate==1))));
farate(farate==1) = 1*(1-(1./(2*nfoilbloc(farate==1))));
dprime = norminv(hitrate) - norminv(farate);
subplot(2,2,2);hold on;
plot(dprime);
ylim([-1 4]);
PlotHVLines(cumsum(nblocs_stages),'v','k:');
ylabel("d'");
xlabel('20-trial blocs');

subplot(2,2,3);hold on;
hitrate = squeeze(sum(count_behav_GNG(:,1,:),3)) ./ sum(ntargetbloc,2);
farate = squeeze(sum(count_behav_GNG(:,2,:),3)) ./ sum(nfoilbloc,2);
accuracy = (hitrate+ (1-farate))/2;
plot(accuracy);
ylim([0.4 1]);
PlotHVLines(cumsum(nblocs_stages),'v','k:');
ylabel('Accuracy');
xlabel('20-trial blocs');

acc = accuracy;
figure;hold on;plot(smoothdata(acc,'movmean',15));
PlotHVLines(cumsum(nblocs_stages),'v','k:');
stages = cumsum(nblocs_stages);
accuracyreinf = smoothdata(accuracyreinf,'movmean',15);
stage1 = 1:stages(1);
stage2 = stages(1)+1:stages(2);
stage3 = stages(2)+1:stages(3);
figure;
ylimm = [0 0.2];xlimm = [0.6 0.9];
ylimm1 = [0 0.2];xlimm1 = [0.55 0.65];
ylimm3 = [0 0.2];xlimm3 = [0.90 0.95];
% smoothF = 2;
for comp=1:5
    subplot(5,3,3*(comp-1)+1);hold on;    
    wlearning = K.U{3}(stage1,comp);
    wlearning = smoothdata(wlearning,'movmean',smoothF);
%     figure;plot(wlearning);
    scatter(accuracyreinf(stage1),wlearning,'k');
    [~,p] = corr(accuracyreinf(stage1),wlearning);
    if p<0.05
        [~,yfit] = LinearRegression(accuracyreinf(stage1),wlearning);
        plot(accuracyreinf(stage1),yfit,'r');
    end
    ylim(ylimm1);xlim(xlimm1);
    subplot(5,3,3*(comp-1)+2);hold on;    
    wlearning = K.U{3}(stage2,comp);
    wlearning = smoothdata(wlearning,'movmean',smoothF);
    scatter(accuracyreinf(stage2),wlearning,'k');
    [~,p] = corr(accuracyreinf(stage2),wlearning);
    if p<0.05
        [~,yfit] = LinearRegression(accuracyreinf(stage2),wlearning);
        plot(accuracyreinf(stage2),yfit,'r');
    end
    ylim(ylimm);xlim(xlimm);
    subplot(5,3,3*(comp-1)+3);hold on;    
    wlearning = K.U{3}(stage3,comp);
    wlearning = smoothdata(wlearning,'movmean',smoothF);
    scatter(accuracyreinf(stage3),wlearning,'k');
    [~,p] = corr(accuracyreinf(stage3),wlearning);
    if p<0.05
        [~,yfit] = LinearRegression(accuracyreinf(stage3),wlearning);
        plot(accuracyreinf(stage3),yfit,'r');
    end
    ylim(ylimm3);xlim(xlimm3);
end

ylimm2 = [0 0.2];xlimm2 = [0.6 0.9];
ylimm1 = [0 0.2];xlimm1 = [0.55 0.65];
ylimm3 = [0 0.2];xlimm3 = [0.90 0.95];
smoothF = 20;
figure;
for comp=1:5
    subplot(3,3,comp);hold on;
    dd = smoothdata(K.U{3}(:,comp),'movmean',smoothF);
    plot(dd);
    f = @(param,xval) param(1) + ( param(2)-param(1) )./ (   1 + 10.^( ( param(3) - xval ) * param(4) )   );
    x = 1:size(dd,1);
    PlotHVLines(cumsum(nblocs_stages),'v','k:');
    y = dd;
    param = sigm_fit(x',y,[],[],0); 
    fitteddd = f(param,x);    
    plot(fitteddd);    
%     fo = fit(x',K.U{3}(:,comp),'poly2');
%     plot(fo,'r');    
    yyaxis right;
    plot(smoothdata(acc,'movmean',20));
end
accuracyreinf = smoothdata(acc,'movmean',smoothF);

% plot repartition group clusterSI according to TCA w
topcells = load([path2savevar 'TCA-top-cell-per-comp.mat']);
topcells = topcells.tosave;
topcells = topcells{1};
topposcells = topcells(:,1);
topnegcells = topcells(:,2);
figure;hold on;
for comp=1:5
    subplot(5,2,1+(comp-1)*2);hold on;
    histogram(idxResized(topposcells{comp}(topposcells{comp}<=nCellPerMouse(5))));
    histogram(idxResized(topposcells{comp}(topposcells{comp}>nCellPerMouse(5))));
    subplot(5,2,2+(comp-1)*2);hold on;
    histogram(idxResized(topnegcells{comp}(topnegcells{comp}<=nCellPerMouse(5))));
    histogram(idxResized(topnegcells{comp}(topnegcells{comp}>nCellPerMouse(5))));
end
figure;hold on;
for clu=1:4    
    thesecells = find(idxResized==clu);    
    propGNG = nan(5,2);
    propPASS = nan(5,2);
    for comp=1:5
        propGNG(comp,1) = nansum(ismember(topposcells{comp},(thesecells(thesecells<=nCellPerMouse(5)))))/...
            nansum(topposcells{comp}<=nCellPerMouse(5))*100;
        propPASS(comp,1) = nansum(ismember(topposcells{comp},(thesecells(thesecells>nCellPerMouse(5)))))/...
            nansum(topposcells{comp}>nCellPerMouse(5))*100;
        propGNG(comp,2) = nansum(ismember(topnegcells{comp},(thesecells(thesecells<=nCellPerMouse(5)))))/...
            nansum(topnegcells{comp}<=nCellPerMouse(5))*100;
        propPASS(comp,2) = nansum(ismember(topnegcells{comp},(thesecells(thesecells>nCellPerMouse(5)))))/...
            nansum(topnegcells{comp}>nCellPerMouse(5))*100;
    end
    subplot(4,2,1+(clu-1)*2);hold on;
    bar([propGNG(:,1) propPASS(:,1)],'grouped');
    subplot(4,2,2+(clu-1)*2);hold on;
    bar([propGNG(:,1) propPASS(:,1)],'grouped');
end

figure;
for comp=1:5
    subplot(5,3,3*(comp-1)+1);hold on;    
    wlearning = K.U{3}(stage1,comp);
    wlearning = smoothdata(wlearning,'movmean',smoothF);
%     figure;plot(wlearning);
    scatter(diff(accuracyreinf(stage1)),diff(wlearning),'k');
    [~,p] = corr(diff(accuracyreinf(stage1)),diff(wlearning));
    if p<0.05
        [~,yfit] = LinearRegression(diff(accuracyreinf(stage1)),diff(wlearning));
        plot(diff(accuracyreinf(stage1)),yfit,'r');
    end
%     ylim(ylimm1);xlim(xlimm1);
    subplot(5,3,3*(comp-1)+2);hold on;    
    wlearning = K.U{3}(stage2,comp);
    wlearning = smoothdata(wlearning,'movmean',smoothF);
    scatter(diff(accuracyreinf(stage2)),diff(wlearning),'k');
    [~,p] = corr(diff(accuracyreinf(stage2)),diff(wlearning));
    if p<0.05
        [~,yfit] = LinearRegression(diff(accuracyreinf(stage2)),diff(wlearning));
        plot(diff(accuracyreinf(stage2)),yfit,'r');
    end
%     ylim(ylimm);xlim(xlimm);
    subplot(5,3,3*(comp-1)+3);hold on;    
    wlearning = K.U{3}(stage3,comp);
    wlearning = smoothdata(wlearning,'movmean',smoothF);
    scatter(diff(accuracyreinf(stage3)),diff(wlearning),'k');
    [~,p] = corr(diff(accuracyreinf(stage3)),diff(wlearning));
    if p<0.05
        [~,yfit] = LinearRegression(diff(accuracyreinf(stage3)),diff(wlearning));
        plot(diff(accuracyreinf(stage3)),yfit,'r');
    end
%     ylim(ylimm3);xlim(xlimm3);
end


