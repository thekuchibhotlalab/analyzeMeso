function fig = fn_plotTrackingQC(tracking,visibility)
%FN_PLOTTRACKINGQC Plot the saved ranking curve without rerunning tracking.
if nargin<2, visibility=get(groot,'DefaultFigureVisible'); end
fig=figure('Color','w','Name','Session tracking QC','Visible',visibility);
layout=tiledlayout(fig,2,1,'TileSpacing','compact');
C=tracking.curve;
ax=nexttile(layout);
plot(ax,C.nSessions,C.nTrackedNeurons,'-o','LineWidth',1.5);
xlabel(ax,'Sessions taken (selection order)');
ylabel(ax,'Common tracked neurons');
grid(ax,'on');
if isfield(tracking,'method')
    title(ax,['Selection method: ' char(tracking.method)],'Interpreter','none');
else
    title(ax,'Cumulative tracking across selected sessions');
end
fn_markSelection(ax,tracking);
ax=nexttile(layout);
plot(ax,C.nSessions,C.nTrials,'-o','LineWidth',1.5);
xlabel(ax,'Sessions taken (same ordering)');
ylabel(ax,'Unique selected trials');
grid(ax,'on');
fn_markSelection(ax,tracking);
end

function fn_markSelection(ax,tracking)
if isfield(tracking,'numSessionsSelected')
    xline(ax,tracking.numSessionsSelected,'--r','Selected', ...
        'Tag','TrialSelectionPrefix');
end
end
