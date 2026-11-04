function [figures,files]=fn_plotLearningProgressionEmbedding(r,p)
%FN_PLOTLEARNINGPROGRESSIONEMBEDDING Recolor a shared embedding and show PCA pairs.
[~,d]=fn_learningProgressionEmbeddingConfig(); if nargin<2||isempty(p), p=struct(); end
assert(isstruct(p)&&isscalar(p)&&isempty(setdiff(fieldnames(p),fieldnames(d))), ...
    'learningEmbedding:PlotConfig','Use options from fn_learningProgressionEmbeddingConfig.');
for f=fieldnames(d)', if ~isfield(p,f{1}), p.(f{1})=d.(f{1}); end; end
for f={'makePlot','visible','connectBins','showPCA'}, validateattributes(p.(f{1}),{'logical'},{'scalar'}); end
validateattributes(p.pointSize,{'numeric'},{'scalar','positive','finite'});
p.colorBy=string(p.colorBy(:));
assert(~isempty(p.colorBy)&&all(ismember(p.colorBy,string(r.pointInfo.Properties.VariableNames))), ...
    'learningEmbedding:PlotConfig','colorBy must name pointInfo columns.');
prefix=char(p.prefix); assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'learningEmbedding:PlotConfig','Use a filename prefix.');
figures=struct(); files=struct(); if ~p.makePlot, return; end
if ~isempty(p.savePath)&&~isfolder(p.savePath), mkdir(p.savePath); end
if ~isempty(r.embedding)
    [figures.umap,file]=draw(r,p,'umap'); if ~isempty(file), files.umap=file; end
end
if p.showPCA
    [figures.pca,file]=draw(r,p,'pca'); if ~isempty(file), files.pca=file; end
end
end

function [handle,file]=draw(r,p,mode)
visible='off'; if p.visible, visible='on'; end
isPCA=strcmp(mode,'pca'); T=r.pointInfo;
if isPCA, panels=3; Y=r.pca.scores; else, panels=numel(p.colorBy); Y=r.embedding; end
fig=figure('Name',['Learning progression ' upper(mode)],'Color','w','Visible',visible, ...
    'Position',[40 40 1560 70+430*ceil(panels/3)]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
layout=tiledlayout(fig,ceil(panels/3),min(3,panels),'TileSpacing','compact','Padding','compact');
pairs=[1 2;1 3;2 3]; periods=r.cfg.responsePeriods; ng=height(r.groupLabels);
colors=lines(ng); markers={'o','s'};
for panel=1:panels
    ax=nexttile(layout); hold(ax,'on'); dims=[1 2]; if isPCA, dims=pairs(panel,:); end
    if max(dims)>size(Y,2)
        text(ax,0.5,0.5,'Too few neural dimensions','HorizontalAlignment','center'); axis(ax,'off'); continue;
    end
    for g=1:ng
        for e=1:numel(periods)
            rows=find(T.groupIndex==g&T.responsePeriod==periods(e));
            [~,order]=sort(T.learningBin(rows)); rows=rows(order);
            if p.connectBins
                plot(ax,Y(rows,dims(1)),Y(rows,dims(2)),'-','Color',[0.75 0.75 0.75],'HandleVisibility','off');
            end
            if isPCA
                scatter(ax,Y(rows,dims(1)),Y(rows,dims(2)),p.pointSize,colors(g,:),markers{e},'filled', ...
                    'DisplayName',char(r.groupLabels.groupName(g)+" / "+periods(e)));
            end
            plot(ax,Y(rows(1),dims(1)),Y(rows(1),dims(2)),'ko','MarkerSize',9,'HandleVisibility','off');
        end
    end
    if isPCA
        xlabel(ax,sprintf('PC%d (%.1f%%)',dims(1),r.pca.explained(dims(1))));
        ylabel(ax,sprintf('PC%d (%.1f%%)',dims(2),r.pca.explained(dims(2))));
        title(ax,sprintf('PC%d vs PC%d',dims));
        if panel==1, legend(ax,'Location','best','Interpreter','none','FontSize',8); end
    else
        field=p.colorBy(panel);
        if ismember(field,["learningBin","relativeProgress"])
            scatter(ax,Y(:,1),Y(:,2),p.pointSize,T.(field),'filled');
            colormap(ax,parula(256)); cb=colorbar(ax); cb.Label.String=char(field);
            if field=="learningBin", caxis(ax,[1 r.cfg.nBins]); else, caxis(ax,[0 1]); end
        else
            labels=string(T.(field)); levels=unique(labels,'stable'); palette=lines(numel(levels)); handles=gobjects(numel(levels),1);
            for k=1:numel(levels)
                rows=labels==levels(k); handles(k)=scatter(ax,Y(rows,1),Y(rows,2),p.pointSize,palette(k,:),'filled');
            end
            legend(ax,handles,cellstr(levels),'Location','best','Interpreter','none');
        end
        title(ax,"Colored by "+field,'Interpreter','none'); xlabel(ax,'UMAP 1'); ylabel(ax,'UMAP 2');
    end
    axis(ax,'equal'); box(ax,'on');
end
title(layout,{sprintf('%s | %d groups x %d response periods x %d learning bins | %d pooled neurons, %d animals', ...
    upper(mode),ng,numel(periods),r.cfg.nBins,height(r.neurons),sum(r.animalAudit.included)), ...
    'Bin-averaged responses; circles mark first bins; progression is relative within each group/animal'});
file='';
if ~isempty(p.savePath)
    file=fullfile(p.savePath,[char(p.prefix) '_' mode '.png']); exportgraphics(fig,file,'Resolution',150);
    savefig(fig,[file(1:end-4) '.fig']);
end
if p.visible, handle=fig; else, handle=[]; end
end
