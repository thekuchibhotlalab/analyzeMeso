function [figures,files] = fn_plotNeuralEmbedding(r,p)
%FN_PLOTNEURALEMBEDDING Learning/time, task, action views of ONE saved embedding.
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
p.layout=validatestring(p.layout,{'combined','labels'});
if strcmp(p.layout,'combined')
    [figures,files]=plotCombined(r,p); return;
end
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
            plotEmbedding(ax,Y(ids,:),'-','Color',0.55+0.45*palette(group,:), ...
                'HandleVisibility','off');
        end
    end
    for l=1:numel(levels)
        keep=labels==levels(l);
        handles(l)=scatterEmbedding(ax,Y(keep,:),p.pointSize,palette(l,:),'filled');
    end
    labelAxes(ax,size(Y,2)); box(ax,'on');
    title(ax,"Colored by "+variables(v),'Interpreter','none');
    legend(ax,handles,cellstr(levels),'Interpreter','none','Location','bestoutside');
end

if p.showTime
    ax=nexttile(layout); axs(end)=ax;
    pointTime=r.pointInfo.time;
    scatterEmbedding(ax,Y,p.pointSize,pointTime,'filled','Tag','timeProgression');
    limits=[min(pointTime) max(pointTime)];
    if limits(1)==limits(2), limits=limits+[-0.5 0.5]; end
    clim(ax,limits); colormap(ax,parula(256));
    cb=colorbar(ax); cb.Label.String='Time within trial (s)';
    labelAxes(ax,size(Y,2)); box(ax,'on');
    title(ax,'Colored by time (all conditions)');
end
linkViews(fig,axs,size(Y,2));
title(layout,sprintf('One unsupervised %dD embedding; each point = one condition x time-bin trial mean',size(Y,2)));
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    file=fullfile(p.savePath,[prefix '_umap.png']);
    exportgraphics(fig,file,'Resolution',150); files.umap=file;
    savefig(fig,[file(1:end-4) '.fig']);
end
if p.visible, figures.umap=fig; else, figures.umap=[]; end
end

function [figures,files]=plotCombined(r,p)
required={'learning','task','action'};
assert(all(ismember(required,r.conditions.Properties.VariableNames)), ...
    'neuralEmbedding:CombinedLabels', ...
    'Combined plots require learning, task, and action columns in conditions. Use layout=labels for legacy plots.');
Y=r.embedding; ids=r.pointInfo.conditionIndex; time=r.pointInfo.time(:);
assert(ismember(size(Y,2),[2 3])&&size(Y,1)==numel(ids)&&numel(time)==numel(ids)&&all(isfinite(time)), ...
    'neuralEmbedding:PointMapping','Embedding rows and finite point times must align.');
% Use the condition table explicitly, including when replotting older results.
phase=lower(strtrim(string(r.conditions.learning(ids))));
task=upper(strtrim(string(r.conditions.task(ids))));
action=upper(strtrim(string(r.conditions.action(ids))));
assert(all(ismember(phase,["e","int"])), 'neuralEmbedding:Learning', ...
    'conditions.learning must contain E or Int.');
assert(all(ismember(task,["T1","T2"]))&&all(ismember(action,["L","R"])), ...
    'neuralEmbedding:TaskAction','conditions.task must be T1/T2 and action must be L/R.');
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'neuralEmbedding:PlotConfig','prefix must be a filename prefix.');
limits=[min(time) max(time)];
if limits(1)==limits(2), limits=limits+[-.5 .5]; end
fraction=(time-limits(1))/diff(limits);
window=p.taskActionTimeWindow;
inWindow=true(size(time)); windowLabel='all fitted times';
if ~isempty(window)
    validateattributes(window,{'numeric'},{'real','finite','vector','numel',2});
    assert(window(1)<=window(2),'neuralEmbedding:TimeWindow','Time window must be increasing.');
    inWindow=time>=window(1)&time<=window(2);
    windowLabel=sprintf('%g to %g s',window(1),window(2));
end
visible='off'; if p.visible, visible='on'; end
fig=figure('Name','Trial-averaged neural UMAP','Color','w','Visible',visible, ...
    'Position',[40 40 1500 600]);
