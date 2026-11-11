function plan=fn_learningTrialWindows(T,cfg)
%FN_LEARNINGTRIALWINDOWS Define anchors BEFORE behavioral/session filtering.
% TrialInfo row order is the behavioral clock; no compression of excluded trials.
assert(istable(T)&&all(ismember({'dayLabel','date','stimuli'},T.Properties.VariableNames)), ...
    'learningAxes:Metadata','trialInfo requires dayLabel, date, and stimuli.');
validateattributes(cfg.nT2Bins,{'numeric'},{'scalar','integer','positive'});
validateattributes(cfg.windowWidthChunks,{'numeric'},{'scalar','finite','>=',1});
assert(issorted(T.date),'learningAxes:Order','trialInfo must be chronological; do not reorder neural provenance independently.');
day=lower(strtrim(string(T.dayLabel))); n=height(T); idx=(1:n)';
t2=find(day==lower(string(cfg.t2AnchorLabel)),1);
inter=find(day==lower(string(cfg.intAnchorLabel)),1);
assert(~isempty(t2)&&~isempty(inter)&&inter>t2,'learningAxes:Anchors','Need T2E followed by Int in full trialInfo.');
width=(inter-t2)/cfg.nT2Bins;
assert(width>=1,'learningAxes:Bins','More T2 bins than available behavioral trials.');
eligible=ismember(day,lower(string(cfg.dayLabels)));
prior=find(idx<t2 & day==lower(string(cfg.preTrainingLabel)) & ismember(T.stimuli,[1 2]));
assert(~isempty(prior),'learningAxes:PriorDay','No preceding T1L trials found for the first T2 window.');
prior=prior(T.date(prior)==max(T.date(prior)));
last=find(eligible&idx>=inter,1,'last');
assert(~isempty(last),'learningAxes:Anchors','No eligible interleaved-period trials.');
nInt=ceil((last-inter+1)/width); count=cfg.nT2Bins+nInt;
period=[repmat("T2",cfg.nT2Bins,1);repmat("Int",nInt,1)];
bin=[(1:cfg.nT2Bins)';(1:nInt)'];
start=zeros(count,1); stop=start; center=start; trials=cell(count,1);
for b=1:count
    if period(b)=="T2", anchor=t2; endpoint=inter; else, anchor=inter; endpoint=last+1; end
    center(b)=anchor+(bin(b)-.5)*width;
    start(b)=max(anchor,center(b)-cfg.windowWidthChunks*width/2);
    stop(b)=min(endpoint,center(b)+cfg.windowWidthChunks*width/2);
    trials{b}=find(eligible&idx>=start(b)&idx<stop(b));
    if b==1, trials{b}=unique([prior;trials{b}],'sorted'); end
end
windows=table(period,bin,start,stop,center,trials, ...
    'VariableNames',{'period','bin','startTrial','endTrialExclusive','centerTrial','sourceTrialRows'});
plan=struct('windows',windows,'t2AnchorRow',t2,'intAnchorRow',inter, ...
    'chunkWidthTrials',width,'priorT1Rows',prior,'priorT1Date',T.date(prior(1)), ...
    'eligibleRows',unique(vertcat(trials{:})),'clock','Full trialInfo row order before filters');
for field={'nT2Bins','windowWidthChunks','t2AnchorLabel','intAnchorLabel','preTrainingLabel','dayLabels'}
    plan.binningConfig.(field{1})=cfg.(field{1});
end
end
