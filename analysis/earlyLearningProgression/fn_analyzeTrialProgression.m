function [result,figures] = fn_analyzeTrialProgression(activity,conditions,cfg,plotCfg)
%FN_ANALYZETRIALPROGRESSION Early trials and condition-specific subpopulations.
% activity: condition x animal cells, each neuron x time x chronological trial.
% conditions: one row per cell row (e.g. conditionName and stimulus).
% Neurons pool across animals; trial r means the r-th occurrence within each
% condition/animal, NOT a simultaneous trial. No normalization or reordering.
[defaults,plotDefaults]=fn_trialProgressionConfig();
if nargin<3, cfg=struct(); end
if nargin<4, plotCfg=struct(); end
cfg=options(cfg,defaults); plotCfg=options(plotCfg,plotDefaults);
cfg.selectionMethod=validatestring(cfg.selectionMethod,{'variance','progression'});
cfg.progressionDirection=validatestring(cfg.progressionDirection,{'positive','negative','both'});
cfg.comparisonReference=validatestring(cfg.comparisonReference,{'all','progression'});
validateattributes(cfg.nProgressionTrials,{'numeric'},{'scalar','integer','>=',2,'finite'});
validateattributes(cfg.nEndTrials,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.selectedFraction,{'numeric'},{'scalar','positive','<=',1,'finite'});
for field={'psthTrials','startTrials'}
    validateattributes(cfg.(field{1}),{'numeric'},{'vector','nonempty','integer','positive','finite'});
    assert(numel(unique(cfg.(field{1})))==numel(cfg.(field{1})), ...
        'trialProgression:Trials','Trial indices must be unique.');
end
if ~isempty(cfg.endTrials)
    validateattributes(cfg.endTrials,{'numeric'},{'vector','integer','positive','finite'});
    assert(numel(unique(cfg.endTrials))==numel(cfg.endTrials),'trialProgression:Trials','endTrials must be unique.');
end
if ~isempty(cfg.nSelectedNeurons)
    validateattributes(cfg.nSelectedNeurons,{'numeric'},{'scalar','integer','positive','finite'});
end
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity),'trialProgression:Input', ...
    'Use a condition x animal cell array.');
[nc,na]=size(activity);
assert(istable(conditions)&&height(conditions)==nc&&width(conditions)>0,'trialProgression:Conditions', ...
    'Provide a condition table with one row per input condition.');
if ~ismember('conditionName',conditions.Properties.VariableNames)
    % A stimulus-only table is enough; do not infer scientific labels from names.
    names=strings(nc,1);
    for j=1:width(conditions)
        values=string(conditions.(conditions.Properties.VariableNames{j}));
        assert(iscolumn(values)&&~any(ismissing(values)),'trialProgression:Conditions','Use scalar condition labels.');
        if j>1, names=names+", "; end
        names=names+string(conditions.Properties.VariableNames{j})+"="+values;
    end
    conditions.conditionName=names;
end
names=string(conditions.conditionName);
assert(iscolumn(names)&&numel(unique(names))==nc&&all(~ismissing(names)&strlength(names)>0), ...
    'trialProgression:Conditions','Condition names must be unique and nonempty.');
