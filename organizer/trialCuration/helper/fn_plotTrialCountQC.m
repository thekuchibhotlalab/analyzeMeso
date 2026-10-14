function fig = fn_plotTrialCountQC(qc,cfg,visibility)
if nargin<3, visibility=get(groot,'DefaultFigureVisible'); end
fig=figure('Color','w','Name','Trial-count QC','Visible',visibility);
bar([qc.NBeforeRT qc.NAfterRT qc.NAfterSessionSelection qc.NNeural]);
hold on;
yline(cfg.minTrials,'--','minimum trials');
xticks(1:height(qc));
xticklabels(qc.Condition);
xtickangle(45);
ylabel('Number of trials');
legend({'Before RT','After RT','Selected sessions','With neural data'},'Location','best');
title('Trial-count QC');
box off;
end
