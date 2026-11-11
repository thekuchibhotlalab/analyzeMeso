function [result,figures]=fn_analyzeLearningChoiceAxes(curated,cfg,plotCfg)
%FN_ANALYZELEARNINGCHOICEAXES Per-animal T1/T2 choice axes in overlapping bins.
% No pseudo-trial pairing or cross-animal axes. Common neuron rows across bins.
[defaults,defaultPlots]=fn_learningChoiceAxesConfig();
if nargin<2, cfg=defaults; else, cfg=fill(cfg,defaults); end
if nargin<3, plotCfg=defaultPlots; else, plotCfg=fill(plotCfg,defaultPlots); end
cfg.decoder=validatestring(cfg.decoder,{'lda','svm'});
validateattributes(cfg.folds,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.repeats,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.minTrialsPerClass,{'numeric'},{'scalar','integer','>=',2});
validateattributes(cfg.seed,{'numeric'},{'scalar','integer','nonnegative'});
validateattributes(cfg.ldaRidge,{'numeric'},{'scalar','positive','finite'});
validateattributes(cfg.svmBoxConstraint,{'numeric'},{'scalar','positive','finite'});
assert(isequal(cfg.choiceOffsets,-3:-1)&&cfg.frameRate==15,'learningAxes:ChoiceWindow', ...
    'This analysis uses the existing -3:-1 frames (200 ms at 15 Hz) choice window.');
