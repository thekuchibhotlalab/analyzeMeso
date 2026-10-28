function [result,figures] = fn_analyzeStimRewardAlignment(activity,conditions,cfg,plotCfg,trialInfo)
%FN_ANALYZESTIMREWARDALIGNMENT Compare stimulus and reward response patterns.
% activity: condition x animal cells of neuron x time x trial dffStim.
% conditions: table, conditionDef struct array, or complete selection config.
% trialInfo: same-size cells of trialInfoNeural, in exact activity trial order.
% Keep identical tracked neuron rows across conditions within each animal.
% Correlations are ACROSS NEURONS, computed separately for every animal/S.
% Frames after choice are a reward-period proxy, not measured reward onset.
[defaults,plotDefaults]=fn_stimRewardAlignmentConfig();
if nargin<3, cfg=struct(); end
if nargin<4, plotCfg=struct(); end
assert(nargin>=5,'stimReward:TrialInfo','Provide aligned trialInfoNeural cells as input 5.');
cfg=options(cfg,defaults); plotCfg=options(plotCfg,plotDefaults);
cfg.normalization=validatestring(cfg.normalization,{'none','zscore'});
assert(strcmpi(cfg.neuralField,'dffStim'),'stimReward:Alignment','Use dffStim activity.');
if isstruct(conditions)&&isscalar(conditions)&&isfield(conditions,'conditionDef')
    if isfield(conditions,'neuralField')
        assert(strcmpi(conditions.neuralField,'dffStim'),'stimReward:Alignment', ...
            'Selection config must load dffStim; reload activity after changing it.');
    end
    conditions=conditions.conditionDef;
end
if isstruct(conditions), conditions=struct2table(conditions(:),'AsArray',true); end
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity)&& ...
    istable(conditions)&&height(conditions)==size(activity,1),'stimReward:Input', ...
    'Use condition x animal activity cells and one condition definition per row.');
assert(iscell(trialInfo)&&isequal(size(trialInfo),size(activity)), ...
    'stimReward:TrialInfo','trialInfo cells must match activity.');
validateattributes(cfg.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.binSize,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.nEarlyTrials,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.pooledBinSize,{'numeric'},{'scalar','integer','positive','finite'});
for field={'stimulusOffsets','rewardOffsets'}
    validateattributes(cfg.(field{1}),{'numeric'},{'vector','integer','positive','finite','nonempty'});
end
if ~isempty(cfg.baselineOffsets)
    validateattributes(cfg.baselineOffsets,{'numeric'},{'vector','integer','<',0,'finite'});
end
validateattributes(cfg.includePartialBin,{'logical'},{'scalar'});
validateattributes(cfg.stimuli,{'numeric'},{'vector','finite','integer','positive','nonempty'});
assert(numel(unique(cfg.stimuli))==numel(cfg.stimuli),'stimReward:Stimuli','Use unique stimulus IDs.');
cfg.phaseOrder=string(cfg.phaseOrder(:));
assert(~isempty(cfg.phaseOrder)&&all(~ismissing(cfg.phaseOrder)&strlength(cfg.phaseOrder)>0)&& ...
    numel(unique(cfg.phaseOrder))==numel(cfg.phaseOrder),'stimReward:Phases','Use unique phase labels.');
[nc,na]=size(activity); ns=numel(cfg.stimuli);
if isempty(cfg.animalLabels), cfg.animalLabels="Animal "+string(1:na); end
cfg.animalLabels=string(cfg.animalLabels(:));
assert(numel(cfg.animalLabels)==na&&all(~ismissing(cfg.animalLabels)&strlength(cfg.animalLabels)>0), ...
    'stimReward:Animals','Provide one nonempty animal label per column.');
result=struct('cfg',cfg,'conditions',conditions);
result.normalization=struct('method',cfg.normalization, ...
    'scope','All finite samples across supplied time points, trials and conditions per neuron/animal', ...
    'offset',{cell(1,na)},'scale',{cell(1,na)},'nSamples',{cell(1,na)},'degenerate',{cell(1,na)});
