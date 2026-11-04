function [figures,files] = fn_plotStimRewardAlignment(result,p)
%FN_PLOTSTIMREWARDALIGNMENT Replot reduced responses without neural time series.
[~,defaults]=fn_stimRewardAlignmentConfig();
if nargin<2, p=struct(); end
assert(isstruct(p)&&isscalar(p),'stimReward:PlotConfig','Use a scalar plot config.');
assert(isempty(setdiff(fieldnames(p),fieldnames(defaults))),'stimReward:PlotConfig','Unknown plotting option.');
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
figures=struct(); files=struct(); if ~p.makePlot, return; end
validateattributes(p.maxScatterPanels,{'numeric'},{'scalar','integer','positive','finite'});
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'stimReward:PlotConfig','Use a filename prefix.');
visibility='off'; if p.visible, visibility='on'; end
[ns,na]=size(result.byStimulus);
for a=1:na
    for s=1:ns
        B=result.byStimulus(s,a); nb=height(B.bins);
        % Use identical axis limits across all scatter bins for this animal/S.
        limits=[axisRange(B.stimulusMean),axisRange(B.rewardMean)];
        for page=1:ceil(nb/p.maxScatterPanels)
            bins=(page-1)*p.maxScatterPanels+1:min(page*p.maxScatterPanels,nb);
            ncol=min(4,numel(bins)); nrow=ceil(numel(bins)/ncol);
            fig=figure('Name',B.animalLabel+": S"+B.stimulus+" stimulus/reward", ...
                'Color','w','Visible',visibility,'Position',[40 40 360*ncol 290*nrow]);
            layout=tiledlayout(fig,nrow,ncol,'TileSpacing','compact','Padding','compact');
            title(layout,sprintf('%s | S%g rewarded | each point = one neuron (n=%d)', ...
                B.animalLabel,B.stimulus,numel(B.neuronRows)),'Interpreter','none');
            for b=bins
                ax=nexttile(layout);
                scatter(ax,B.stimulusMean(:,b),B.rewardMean(:,b),12,'filled');
                xlim(ax,limits(1:2)); ylim(ax,limits(3:4)); grid(ax,'on');
                xlabel(ax,'Stimulus response'); ylabel(ax,'Reward-period response');
                title(ax,sprintf('Trials %d-%d (valid %d) | r = %.2f', ...
                    B.bins.firstTrial(b),B.bins.lastTrial(b),B.bins.nValidTrials(b),B.withinBinCorrelation(b)));
            end
            finish(fig,sprintf('animal%d_S%g_scatter%d',a,B.stimulus,page));
        end
    end
    fig=figure('Name',result.cfg.animalLabels(a)+": alignment over learning", ...
        'Color','w','Visible',visibility,'Position',[40 40 max(650,450*ns) 720]);
    layout=tiledlayout(fig,2,ns,'TileSpacing','compact','Padding','compact');
    title(layout,{char(result.cfg.animalLabels(a))+" | correlations across neurons", ...
        'Rewarded trials; phases concatenated; each stimulus has its own trial sequence'},'Interpreter','none');
    for s=1:ns
        B=result.byStimulus(s,a); nb=height(B.bins);
        ax=nexttile(layout,s);
        if nb==0
            axis(ax,'off'); text(ax,0.5,0.5,"S"+B.stimulus+": "+B.status,'HorizontalAlignment','center');
        else
            C=B.crossBinCorrelation;
            imagesc(ax,1:nb,1:nb,C,'AlphaData',isfinite(C));
            set(ax,'Color',[0.85 0.85 0.85]); caxis(ax,[-1 1]);
            colors=[linspace(0,1,129)' linspace(0,1,129)' ones(129,1); ...
                ones(128,1) linspace(1-1/128,0,128)' linspace(1-1/128,0,128)'];
            colormap(ax,colors); colorbar(ax); axis(ax,'square');
            xlabel(ax,'Reward-response trial bin'); ylabel(ax,'Stimulus-response trial bin');
            title(ax,sprintf('S%g: r(stimulus bin i, reward bin j)',B.stimulus));
            if nb<=12, xticks(ax,1:nb); yticks(ax,1:nb); end
        end
        ax=nexttile(layout,ns+s); hold(ax,'on');
        if nb>0
            midpoint=(B.bins.firstTrial+B.bins.lastTrial)/2;
            plot(ax,midpoint,B.withinBinCorrelation,'o-','LineWidth',1.5);
            % Phase boundaries are in this stimulus's rewarded-trial ordinals.
            phases=string(B.trials.dayLabel);
            starts=find([true;phases(2:end)~=phases(1:end-1)]);
            for k=2:numel(starts)
                if starts(k)<=B.bins.lastTrial(end)
                    xline(ax,starts(k)-0.5,':',phases(starts(k)),'HandleVisibility','off');
                end
            end
            xlim(ax,[0.5 max(1.5,B.bins.lastTrial(end)+0.5)]);
        end
        ylim(ax,[-1 1]); yline(ax,0,':','HandleVisibility','off'); grid(ax,'on');
        xlabel(ax,'Rewarded trial ordinal (bin midpoint)'); ylabel(ax,'Within-bin Pearson r');
        title(ax,"S"+B.stimulus+": stimulus/reward alignment");
    end
    finish(fig,sprintf('animal%d_correlations',a));
