function [figures,files] = fn_plotTrialProgression(r,p)
%FN_PLOTTRIALPROGRESSION Replot saved aggregate responses without raw trials.
[~,defaults]=fn_trialProgressionConfig();
if nargin<2||isempty(p), p=struct(); end
assert(isstruct(p)&&isscalar(p),'trialProgression:PlotConfig','Use a scalar plotting config.');
extra=setdiff(fieldnames(p),fieldnames(defaults));
assert(isempty(extra),'trialProgression:PlotConfig','Unknown options: %s.',strjoin(extra,', '));
for name=fieldnames(defaults)'
    if ~isfield(p,name{1}), p.(name{1})=defaults.(name{1}); end
end
figures=struct(); files=struct(); if ~p.makePlot, return; end
p.heatmapMethod=validatestring(p.heatmapMethod,{'bin','smooth','none'});
validateattributes(p.heatmapWindow,{'numeric'},{'scalar','integer','positive','finite'});
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'trialProgression:PlotConfig','prefix must be a filename prefix.');
visibility='off'; if p.visible, visibility='on'; end
nc=numel(r.byCondition); time=reshape(r.time,1,[]);
normalizationLabel="";
if isfield(r.cfg,'normalization')&&~strcmp(r.cfg.normalization,'none')
    normalizationLabel=" ("+string(r.cfg.normalization)+" normalized)";
end
if p.showStimulusBins&&isfield(r,'stimulusBins')&&~isempty(r.stimulusBins)
    B=r.stimulusBins; [ns,na]=size(B.trialCounts);
    fig=figure('Name','Equal-count stimulus bins','Color','w','Visible',visibility, ...
        'Position',[40 40 max(650,320*na) max(400,300*ns)]);
    layout=tiledlayout(fig,ns,na,'TileSpacing','compact','Padding','compact');
    title(layout,{string(sprintf('%d equal-count bins per animal and stimulus; all selected trials',B.nBins))+normalizationLabel, ...
        char(B.conditions.dayLabel(1))+"; outcomes pooled; gray = empty bin"});
    values=B.meanPsth(isfinite(B.meanPsth)); colorRange=[0 1];
    if ~isempty(values)
        colorRange=[min(values) max(values)];
        if diff(colorRange)==0, colorRange=colorRange+[-0.5 0.5]; end
    end
    for s=1:ns
        for a=1:na
            ax=nexttile(layout);
            caption=B.conditions.conditionName(s)+" | "+B.animalLabels(a);
            if B.nNeurons(s,a)==0
                axis(ax,'off'); text(ax,0.5,0.5,caption+": "+B.status(s,a), ...
                    'HorizontalAlignment','center','Interpreter','none');
                continue;
            end
            H=B.meanPsth(:,:,s,a)';
            imagesc(ax,time,1:B.nBins,H,'AlphaData',isfinite(H));
            set(ax,'Color',[0.85 0.85 0.85]); caxis(ax,colorRange); limitTime(ax);
            xlabel(ax,'Time (s)'); ylabel(ax,'Bin in concatenated trial sequence');
            yticks(ax,1:B.nBins);
            title(ax,caption+": "+B.trialCounts(s,a)+" trials, "+B.nNeurons(s,a)+" neurons",'Interpreter','none');
            colorbar(ax);
        end
    end
    finish(fig,'stimulusBins');
end
animalScopes=0;
if p.showAnimals
    if isfield(r.byCondition,'byAnimal')
        animalScopes=0:numel(r.byCondition(1).byAnimal);
    else
        warning('trialProgression:AnimalPlots','Rerun fn_analyzeTrialProgression to store per-animal summaries.');
    end
end
for animalScope=animalScopes
    view=r.byCondition; heading="All pooled neurons"+normalizationLabel; scopeLabel="Pooled animals";
    if animalScope>0
        scopeLabel=view(1).byAnimal(animalScope).animalLabel;
        heading=scopeLabel+": all neurons"+normalizationLabel;
        for c=1:nc
            view(c).allPopulation=view(c).byAnimal(animalScope).allPopulation;
            view(c).animalAudit=view(c).animalAudit(animalScope,:);
        end
    end
