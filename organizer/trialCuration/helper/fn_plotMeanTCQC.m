function fig = fn_plotMeanTCQC(byCondition,cfg,visibility)
%FN_PLOTMEANTCQC Adds aligned event marker for easier sanity checking.
if nargin<3, visibility=get(groot,'DefaultFigureVisible'); end
names=fieldnames(byCondition);
nCond=numel(names);
nCol=3; nRow=ceil(nCond/nCol);

fig=figure('Color','w','Name','Mean neural TC QC','Visible',visibility);
tiledlayout(nRow,nCol,'TileSpacing','compact','Padding','compact');

for k=1:nCond
    nexttile;
    C=byCondition.(names{k});
    y=C.populationMeanTC;

    if ~isempty(y)
        plot(y,'LineWidth',1.5);
        hold on;
        if cfg.alignedEventFrame>=1 && cfg.alignedEventFrame<=numel(y)
            xline(cfg.alignedEventFrame,'--k',cfg.alignedEventName);
        end
    end

    title(names{k},'Interpreter','none');
    xlabel('Aligned frame');
    ylabel('Mean activity');
    box off;
end
sgtitle(sprintf('Population mean time-course QC | aligned to %s', ...
    cfg.alignedEventName));
end