end
if p.showPooledEarlyTrials&&isfield(result,'pooledEarlyTrials')
    P=result.pooledEarlyTrials;
    assert(isfield(P,'byStimulus'),'stimReward:Recompute', ...
        'Rerun fn_analyzeStimRewardAlignment to compute separate pooled stimulus correlations.');
    palette=lines(numel(result.cfg.stimuli));
    for s=1:numel(P.byStimulus)
        G=P.byStimulus(s); nt=numel(G.binIndices); rows=G.pointRows;
        ncol=min(5,max(1,nt)); nrow=ceil(max(1,nt)/ncol);
        fig=figure('Name',sprintf('Pooled S%g stimulus/reward trials',G.stimulus), ...
            'Color','w','Visible',visibility,'Position',[40 40 320*ncol 280*nrow]);
        layout=tiledlayout(fig,nrow,ncol,'TileSpacing','compact','Padding','compact');
        title(layout,{sprintf('S%g | all contributing animals | %s',G.stimulus,result.cfg.normalization), ...
            'Each point = one neuron averaged within the labeled rewarded-trial bin'});
        limits=[axisRange(P.stimulusActivity(rows,G.binIndices)), ...
            axisRange(P.rewardActivity(rows,G.binIndices))];
        if nt==0
            ax=nexttile(layout); axis(ax,'off');
            text(ax,0.5,0.5,'No valid rewarded-trial responses; 0 animals', ...
                'HorizontalAlignment','center','Units','normalized');
        end
        for j=1:nt
            b=G.binIndices(j); ax=nexttile(layout);
            good=isfinite(P.stimulusActivity(rows,b))&isfinite(P.rewardActivity(rows,b));
            select=rows(good);
            scatter(ax,P.stimulusActivity(select,b),P.rewardActivity(select,b), ...
                8,palette(s,:),'filled','MarkerFaceAlpha',0.35);
            xlim(ax,limits(1:2)); ylim(ax,limits(3:4)); grid(ax,'on');
            xlabel(ax,'Stimulus response'); ylabel(ax,'Reward-period response');
            title(ax,{sprintf('Trials %d-%d | r = %.2f',G.bins.firstTrial(j),G.bins.lastTrial(j),G.correlation(j)), ...
                sprintf('%d animals remaining; %d neurons',G.nAnimals(j),G.nPoints(j))});
        end
        finish(fig,sprintf('pooledEarlyTrials_S%g',G.stimulus));
    end
end
    function finish(fig,key)
        if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
        if ~isempty(p.savePath)
            if ~isfolder(p.savePath), mkdir(p.savePath); end
            file=fullfile(p.savePath,[prefix '_' key '.png']);
            exportgraphics(fig,file,'Resolution',150); files.(key)=file;
            savefig(fig,[file(1:end-4) '.fig']);
        end
        if p.visible, figures.(key)=fig; else, figures.(key)=[]; end
    end
end

function limits=axisRange(x)
x=x(isfinite(x)); limits=[-1 1];
if isempty(x), return; end
limits=[min(x) max(x)]; pad=0.05*diff(limits);
if pad==0, pad=max(0.01,abs(limits(1))*0.05); end
limits=limits+[-pad pad];
end
