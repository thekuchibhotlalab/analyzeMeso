function [figures,files] = fn_plotNeuralGeometry(r,p)
%FN_PLOTNEURALGEOMETRY Plot a saved result without loading neural trials again.
% Graphics are always separate from r. Hidden saved plots are closed.
% Grouped outputs: activity, projections, variance, and optional trajectories.
[~,defaults]=fn_neuralGeometryConfig();
if nargin<2 || isempty(p), p=struct(); end
assert(isstruct(p)&&isscalar(p),'neuralGeometry:PlotConfig','Use a scalar plot configuration.');
extra=setdiff(fieldnames(p),fieldnames(defaults));
assert(isempty(extra),'neuralGeometry:PlotConfig','Unknown plot options: %s.',strjoin(extra,', '));
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
p.trajectory=validatestring(p.trajectory,{'none','3d','2d','both'});
p.similarity=validatestring(p.similarity,{'correlation','angle','cosine'});
p.projectionError=validatestring(p.projectionError,{'sem','sd','none'});
validateattributes(p.columns,{'numeric'},{'scalar','integer','>=',3,'finite'});
validateattributes(p.figureWidth,{'numeric'},{'scalar','positive','finite'});
validateattributes(p.rowHeight,{'numeric'},{'scalar','positive','finite'});
validateattributes(p.showConditionContribution,{'logical','numeric'},{'scalar','binary'});
figures=struct(); files=struct();
if ~p.makePlot, return; end
isCV=isfield(r,'crossValidation')&&r.crossValidation.enabled;
K=size(r.weights,2);
nc=height(r.conditions); nf=numel(r.variables); time=r.time;
names=string(r.conditions.conditionName); labels=r.axisLabels;
colors=lines(nc); selected=[];
if ~isempty(p.trialTypes)
    [found,selected]=ismember(string(p.trialTypes),names);
    assert(all(found),'neuralGeometry:PlotConditions','Unknown trialTypes names.');
end
visibility='off'; if p.visible, visibility='on'; end
folder=char(p.savePath);
if ~isempty(folder)&&~isfolder(folder), mkdir(folder); end
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'neuralGeometry:PlotConfig','prefix must be a filename prefix.');

% Figure 1: all heatmaps followed by wider population-mean panels.
cols=min(p.columns,max(nc,nf)); heatRows=ceil(nc/cols);
meanSpan=max(1,floor(cols/nf)); totalRows=heatRows+ceil(nf/cols);
[f,layout]=newFigure('Activity sanity checks',totalRows*cols,cols);
limits=[min(r.conditionMeans,[],'all') max(r.conditionMeans,[],'all')];
if limits(1)==limits(2), limits=limits+[-1 1]; end
for c=1:nc
    ax=nexttile(layout);
    imagesc(ax,time,1:height(r.neurons),r.conditionMeans(r.sanity.neuronOrder,:,c),limits);
    title(ax,names(c),'Interpreter','none'); xlabel(ax,'Time (s)');
    if mod(c-1,cols)==0, ylabel(ax,'Neuron (shared peak-time order)'); end
end
cb=colorbar(ax); cb.Layout.Tile='east';
useHelper=exist('fn_plotMeanErrorbar','file')==2 && exist('fn_nansem','file')==2 ...
    && exist('fn_plotFillErrorbar','file')==2;
for v=1:nf
    ax=nexttile(layout,heatRows*cols+(v-1)*meanSpan+1,[1 meanSpan]);
    hold(ax,'on'); levels=r.factors(v).levels; palette=lines(numel(levels));
    handles=gobjects(numel(levels),1);
    for l=1:numel(levels)
        rows=string(r.conditions.(r.variables(v)))==levels(l);
        Y=mean(r.conditionMeans(:,:,rows),3); color=palette(l,:);
        if useHelper && size(Y,1)>1
            axes(ax); %#ok<LAXES>
            [handles(l),shade]=fn_plotMeanErrorbar(time,Y,color,color, ...
                {'LineWidth',1.5},{'FaceAlpha',0.18});
            set(shade,'HandleVisibility','off');
        else
            mu=mean(Y,1); se=std(Y,0,1)/sqrt(size(Y,1));
            fill(ax,[time fliplr(time)],[mu-se fliplr(mu+se)],color, ...
                'FaceAlpha',0.18,'EdgeColor','none','HandleVisibility','off');
            handles(l)=plot(ax,time,mu,'Color',color,'LineWidth',1.5);
        end
    end
    title(ax,r.variables(v),'Interpreter','none'); xlabel(ax,'Time (s)'); ylabel(ax,'Mean activity');
    legend(ax,handles,cellstr(levels),'Interpreter','none','Location','best');
