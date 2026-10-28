function [figures,files]=fn_plotTaskStimGeometry(r,p)
%FN_PLOTTASKSTIMGEOMETRY All three pairs of LDA scores and decision boundaries.
[~,defaults]=fn_taskStimGeometryConfig();
if nargin<2, p=struct(); end
assert(isstruct(p)&&isscalar(p)&&isempty(setdiff(fieldnames(p),fieldnames(defaults))), ...
    'taskStim:PlotConfig','Use supported plot options from fn_taskStimGeometryConfig.');
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
for field={'makePlot','visible'}, validateattributes(p.(field{1}),{'logical'},{'scalar'}); end
validateattributes(p.pointSize,{'numeric'},{'scalar','positive','finite'});
figures=struct(); files=struct(); if ~p.makePlot, return; end
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'taskStim:PlotConfig','Use a filename prefix.');
visible='off'; if p.visible, visible='on'; end
fig=figure('Name','Task/stimulus LDA geometry','Color','w','Visible',visible, ...
    'Position',[50 50 1600 530]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
layout=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
pairs=[1 2;1 3;2 3]; labels=string(r.conditions.stimulus);
levels=unique(labels,'stable'); colors=lines(numel(levels));
for panel=1:3
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
    xline(ax,r.thresholds(pair(1)),'k--','LineWidth',1.2,'HandleVisibility','off');
    yline(ax,r.thresholds(pair(2)),'k--','LineWidth',1.2,'HandleVisibility','off');
    xlabel(ax,axisLabel(r,pair(1))); ylabel(ax,axisLabel(r,pair(2)));
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
end
if p.visible, figures.projections=fig; else, figures.projections=[]; end
end

function label=axisLabel(r,k)
label=sprintf('%s score (%s < boundary < %s)',r.axisInfo.comparison(k), ...
    r.axisInfo.negativeClass(k),r.axisInfo.positiveClass(k));
end
