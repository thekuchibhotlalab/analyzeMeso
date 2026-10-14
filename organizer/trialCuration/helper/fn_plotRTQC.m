function fig = fn_plotRTQC(selection,cfg)
%FN_PLOTRTQC Six columns, ordered by training phase without changing selections.
nCond=numel(selection);
nCol=6;
[plotOrder,tileIndex,nRow]=fn_learningLayout(selection,nCol);

fig=figure('Color','w','Name','RT QC','Position',[50 50 1500 260*nRow]);
tiledlayout(nRow,nCol,'TileSpacing','compact','Padding','compact');

allRT=[];
for k=1:nCond
    allRT=[allRT;selection(k).trialsBeforeRT.RT]; %#ok<AGROW>
end
allRT=allRT(isfinite(allRT));

if isempty(allRT)
    xLimits=[0 1];
else
    q=prctile(allRT,[1 99]);
    if q(1)==q(2), xLimits=[q(1)-0.1 q(2)+0.1]; else, xLimits=q; end
end

for i=1:nCond
    k=plotOrder(i);
    nexttile(tileIndex(i));
    rt=selection(k).trialsBeforeRT.RT;
    rt=rt(isfinite(rt));
    if ~isempty(rt), histogram(rt,30,'Normalization','probability'); end
    hold on;
    xline(cfg.RTRange(1),'--');
    xline(cfg.RTRange(2),'--');
    xlim(xLimits);
    title(selection(k).name,'Interpreter','none');
    xlabel('RT (s)');
    ylabel('Probability');
end
sgtitle('RT distributions before filtering');
end

function [order,tiles,nRow]=fn_learningLayout(selection,nCol)
% Start T1, T2, retraining and Int on separate rows. More than six conditions
% in a group continue on the next row. Preserve input order within each phase.
phases=["T1E","T1M","T1L","T2E","T2M","T2L","T1R","Int"];
phaseGroup=[1 1 1 2 2 2 3 4];
n=numel(selection);
group=5*ones(n,1); phase=inf(n,1);
for k=1:n
    if isfield(selection(k),'definition') && isfield(selection(k).definition,'dayLabels')
        labels=string(selection(k).definition.dayLabels);
        hits=find(ismember(lower(phases),lower(strtrim(labels))));
        if ~isempty(hits)
            phase(k)=hits(1); % Pooled conditions use their earliest known phase.
            group(k)=phaseGroup(hits(1));
        end
    end
end
[~,order]=sortrows([group,phase,(1:n)'],[1 2 3]);
tiles=zeros(n,1); rowsUsed=0;
for g=unique(group(order))'
    positions=find(group(order)==g);
    tiles(positions)=rowsUsed*nCol+(1:numel(positions))';
    rowsUsed=rowsUsed+ceil(numel(positions)/nCol);
end
nRow=max(1,rowsUsed);
end
