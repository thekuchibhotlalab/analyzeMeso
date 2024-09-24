%% PLOT single mouse behavior
mouse = 'zz142'; datapath = ['G:\ziyi\mesoData\' mouse '_behavior\matlab\'];
[summaryStatT1,summaryStatT2] = fn_plotMesoBehavIndvidual(mouse,datapath,true);

%% SUMMARY STAT mouse behavior

mouseList = {'zz137','zz142','zz151','zz153','zz155','zz159'};

datapath = cellfun(@(x)(['G:\ziyi\mesoData\' x '_behavior\matlab\']),mouseList,'UniformOutput',false) ;

[summaryStatT1,summaryStatT2,summaryStatT1Inter,summaryStatT2Inter] = cellfun(@(x,y)(fn_plotMesoBehavIndvidual(x,y)),mouseList,datapath,'UniformOutput',false);

%% get summary data
accT1 = fn_cell2matFillNan(cellfun(@(x)(x.acc),summaryStatT1,'UniformOutput',false));
accT2 = fn_cell2matFillNan(cellfun(@(x)(x.acc),summaryStatT2,'UniformOutput',false));
biasT1 = fn_cell2matFillNan(cellfun(@(x)(abs(x.bias)),summaryStatT1,'UniformOutput',false));
biasT2 = fn_cell2matFillNan(cellfun(@(x)(abs(x.bias)),summaryStatT2,'UniformOutput',false));

accT1_inter = fn_cell2matFillNan(cellfun(@(x)(x.acc),summaryStatT1Inter,'UniformOutput',false));
accT2_inter = fn_cell2matFillNan(cellfun(@(x)(x.acc),summaryStatT2Inter,'UniformOutput',false));

%% plot learning curve
figure;  subplot(1,2,1); hold on;
plot([1 size(accT1,1)],[0.5 0.5],'Color',[0.8 0.8 0.8],'LineWidth',2)
[f_mean, f_sample] = fn_plotMeanSampleLine(1:size(accT1,1),accT1', {'LineWidth',3,'Color',matlabColors(2)},...
    {'LineWidth',1,'Color',[0.8 0.8 0.8]});
xlim([0 7000])

subplot(1,2,2); hold on;
plot([1 size(accT2,1)],[0.5 0.5],'Color',[0.8 0.8 0.8],'LineWidth',2)
[f_mean, f_sample] = fn_plotMeanSampleLine(1:size(accT2,1),accT2', {'LineWidth',3,'Color',matlabColors(3)},...
    {'LineWidth',1,'Color',[0.8 0.8 0.8]});
xlim([0 3000])


%% plot learning curve
figure;  subplot(1,2,1); hold on;
[f_mean, f_sample] = fn_plotMeanSampleLine(1:size(biasT1,1),biasT1', {'LineWidth',3,'Color',matlabColors(2)},...
    {'LineWidth',1,'Color',[0.8 0.8 0.8]});
xlim([0 7000])

subplot(1,2,2); hold on;
[f_mean, f_sample] = fn_plotMeanSampleLine(1:size(biasT2,1),biasT2', {'LineWidth',3,'Color',matlabColors(3)},...
    {'LineWidth',1,'Color',[0.8 0.8 0.8]});
xlim([0 3000])

%% plot
plotPrePost('T1',summaryStatT1,summaryStatT2);

plotPrePost('T1T2',summaryStatT1,summaryStatT2);

plotPrePost('T2',summaryStatT1,summaryStatT2);

plotPrePost('Inter',summaryStatT1,summaryStatT1Inter);

plotPrePost('Inter',summaryStatT2,summaryStatT2Inter);
%% functions 

function plotPrePost(keyword,summaryStatT1,summaryStatT2)
    switch keyword
        case 'T1'
            c1 = summaryStatT1; c2 = summaryStatT1;
            s1 = 'Pre'; s2 = 'Post';
        case 'T1T2'
            c1 = summaryStatT1; c2 = summaryStatT2;
            s1 = 'Post'; s2 = 'Pre';
        case 'T2'
            c1 = summaryStatT2; c2 = summaryStatT2;
            s1 = 'Pre'; s2 = 'Post';
        case 'Inter'
            c1 = summaryStatT1; c2 = summaryStatT2;% put 'inter' as T2, 'T1 or T2' as T1
            s1 = 'Post'; s2 = '';
    end 
% plot
figure; subplot(1,4,1);
[p] = fn_plotComparison({cellfun(@(x)(x.(['acc' s1])),c1,'UniformOutput',true),cellfun(@(x)(x.(['acc' s2])),c2...
    ,'UniformOutput',true)},'paired',true,'dotType','side','compType','errorbarWithDot','scatterArgIn',...
    {5,'MarkerEdgeColor','none','MarkerFaceColor','none'},'errorbarArgIn', {'Color',[0.2 0.2 0.2],...
    'LineWidth',1.5,'LineStyle','none'}); 
xticks([1 2]); xticklabels({'pre-learning', 'post-learning'}); xtickangle(60); ylabel('accuracy')
subplot(1,4,2);
[p] = fn_plotComparison({cellfun(@(x)(x.(['bias' s1])),c1,'UniformOutput',true),cellfun(@(x)(x.(['bias' s2])),c2...
    ,'UniformOutput',true)},'paired',true,'dotType','side','compType','errorbarWithDot','scatterArgIn',...
    {5,'MarkerEdgeColor','none','MarkerFaceColor','none'},'errorbarArgIn', {'Color',[0.2 0.2 0.2],...
    'LineWidth',1.5,'LineStyle','none'}); 
xticks([1 2]); xticklabels({'pre-learning', 'post-learning'}); xtickangle(60); ylabel('bias magnitude')

subplot(1,4,3);
[p] = fn_plotComparison({cellfun(@(x)(x.(['ar' s1])),c1,'UniformOutput',true),cellfun(@(x)(x.(['ar' s2])),c2...
    ,'UniformOutput',true)},'paired',true,'dotType','side','compType','errorbarWithDot','scatterArgIn',...
    {5,'MarkerEdgeColor','none','MarkerFaceColor','none'},'errorbarArgIn', {'Color',[0.2 0.2 0.2],...
    'LineWidth',1.5,'LineStyle','none'}); 
xticks([1 2]); xticklabels({'pre-learning', 'post-learning'}); xtickangle(60); ylabel('action rate')

subplot(1,4,4);
[p] = fn_plotComparison({cellfun(@(x)(x.(['rt' s1])),c1,'UniformOutput',true),cellfun(@(x)(x.(['rt' s2])),c2...
    ,'UniformOutput',true)},'paired',true,'dotType','side','compType','errorbarWithDot','scatterArgIn',...
    {5,'MarkerEdgeColor','none','MarkerFaceColor','none'},'errorbarArgIn', {'Color',[0.2 0.2 0.2],...
    'LineWidth',1.5,'LineStyle','none'}); 
xticks([1 2]); xticklabels({'pre-learning', 'post-learning'}); xtickangle(60); ylabel('response time (s)')



end 