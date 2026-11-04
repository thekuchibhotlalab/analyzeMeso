function [figures,files]=fn_plotTaskStimGeometry(r,p)
%FN_PLOTTASKSTIMGEOMETRY Pairwise LDA scores, one row per comparison triplet.
[~,defaults]=fn_taskStimGeometryConfig();
if nargin<2, p=struct(); end
assert(isstruct(p)&&isscalar(p)&&isempty(setdiff(fieldnames(p),fieldnames(defaults))), ...
    'taskStim:PlotConfig','Use supported plot options from fn_taskStimGeometryConfig.');
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
for field={'makePlot','visible'}, validateattributes(p.(field{1}),{'logical'},{'scalar'}); end
validateattributes(p.pointSize,{'numeric'},{'scalar','positive','finite'});
nf=size(r.weights,2);
validateattributes(p.axisColors,{'numeric'},{'2d','ncols',3,'nonempty','real','finite','>=',0,'<=',1});
% Older plot configs may provide only the original three colors.
if size(p.axisColors,1)<nf
    p.axisColors(end+1:nf,:)=defaults.axisColors(size(p.axisColors,1)+1:nf,:);
end
figures=struct(); files=struct(); if ~p.makePlot, return; end
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'taskStim:PlotConfig','Use a filename prefix.');
visible='off'; if p.visible, visible='on'; end
fig=figure('Name','Task/stimulus LDA geometry','Color','w','Visible',visible, ...
    'Position',[50 50 1600 80+450*(nf/3)]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
layout=tiledlayout(fig,nf/3,3,'TileSpacing','compact','Padding','compact');
pairs=[1 2;1 3;2 3];
if nf==6, pairs=[pairs;pairs+3]; end
labels=string(r.conditions.stimulus);
levels=unique(labels,'stable'); colors=lines(numel(levels));
for panel=1:size(pairs,1)
    ax=nexttile(layout); hold(ax,'on'); pair=pairs(panel,:);
    if ~all(r.axisInfo.valid(pair))
        text(ax,0.5,0.5,'No mean separation for at least one axis','HorizontalAlignment','center');
        axis(ax,'off'); continue;
    end
    handles=gobjects(numel(levels),1);
    for s=1:numel(levels)
        ids=find(labels==levels(s)); scores=vertcat(r.projection.scores{ids});
        handles(s)=scatter(ax,scores(:,pair(1)),scores(:,pair(2)),p.pointSize, ...
            colors(s,:),'filled','MarkerFaceAlpha',0.45,'MarkerEdgeAlpha',0.45);
    end
    xline(ax,r.thresholds(pair(1)),'--','Color',p.axisColors(pair(1),:),'LineWidth',1.2,'HandleVisibility','off');
    yline(ax,r.thresholds(pair(2)),'--','Color',p.axisColors(pair(2),:),'LineWidth',1.2,'HandleVisibility','off');
    xlabel(ax,axisLabel(r,pair(1)),'Color',p.axisColors(pair(1),:),'Interpreter','none');
    ylabel(ax,axisLabel(r,pair(2)),'Color',p.axisColors(pair(2),:),'Interpreter','none');
    ax.XColor=p.axisColors(pair(1),:); ax.YColor=p.axisColors(pair(2),:);
    title(ax,sprintf('%s vs %s',r.cfg.comparisons(pair(1)),r.cfg.comparisons(pair(2))),'Interpreter','none');
    axis(ax,'equal'); box(ax,'on'); grid(ax,'on');
    if panel==1, legend(ax,handles,cellstr(levels),'Location','best','Interpreter','none'); end
end
if r.projection.isPseudoPopulation, points='Independent pseudo-trials'; else, points='Actual trials'; end
title(layout,{sprintf('%s responses | %d pooled neurons | %d animals', ...
    r.cfg.period,height(r.neurons),sum(r.animalAudit.included)), ...
    [points '; dashed lines = equal-prior LDA decision thresholds (in-sample)']});
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    file=fullfile(p.savePath,[prefix '_' r.cfg.period '.png']);
    exportgraphics(fig,file,'Resolution',150); files.projections=file;
    savefig(fig,[file(1:end-4) '.fig']);
end
if p.visible, figures.projections=fig; else, figures.projections=[]; end
[figures.similarity,file]=plotSimilarity(r,p,visible,prefix);
if ~isempty(file), files.similarity=file; end
end

function [handle,file]=plotSimilarity(r,p,visible,prefix)
nf=size(r.weights,2); side=580+50*(nf-3);
fig=figure('Name','Task/stimulus axis similarity','Color','w','Visible',visible, ...
    'Position',[80 80 side+70 side]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
ax=axes(fig); C=r.weights'*r.weights;
C(C>1)=1; C(C< -1)=-1; angles=acosd(C);
imagesc(ax,C,'AlphaData',isfinite(C)); ax.Color=[0.8 0.8 0.8];
caxis(ax,[-1 1]);
palette=interp1([-1 0 1],[0.15 0.3 0.8;1 1 1;0.8 0.15 0.15],linspace(-1,1,257));
colormap(ax,palette); cb=colorbar(ax); cb.Label.String='Cosine similarity';
axis(ax,'image'); ax.XTick=1:nf; ax.YTick=1:nf; ax.TickLabelInterpreter='tex';
labels=cell(nf,1);
for k=1:nf
    name=char(r.cfg.comparisons(k)); name=strrep(name,'\','\\');
    name=strrep(name,'_','\_'); name=strrep(name,'{','\{'); name=strrep(name,'}','\}');
    labels{k}=sprintf('\\color[rgb]{%.3f,%.3f,%.3f}%s',p.axisColors(k,:),name);
end
ax.XTickLabel=labels; ax.YTickLabel=labels;
for row=1:nf
    for col=1:nf
        if isfinite(C(row,col))
            label=sprintf('%.2f\n%.1f%s',C(row,col),angles(row,col),char(176));
            color='k'; if abs(C(row,col))>0.65, color='w'; end
        else, label='Undefined'; color='k'; end
        text(ax,col,row,label,'HorizontalAlignment','center','Color',color,'FontSize',12);
    end
end
title(ax,{'Neural-weight cosine similarity and angle', ...
    '0 = 90 degrees; +1 = parallel; -1 = opposite'});
file='';
if ~isempty(p.savePath)
    file=fullfile(p.savePath,[prefix '_' r.cfg.period '_similarity.png']);
    exportgraphics(fig,file,'Resolution',150);
    savefig(fig,[file(1:end-4) '.fig']);
end
if p.visible, handle=fig; else, handle=[]; end
end

function label=axisLabel(r,k)
label=sprintf('%s score (%s < boundary < %s)',r.axisInfo.comparison(k), ...
    r.axisInfo.negativeClass(k),r.axisInfo.positiveClass(k));
end
