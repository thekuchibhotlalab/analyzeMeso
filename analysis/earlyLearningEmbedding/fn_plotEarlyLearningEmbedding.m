function [figures,files]=fn_plotEarlyLearningEmbedding(r,p)
%FN_PLOTEARLYLEARNINGEMBEDDING Annotate shared UMAP and PCA by stimulus/bin/event.
[~,defaults]=fn_earlyLearningEmbeddingConfig();
if nargin<2||isempty(p), p=struct(); end
assert(isstruct(p)&&isscalar(p)&&isempty(setdiff(fieldnames(p),fieldnames(defaults))), ...
    'earlyEmbedding:PlotConfig','Use a scalar plot config with supported options.');
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
figures=struct(); files=struct(); if ~p.makePlot, return; end
validateattributes(p.pointSize,{'numeric'},{'scalar','positive','finite'});
validateattributes(p.connectBins,{'logical'},{'scalar'});
validateattributes(p.showPCA,{'logical'},{'scalar'});
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'earlyEmbedding:PlotConfig','Use a filename prefix.');
visible='off'; if p.visible, visible='on'; end
fig=figure('Name','Early-learning stimulus/reward UMAP','Color','w','Visible',visible, ...
    'Position',[40 40 1560 500]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
layout=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
Y=r.embedding; T=r.pointInfo; axesList=gobjects(3,1);
stimuli=unique(T.stimulus,'stable'); periods=unique(T.responsePeriod,'stable');
for panel=1:3
    ax=nexttile(layout); axesList(panel)=ax; hold(ax,'on');
    if p.connectBins
        for s=stimuli'
            for e=periods'
                rows=find(T.stimulus==s&T.responsePeriod==e);
                [~,order]=sort(T.learningBin(rows)); rows=rows(order);
                plot(ax,Y(rows,1),Y(rows,2),'-','Color',[0.75 0.75 0.75],'HandleVisibility','off');
                plot(ax,Y(rows(1),1),Y(rows(1),2),'ko','MarkerSize',8,'HandleVisibility','off');
            end
        end
    end
    if panel==2
        scatter(ax,Y(:,1),Y(:,2),p.pointSize,T.learningBin,'filled');
        colormap(ax,parula(256)); caxis(ax,[1 r.cfg.nBins]);
        cb=colorbar(ax); cb.Label.String='Learning chunk (early to late)';
        title(ax,'Colored by learning chunk');
    else
        if panel==1, labels="S"+T.stimulus; caption='Colored by stimulus';
        else, labels=T.responsePeriod; caption='Colored by response period'; end
        levels=unique(labels,'stable'); colors=lines(numel(levels)); handles=gobjects(numel(levels),1);
        for k=1:numel(levels)
            rows=labels==levels(k);
            handles(k)=scatter(ax,Y(rows,1),Y(rows,2),p.pointSize,colors(k,:),'filled');
        end
        legend(ax,handles,cellstr(levels),'Location','best'); title(ax,caption);
    end
    xlabel(ax,'UMAP 1'); ylabel(ax,'UMAP 2'); axis(ax,'equal'); box(ax,'on');
end
linkaxes(axesList,'xy');
caption=sprintf('%d chunks per stimulus; %.0f%% target overlap',r.cfg.nBins,100*r.cfg.overlap);
if p.connectBins, caption=[caption '; circles mark first chunks']; end
title(layout,{sprintf('One UMAP | %d chunk means | %d pooled neurons | %d animals', ...
    height(T),height(r.neurons),sum(r.animalAudit.included)), ...
    caption});
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    file=fullfile(p.savePath,[prefix '_umap.png']);
    exportgraphics(fig,file,'Resolution',150); files.umap=file;
end
if p.visible, figures.umap=fig; else, figures.umap=[]; end
if p.showPCA && isfield(r,'pca')
    [figures.pca,file]=plotPCA(r,p,visible,prefix);
    if ~isempty(file), files.pca=file; end
end
end

function [handle,file]=plotPCA(r,p,visible,prefix)
fig=figure('Name','Early-learning stimulus/reward PCA','Color','w','Visible',visible, ...
    'Position',[40 60 1560 500]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
layout=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
Y=r.pca.scores; T=r.pointInfo; pairs=[1 2;1 3;2 3];
stimuli=unique(T.stimulus,'stable'); periods=unique(T.responsePeriod,'stable');
colors=lines(numel(stimuli)); markers={'o','s','^','d','v'};
for panel=1:3
    ax=nexttile(layout); hold(ax,'on'); dims=pairs(panel,:);
    if max(dims)>size(Y,2)
        text(ax,0.5,0.5,'Too few dimensions for this PC pair','HorizontalAlignment','center');
        axis(ax,'off'); continue;
    end
    for s=1:numel(stimuli)
        for e=1:numel(periods)
            rows=find(T.stimulus==stimuli(s)&T.responsePeriod==periods(e));
            [~,order]=sort(T.learningBin(rows)); rows=rows(order);
            if p.connectBins
                plot(ax,Y(rows,dims(1)),Y(rows,dims(2)),'-', ...
                    'Color',colors(s,:),'HandleVisibility','off');
            end
            scatter(ax,Y(rows,dims(1)),Y(rows,dims(2)),p.pointSize, ...
                colors(s,:),markers{1+mod(e-1,numel(markers))},'filled', ...
                'DisplayName',sprintf('S%g %s',stimuli(s),periods(e)));
            % Label endpoints to show direction through learning without changing coordinates.
            for q=unique([1 numel(rows)])
                text(ax,Y(rows(q),dims(1)),Y(rows(q),dims(2)), ...
                    sprintf('  %d',T.learningBin(rows(q))),'FontSize',8, ...
                    'HandleVisibility','off');
            end
        end
    end
    xlabel(ax,sprintf('PC%d (%.1f%%)',dims(1),r.pca.explained(dims(1))));
    ylabel(ax,sprintf('PC%d (%.1f%%)',dims(2),r.pca.explained(dims(2))));
    title(ax,sprintf('PC%d vs PC%d',dims)); axis(ax,'equal'); box(ax,'on');
    if panel==1, legend(ax,'Location','best'); end
end
title(layout,{'PCA of the same pooled-neuron chunk means', ...
    'Color = stimulus; marker = response period; numbers = first/last learning chunk'});
file='';
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    file=fullfile(p.savePath,[prefix '_pca.png']); exportgraphics(fig,file,'Resolution',150);
end
if p.visible, handle=fig; else, handle=[]; end
end