end
title(layout,{'Pooled activity: condition PSTHs and marginalized population means', ...
    'Shared peak-time neuron order; shading = SEM across neuron-wise trial means'});
finish(f,'activity');
if K==0, warning('neuralGeometry:NoAxes','No separable axes; only activity sanity checks plotted.'); return; end

% Figure 2: one aligned row block per projection type.
cols=min(p.columns,K); projectionRows=ceil(K/cols);
traceRows=projectionRows*double(~isempty(selected));
panels=(projectionRows+traceRows)*cols;
[f,layout]=newFigure('Projection time courses',panels,cols);
errorMode=p.projectionError;
if ~strcmp(errorMode,'none') && ~isfield(r.projection,['condition' upper(errorMode)])
    warning('neuralGeometry:MissingProjectionError', ...
        'Saved result lacks trial-based %s. Rerun fn_analyzeNeuralGeometry once to add projection bands.',upper(errorMode));
    errorMode='none';
end
if strcmp(errorMode,'none')
    title(layout,'Fixed pooled-neuron axes: marginalized and condition time courses');
elseif isCV
    title(layout,{'Held-out projections, averaged over training splits', ...
        'Shading = SEM across repeat means; partition variability, not animal uncertainty'});
else
    title(layout,{'Fixed pooled-neuron axes: marginalized and condition time courses', ...
        ['Shading = +/-1 trial-based ' upper(errorMode) '; fixed axes, independent animal contributions']});
end
for k=1:K
    ax=nexttile(layout); hold(ax,'on');
    fi=find(r.variables==r.axisInfo.variable(k)); local=r.axisInfo.axis(k);
    F=r.factors(fi);
    palette=lines(numel(F.levels)); handles=gobjects(numel(F.levels),1);
    for l=1:numel(F.levels)
        rows=find(string(r.conditions.(r.variables(fi)))==F.levels(l));
        mu=reshape(F.marginalProjection(local,:,l),1,[]);
        band=projectionBand(r,k,rows,errorMode);
        if ~isempty(band)
            fill(ax,[time fliplr(time)],[mu-band fliplr(mu+band)],palette(l,:), ...
                'FaceAlpha',0.18,'EdgeColor','none','HandleVisibility','off');
        end
        handles(l)=plot(ax,time,mu,'Color',palette(l,:),'LineWidth',1.5);
    end
    title(ax,"Marginal: "+labels(k),'Interpreter','none'); xlabel(ax,'Time (s)'); ylabel(ax,'Projection');
    if local==1, legend(ax,handles,cellstr(F.levels),'Interpreter','none','Location','best'); end
end

if ~isempty(selected)
    for k=1:K
        ax=nexttile(layout,projectionRows*cols+k); hold(ax,'on');
        for c=reshape(selected,1,[])
            mu=reshape(r.projection.conditionMean(k,:,c),1,[]);
            band=projectionBand(r,k,c,errorMode);
            if ~isempty(band)
                fill(ax,[time fliplr(time)],[mu-band fliplr(mu+band)],colors(c,:), ...
                    'FaceAlpha',0.18,'EdgeColor','none','HandleVisibility','off');
            end
            plot(ax,time,mu,'Color',colors(c,:),'LineWidth',1.3);
        end
        title(ax,"Conditions: "+labels(k),'Interpreter','none'); xlabel(ax,'Time (s)'); ylabel(ax,'Projection');
        if k==1
            lg=legend(ax,cellstr(names(selected)),'Interpreter','none','Orientation','horizontal');
            lg.Layout.Tile='south';
        end
    end
end

finish(f,'projections');

% Figure 3: summaries and similarity, time-resolved variance, separation.
% Time courses retain their per-time denominator. Summary pools time as well.
axisPopulation=r.variance.axisFractionOfPopulationTotalByTime;
if isfield(r.variance,'pooledAllTrialsFraction')
    pooledPopulation=r.variance.pooledAllTrialsPopulationVariance;
    trialMeanSummary=r.variance.pooledTrialMeanFraction;