result.reduced=struct('stimulus',{cell(nc,na)},'reward',{cell(nc,na)},'trials',{cell(nc,na)});
template=struct('animalLabel',"",'stimulus',NaN,'trials',table(), ...
    'stimulusActivity',[],'rewardActivity',[],'bins',table(),'stimulusMean',[], ...
    'rewardMean',[],'neuronMask',[],'neuronRows',[],'crossBinCorrelation',[], ...
    'withinBinCorrelation',[],'status',"no rewarded trials");
result.byStimulus=repmat(template,ns,na);
for a=1:na
    [offset,scale,count,degenerate]=normalizationStats(activity(:,a),cfg.normalization);
    result.normalization.offset{a}=offset; result.normalization.scale{a}=scale;
    result.normalization.nSamples{a}=count; result.normalization.degenerate{a}=degenerate;
    nNeuron=[]; allS=cell(nc,1); allR=cell(nc,1); maps=cell(nc,1);
    for c=1:nc
        X=activity{c,a}; if isempty(X), continue; end
        validateattributes(X,{'numeric'},{'real','nonempty'});
        assert(ndims(X)<=3,'stimReward:Input','Activity must be neuron x time x trial.');
        if isempty(nNeuron), nNeuron=size(X,1); end
        assert(size(X,1)==nNeuron,'stimReward:Neurons', ...
            'Animal %d: use the same tracked neuron rows across all conditions.',a);
        T=trialInfo{c,a};
        required={'dayLabel','responseType','sourceTrialRow',cfg.stimulusFrameField,cfg.choiceFrameField};
        assert(istable(T)&&height(T)==size(X,3)&&all(ismember(required,T.Properties.VariableNames)), ...
            'stimReward:TrialInfo','Cell (%d,%d): metadata must match trials and contain %s.',c,a,strjoin(required,', '));
        if ismember('stimuli',T.Properties.VariableNames), stimulus=T.stimuli;
        elseif ismember('stimulus',T.Properties.VariableNames), stimulus=T.stimulus;
        else
            assert(ismember('stimulus',conditions.Properties.VariableNames),'stimReward:Stimulus','Provide trial stimuli or condition stimulus.');
            value=conditions.stimulus(c,:); if iscell(value), value=value{1}; end
            validateattributes(value,{'numeric'},{'scalar','real','finite'});
            stimulus=repmat(value,height(T),1);
        end
        validateattributes(stimulus,{'numeric'},{'column','numel',height(T),'real','finite'});
        validateattributes(T.responseType,{'numeric'},{'column','numel',height(T)});
        % Metadata decides reward status, even if a selection contains mixed outcomes.
        keep=find(T.responseType==1&ismember(stimulus,cfg.stimuli));
        if isempty(keep), continue; end
        source=double(T.sourceTrialRow(keep)); phase=string(T.dayLabel(keep));
        validateattributes(source,{'numeric'},{'column','integer','positive','finite'});
        assert(iscolumn(phase)&&all(ismember(phase,cfg.phaseOrder)), ...
            'stimReward:Phases','cfg.phaseOrder must include every rewarded trial phase.');
        validateattributes(T.(cfg.stimulusFrameField),{'numeric'},{'column','numel',height(T),'real'});
        validateattributes(T.(cfg.choiceFrameField),{'numeric'},{'column','numel',height(T),'real'});
        stimFrame=double(T.(cfg.stimulusFrameField)(keep));
        choiceFrame=double(T.(cfg.choiceFrameField)(keep));
        assert(iscolumn(stimFrame)&&iscolumn(choiceFrame),'stimReward:Frames','Use scalar frame values per trial.');
        S=nan(nNeuron,numel(keep)); R=S;
        choiceIndex=cfg.eventFrame+choiceFrame-stimFrame;
        valid=false(numel(keep),1); overlap=valid;
        stimulusBins=cfg.eventFrame+cfg.stimulusOffsets;
        baselineBins=cfg.eventFrame+cfg.baselineOffsets;
        for j=1:numel(keep)
            rewardBins=choiceIndex(j)+cfg.rewardOffsets;
            idx=[stimulusBins(:);rewardBins(:);baselineBins(:)];
            valid(j)=all(isfinite([stimFrame(j) choiceFrame(j)]))&& ...
                all(mod([stimFrame(j) choiceFrame(j)],1)==0)&&choiceFrame(j)>=stimFrame(j)&& ...
                all(isfinite(idx)&idx>=1&idx<=size(X,2)&mod(idx,1)==0);
            if ~valid(j), continue; end
            baseline=0;
            if ~isempty(baselineBins), baseline=mean(double(X(:,baselineBins,keep(j))),2); end
            S(:,j)=mean(double(X(:,stimulusBins,keep(j))),2)-baseline;
            R(:,j)=mean(double(X(:,rewardBins,keep(j))),2)-baseline;
            overlap(j)=any(ismember(stimulusBins,rewardBins));
        end
        % Linear normalization commutes with averaging. A shared baseline
        % subtraction cancels the z-score offset, leaving division by scale.
        if strcmp(cfg.normalization,'zscore')
            if isempty(baselineBins), S=S-offset; R=R-offset; end
            S=S./scale; R=R./scale;
        end
        M=table(repmat(c,numel(keep),1),keep,source,phase,stimulus(keep), ...
            choiceIndex,valid,overlap,'VariableNames',{'sourceCondition','sourceTrial', ...
            'sourceTrialRow','dayLabel','stimulus','choiceIndex','validWindow','overlappingWindows'});
        result.reduced.stimulus{c,a}=S; result.reduced.reward{c,a}=R;
        result.reduced.trials{c,a}=M;
        allS{c}=S; allR{c}=R; maps{c}=M;
    end
    present=~cellfun(@isempty,maps);
    if any(present)
        M=vertcat(maps{present}); S=cat(2,allS{present}); R=cat(2,allR{present});
        assert(numel(unique(M.sourceTrialRow))==height(M),'stimReward:DuplicateTrial', ...
            'Animal %d has duplicate rewarded sourceTrialRow entries across conditions.',a);
        [~,phaseRank]=ismember(M.dayLabel,cfg.phaseOrder);
        [~,order]=sortrows([phaseRank M.sourceTrialRow],[1 2]);
        M=M(order,:); S=S(:,order); R=R(:,order);
    end
    for s=1:ns
        B=template; B.animalLabel=cfg.animalLabels(a); B.stimulus=cfg.stimuli(s);
        if any(present)
            select=M.stimulus==cfg.stimuli(s);
            B.trials=M(select,:); B.stimulusActivity=S(:,select); B.rewardActivity=R(:,select);
            B=summarizeBins(B,cfg);
        end
        result.byStimulus(s,a)=B;
    end
