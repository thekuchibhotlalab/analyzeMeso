function [figures,files]=fn_plotChoiceBiasGeometry(r,p)
%FN_PLOTCHOICEBIASGEOMETRY Trial overlays and block-level bias relationships.
[~,d]=fn_choiceBiasGeometryConfig(); if nargin<2, p=struct(); end
assert(isempty(setdiff(fieldnames(p),fieldnames(d))),'choiceBias:Plot','Unknown plot option.');
for key=fieldnames(d)', if ~isfield(p,key{1}), p.(key{1})=d.(key{1}); end, end
figures=struct(); files=struct(); if ~p.makePlot, return; end
visible='off'; if p.visible, visible='on'; end
if ~isempty(p.savePath)&&~isfolder(p.savePath), mkdir(p.savePath); end
cfg=r.cfg; frames={r.preFrameIndices,r.choiceFrameIndices}; events=[cfg.choiceFrame cfg.choiceFrame];
periodNames={'Pre-trial ITI','Pre-choice'}; timeNames={'Time from choice (s)','Time from choice (s)'};
f=figure('Color','w','Visible',visible,'Position',[80 80 1100 720]); layout=tiledlayout(f,2,2,'TileSpacing','compact');
for task=1:2
    selected=r.entries([r.entries.task]==task);
    if isempty(selected), Y=[]; bias=[]; action=[];
    else
        Y=vertcat(selected.projection);
        % Animals can carry different optional trialInfo columns. Only pool
        % the two numeric variables used here; preserve each original table.
        biasParts=arrayfun(@(e)e.trialInfo.choiceBias,selected,'UniformOutput',false);
        actionParts=arrayfun(@(e)e.trialInfo.action,selected,'UniformOutput',false);
        bias=vertcat(biasParts{:}); action=vertcat(actionParts{:});
    end
    for period=1:2
        ax=nexttile(layout,(task-1)*2+period); hold(ax,'on'); handles=gobjects(0); labels={};
        t=(frames{period}-events(period))/cfg.frameRate;
        for biased=[false true]
            if biased, use=abs(bias)>cfg.biasedThreshold; state='Biased';
            else, use=abs(bias)<cfg.unbiasedThreshold; state='Unbiased'; end
            for side=1:2
                ids=use&action==side; if ~any(ids), continue; end
                sideName='L'; if side==2, sideName='R'; end
                color=multitaskColors(sideName); if ~biased, color=.4*color+.6; end
                traces=Y(ids,frames{period});
                if p.showTrials
                    plot(ax,t,traces','Color',.22*color+.78,'LineWidth',p.trialLineWidth,'HandleVisibility','off');
                end
                style='-'; if side==2, style='--'; end
                handles(end+1)=plot(ax,t,mean(traces,1,'omitnan'),'Color',color,'LineStyle',style,'LineWidth',2); %#ok<AGROW>
                labels{end+1}=sprintf('%s %s (n=%d)',state,sideName,sum(ids)); %#ok<AGROW>
            end
        end
        title(ax,sprintf('T%d | %s',task,periodNames{period})); xlabel(ax,timeNames{period});
        ylabel(ax,'Held-out choice-axis projection (noise SD)'); styleAxes(ax);
        xlim(ax,[t(1)-.02 t(end)+.02]);
        if ~isempty(handles), legend(ax,handles,labels,'Box','off','Location','best');
        else, text(ax,.5,.5,'No trials in these bias groups','Units','normalized','HorizontalAlignment','center'); end
    end
end
title(layout,{'Interleaved: biased versus unbiased trials', ...
    sprintf('|bias| > %.2f versus |bias| < %.2f; thin lines = trials, thick lines = trial-weighted means',cfg.biasedThreshold,cfg.unbiasedThreshold)});
finish(f,'projections');
f=figure('Color','w','Visible',visible,'Position',[100 100 1100 440]); layout=tiledlayout(f,1,2,'TileSpacing','compact');
fields={'preSeparation','choiceSeparation'};
for period=1:2
    ax=nexttile(layout); hold(ax,'on'); notes={};
    if ~isempty(r.bins)
        for task=1:2
            B=r.bins(r.bins.task==task,:); if isempty(B), continue; end
            x=B.bias; if cfg.biasMagnitude, x=abs(x); end
            y=B.(fields{period}); color=multitaskColors("T"+task);
            scatter(ax,x,y,24,color,'filled','MarkerFaceAlpha',.65,'DisplayName',sprintf('T%d',task));
            fit=r.regression([r.regression.task]==task&strcmp({r.regression.period},fields{period}));
            if isfinite(fit.slope)
                xx=[min(x) max(x)]; plot(ax,xx,fit.intercept+fit.slope*xx,'Color',color,'LineWidth',1.5,'HandleVisibility','off');
            end
            notes{end+1}=sprintf('T%d: slope %.3g, within-animal r %.2f; %d bins / %d animals', ...
                task,fit.slope,fit.withinAnimalR,fit.nBins,fit.nAnimals); %#ok<AGROW>
        end
        legend(ax,'Location','best','Box','off');
    end
    title(ax,periodNames{period}); ylabel(ax,'L - R projection separation (noise SD)');
    if cfg.biasMagnitude, xlabel(ax,'Absolute accuracy bias'); else, xlabel(ax,'Accuracy bias (L - R)'); end
    styleAxes(ax);
    if ~isempty(notes), text(ax,.02,.02,strjoin(notes,newline),'Units','normalized','VerticalAlignment','bottom','FontSize',8); end
end
title(layout,{'Bias and L/R separation: non-overlapping behavioral blocks', ...
    'Animal-adjusted descriptive regression; each dot = animal x task x block'});
finish(f,'correlations');
    function finish(fig,key)
        if ~isempty(p.savePath)
            stem=fullfile(p.savePath,[p.prefix '_' key]); exportgraphics(fig,[stem '.png'],'Resolution',180);
            fig.Visible='on'; savefig(fig,[stem '.fig']); files.(key)=struct('png',[stem '.png'],'fig',[stem '.fig']);
        end
        if p.visible, figures.(key)=fig; else, close(fig); figures.(key)=[]; end
    end
end
function styleAxes(ax)
set(ax,'TickDir','out','Box','off','XColor','k','YColor','k','FontName','Arial'); grid(ax,'off');
end
