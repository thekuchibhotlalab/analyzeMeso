function [figures,files] = fn_plotNeuralEmbedding(r,p)
%FN_PLOTNEURALEMBEDDING Recolor ONE saved embedding by labels and trial time.
[~,defaults]=fn_neuralEmbeddingConfig();
if nargin<2||isempty(p), p=struct(); end
assert(isstruct(p)&&isscalar(p),'neuralEmbedding:PlotConfig','Use a scalar plot config.');
extra=setdiff(fieldnames(p),fieldnames(defaults));
assert(isempty(extra),'neuralEmbedding:PlotConfig','Unknown plot options: %s.',strjoin(extra,', '));
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
figures=struct(); files=struct(); if ~p.makePlot, return; end
validateattributes(p.pointSize,{'numeric'},{'scalar','positive','finite'});
validateattributes(p.showTime,{'logical','numeric'},{'scalar','binary'});
variables=string(p.colorBy(:));
if isempty(variables), variables=["conditionName";r.variables(:)]; end
assert(numel(unique(variables))==numel(variables)&&all(ismember(variables,string(r.conditions.Properties.VariableNames))), ...
    'neuralEmbedding:PlotConfig','colorBy must name unique condition-table columns.');
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'neuralEmbedding:PlotConfig','prefix must be a filename prefix.');
visible='off'; if p.visible, visible='on'; end
nPanels=numel(variables)+double(p.showTime);
cols=min(3,nPanels); if nPanels==4, cols=2; end
rows=ceil(nPanels/cols);
fig=figure('Name','Trial-averaged neural UMAP','Color','w','Visible',visible, ...
    'Position',[40 40 550*cols 480*rows]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
layout=tiledlayout(fig,rows,cols,'TileSpacing','compact','Padding','compact');
Y=r.embedding; axs=gobjects(nPanels,1);
for v=1:numel(variables)
    ax=nexttile(layout); axs(v)=ax; hold(ax,'on');
    labels=string(r.pointLabels.(variables(v))); levels=unique(labels,'stable');
    palette=lines(numel(levels)); handles=gobjects(numel(levels),1);
    if p.connectTime
        for c=1:height(r.conditions)
            ids=find(r.pointInfo.conditionIndex==c);
            [~,order]=sort(r.pointInfo.timeIndex(ids)); ids=ids(order);
            group=find(levels==labels(ids(1)));
            plot(ax,Y(ids,1),Y(ids,2),'-','Color',0.55+0.45*palette(group,:), ...
                'HandleVisibility','off');
        end
    end
    for l=1:numel(levels)
        keep=labels==levels(l);
        handles(l)=scatter(ax,Y(keep,1),Y(keep,2),p.pointSize,palette(l,:),'filled');
    end
    xlabel(ax,'UMAP 1'); ylabel(ax,'UMAP 2'); axis(ax,'equal'); box(ax,'on');
    title(ax,"Colored by "+variables(v),'Interpreter','none');
    legend(ax,handles,cellstr(levels),'Interpreter','none','Location','bestoutside');
end
if p.showTime
    ax=nexttile(layout); axs(end)=ax;
    pointTime=r.pointInfo.time;
    scatter(ax,Y(:,1),Y(:,2),p.pointSize,pointTime,'filled','Tag','timeProgression');
    limits=[min(pointTime) max(pointTime)];
    if limits(1)==limits(2), limits=limits+[-0.5 0.5]; end
    clim(ax,limits); colormap(ax,parula(256));
    cb=colorbar(ax); cb.Label.String='Time within trial (s)';
    xlabel(ax,'UMAP 1'); ylabel(ax,'UMAP 2'); axis(ax,'equal'); box(ax,'on');
    title(ax,'Colored by time (all conditions)');
end
linkaxes(axs,'xy');
title(layout,'One unsupervised 2D embedding; each point = one condition x time-bin trial mean');
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    file=fullfile(p.savePath,[prefix '_umap.png']);
    exportgraphics(fig,file,'Resolution',150); files.umap=file;
    savefig(fig,[file(1:end-4) '.fig']);
end
if p.visible, figures.umap=fig; else, figures.umap=[]; end
end
