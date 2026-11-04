function [figures,files]=fn_plotTaskActionDecoding(r,p)
%FN_PLOTTASKACTIONDECODING Replot accuracy-only results without neural arrays.
[~,defaults]=fn_taskActionDecodingConfig();
if nargin<2, p=struct(); end
for key=fieldnames(defaults)', if ~isfield(p,key{1}), p.(key{1})=defaults.(key{1}); end; end
p.populationXAxis=validatestring(p.populationXAxis,{'percent','count'});
figures=struct(); files=struct(); if ~p.makePlot, return; end
validateattributes(p.histogramEdges,{'numeric'},{'vector','increasing','finite'});
visible='off'; if p.visible, visible='on'; end
folder=char(p.savePath); if ~isempty(folder)&&~isfolder(folder), mkdir(folder); end
assert(~isempty(p.prefix)&&~contains(string(p.prefix),{'/','\'}),'taskActionDecoding:Prefix','Use a filename prefix.');
colors=lines(numel(r.animalLabels)); cmp=r.comparisons;
[fig,layout]=makeFigure('Choice decoding: individual neurons',1,2);
ax=nexttile(layout); hold(ax,'on'); pair=r.choicePairs;
for a=1:numel(r.animalLabels)
    use=pair.animalIndex==a;
    if any(use), scatter(ax,pair.accuracyT1(use),pair.accuracyT2(use),12,colors(a,:), ...
            'filled','DisplayName',r.animalLabels(a)); end
end
plot(ax,[0 1],[0 1],'k:','HandleVisibility','off'); xline(ax,.5,'k:','HandleVisibility','off'); yline(ax,.5,'k:','HandleVisibility','off');
axis(ax,'square'); xlim(ax,[0 1]); ylim(ax,[0 1]);
xlabel(ax,"L/R accuracy in "+r.cfg.taskLabels(1)); ylabel(ax,"L/R accuracy in "+r.cfg.taskLabels(2));
title(ax,'Same neuron in both tasks'); legend(ax,'Location','best','Interpreter','none');
ax=nexttile(layout); hold(ax,'on');
for k=1:2
    data=r.neurons.accuracy(r.neurons.comparison==cmp(k).name);
    histogram(ax,data,p.histogramEdges,'Normalization','probability','DisplayStyle','stairs', ...
        'LineWidth',1.8,'DisplayName',sprintf('%s (n=%d)',r.cfg.taskLabels(k),numel(data)));
end
xline(ax,.5,'k:','HandleVisibility','off'); xlabel(ax,'Held-out balanced accuracy'); ylabel(ax,'Fraction of neurons');
title(ax,'Single-neuron LDA distributions'); legend(ax,'Location','best');
title(layout,sprintf('Choice: per-trial mean of frames %s; pooled cells, models fitted per animal',frameLabel(r.cfg.choiceFrames)));
finish(fig,'choiceAccuracy');

ids=find(string({cmp.kind})=="task"); cols=min(2,numel(ids));
[fig,layout]=makeFigure('Task decoding: individual neurons',ceil(numel(ids)/cols),cols);
for k=ids
    ax=nexttile(layout); hold(ax,'on');
    data=r.neurons.accuracy(r.neurons.comparison==cmp(k).name);
    histogram(ax,data,p.histogramEdges,'Normalization','probability','FaceColor',[.2 .5 .8]);
    xline(ax,.5,'k:'); xlabel(ax,'Held-out balanced accuracy'); ylabel(ax,'Fraction of neurons');
    title(ax,sprintf('%s: frames %s (n=%d)',cmp(k).name,frameLabel(cmp(k).frames),numel(data)),'Interpreter','none');
end
function label=frameLabel(frames)
if numel(frames)>1 && all(diff(frames)==1)
    label=sprintf('%d:%d',frames(1),frames(end));
else
    label=mat2str(frames);
end
end
if isfield(r.cfg,'balanceTaskActions')&&r.cfg.balanceTaskActions
    title(layout,'Task single-neuron LDA; equal L/R counts within each task');
else
    title(layout,'Task single-neuron LDA; L/R trials pooled within each task');
end
finish(fig,'taskAccuracy');

removing=ismember('removedFraction',r.population.Properties.VariableNames)&& ...
    any(isfinite(r.population.removedFraction));
[fig,layout]=makeFigure('Within-animal population SVM',ceil(numel(cmp)/2),2);
for k=1:numel(cmp)
    ax=nexttile(layout); hold(ax,'on');
    for a=1:numel(r.animalLabels)
        rows=r.population.animalIndex==a & r.population.comparison==cmp(k).name;
        A=r.population(rows,:); if isempty(A), continue; end
        if removing
            if strcmp(p.populationXAxis,'percent'), x=100*A.removedFraction; else, x=A.nRemoved; end
        else
            if strcmp(p.populationXAxis,'percent'), x=100*A.fraction; else, x=A.nNeurons; end
        end
        % Repeated percentages can map to the same count for small populations.
        [x,ix]=unique(x,'stable'); mu=A.accuracy(ix); se=A.sem(ix);
        fill(ax,[x;flipud(x)],[mu-se;flipud(mu+se)],colors(a,:), ...
            'FaceAlpha',.12,'EdgeColor','none','HandleVisibility','off');
        plot(ax,x,mu,'-o','MarkerSize',3,'LineWidth',1.4,'Color',colors(a,:), ...
            'DisplayName',r.animalLabels(a));
    end
    yline(ax,.5,'k:','HandleVisibility','off'); ylim(ax,[0 1]);
    if removing
        if strcmp(p.populationXAxis,'percent'), xlabel(ax,'Top-ranked neurons removed (%)'); else, xlabel(ax,'Number of top-ranked neurons removed'); end
    else
        if strcmp(p.populationXAxis,'percent'), xlabel(ax,'Top neurons selected (%)'); else, xlabel(ax,'Number of best neurons selected'); end
    end
    ylabel(ax,'Held-out balanced accuracy'); title(ax,cmp(k).name,'Interpreter','none');
    if k==1, legend(ax,'Location','best','Interpreter','none'); end
end
caption='Linear SVM refitted per animal and neuron subset';
if removing, caption='Linear SVM on remaining neurons: all neurons, then remove the best'; end
title(layout,{caption, ...
    'Training-only neuron ranking; real test trials; SEM across repeated CV'});
finish(fig,'populationSVM');

    function [f,l]=makeFigure(name,rows,cols)
        f=figure('Name',name,'Color','w','Visible',visible,'Position',[40 40 1400 max(450,330*rows)]);
        l=tiledlayout(f,rows,cols,'TileSpacing','compact','Padding','compact');
    end
    function finish(f,name)
        if ~p.visible, cleanup=onCleanup(@()close(f)); end %#ok<NASGU>
        if ~isempty(folder)
            file=fullfile(folder,[char(p.prefix) '_' name '.png']); exportgraphics(f,file,'Resolution',150); files.(name)=file;
            savefig(f,[file(1:end-4) '.fig']);
        end
        if p.visible, figures.(name)=f; else, figures.(name)=[]; end
    end
end