if isfield(r.cfg,'groupBy')&&ismember(r.cfg.groupBy,{'phaseOutcome','outcome'})
    phases=unique(string(r.conditions.dayLabel),'stable'); palette=lines(3);
    outcomeNames=["rewarded","incorrect","probe"];
    fig=figure('Name',scopeLabel+": outcome comparisons",'Color','w','Visible',visibility, ...
        'Position',[40 40 750 max(400,300*numel(phases))]);
    layout=tiledlayout(fig,numel(phases),1,'TileSpacing','compact','Padding','compact');
    title(layout,{scopeLabel+": stimulus types pooled chronologically within each outcome", ...
        'Mean of early analyzed trials; shading = SEM across neurons'});
    for phase=1:numel(phases)
            ax=nexttile(layout); hold(ax,'on'); handles=gobjects(0); labels=strings(0,1);
            for j=1:3
                c=find(string(r.conditions.dayLabel)==phases(phase)&string(r.conditions.outcome)==outcomeNames(j));
                if isempty(c), continue; end
                C=view(c); S=C.allPopulation;
                if isempty(S)||S.nNeurons==0, continue; end
                handles(end+1)=trace(ax,time,S.meanPsth,S.meanSEM,palette(j,:)); %#ok<AGROW>
                labels(end+1)=outcomeNames(j)+" (first "+C.nProgressionTrials+", n="+S.nNeurons+")"; %#ok<AGROW>
            end
            title(ax,{char(phases(phase)),char(heading)},'Interpreter','none');
            xlabel(ax,'Time (s)'); ylabel(ax,'Mean activity');
            limitTime(ax);
            if ~isempty(handles), legend(ax,handles,cellstr(labels),'Location','best');
            else, text(ax,0.5,0.5,'No eligible neurons','Units','normalized'); end
    end
    finish(fig,scopeKey('outcomeComparison'));