end
result.pooledEarlyTrials=poolEarlyTrials(result.byStimulus,cfg.nEarlyTrials,cfg.pooledBinSize);
result.pooledEarlyTrials.byStimulus=splitPooledStimuli(result.pooledEarlyTrials,cfg.stimuli);
[figures,result.plotFiles]=fn_plotStimRewardAlignment(result,plotCfg);
end

function [offset,scale,count,degenerate]=normalizationStats(blocks,method)
present=find(~cellfun(@isempty,blocks)); nn=0;
if ~isempty(present), nn=size(blocks{present(1)},1); end
offset=zeros(nn,1); scale=ones(nn,1); count=zeros(nn,1); degenerate=false(nn,1);
for c=present'
    validateattributes(blocks{c},{'numeric'},{'real'});
    assert(ndims(blocks{c})<=3&&size(blocks{c},1)==nn,'stimReward:Neurons', ...
        'Match neuron identities/order across all conditions within each animal.');
end
if strcmp(method,'none'), return; end
for c=present'
    X=reshape(double(blocks{c}),nn,[]); finite=isfinite(X);
    X(~finite)=0; offset=offset+sum(X,2); count=count+sum(finite,2);
end
offset=offset./max(count,1); ss=zeros(nn,1);
for c=present'
    X=reshape(double(blocks{c}),nn,[]); finite=isfinite(X);
    X=X-offset; X(~finite)=0; ss=ss+sum(X.^2,2);