if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
ax1=axes(fig,'Position',[.055 .25 .26 .62],'Tag','learningTime'); hold(ax1,'on');
ax2=axes(fig,'Position',[.385 .25 .26 .62],'Tag','task'); hold(ax2,'on');
ax3=axes(fig,'Position',[.715 .25 .26 .62],'Tag','action'); hold(ax3,'on');
phases=["e","int"]; phases=phases(ismember(phases,phase));
h=gobjects(numel(phases),1);
for k=1:numel(phases)
    keep=find(phase==phases(k)); base=multitaskColors(phases(k));
    colors=timeShade(base,fraction(keep));
    h(k)=scatterEmbedding(ax1,Y(keep,:),p.pointSize,colors,'filled', ...
        'Tag','learningPoints','UserData',keep);
    if p.connectTime, connectConditions(ax1,r,keep,base); end
    % Each phase gets its own exact dark-to-light RGB/time key.
    width=.26/numel(phases)-.02; left=.055+(k-1)*.26/numel(phases);
    keyAx=axes(fig,'Position',[left .10 width .01],'Visible','off','Tag','timeKey');
    colormap(keyAx,timeShade(base,linspace(0,1,256)')); clim(keyAx,limits);
    cb=colorbar(keyAx,'southoutside'); cb.Position=[left .12 width .022];
    cb.Ticks=linspace(limits(1),limits(2),3);
    cb.TickLabels=compose('%.2g',cb.Ticks);
    label='Early (E)'; if phases(k)=="int", label='Interleaved (Int)'; end
    cb.Label.String=[label ': time (s)'];
end
names=replace(phases,["e","int"],["Early (E)","Interleaved (Int)"]);
legend(ax1,h,cellstr(names),'Location','northoutside','Orientation','horizontal','Box','off');
title(ax1,'Learning phase + trial time');
for kind=1:2
    if kind==1, ax=ax2; groups=["T1","T2"]; labels=task; tag='taskPoints';
    else, ax=ax3; groups=["L","R"]; labels=action; tag='actionPoints'; end
    g=gobjects(0); names=strings(0);
    for k=1:numel(groups)
        keep=find(inWindow&labels==groups(k));
        if isempty(keep), continue; end
        s=multitaskColors(groups(k),'style');
        if kind==1, s.Marker='o'; s.MarkerFaceColor=s.Color; end
        g(end+1)=scatterEmbedding(ax,Y(keep,:),p.pointSize,s.Color, ...
            'Marker',s.Marker,'MarkerFaceColor',s.MarkerFaceColor, ...
            'MarkerEdgeColor',s.MarkerEdgeColor,'LineWidth',1.1, ...
            'Tag',tag,'UserData',keep); %#ok<AGROW>
        names(end+1)=groups(k); %#ok<AGROW>
        if p.connectTime, connectConditions(ax,r,keep,s.Color,s.LineStyle); end
    end
    if ~isempty(g)
        legend(ax,g,cellstr(names),'Location','northoutside','Orientation','horizontal','Box','off');
    else
        text(ax,.5,.5,'No samples in selected time window','Units','normalized', ...
            'HorizontalAlignment','center');
    end
end
title(ax2,{'Task identity',windowLabel}); title(ax3,{'Action',windowLabel});
for ax=[ax1 ax2 ax3]
    labelAxes(ax,size(Y,2));
    set(ax,'Box','off','TickDir','out','FontName','Arial','FontSize',11);
end
linkViews(fig,[ax1 ax2 ax3],size(Y,2));
sgtitle(fig,sprintf('One unsupervised %dD embedding; each point = one condition x time-bin trial mean',size(Y,2)));
files=struct();
if ~isempty(p.savePath)
    if ~isfolder(p.savePath), mkdir(p.savePath); end
    file=fullfile(p.savePath,[prefix '_umap.png']);
    exportgraphics(fig,file,'Resolution',150); files.umap=file;
    savefig(fig,[file(1:end-4) '.fig']);
end
figures=struct('umap',[]); if p.visible, figures.umap=fig; end
end

function rgb=timeShade(base,fraction)
% Keep hue recognizable: start at 65% base, end at 55% white + 45% base.
dark=.65*base; light=.45*base+.55;
rgb=dark+fraction(:).*(light-dark);
end

function connectConditions(ax,r,keep,color,lineStyle)
if nargin<5, lineStyle='-'; end
for c=unique(r.pointInfo.conditionIndex(keep))'
    rows=keep(r.pointInfo.conditionIndex(keep)==c);
    [~,order]=sort(r.pointInfo.time(rows)); rows=rows(order);
    plotEmbedding(ax,r.embedding(rows,:),'LineStyle',lineStyle, ...
        'Color',.65+.35*color,'HandleVisibility','off');
end
end

function h=scatterEmbedding(ax,Y,varargin)
if size(Y,2)==3
    h=scatter3(ax,Y(:,1),Y(:,2),Y(:,3),varargin{:});
else
    h=scatter(ax,Y(:,1),Y(:,2),varargin{:});
end
end

function h=plotEmbedding(ax,Y,varargin)
if size(Y,2)==3
    h=plot3(ax,Y(:,1),Y(:,2),Y(:,3),varargin{:});
else
    h=plot(ax,Y(:,1),Y(:,2),varargin{:});
end
end

function labelAxes(ax,nDimensions)
xlabel(ax,'UMAP 1'); ylabel(ax,'UMAP 2'); axis(ax,'equal');
if nDimensions==3
    zlabel(ax,'UMAP 3'); view(ax,[-37.5 30]); grid(ax,'on');
end
end

function linkViews(fig,axs,nDimensions)
if nDimensions==3
    % Retain the link so rotating a visible panel updates the other panels.
    setappdata(fig,'embeddingViewLink',linkprop(axs,{'XLim','YLim','ZLim','View'}));
else
    linkaxes(axs,'xy');
end
end