end
    heatmaps=cell(nc,1); heatLabels=cell(nc,1); colorRange=[Inf -Inf];
    for c=1:nc
        S=view(c).allPopulation;
        if isempty(S)||S.nNeurons==0, continue; end
        [heatmaps{c},heatLabels{c}]=heatmapData(S.trialPsth,p);
        colorRange=[min(colorRange(1),min(heatmaps{c}(:))) max(colorRange(2),max(heatmaps{c}(:)))];
    end
    fig=figure('Name',heading,'Color','w','Visible',visibility, ...
        'Position',[40 40 1650 max(400,330*nc)]);
    forLayout=tiledlayout(fig,nc,4,'TileSpacing','compact','Padding','compact');
    title(forLayout,{char(heading),'Trial order is within condition/animal; shading = descriptive SEM across neurons'});
    for c=1:nc
        C=view(c); S=C.allPopulation;
        if isempty(S)||S.nNeurons==0
            for j=1:4
                ax=nexttile(forLayout); axis(ax,'off');
                text(ax,0.5,0.5,C.conditionName+": no eligible neurons",'HorizontalAlignment','center','Interpreter','none');
            end
            continue;
        end
        caption=C.conditionName+" (n="+S.nNeurons+")";
        ax=nexttile(forLayout); hold(ax,'on'); palette=lines(numel(C.psthTrials)); handles=gobjects(numel(C.psthTrials),1);
        for j=1:numel(C.psthTrials)
            handles(j)=trace(ax,time,S.displayPsth(:,j),S.displayPsthSEM(:,j),palette(j,:));
        end
        title(ax,caption+": individual trials",'Interpreter','none');
        xlabel(ax,'Time (s)'); ylabel(ax,'Mean activity');
        limitTime(ax);
        if ~isempty(handles), legend(ax,handles,cellstr("Trial "+string(C.psthTrials)),'Location','best'); end
        ax=nexttile(forLayout); hold(ax,'on'); palette=lines(2);
        h1=trace(ax,time,S.startPsth,S.startSEM,palette(1,:));
        h2=trace(ax,time,S.endPsth,S.endSEM,palette(2,:));
        title(ax,caption+": start vs end",'Interpreter','none');
        xlabel(ax,'Time (s)'); ylabel(ax,'Mean activity');
        limitTime(ax);
        starts=C.animalAudit.startTrials(C.animalAudit.included);
        ends=C.animalAudit.endTrials(C.animalAudit.included);
        legend(ax,[h1 h2],{rangeLabel('Start',starts),rangeLabel('End',ends)},'Location','best');
        ax=nexttile(forLayout); imagesc(ax,time,1:size(heatmaps{c},2),heatmaps{c}');
        if all(isfinite(colorRange))&&diff(colorRange)>0, caxis(ax,colorRange); end
        if strcmp(p.heatmapMethod,'bin')
            yticks(ax,1:numel(heatLabels{c})); yticklabels(ax,heatLabels{c});
        end
        colorbar(ax); xlabel(ax,'Time (s)'); ylabel(ax,'Within-condition trial');
        limitTime(ax);
        title(ax,caption+": first "+C.nProgressionTrials+" ("+string(p.heatmapMethod)+")",'Interpreter','none');
        ax=nexttile(forLayout); hold(ax,'on');
        trace(ax,1:C.nProgressionTrials,S.progression,S.progressionSEM,[0.15 0.35 0.65]);
        xlabel(ax,'Within-condition trial'); ylabel(ax,'Mean activity in scoring window');
        title(ax,sprintf('%s: %.3g to %.3g s',C.conditionName,time(r.scoreBins(1)),time(r.scoreBins(end))), ...
            'Interpreter','none');
    end
    set(findall(fig,'Type','axes'),'FontSize',9);
    finish(fig,scopeKey('allNeurons'));
end
    function key=scopeKey(base)
        key=base;
        if animalScope>0, key=sprintf('animal%d_%s',animalScope,base); end
    end
    function limitTime(ax)
        if isfield(r.cfg,'timeWindow')&&~isempty(r.cfg.timeWindow)&&diff(r.cfg.timeWindow)>0
            xlim(ax,r.cfg.timeWindow); % Prevent automatic padding outside the requested window.
        end
    end
    function h=trace(ax,x,mu,se,color)
        x=reshape(x,1,[]); mu=reshape(mu,1,[]); se=reshape(se,1,[]);
        if p.showSEM&&all(isfinite(se))
            fill(ax,[x fliplr(x)],[mu-se fliplr(mu+se)],color, ...
                'FaceAlpha',0.15,'EdgeColor','none','HandleVisibility','off');
        end
        h=plot(ax,x,mu,'Color',color,'LineWidth',1.4);
    end
    function finish(fig,key)
        if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
        if ~isempty(p.savePath)
            if ~isfolder(p.savePath), mkdir(p.savePath); end
            file=fullfile(p.savePath,[prefix '_' key '.png']);
            exportgraphics(fig,file,'Resolution',150); files.(key)=file;
        end
        if p.visible, figures.(key)=fig; else, figures.(key)=[]; end
    end
end

function [H,labels]=heatmapData(X,p)
% Process only the displayed trial axis; scoring and comparison PSTHs stay raw.
nr=size(X,2); labels=strings(0,1);
switch p.heatmapMethod
    case 'bin'
        starts=1:p.heatmapWindow:nr; H=zeros(size(X,1),numel(starts));
        for j=1:numel(starts)
            stop=min(nr,starts(j)+p.heatmapWindow-1);
            H(:,j)=mean(X(:,starts(j):stop),2);
            labels(j)=string(starts(j))+"-"+stop;
        end
    case 'smooth'
        H=movmean(X,p.heatmapWindow,2,'Endpoints','shrink');
    case 'none'
        H=X;
end
end

function label=rangeLabel(prefix,sets)
if isempty(sets), label=prefix; return; end
same=all(cellfun(@(x)isequal(x,sets{1}),sets));
if same
    label=sprintf('%s: trials %s',prefix,mat2str(sets{1}));
else
    label=[prefix ': animal-specific indices (see audit)'];
end
end
