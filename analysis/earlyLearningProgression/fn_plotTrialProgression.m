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
prefix=char(p.prefix);
assert(~isempty(prefix)&&~contains(prefix,{'/','\'}),'trialProgression:PlotConfig','prefix must be a filename prefix.');
visibility='off'; if p.visible, visibility='on'; end
nc=numel(r.byCondition); time=reshape(r.time,1,[]);
fields={'allPopulation','selectedPopulation'}; keys={'allNeurons','selectedNeurons'};
headings={'All pooled neurons',['Selected neurons: ' char(r.cfg.selectionMethod)]};
for population=1:2
    fig=figure('Name',headings{population},'Color','w','Visible',visibility, ...
        'Position',[40 40 1650 max(400,330*nc)]);
    forLayout=tiledlayout(fig,nc,4,'TileSpacing','compact','Padding','compact');
    title(forLayout,{headings{population},'Trial order is within condition/animal; shading = descriptive SEM across neurons'});
    for c=1:nc
        C=r.byCondition(c); S=C.(fields{population});
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
        if ~isempty(handles), legend(ax,handles,cellstr("Trial "+string(C.psthTrials)),'Location','best'); end
        ax=nexttile(forLayout); hold(ax,'on'); palette=lines(2);
        h1=trace(ax,time,S.startPsth,S.startSEM,palette(1,:));
        h2=trace(ax,time,S.endPsth,S.endSEM,palette(2,:));
        title(ax,caption+": start vs end",'Interpreter','none');
        xlabel(ax,'Time (s)'); ylabel(ax,'Mean activity');
        starts=C.animalAudit.startTrials(C.animalAudit.included);
        ends=C.animalAudit.endTrials(C.animalAudit.included);
        legend(ax,[h1 h2],{rangeLabel('Start',starts),rangeLabel('End',ends)},'Location','best');
        ax=nexttile(forLayout); imagesc(ax,time,1:C.nProgressionTrials,S.trialPsth');
        colorbar(ax); xlabel(ax,'Time (s)'); ylabel(ax,'Within-condition trial');
        title(ax,caption+": first "+C.nProgressionTrials,'Interpreter','none');
        ax=nexttile(forLayout); hold(ax,'on');
        trace(ax,1:C.nProgressionTrials,S.progression,S.progressionSEM,[0.15 0.35 0.65]);
        xlabel(ax,'Within-condition trial'); ylabel(ax,'Mean activity in scoring window');
        title(ax,sprintf('%s: %.3g to %.3g s',C.conditionName,time(r.scoreBins(1)),time(r.scoreBins(end))), ...
            'Interpreter','none');
    end
    set(findall(fig,'Type','axes'),'FontSize',9);
    finish(fig,keys{population});
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

function label=rangeLabel(prefix,sets)
if isempty(sets), label=prefix; return; end
same=all(cellfun(@(x)isequal(x,sets{1}),sets));
if same
    label=sprintf('%s: trials %s',prefix,mat2str(sets{1}));
else
    label=[prefix ': animal-specific indices (see audit)'];
end
end