labels=string(cfg.animalLabels(:));
if isempty(labels), labels="animal"+string((1:na)'); end
assert(numel(labels)==na&&numel(unique(labels))==na&&all(~ismissing(labels)&strlength(labels)>0), ...
    'trialProgression:Labels','Provide one unique nonempty label per animal column.');
counts=zeros(nc,na); nNeurons=nan(1,na); nt=[];
for c=1:nc
    for a=1:na
        A=activity{c,a}; if isempty(A), continue; end
        validateattributes(A,{'numeric'},{'real','nonempty'});
        assert(ndims(A)<=3,'trialProgression:Shape','Each cell must be neuron x time x trial.');
        if isempty(nt), nt=size(A,2); end
        if isnan(nNeurons(a)), nNeurons(a)=size(A,1); end
        assert(size(A,2)==nt&&size(A,1)==nNeurons(a),'trialProgression:Shape', ...
            'Match time bins across animals and neuron identities/order across conditions within each animal.');
        counts(c,a)=size(A,3);
    end
end
assert(~isempty(nt),'trialProgression:Empty','All activity cells are empty.');
if isempty(cfg.time)
    validateattributes(cfg.frameRate,{'numeric'},{'scalar','positive','finite'});
    validateattributes(cfg.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
    time=((1:nt)-cfg.eventFrame)/cfg.frameRate;
else
    time=reshape(cfg.time,1,[]);
    assert(numel(time)==nt&&all(isfinite(time))&&all(diff(time)>0), ...
        'trialProgression:Time','time must be finite, increasing, and match time bins.');
end
scoreBins=1:nt;
if ~isempty(cfg.scoreTimeWindow)
    validateattributes(cfg.scoreTimeWindow,{'numeric'},{'vector','numel',2,'real','finite'});
    assert(cfg.scoreTimeWindow(1)<=cfg.scoreTimeWindow(2),'trialProgression:Time','Invalid scoreTimeWindow.');
    scoreBins=find(time>=cfg.scoreTimeWindow(1)&time<=cfg.scoreTimeWindow(2));
end
assert(~isempty(scoreBins),'trialProgression:Time','No bins in scoreTimeWindow.');
result=struct('cfg',cfg,'conditions',conditions,'time',time,'scoreBins',scoreBins, ...
    'trialCounts',counts,'byCondition',[]);
for c=1:nc
    available=counts(c,:)>=2;
    R=0; if any(available), R=min(cfg.nProgressionTrials,min(counts(c,available))); end
    early=cell(na,1); display=early; first=early; last=early; maps=early;
    included=false(na,1); dropped=zeros(na,1); reasons=strings(na,1);
    starts=cell(na,1); ends=starts; overlapping=false(na,1);
    % Use one fixed early-trial cohort, not a different neuron set at late ordinals.
    displayTrials=reshape(cfg.psthTrials(cfg.psthTrials<=R),1,[]);
    for a=1:na
        if ~available(a), reasons(a)="empty or fewer than two trials"; continue; end
        total=counts(c,a); limit=total;
        if strcmp(cfg.comparisonReference,'progression'), limit=R; end
        starts{a}=reshape(cfg.startTrials(cfg.startTrials<=limit),1,[]);
        if isempty(cfg.endTrials)
            ends{a}=max(1,limit-cfg.nEndTrials+1):limit;
        else
            ends{a}=reshape(cfg.endTrials(cfg.endTrials<=limit),1,[]);
        end
        assert(~isempty(starts{a})&&~isempty(ends{a}),'trialProgression:Comparison', ...
            'No valid comparison trials for condition %s, animal %s.',names(c),labels(a));
        overlapping(a)=~isempty(intersect(starts{a},ends{a}));
        used=unique([1:R starts{a} ends{a}]);
        A=activity{c,a}; valid=all(reshape(isfinite(A(:,:,used)),size(A,1),[]),2);
        assert(cfg.dropNonfiniteNeurons||all(valid),'trialProgression:Nonfinite','Nonfinite activity in analyzed trials.');
        dropped(a)=sum(~valid);
        if ~any(valid), reasons(a)="no finite neurons in analyzed trials"; continue; end
        early{a}=double(A(valid,:,1:R)); display{a}=double(A(valid,:,displayTrials));
        first{a}=mean(double(A(valid,:,starts{a})),3);
        last{a}=mean(double(A(valid,:,ends{a})),3); included(a)=true;
        maps{a}=table(repmat(a,sum(valid),1),repmat(labels(a),sum(valid),1),find(valid), ...
            'VariableNames',{'animalIndex','animalLabel','rowInAnimal'});
    end
    one=struct('conditionName',names(c),'nProgressionTrials',R,'psthTrials',displayTrials, ...
        'neurons',table(),'selectedNeuronMask',false(0,1),'allPopulation',[], ...
        'selectedPopulation',[],'status',"no usable neurons");
    one.animalAudit=table((1:na)',labels,counts(c,:)',included,dropped,starts,ends,overlapping,reasons, ...
        'VariableNames',{'animalIndex','animalLabel','nTrials','included','nDroppedNeurons', ...
        'startTrials','endTrials','comparisonOverlap','reason'});
    if any(included)
        E=cat(1,early{included}); D=cat(1,display{included}); F=cat(1,first{included}); L=cat(1,last{included});
        neurons=vertcat(maps{included}); nn=size(E,1);
        x=(1:R)-mean(1:R); S=E(:,scoreBins,:);
        slope=sum(S.*reshape(x,1,1,[]),3)/sum(x.^2);
        varianceScore=mean(var(S,0,3),2); % Variance across trials, THEN average time.
        progressionScore=mean(slope.^2,2)*var(1:R,0);
        meanSlope=mean(slope,2); score=varianceScore;
        if strcmp(cfg.selectionMethod,'progression')
            score=progressionScore;
            switch cfg.progressionDirection
                case 'positive', score(meanSlope<=0)=NaN;
                case 'negative', score(meanSlope>=0)=NaN;
            end
        end
        % No arbitrary selection of silent or perfectly constant neurons.
        eligible=find(isfinite(score)&score>0);
        [~,order]=sort(score(eligible),'descend'); ranked=eligible(order);
        if isempty(cfg.nSelectedNeurons), nTake=ceil(cfg.selectedFraction*numel(eligible));
        else, nTake=min(cfg.nSelectedNeurons,numel(eligible)); end
        mask=false(nn,1); mask(ranked(1:nTake))=true;
        neurons.varianceScore=varianceScore; neurons.progressionScore=progressionScore;
        neurons.meanSlopePerTrial=meanSlope; neurons.selectionScore=score; neurons.selected=mask;
        one.neurons=neurons; one.selectedNeuronMask=mask;
        one.allPopulation=summarize(E,D,F,L,scoreBins);
        one.selectedPopulation=summarize(E(mask,:,:),D(mask,:,:),F(mask,:),L(mask,:),scoreBins);
        one.status="computed";
        if cfg.verbose
            fprintf('%s: first %d trials; %d pooled neurons, %d selected (%s).\n',names(c),R,nn,sum(mask),cfg.selectionMethod);
        end
    end
    if R>0&&R<cfg.nProgressionTrials
        warning('trialProgression:Short','%s: using first %d common trials instead of %d.',names(c),R,cfg.nProgressionTrials);
    end
    if any(overlapping&included)
        warning('trialProgression:Overlap','%s: start/end comparison overlaps for some animals; inspect animalAudit.',names(c));
    end
    result.byCondition=[result.byCondition;one]; %#ok<AGROW>
end
result.estimation='Descriptive pooled-neuron analysis; selection and display use the same trials (not held-out validation).';
[figures,result.plotFiles]=fn_plotTrialProgression(result,plotCfg);
end

function s=summarize(E,D,F,L,bins)
nn=size(E,1); nt=size(E,2); nr=size(E,3);
s=struct('nNeurons',nn,'trialPsth',nan(nt,nr),'trialPsthSEM',nan(nt,nr), ...
    'displayPsth',nan(nt,size(D,3)),'displayPsthSEM',nan(nt,size(D,3)), ...
    'startPsth',nan(nt,1),'endPsth',nan(nt,1),'startSEM',nan(nt,1),'endSEM',nan(nt,1), ...
    'progression',nan(1,nr),'progressionSEM',nan(1,nr));
if nn==0, return; end
s.trialPsth=reshape(mean(E,1),nt,nr); s.trialPsthSEM=reshape(std(E,0,1)/sqrt(nn),nt,nr);
s.displayPsth=reshape(mean(D,1),nt,[]); s.displayPsthSEM=reshape(std(D,0,1)/sqrt(nn),nt,[]);
s.startPsth=mean(F,1)'; s.endPsth=mean(L,1)';
s.startSEM=std(F,0,1)'/sqrt(nn); s.endSEM=std(L,0,1)'/sqrt(nn);
windowMeans=reshape(mean(E(:,bins,:),2),nn,nr);
s.progression=mean(windowMeans,1); s.progressionSEM=std(windowMeans,0,1)/sqrt(nn);
if nn==1
    s.trialPsthSEM(:)=NaN; s.displayPsthSEM(:)=NaN; s.startSEM(:)=NaN;
    s.endSEM(:)=NaN; s.progressionSEM(:)=NaN;
end
end

function cfg=options(cfg,defaults)
if isempty(cfg), cfg=struct(); end
assert(isstruct(cfg)&&isscalar(cfg),'trialProgression:Config','Use scalar configuration structs.');
extra=setdiff(fieldnames(cfg),fieldnames(defaults));
assert(isempty(extra),'trialProgression:Config','Unknown options: %s.',strjoin(extra,', '));
for name=fieldnames(defaults)'
    if ~isfield(cfg,name{1}), cfg.(name{1})=defaults.(name{1}); end
end
end