end
scale=sqrt(ss./max(count-1,1));
degenerate=count<2|~isfinite(scale)|scale==0;
scale(degenerate)=1; % Constant neurons become zero; missing values stay missing.
end

function P=poolEarlyTrials(groups,nTrials,binSize)
% Each row is a neuron-stimulus pair; each column averages a fixed trial bin.
% Use identical finite trial pairs for S and R; missing trials never shift bins.
firstTrial=(1:binSize:nTrials)'; lastTrial=min(firstTrial+binSize-1,nTrials);
nb=numel(firstTrial);
[ns,na]=size(groups); S=cell(ns,na); R=S; maps=S; counts=S;
for a=1:na
    for s=1:ns
        B=groups(s,a); n=min(nTrials,height(B.trials));
        if n==0, continue; end
        nn=size(B.stimulusActivity,1);
        S{s,a}=nan(nn,nb); R{s,a}=nan(nn,nb); counts{s,a}=zeros(nn,nb);
        for b=1:nb
            idx=firstTrial(b):min(lastTrial(b),n);
            if isempty(idx), continue; end
            x=B.stimulusActivity(:,idx); y=B.rewardActivity(:,idx);
            good=isfinite(x)&isfinite(y); counts{s,a}(:,b)=sum(good,2);
            x(~good)=NaN; y(~good)=NaN;
            S{s,a}(:,b)=mean(x,2,'omitnan'); R{s,a}(:,b)=mean(y,2,'omitnan');
        end
        maps{s,a}=table(repmat(a,nn,1),repmat(B.animalLabel,nn,1), ...
            repmat(B.stimulus,nn,1),(1:nn)', ...
            'VariableNames',{'animalIndex','animalLabel','stimulus','neuronRow'});
    end
end
present=~cellfun(@isempty,maps);
P=struct('stimulusActivity',zeros(0,nb),'rewardActivity',zeros(0,nb), ...
    'trialCounts',zeros(0,nb),'bins',table(firstTrial,lastTrial), ...
    'points',table(),'correlation',nan(1,nb),'nPoints',zeros(1,nb), ...
    'nAnimals',zeros(1,nb),'nStimuli',zeros(1,nb));
if ~any(present,'all'), return; end
P.stimulusActivity=vertcat(S{present}); P.rewardActivity=vertcat(R{present});
P.trialCounts=vertcat(counts{present});
P.points=vertcat(maps{present});
for j=1:nb
    good=isfinite(P.stimulusActivity(:,j))&isfinite(P.rewardActivity(:,j));
    P.correlation(j)=pearson(P.stimulusActivity(good,j),P.rewardActivity(good,j));
    P.nPoints(j)=sum(good); P.nAnimals(j)=numel(unique(P.points.animalIndex(good)));
    P.nStimuli(j)=numel(unique(P.points.stimulus(good)));
end
end

function groups=splitPooledStimuli(P,stimuli)
% Keep separate correlations and actual contributing-animal counts per stimulus.
template=struct('stimulus',NaN,'pointRows',[],'binIndices',[], ...
    'bins',table(),'correlation',[],'nPoints',[],'nAnimals',[]);
