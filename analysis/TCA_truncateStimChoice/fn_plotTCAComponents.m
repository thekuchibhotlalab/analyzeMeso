function [result,figures]=fn_plotTCAComponents(ppc,ac,opts)
%FN_PLOTTCACOMPONENTS Matched-region rows and within-region component groups.
% Inputs contain M (cell array of ktensors/structs) and optional VEpct.
% L1-normalize factor columns and absorb their scale into lambda.
if nargin<2, ac=[]; end
if nargin<3, opts=struct(); end
defaults=struct('ppcModel',7,'acModel',7,'ppcComponents',[5 6],'acComponents',[5 6], ...
    'ppcGroups',{{[5 6]}},'acGroups',{{[5 6]}},'visible',true,'savePath','', ...
    'showDiagnostics',true,'stimFrame',10,'choiceFrame',16,'fontSize',10, ...
    'rowHeight',225,'figureWidth',1250,'frameRate',15);
extra=setdiff(fieldnames(opts),fieldnames(defaults));
assert(isempty(extra),'TCAPlot:Options','Unknown options: %s',strjoin(extra,', '));
if ~isfield(opts,'ppcGroups')&&isfield(opts,'ppcComponents'), opts.ppcGroups={opts.ppcComponents}; end
if ~isfield(opts,'acGroups')&&isfield(opts,'acComponents'), opts.acGroups={opts.acComponents}; end
for key=fieldnames(defaults)'
    if ~isfield(opts,key{1}), opts.(key{1})=defaults.(key{1}); end
end
validateattributes(opts.visible,{'logical'},{'scalar'});
validateattributes(opts.showDiagnostics,{'logical'},{'scalar'});
validateattributes(opts.frameRate,{'numeric'},{'scalar','positive','finite'});
regions={canonical(ppc,opts.ppcModel,'PPC',opts.ppcComponents,opts.ppcGroups)};
if ~isempty(ac), regions{end+1}=canonical(ac,opts.acModel,'AC',opts.acComponents,opts.acGroups); end
nr=numel(regions); nrows=numel(regions{1}.selected);
if nr==2
    assert(numel(regions{2}.selected)==nrows,'TCAPlot:Matches','Provide one AC component for each selected PPC component.');
    assert(size(regions{1}.factors{2},1)==size(regions{2}.factors{2},1),'TCAPlot:Time','Matched models need the same temporal bins/alignment.');
end
result=struct('options',opts,'regions',{regions},'groups',struct(),'plotFiles',struct(), ...
    'normalization','Factor columns sum to one; scale absorbed into lambda. Relative weights are component mass fractions, not variance explained.', ...
    'timeNote','Cropped composite frames: stimulus 10, choice 16 by default; not continuous elapsed time.');
figures=struct(); visibility='off'; if opts.visible, visibility='on'; end
if ~isempty(opts.savePath)&&~isfolder(opts.savePath), mkdir(opts.savePath); end
if nrows>0
    [f,layout]=newFigure(nrows,'Matched TCA components');
    for row=1:nrows
        inner=tiledlayout(layout,nr,1,'TileSpacing','compact','Padding','compact');
        inner.Layout.Tile=(row-1)*5+1;
        for g=1:nr
            R=regions{g}; ax=nexttile(inner); drawWeights(ax,R,R.selected(row));
            if nr>1, ylabel(ax,'TC weight'); end
            title(ax,sprintf('%s: component %d',R.name,R.selected(row)),'FontWeight','normal');
        end
        for mode=2:5
            if mode==2
                Y=[]; colors=[];
                for g=1:nr
                    R=regions{g}; Y(:,g)=R.factors{2}(:,R.selected(row)); %#ok<AGROW>
                    colors(g,:)=R.color; %#ok<AGROW>
                end
                temporalPanel(layout,(row-1)*5+2,Y,colors,false);
                continue
            end
            ax=nexttile(layout,(row-1)*5+mode); hold(ax,'on'); h=gobjects(nr,1);
            for g=1:nr
                R=regions{g}; y=R.factors{mode}(:,R.selected(row));
                if mode==2
                    h(g)=plot(ax,1:numel(y),y,'Color',R.color,'LineWidth',1.8);
                else
                    h(g)=plot(ax,1:numel(y),y,'o','LineStyle','none','Color',R.color,'LineWidth',1.3, ...
                        'MarkerFaceColor','none','MarkerSize',5);
                end
            end
            factorAxes(ax,mode,false);
            if row==1&&mode==2, legend(ax,h,cellfun(@(r)r.name,regions,'UniformOutput',false),'Box','off','Location','best'); end
        end
    end
    title(layout,'Matched components | learning, action and task are separate factors','FontWeight','normal');
    finish(f,'matched');