else
    % Reconstruct from saved means/variances, with no neural reload or refit.
    projected=var(reshape(r.projection.conditionMean,K,numel(time)*nc),1,2);
    population=sum(var(reshape(r.conditionMeans,height(r.neurons),numel(time)*nc),1,2));
    trialMeanSummary=projected./population;
    noise=mean(r.variance.populationTotalVarianceByTime- ...
        r.variance.populationBetweenConditionVarianceByTime);
    pooledPopulation=population+noise;
    trialMeanSummary(~isfinite(trialMeanSummary))=NaN;
end
if isfield(r.variance,'variableUniquePooledPopulationFraction')
    variableSummary=r.variance.variableUniquePooledPopulationFraction;
else
    if isfield(r.variance,'variableUniqueEnergyByTime')
        energy=r.variance.variableUniqueEnergyByTime;
    else
        energy=r.variance.variableUniqueFractionByTime.*r.variance.totalByTime;
        for v=1:nf
            if r.variance.variableIdentifiable(v)
                e=energy(:,:,v); e(r.variance.totalByTime==0)=0; energy(:,:,v)=e;
            end
        end
    end
    variableSummary=reshape(mean(energy,2),K,nf)./pooledPopulation;
    variableSummary(~isfinite(variableSummary))=NaN;
end
cols=min(p.columns,max(K,3));
summaryCount=3+double(p.showConditionContribution);
summaryRows=ceil(summaryCount/cols);
summarySpan=max(1,floor(cols/min(summaryCount,cols)));
varianceRows=ceil(K/cols);
separationStart=(summaryRows+(1+double(p.showConditionContribution))*varianceRows)*cols;
[f,layout]=newFigure('Variance and axis similarity',separationStart+2*nf,cols);
if isCV
    title(layout,'Held-out variance and separation: split means +/- SEM across repeats; mean-axis similarity');
else
    title(layout,'In-sample variance explained, matching-variable separation, and axis similarity');
end
ax=nexttile(layout,1,[1 summarySpan]); bars=bar(ax,variableSummary); xticks(ax,1:K);
if isCV
    hold(ax,'on'); se=r.crossValidation.varianceSEM.variableUniquePooledPopulationFraction;
    for v=1:nf, errorbar(ax,bars(v).XEndPoints,variableSummary(:,v),se(:,v),'k.','HandleVisibility','off'); end
end
xticklabels(ax,labels); set(ax,'TickLabelInterpreter','none'); ylabel(ax,'Unique variable variance / population total');
title(ax,{'Task-variable separation on each axis', 'Population total includes all trials and time'});
legend(ax,cellstr(r.variables),'Interpreter','none','Location','best');
ax=nexttile(layout,1+summarySpan,[1 summarySpan]); bar(ax,trialMeanSummary); xticks(ax,1:K);
if isCV
    hold(ax,'on'); errorbar(ax,1:K,trialMeanSummary,r.crossValidation.varianceSEM.pooledTrialMeanFraction,'k.');
