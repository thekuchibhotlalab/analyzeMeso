function [figures,files]=fn_plotLearningChoiceAxes(result,p)
%FN_PLOTLEARNINGCHOICEAXES Group SEM uses animals; individual SEM uses repeats.
figures=struct(); files=struct(); if ~p.makePlot, return; end
animals=result.animals; na=numel(animals); n=max(cellfun(@(a)height(a.windows),animals));
acc=nan(n,2,na); cosine=nan(n,na); drift=acc; rows=cell(na,1);
for a=1:na
    r=animals{a}; nb=height(r.windows); acc(1:nb,:,a)=r.accuracy;
    cosine(1:nb,a)=r.cosine; drift(1:nb,:,a)=r.cosineToReference;
    rows{a}=table(repmat(r.animalID,nb,1),r.windows.period,r.windows.bin, ...
        r.accuracy(:,1),r.accuracy(:,2),r.cosine,r.angleDegrees, ...
        r.counts(:,1),r.counts(:,2),r.counts(:,3),r.counts(:,4),r.status, ...
        'VariableNames',{'animal','period','bin','accuracyT1','accuracyT2','cosine','angleDegrees', ...
        'nT1L','nT1R','nT2L','nT2R','status'});
end
if exist('multitaskColors','file')==2
    colors=[multitaskColors('T1');multitaskColors('T2')];
else
    colors=[84 135 186;222 153 84]/255;
end
visibility='off'; if p.visible, visibility='on'; end
if ~isempty(p.savePath)&&~isfolder(p.savePath), mkdir(p.savePath); end
f=figure('Color','w','Visible',visibility,'Position',[100 100 1050 720]);
layout=tiledlayout(f,2,2,'TileSpacing','compact');
ax=nexttile(layout); hold(ax,'on');
for task=1:2
    [mu,se]=stats(reshape(acc(:,task,:),n,na)); band(ax,mu,se,colors(task,:),"T"+task);
end
yline(ax,.5,':','HandleVisibility','off'); ylim(ax,[0 1]); ylabel(ax,'Held-out balanced accuracy'); legend(ax,'Location','best'); decorate(ax,n);
ax=nexttile(layout); hold(ax,'on'); [mu,se]=stats(cosine); band(ax,mu,se,[.25 .25 .25],'T1 vs T2');
ylim(ax,[-1 1]); yline(ax,0,':','HandleVisibility','off'); ylabel(ax,'T1/T2 choice-axis cosine'); decorate(ax,n);
ax=nexttile(layout); hold(ax,'on');
for task=1:2
    [mu,se]=stats(reshape(drift(:,task,:),n,na)); band(ax,mu,se,colors(task,:),"T"+task);
end
ylim(ax,[-1 1]); ylabel(ax,'Cosine to first valid bin for each task'); legend(ax,'Location','best'); decorate(ax,n);
ax=nexttile(layout); stairs(ax,1:n,sum(isfinite(cosine),2),'k','LineWidth',1.5);
ylim(ax,[0 na+.5]); yticks(ax,0:na); ylabel(ax,'Animals with both choice axes'); decorate(ax,n);
title(layout,sprintf('%s choice axes | group mean +/- between-animal SEM',upper(result.cfg.decoder)));
finish(f,'group');
for a=1:na
    r=animals{a}; nb=height(r.windows);
    f=figure('Color','w','Visible',visibility,'Position',[120 100 1150 340]);
    layout=tiledlayout(f,1,3,'TileSpacing','compact');
    ax=nexttile(layout); hold(ax,'on');
    for task=1:2, band(ax,r.accuracy(:,task),r.accuracySEM(:,task),colors(task,:),"T"+task); end
    yline(ax,.5,':','HandleVisibility','off'); ylim(ax,[0 1]); ylabel(ax,'Held-out balanced accuracy'); legend(ax,'Location','best'); decorate(ax,nb);
    ax=nexttile(layout); hold(ax,'on'); band(ax,r.cosine,r.cosineSEM,[.25 .25 .25],'T1 vs T2');
    ylim(ax,[-1 1]); yline(ax,0,':','HandleVisibility','off'); ylabel(ax,'T1/T2 choice-axis cosine'); decorate(ax,nb);
    ax=nexttile(layout); hold(ax,'on');
    for k=1:4
        style='-'; if mod(k,2)==0, style='--'; end
        plot(ax,1:nb,r.counts(:,k),'Color',colors(ceil(k/2),:),'LineStyle',style,'LineWidth',1.3);
    end
    ylabel(ax,'Available trials before class balancing'); legend(ax,{'T1 L','T1 R','T2 L','T2 R'},'Location','best'); decorate(ax,nb);
    title(layout,sprintf('%s | %d common neurons | mean +/- CV-repeat SEM',r.animalID,numel(r.neuronIDs)),'Interpreter','none');
    finish(f,sprintf('animal%d_%s',a,matlab.lang.makeValidName(char(r.animalID))));
end
if ~isempty(p.savePath)
    writetable(vertcat(rows{:}),fullfile(p.savePath,[p.prefix '_summary.csv']));
end
    function decorate(ax,nb)
        boundary=result.cfg.nT2Bins+.5;
        xline(ax,boundary,':','Int start','HandleVisibility','off');
        xlim(ax,[.5 nb+.5]);
        ticks=unique([1: max(1,ceil(nb/10)):nb,result.cfg.nT2Bins,result.cfg.nT2Bins+1,nb]);
        ticks=ticks(ticks>=1&ticks<=nb); labels=strings(size(ticks));
        for j=1:numel(ticks)
            if ticks(j)<=result.cfg.nT2Bins, labels(j)="T2 "+ticks(j);
            else, labels(j)="Int "+(ticks(j)-result.cfg.nT2Bins); end
        end
        xticks(ax,ticks); xticklabels(ax,labels); xtickangle(ax,35);
        set(ax,'TickDir','out','Box','off','FontName','Arial','FontSize',9);
    end
    function finish(fig,key)
        if ~p.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
        if ~isempty(p.savePath)
            stem=fullfile(p.savePath,[p.prefix '_' key]);
            exportgraphics(fig,[stem '.png'],'Resolution',150); savefig(fig,[stem '.fig']);
            files.(key)=struct('png',[stem '.png'],'fig',[stem '.fig']);
        end
        if p.visible, figures.(key)=fig; else, figures.(key)=[]; end
    end
end
function band(ax,mu,se,color,label)
x=(1:numel(mu))'; valid=isfinite(mu)&isfinite(se);
% Separate finite runs so missing bins never become connected confidence bands.
edges=diff([false;valid;false]); starts=find(edges==1); stops=find(edges==-1)-1;
for k=1:numel(starts)
    ii=starts(k):stops(k); xx=x(ii); lo=mu(ii)-se(ii); hi=mu(ii)+se(ii);
    fill(ax,[xx;flipud(xx)],[lo;flipud(hi)],color,'FaceAlpha',.18,'EdgeColor','none','HandleVisibility','off');
end
plot(ax,x,mu,'Color',color,'LineWidth',1.5,'DisplayName',label);
end
function [mu,se]=stats(X)
n=sum(isfinite(X),2); mu=mean(X,2,'omitnan'); se=std(X,0,2,'omitnan')./sqrt(n); se(n<2)=NaN;
end