end
for g=1:nr
    R=regions{g}; groups=R.groups; summaries=cell(numel(groups),1);
    if ~isempty(groups)
        [f,layout]=newFigure(numel(groups),[R.name ' grouped components']);
        for row=1:numel(groups)
            ids=groups{row}; ax=nexttile(layout,(row-1)*5+1); drawWeights(ax,R,ids);
            title(ax,[R.name ': ' strjoin(cellstr(string(ids)),', ')],'FontWeight','normal');
            group=struct('componentIDs',ids,'individualFactors',{cell(1,4)}, ...
                'meanFactors',{cell(1,4)},'preferredAction',[],'preferredTask',[]);
            for mode=2:5
                Y=R.factors{mode}(:,ids);
                if mode>=4
                    [Y,order]=sort(Y,1,'descend');
                    if mode==4, group.preferredAction=order(1,:); else, group.preferredTask=order(1,:); end
                    tied=abs(Y(1,:)-Y(2,:))<1e-12;
                    if mode==4, group.preferredAction(tied)=NaN; else, group.preferredTask(tied)=NaN; end
                end
                group.individualFactors{mode-1}=Y; group.meanFactors{mode-1}=mean(Y,2);
                if mode==2
                    temporalPanel(layout,(row-1)*5+2,Y,R.color,true);
                    continue
                end
                ax=nexttile(layout,(row-1)*5+mode); hold(ax,'on');
                plot(ax,1:size(Y,1),Y,'o','LineStyle','none','MarkerFaceColor','none', ...
                    'Color',[.75 .75 .75],'LineWidth',.8,'MarkerSize',4,'HandleVisibility','off');
                plot(ax,1:size(Y,1),mean(Y,2),'o','LineStyle','none','Color',R.color,'LineWidth',2, ...
                    'MarkerFaceColor','none','MarkerSize',5);
                factorAxes(ax,mode,true);
            end
            summaries{row}=group;
        end
        title(layout,[R.name ': selected factors in gray; equal-component mean in color'],'FontWeight','normal');
        finish(f,['groups_' R.name]);
    end
    result.groups.(R.name)=summaries;
    if opts.showDiagnostics
        f=figure('Color','w','Visible',visibility,'Position',[100 100 1250 310]);
        layout=tiledlayout(f,1,5,'TileSpacing','compact');
        labels={'Neuron','Composite frame','Learning phase','Action','Task'};
        for mode=1:5
            ax=nexttile(layout); imagesc(ax,R.factors{mode}'); colorbar(ax);
            xlabel(ax,labels{mode}); ylabel(ax,'Component ID'); title(ax,labels{mode}); styleAxes(ax);
            if mode==2
                xline(ax,opts.stimFrame,'--w'); xline(ax,opts.choiceFrame,'--w');
            elseif mode==3
                xticks(ax,1:4); xticklabels(ax,{'E','M','L','Int'});
            elseif mode==4
                xticks(ax,1:2); xticklabels(ax,{'L','R'});
            elseif mode==5
                xticks(ax,1:2); xticklabels(ax,{'T1','T2'});
            end
        end
        title(layout,sprintf('%s | model index %d | %d components',R.name,R.modelIndex,numel(R.lambda)));
        finish(f,['factors_' R.name]);
        f=figure('Color','w','Visible',visibility,'Position',[100 100 1000 300]);
        layout=tiledlayout(f,1,3);
        ax=nexttile(layout); drawWeights(ax,R,R.selected); title(ax,'Component weights');
        ax=nexttile(layout); imagesc(ax,corr(R.factors{1}),[-1 1]); colorbar(ax); styleAxes(ax);
        title(ax,'Neural-factor correlation'); xlabel(ax,'Component ID'); ylabel(ax,'Component ID');
        ax=nexttile(layout);
        if ~isempty(R.VEpct), plot(ax,1:numel(R.VEpct),R.VEpct,'o-','Color',R.color); end
        xlabel(ax,'Model index'); ylabel(ax,'Variance explained (%)'); styleAxes(ax);
        finish(f,['diagnostics_' R.name]);
    end
end
if ~isempty(opts.savePath), save(fullfile(opts.savePath,'tca_component_summary.mat'),'result'); end
    function [f,L]=newFigure(rows,name)
        f=figure('Name',name,'Color','w','Visible',visibility, ...
            'Position',[100 100 opts.figureWidth max(280,rows*opts.rowHeight+55)]);
        L=tiledlayout(f,rows,5,'TileSpacing','compact','Padding','compact');
    end
    function drawWeights(ax,R,selected)
        [weights,order]=sort(R.relativeWeight,'descend');
        b=bar(ax,1:numel(weights),weights,'FaceColor','flat','EdgeColor','none');
        colors=repmat([.80 .80 .80],numel(weights),1);
        colors(ismember(order,selected),:)=repmat(R.color,sum(ismember(order,selected)),1);
        b.CData=colors; xlim(ax,[.3 numel(weights)+.7]);
        xlabel(ax,'Components (weight rank)'); ylabel(ax,'Relative TC weight'); styleAxes(ax);
        ax.UserData=struct('componentIDsByRank',order,'highlightedComponentIDs',selected);
    end
    function temporalPanel(parent,tile,Y,colors,grouped)
        % The composite joins stim +2 to choice -3; never connect this gap.
        lastStim=opts.stimFrame+2; nt=size(Y,1);
        assert(lastStim>=1&&lastStim<nt&&opts.choiceFrame>lastStim&&opts.choiceFrame<=nt, ...
            'TCAPlot:Time','Stimulus +2 and choice onset must lie in their respective segments.');
          % One layout column per frame, plus two blank columns at the join.
          % Segment widths and x ranges are proportional: identical seconds/pixel.
          L=tiledlayout(parent,1,nt+2,'TileSpacing','none','Padding','compact');
        L.Layout.Tile=tile;
        title(L,'Within-trial dynamics','FontWeight','normal','FontSize',opts.fontSize);
        segments={1:lastStim,lastStim+1:nt}; anchors=[opts.stimFrame opts.choiceFrame];
        names={'Stim','Choice'};
        peak=max(Y,[],'all'); if peak==0, peak=1; end
        for s=1:2
              idx=segments{s};
              startTile=1; if s==2, startTile=lastStim+3; end
              ax=nexttile(L,startTile,[1 numel(idx)]); hold(ax,'on');
              x=(idx-anchors(s))/opts.frameRate;
            if grouped
                plot(ax,x,Y(idx,:),'Color',[.75 .75 .75],'LineWidth',.8);
                plot(ax,x,mean(Y(idx,:),2),'Color',colors,'LineWidth',2);
            else
                for k=1:size(Y,2)
                    plot(ax,x,Y(idx,k),'Color',colors(k,:),'LineWidth',1.8);
                end
            end
              ylim(ax,[0 peak*1.12]);
              xlim(ax,[x(1)-.5/opts.frameRate x(end)+.5/opts.frameRate]);
            xline(ax,0,':','Color',[.6 .6 .6],'HandleVisibility','off');
            text(ax,0,peak*1.08,names{s},'HorizontalAlignment','center', ...
                'VerticalAlignment','top','FontSize',opts.fontSize-1);
              styleAxes(ax); ax.YAxis.Visible='off';
              % Each segment has its own event-relative time axis in seconds.
              ticks=(ceil(x(1)/.5):floor(x(end)/.5))*.5;
              xticks(ax,unique([ticks 0]));
              if s==1, xlabel(ax,{'Time from','stimulus (s)'});
              else, xlabel(ax,{'Time from','choice (s)'}); end
              set(ax,'LooseInset',[0 0 0 0]);
            ax.Tag=['temporal_' lower(names{s})];
              ax.UserData=struct('sourceFrames',idx,'eventFrame',anchors(s), ...
                  'timeSeconds',x,'frameRate',opts.frameRate);
        end
    end
    function factorAxes(ax,mode,preferred)
        styleAxes(ax); ylabel(ax,'Normalized factor');
        switch mode
            case 2
                title(ax,'Within-trial dynamics','FontWeight','normal');
                nt=size(regions{1}.factors{2},1);
                xlim(ax,[1 nt]); xlabel(ax,'Composite frame');
                xline(ax,opts.stimFrame,':','Stim','HandleVisibility','off');
                xline(ax,opts.choiceFrame,':','Choice','HandleVisibility','off');
            case 3
                title(ax,'Learning factor','FontWeight','normal'); xlim(ax,[.5 4.5]);
                xticks(ax,1:4); xticklabels(ax,{'E','M','L','Int'}); ylim(ax,[0 1.05]);
            otherwise
                names={'Action factor','Task factor'}; title(ax,names{mode-3},'FontWeight','normal');
                xlim(ax,[.65 2.35]); xticks(ax,1:2); ylim(ax,[0 1.05]);
                if preferred, xticklabels(ax,{'Preferred','Unpreferred'});
                elseif mode==4, xticklabels(ax,{'L','R'});
                else, xticklabels(ax,{'T1','T2'}); end
        end
    end
    function styleAxes(ax)
        set(ax,'Box','off','TickDir','out','FontName','Arial','FontSize',opts.fontSize);
    end
    function finish(fig,key)
        if ~opts.visible, cleanup=onCleanup(@()close(fig)); end %#ok<NASGU>
        if ~isempty(opts.savePath)
            stem=fullfile(opts.savePath,['tca_' key]);
            exportgraphics(fig,[stem '.png'],'Resolution',180);
            % Save visible so reopening a FIG does not leave it hidden.
            set(fig,'Visible','on'); savefig(fig,[stem '.fig']);
            if ~opts.visible, set(fig,'Visible','off'); end
            result.plotFiles.(key)=struct('png',[stem '.png'],'fig',[stem '.fig']);
        end
        if opts.visible, figures.(key)=fig; else, figures.(key)=[]; end
    end
end
function R=canonical(data,index,name,selected,groups)
assert(isstruct(data)&&isfield(data,'M')&&iscell(data.M),'TCAPlot:Model','Input must contain a cell array M.');
validateattributes(index,{'numeric'},{'scalar','integer','>=',1,'<=',numel(data.M)});
m=data.M{index};
if isstruct(m)&&isfield(m,'u'), U=m.u; else, U=m.U; end
lambda=double(m.lambda(:)); rank=numel(lambda);
assert(numel(U)==5&&size(U{3},1)==4&&size(U{4},1)==2&&size(U{5},1)==2, ...
    'TCAPlot:Modes','Expected neuron x time x learning(4) x action(2) x task(2).');
assert(all(isfinite(lambda)&lambda>=0),'TCAPlot:Nonnegative','Weights must be finite and nonnegative.');
for mode=1:5
    u=double(U{mode});
    assert(size(u,2)==rank&&all(isfinite(u)&u>=0,'all'),'TCAPlot:Nonnegative','Factors must be finite and nonnegative with matching ranks.');
    scale=sum(u,1); lambda=lambda.*scale'; scale(scale==0)=1; U{mode}=u./scale;
end
checkIDs(selected,rank); selected=reshape(selected,1,[]);
assert(iscell(groups),'TCAPlot:Groups','Groups must be a cell array, one component list per row.');
for k=1:numel(groups)
    checkIDs(groups{k},rank); assert(~isempty(groups{k}),'TCAPlot:Groups','Component groups cannot be empty.');
    groups{k}=reshape(groups{k},1,[]);
end
weight=lambda; if sum(weight)>0, weight=weight/sum(weight); end
ve=[]; if isfield(data,'VEpct'), ve=data.VEpct; end
R=struct('name',name,'modelIndex',index,'selected',selected,'groups',{groups}, ...
    'factors',{U},'lambda',lambda,'relativeWeight',weight,'VEpct',ve,'color',multitaskColors(name));
end
function checkIDs(ids,rank)
if isempty(ids), return; end
validateattributes(ids,{'numeric'},{'vector','integer','>=',1,'<=',rank,'finite'});
assert(numel(unique(ids))==numel(ids),'TCAPlot:Components','Component IDs must not repeat within a list.');
end