groups=repmat(template,numel(stimuli),1);
for s=1:numel(stimuli)
    G=template; G.stimulus=stimuli(s);
    if ~isempty(P.points), G.pointRows=find(P.points.stimulus==stimuli(s)); end
    nb=height(P.bins); r=nan(1,nb); counts=zeros(1,nb); animals=counts;
    for b=1:nb
        rows=G.pointRows;
        good=isfinite(P.stimulusActivity(rows,b))&isfinite(P.rewardActivity(rows,b));
        rows=rows(good); counts(b)=numel(rows);
        if isempty(rows), continue; end
        animals(b)=numel(unique(P.points.animalIndex(rows)));
        r(b)=pearson(P.stimulusActivity(rows,b),P.rewardActivity(rows,b));
    end
    last=find(counts>0,1,'last');
    if isempty(last), last=0; end
    G.binIndices=1:min(10,last); % Preserve internal gaps; remove trailing empty bins.
    G.bins=P.bins(G.binIndices,:); G.correlation=r(G.binIndices);
    G.nPoints=counts(G.binIndices); G.nAnimals=animals(G.binIndices);
    groups(s)=G;
end
end

function B=summarizeBins(B,cfg)
nt=height(B.trials); if nt==0, return; end
nb=floor(nt/cfg.binSize);
if cfg.includePartialBin, nb=ceil(nt/cfg.binSize); end
if nb==0, B.status="fewer than one full bin"; return; end
firstTrial=(0:nb-1)'*cfg.binSize+1; lastTrial=min(firstTrial+cfg.binSize-1,nt);
% Invalid windows do not shift trial bin boundaries. Use a fixed neuron cohort
% across all included valid trials so changes in r do not reflect neuron dropout.
used=false(1,nt); used(1:lastTrial(end))=true;
used=used&B.trials.validWindow';
mask=all(isfinite(B.stimulusActivity(:,used))&isfinite(B.rewardActivity(:,used)),2);
if ~any(used), mask(:)=false; end
B.neuronMask=mask; B.neuronRows=find(mask);
B.stimulusMean=nan(sum(mask),nb); B.rewardMean=B.stimulusMean;
nValidTrials=zeros(nb,1); overlappingTrials=nValidTrials;
for b=1:nb
    trials=firstTrial(b):lastTrial(b); trials=trials(B.trials.validWindow(trials));
    nValidTrials(b)=numel(trials); overlappingTrials(b)=sum(B.trials.overlappingWindows(trials));
    if isempty(trials), continue; end
    B.stimulusMean(:,b)=mean(B.stimulusActivity(mask,trials),2);
    B.rewardMean(:,b)=mean(B.rewardActivity(mask,trials),2);
end
nTrials=lastTrial-firstTrial+1;
B.bins=table(firstTrial,lastTrial,nTrials,nValidTrials,overlappingTrials);
B.crossBinCorrelation=nan(nb);
for i=1:nb
    for j=1:nb
        B.crossBinCorrelation(i,j)=pearson(B.stimulusMean(:,i),B.rewardMean(:,j));
    end
end
B.withinBinCorrelation=diag(B.crossBinCorrelation);
B.status="ok";
if sum(mask)<3, B.status="fewer than 3 finite neurons; correlations undefined"; end
end

function r=pearson(x,y)
r=NaN;
if numel(x)<3||any(~isfinite(x)|~isfinite(y)), return; end
x=x-mean(x); y=y-mean(y); denominator=norm(x)*norm(y);
if denominator>0, r=(x'*y)/denominator; r=max(-1,min(1,r)); end
end

function out=options(in,defaults)
assert(isstruct(in)&&isscalar(in),'stimReward:Config','Use scalar configuration structs.');
extra=setdiff(fieldnames(in),fieldnames(defaults));
assert(isempty(extra),'stimReward:Config','Unknown options: %s.',strjoin(extra,', '));
out=defaults;
for name=fieldnames(in)', out.(name{1})=in.(name{1}); end
end