if ~iscell(curated), curated={curated}; end
na=numel(curated); animals=cell(na,1); stream=RandStream('mt19937ar','Seed',cfg.seed);
for a=1:na
    c=curated{a};
    assert(c.neuralLoaded&&isfield(c,'learningPlan'),'learningAxes:Input','Use fn_prepareLearningChoiceData first.');
    plan=c.learningPlan; W=plan.windows;
    for key=fieldnames(plan.binningConfig)'
        assert(isequal(cfg.(key{1}),plan.binningConfig.(key{1})),'learningAxes:Bins', ...
            'Reprepare data after changing binning option %s.',key{1});
    end
    assert(sum(W.period=="T2")==cfg.nT2Bins,'learningAxes:Bins','Reprepare data after changing bin settings.');
    assert(isfield(c.tracking,'selectedNeuronMask'),'learningAxes:Tracking','Common tracked-neuron mask is required.');
    ids=find(c.tracking.selectedNeuronMask); assert(~isempty(ids),'learningAxes:Tracking','No tracked neurons.');
    field=lower(string(c.cfg.neuralField));
    if field=="dffchoice"
        frames=31+cfg.choiceOffsets;
    elseif field=="dffstimchoice"
        assert(isfield(c,'neuralAlignment')&&isfield(c.neuralAlignment,'choicePreFrames'), ...
            'learningAxes:Alignment','Composite data must have explicit choice pre-frame metadata.');
        frames=c.neuralAlignment.choicePreFrames;
        assert(numel(frames)==3,'learningAxes:Alignment','Composite must retain all three strictly pre-choice frames.');
    else
        error('learningAxes:Alignment','Use dffChoice or dffStimChoice.');
    end
    features={}; metadata={};
    for k=1:numel(c.neuralSelection)
        s=c.neuralSelection(k); if isempty(s.neuralRaw), continue; end
        assert(max(frames)<=size(s.neuralRaw,2),'learningAxes:Frames','Requested choice frames are absent.');
        features{end+1}=reshape(mean(double(s.neuralRaw(ids,frames,:)),2),numel(ids),[])'; %#ok<AGROW>
        metadata{end+1}=s.trialInfoNeural; %#ok<AGROW>
    end
    assert(~isempty(features),'learningAxes:Input','No loaded neural trials.');
    X=vertcat(features{:}); T=vertcat(metadata{:});
    [~,uniqueRows]=unique(T.sourceTrialRow,'stable'); X=X(uniqueRows,:); T=T(uniqueRows,:);
    % Drop invalid trials rather than changing neuron sets between windows.
    finite=all(isfinite(X),2); invalidRows=T.sourceTrialRow(~finite);
    X=X(finite,:); T=T(finite,:);
    task=1+ismember(T.stimuli,[3 4]); action=2*(T.action==2)-1;
    nb=height(W); nr=cfg.repeats; F=cfg.folds;
    accuracy=nan(nb,2,nr); axesByRepeat=nan(numel(ids),2,nb,nr);
    counts=zeros(nb,4); balanced=zeros(nb,2); status=repmat("insufficient trials",nb,1);
    trialRows=cell(nb,2,nr); foldAssignments=trialRows;
    for b=1:nb
        inWindow=ismember(T.sourceTrialRow,W.sourceTrialRows{b});
        sets=cell(2,2);
        for taskID=1:2
            for class=1:2
                sets{taskID,class}=find(inWindow&task==taskID&action==2*class-3);
                counts(b,2*(taskID-1)+class)=numel(sets{taskID,class});
            end
            balanced(b,taskID)=min(cellfun(@numel,sets(taskID,:)));
        end
        ready=balanced(b,:)>=max(cfg.minTrialsPerClass,2*F);
        if all(ready), status(b)="ok"; elseif any(ready), status(b)="one task insufficient"; end
        for rep=1:nr
            for taskID=find(ready)
                m=balanced(b,taskID); selected=[]; folds=[];
                for class=1:2
                    candidates=sets{taskID,class}; pick=candidates(randperm(stream,numel(candidates),m));
                    selected=[selected;pick(:)]; %#ok<AGROW>
                    folds=[folds;mod((0:m-1)',F)+1]; %#ok<AGROW>
                end
                trialRows{b,taskID,rep}=T.sourceTrialRow(selected);
                foldAssignments{b,taskID,rep}=folds;
                y=action(selected); scores=nan(2*m,1); directions=nan(numel(ids),F);
                for fold=1:F
                    train=folds~=fold; test=~train;
                    model=fn_fitLearningChoiceDecoder(X(selected(train),:),y(train),cfg);
                    scores(test)=X(selected(test),:)*model.weights+model.bias;
                    directions(:,fold)=model.axis;
                end
                predicted=2*(scores>=0)-1;
                accuracy(b,taskID,rep)=mean([mean(predicted(y==-1)==-1),mean(predicted(y==1)==1)]);
                direction=mean(directions,2); length=norm(direction);
                if isfinite(length)&&length>1e-12, axesByRepeat(:,taskID,b,rep)=direction/length; end
            end
        end
        if cfg.verbose, fprintf('Animal %d: %s %d, L/R counts [%s], %s\n',a,W.period(b),W.bin(b),num2str(counts(b,:)),status(b)); end
    end
    cosine=nan(nb,nr);
    for b=1:nb
        for rep=1:nr, cosine(b,rep)=sum(axesByRepeat(:,1,b,rep).*axesByRepeat(:,2,b,rep)); end
    end
    cosine=clipCosine(cosine); angle=acosd(cosine);
    consensus=mean(axesByRepeat,4); consensus=consensus./sqrt(sum(consensus.^2,1));
    acrossTime=cell(2,1); drift=nan(nb,2); reference=nan(1,2);
    for taskID=1:2
        directions=reshape(consensus(:,taskID,:),numel(ids),nb);
        acrossTime{taskID}=clipCosine(directions'*directions);
        ref=find(all(isfinite(directions),1),1);
        if ~isempty(ref), reference(taskID)=ref; drift(:,taskID)=acrossTime{taskID}(:,ref); end
    end
    animalID="animal"+a; if isfield(c,'animalID'), animalID=string(c.animalID); end
    animals{a}=struct('animalID',animalID,'windows',W,'plan',plan,'neuronIDs',ids, ...
        'selectedSessions',c.tracking.selectedSessionRec,'invalidTrialRows',invalidRows, ...
        'counts',counts,'balancedTrialsPerClass',balanced,'status',status, ...
        'accuracyByRepeat',accuracy,'accuracy',mean(accuracy,3), ...
        'accuracySEM',std(accuracy,0,3)/sqrt(nr),'axesByRepeat',axesByRepeat, ...
        'consensusAxes',consensus,'cosineByRepeat',cosine,'cosine',mean(cosine,2), ...
        'cosineSEM',std(cosine,0,2)/sqrt(nr),'angleDegrees',mean(angle,2), ...
        'angleDegreesByRepeat',angle,'temporalCosine',{acrossTime}, ...
        'referenceBin',reference,'cosineToReference',drift, ...
        'trialRows',{trialRows},'foldAssignments',{foldAssignments},'choiceFrames',frames);
end
result=struct('cfg',cfg,'animals',{animals}, ...
    'axisConvention','Unit raw-coordinate decoder normal, positive toward R; each animal has a fixed neuron set.', ...
    'note','Overlapping windows reuse trials. CV SEM is partition variability; group SEM uses animals. No bin-wise significance tests.');
[figures,result.plotFiles]=fn_plotLearningChoiceAxes(result,plotCfg);
end
function x=clipCosine(x)
good=isfinite(x); x(good)=max(-1,min(1,x(good)));
end
function s=fill(s,d)
extra=setdiff(fieldnames(s),fieldnames(d)); assert(isempty(extra),'learningAxes:Options','Unknown options: %s',strjoin(extra,', '));
for k=fieldnames(d)', if ~isfield(s,k{1}), s.(k{1})=d.(k{1}); end; end
end
