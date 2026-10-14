function fig = fn_plotSessionAmplitudeQC(neuralSelection,visibility)
%FN_PLOTSESSIONAMPLITUDEQC Raw session-level neural scale check.
if nargin<2, visibility=get(groot,'DefaultFigureVisible'); end
Condition=strings(0,1);
MeanAbsActivity=zeros(0,1);

for k=1:numel(neuralSelection)
    T=neuralSelection(k).trialInfoNeural;
    X=neuralSelection(k).neuralRaw;
    if isempty(T) || isempty(X), continue; end

    rows=unique(T.sessionInfoRow,'stable');
    for r=rows'
        m=T.sessionInfoRow==r;
        Xi=X(:,:,m);
        Condition(end+1,1)=neuralSelection(k).name; %#ok<AGROW>
        MeanAbsActivity(end+1,1)=mean(abs(Xi(:)),'omitnan'); %#ok<AGROW>
    end
end

fig=figure('Color','w','Name','Session amplitude QC','Visible',visibility);

if isempty(Condition)
    title('No neural data available');
    return;
end

list=unique(Condition,'stable');
hold on;
for i=1:numel(list)
    m=Condition==list(i);
    scatter(repmat(i,sum(m),1),MeanAbsActivity(m),35,'filled');
end
xticks(1:numel(list));
xticklabels(list);
xtickangle(45);
ylabel('Mean absolute activity');
title('Raw neural amplitude by condition and contributing session');
box off;
end