end
xticklabels(ax,labels); set(ax,'TickLabelInterpreter','none'); ylabel(ax,'Projected variance / population total');
title(ax,{'Variance captured: condition means', 'Trials averaged; all time points pooled'});
if p.showConditionContribution
    ax=nexttile(layout,1+2*summarySpan,[1 summarySpan]); imagesc(ax,r.variance.conditionContribution'); colorbar(ax);
    xticks(ax,1:K); xticklabels(ax,labels); yticks(ax,1:nc); yticklabels(ax,names);
    set(ax,'TickLabelInterpreter','none'); title(ax,'Condition contributions');
end
similarityStart=1+(summaryCount-1)*summarySpan;
ax=nexttile(layout,similarityStart,[1 cols-mod(similarityStart-1,cols)]);
switch p.similarity
    case 'angle'
        imagesc(ax,r.similarity.angleDegrees,[0 90]); title(ax,'Unsigned axis angle (degrees)');
    case {'correlation','cosine'}
        if strcmp(p.similarity,'correlation')
            % Pearson correlation across neurons, computed here so saved
            % results can be replotted without rerunning the analysis.
            centered=r.weights-mean(r.weights,1);
            lengths=sqrt(sum(centered.^2,1));
            values=(centered'*centered)./(lengths'*lengths);
            values=max(-1,min(1,values));
            values(lengths==0,:)=NaN; values(:,lengths==0)=NaN;
            similarityTitle='Axis weight correlation (Pearson r)';
        else
            values=r.similarity.cosine;
            similarityTitle='Axis cosine similarity';
        end
        im=imagesc(ax,values,[-1 1]); set(im,'AlphaData',isfinite(values));
        title(ax,similarityTitle);
        set(ax,'Color',[0.85 0.85 0.85]); % Undefined correlations are gray.
        % Odd-length map puts pure white exactly at zero. Local to this axes.
        colormap(ax,interp1([-1 0 1],[0.15 0.35 0.8;1 1 1;0.8 0.15 0.15],linspace(-1,1,257)));
end
cb=colorbar(ax);
if ~strcmp(p.similarity,'angle'), cb.Ticks=[-1 -0.5 0 0.5 1]; end
axis(ax,'square'); xticks(ax,1:K); yticks(ax,1:K);
xticklabels(ax,labels); yticklabels(ax,labels); set(ax,'TickLabelInterpreter','none');
for k=1:K
    ax=nexttile(layout,summaryRows*cols+k); hold(ax,'on');
    if isCV, drawBand(ax,time,axisPopulation(k,:),r.crossValidation.varianceSEM.axisFractionOfPopulationTotalByTime(k,:),[0 0.447 0.741]); end
    plot(ax,time,axisPopulation(k,:),'LineWidth',1.4);
    title(ax,"Variance captured: "+labels(k),'Interpreter','none'); xlabel(ax,'Time (s)'); ylabel(ax,'Projected variance / population total');
end

if p.showConditionContribution
    for k=1:K
        ax=nexttile(layout,(summaryRows+varianceRows)*cols+k); hold(ax,'on');
        for c=1:nc
            if isCV, drawBand(ax,time,reshape(r.variance.conditionContributionByTime(k,:,c),1,[]),reshape(r.crossValidation.varianceSEM.conditionContributionByTime(k,:,c),1,[]),colors(c,:)); end
            plot(ax,time,reshape(r.variance.conditionContributionByTime(k,:,c),1,[]),'Color',colors(c,:));
        end
        title(ax,"Conditions: "+labels(k),'Interpreter','none'); xlabel(ax,'Time (s)'); ylabel(ax,'Contribution / total');
        if k==1
            lg=legend(ax,cellstr(names),'Interpreter','none','Orientation','horizontal'); lg.Layout.Tile='south';
        end
    end
end

for v=1:nf
    F=r.factors(v); ax=nexttile(layout,separationStart+2*v-1);
    if F.nAxes>0
        bar(ax,1:F.nAxes,F.separationCapture);
        if isCV, hold(ax,'on'); errorbar(ax,1:F.nAxes,F.separationCapture,r.crossValidation.factorSEM(v).separationCapture,'k.'); end
    end
    title(ax,"Separation: "+F.name,'Interpreter','none'); xlabel(ax,'Axis'); ylabel(ax,'Separation captured');
    ax=nexttile(layout,separationStart+2*v); hold(ax,'on');
    palette=lines(F.nAxes);
    for k=1:F.nAxes
        if isCV, drawBand(ax,time,F.separationCaptureByTime(k,:),r.crossValidation.factorSEM(v).separationCaptureByTime(k,:),palette(k,:)); end
        plot(ax,time,F.separationCaptureByTime(k,:),'LineWidth',1.2,'Color',palette(k,:));
    end
    title(ax,"Separation: "+F.name,'Interpreter','none'); xlabel(ax,'Time (s)'); ylabel(ax,'Separation captured');
    if F.nAxes>0, legend(ax,cellstr("Axis "+string(1:F.nAxes)),'Location','best'); end
end
finish(f,'variance');

% Decoder figures use real single-neuron trials only.
if isfield(r,'decoding')
    d=r.decoding.mean; se=r.decoding.sem; valid=find(d.validFactor);
    if ~isempty(valid)
        [f,layout]=newFigure('Held-out decoding over time',numel(valid),numel(valid));
        title(layout,{'Single-neuron LDA; training-only ranking for top-neuron groups', ...
            'Shading = SEM across repeat means; balanced accuracy'});
        palette=lines(numel(r.cfg.decoderTopFractions));
        for v=reshape(valid,1,[])
            ax=nexttile(layout); hold(ax,'on');
            for q=1:numel(r.cfg.decoderTopFractions)
                [~,j]=min(abs(d.fractions-r.cfg.decoderTopFractions(q)));
                mu=d.singleTime(j,:,v); err=se.singleTime(j,:,v);
                drawBand(ax,time,mu,err,palette(q,:));
                plot(ax,time,mu,'Color',palette(q,:),'LineWidth',1.5, ...
                    'DisplayName',sprintf('Mean single neuron: top %g%%',100*d.fractions(j)));
            end
            yline(ax,0.5,'k:','HandleVisibility','off'); ylim(ax,[0 1]);
            xlabel(ax,'Time (s)'); ylabel(ax,'Held-out balanced accuracy');
            title(ax,r.variables(v),'Interpreter','none'); legend(ax,'Location','best');
        end
        finish(f,'decodingTime');
        if isfield(d,'neuronSummary')
            [f,layout]=newFigure('Individual-neuron decoding accuracy',numel(valid),numel(valid));
            title(layout,{'Each point = one neuron, sorted by its held-out accuracy', ...
                'Ordering is descriptive; error bars = SEM across repeat means'});
            animals=unique(r.neurons.animalIndex,'stable'); palette=lines(numel(animals));
            for v=reshape(valid,1,[])
                ax=nexttile(layout); hold(ax,'on');
                [mu,order]=sort(d.neuronSummary(:,v),'descend');
                err=se.neuronSummary(order,v); x=(1:numel(order))';
                errorbar(ax,x,mu,err,'LineStyle','none','Color',[.75 .75 .75], ...
                    'CapSize',0,'HandleVisibility','off');
                for a=1:numel(animals)
                    use=r.neurons.animalIndex(order)==animals(a);
                    label=r.neurons.animalLabel(find(r.neurons.animalIndex==animals(a),1));
                    scatter(ax,x(use),mu(use),12,palette(a,:),'filled','DisplayName',label);
                end
                yline(ax,0.5,'k:','HandleVisibility','off'); ylim(ax,[0 1]);
                xlim(ax,[.5 numel(order)+.5]);
                xlabel(ax,'Individual neuron rank (held-out accuracy)'); ylabel(ax,'Held-out balanced accuracy');
                if strcmpi(r.variables(v),r.cfg.decoderChoiceVariable)
                    title(ax,r.variables(v)+": fixed pre-choice frames (-200 ms to <0)",'Interpreter','none');
                else
                    title(ax,r.variables(v)+": full analysis window",'Interpreter','none');
                end
                legend(ax,'Location','best','Interpreter','none');
            end
            finish(f,'decodingNeurons');
        else
            warning('neuralGeometry:OldDecoder', ...
                'This saved result lacks individual held-out neuron accuracies. Rerun the analysis for decodingNeurons.');
        end
    end
end

% Separate factor spaces, then same-rank cross-factor comparisons.
if ~strcmp(p.trajectory,'none')
    % Put action before task irrespective of condition-table column order.
    order=[find(strcmpi(r.variables,'action'));find(strcmpi(r.variables,'task'))];
    order=[order;setdiff((1:nf)',order,'stable')]; groups=cell(1,numel(order));
    for v=1:numel(order)
        ids=find(r.axisInfo.variable==r.variables(order(v)) & r.axisInfo.axis<=3);
        [~,ix]=sort(r.axisInfo.axis(ids)); groups{v}=reshape(ids(ix),1,[]);
    end
    if ~isempty(p.trajectoryAxes)
        ids=p.trajectoryAxes;
        validateattributes(ids,{'numeric'},{'vector','numel',3,'integer','positive','<=',K});
        assert(numel(unique(ids))==3,'neuralGeometry:Trajectory','Choose three distinct global axis indices.');
        groups={reshape(ids,1,[])}; % Explicit override retains custom-triplet support.
    end
    rows={};
    if ismember(p.trajectory,{'3d','both'})
        triples=groups(cellfun(@numel,groups)==3);
        for j=1:3:numel(triples), rows{end+1}=triples(j:min(j+2,end)); end %#ok<AGROW>
        if numel(triples)<numel(groups)
            warning('neuralGeometry:Trajectory','Some variables have fewer than three axes; their 3D panels are skipped.');
        end
    end
    if ismember(p.trajectory,{'2d','both'})
        for v=1:numel(groups)
            ids=groups{v}; if numel(ids)<2, continue; end
            pairs=nchoosek(ids,2); rows{end+1}=num2cell(pairs,2)'; %#ok<AGROW>
        end
        for a=1:numel(groups)
            for b=a+1:numel(groups)
                [~,ia,ib]=intersect(r.axisInfo.axis(groups{a}),r.axisInfo.axis(groups{b}));
                if isempty(ia), continue; end
                pairs=[reshape(groups{a}(ia),[],1) reshape(groups{b}(ib),[],1)];
                rows{end+1}=num2cell(pairs,2)'; %#ok<AGROW>
            end
        end
    end
    if ~isempty(rows)
        % Six grid units allow either two wide 3D panels or three 2D panels.
        [f,layout]=newFigure('Neural trajectories',6*numel(rows),6);
        title(layout,'Condition trajectories: within-variable axes and matched-rank comparisons; circles = first time bin');
        for row=1:numel(rows)
            span=6/numel(rows{row});
            for j=1:numel(rows{row})
                ids=rows{row}{j}; ax=nexttile(layout,(row-1)*6+(j-1)*span+1,[1 span]);
                hold(ax,'on');
                for c=1:nc
                    Y=r.projection.conditionMean(ids,:,c);
                    if numel(ids)==3
                        plot3(ax,Y(1,:),Y(2,:),Y(3,:),'Color',colors(c,:),'LineWidth',1.5);
                        plot3(ax,Y(1,1),Y(2,1),Y(3,1),'o','Color',colors(c,:),'HandleVisibility','off');
                    else
                        plot(ax,Y(1,:),Y(2,:),'Color',colors(c,:),'LineWidth',1.5);
                        plot(ax,Y(1,1),Y(2,1),'o','Color',colors(c,:),'HandleVisibility','off');
                    end
                end
                xlabel(ax,labels(ids(1)),'Interpreter','none'); ylabel(ax,labels(ids(2)),'Interpreter','none');
                if numel(ids)==3
                    zlabel(ax,labels(ids(3)),'Interpreter','none'); view(ax,3);
                end
                grid(ax,'on'); title(ax,strjoin(labels(ids),' / '),'Interpreter','none');
            end
        end
        lg=legend(ax,cellstr(names),'Interpreter','none','Orientation','horizontal'); lg.Layout.Tile='south';
        finish(f,'trajectories');
    end
end

    function [fig,tiles]=newFigure(name,nPanels,nColumns)
        nRows=ceil(nPanels/nColumns);
        fig=figure('Name',name,'Color','w','Visible',visibility, ...
            'Position',[40 40 p.figureWidth max(420,nRows*p.rowHeight)]);
        tiles=tiledlayout(fig,nRows,nColumns,'TileSpacing','compact','Padding','compact');
    end
    function finish(fig,name)
        set(findall(fig,'Type','axes'),'FontSize',9);
        if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
        if ~isempty(folder)
            file=fullfile(folder,[prefix '_' name '.png']);
            exportgraphics(fig,file,'Resolution',150); files.(name)=file;
            savefig(fig,[file(1:end-4) '.fig']);
        end
        if p.visible, figures.(name)=fig; else, figures.(name)=[]; end
    end
end

function band=projectionBand(r,k,rows,mode)
% Marginalize each split BEFORE computing repeat SEM (conditions covary).
if isfield(r,'crossValidation')&&r.crossValidation.enabled&&~strcmp(mode,'none')
    cv=r.crossValidation; S=numel(cv.splits); Y=zeros(numel(r.time),S);
    for s=1:S, Y(:,s)=reshape(mean(cv.splits{s}.projection.conditionMean(k,:,rows),3),[],1); end
    Y=reshape(mean(reshape(Y,[],cv.nFolds,cv.nRepeats),2),[],cv.nRepeats);
    band=std(Y,0,2)';
    if strcmp(mode,'sem'), band=band/sqrt(cv.nRepeats); end
    return;
end
% Marginal means weight conditions equally, even with unequal trial counts.
switch mode
    case 'sem'
        band=sqrt(sum(r.projection.conditionSEM(k,:,rows).^2,3))/numel(rows);
    case 'sd'
        means=r.projection.conditionMean(k,:,rows);
        % Spread of a balanced mixture of condition-specific trial responses.
        band=sqrt(mean(r.projection.conditionSD(k,:,rows).^2+ ...
            (means-mean(means,3)).^2,3));
    otherwise
        band=[];
end
band=reshape(band,1,[]);
end

function drawBand(ax,x,mu,se,color)
x=reshape(x,1,[]); mu=reshape(mu,1,[]); se=reshape(se,1,[]);
fill(ax,[x fliplr(x)],[mu-se fliplr(mu+se)],color,'FaceAlpha',0.18, ...
    'EdgeColor','none','HandleVisibility','off');
end
