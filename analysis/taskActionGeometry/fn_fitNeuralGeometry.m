function [result,figures] = fn_fitNeuralGeometry(activity,conditions,cfg,plotCfg,model)
%FN_FITNEURALGEOMETRY Internal fit/evaluation engine for neural geometry.
% activity: nCondition x nAnimal cells, each neurons x time x trials.
% conditions: matching rows, conditionName plus categorical factor columns.
% One population is formed by concatenating ALL retained neurons across animals.
% Trials are never paired across animals. Noise covariance between animals is
% unobserved and assumed zero. Conditions, not their trial counts, are balanced.
% Axes pool time and trials; projections and variance retain individual bins.
% Optional model evaluates held-out data with fixed training weights and scaling.
% First output has no graphics or input trial arrays. See README.md for math.
if nargin<5, model=[]; end
[defaults,defaultPlots]=fn_neuralGeometryConfig();
if nargin<3 || isempty(cfg), cfg=struct(); end
if nargin<4 || isempty(plotCfg), plotCfg=struct(); end
cfg=fillOptions(cfg,defaults); plotCfg=fillOptions(plotCfg,defaultPlots);
cfg.method=validatestring(cfg.method,{'lda','meanSquared','regression'});
cfg.normalization=validatestring(cfg.normalization,{'none','zscore','rms'});
cfg.covariance=validatestring(cfg.covariance,{'diagonal','withinAnimal'});
cfg.missingAnimal=validatestring(cfg.missingAnimal,{'exclude','error'});
cfg.separationSummary=validatestring(cfg.separationSummary,{'selected','choiceTask'});
validateattributes(cfg.nAxes,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(cfg.ridge,{'numeric'},{'scalar','positive','finite'});
validateattributes(cfg.tolerance,{'numeric'},{'scalar','positive','finite','<',1});
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity), ...
    'neuralGeometry:Input','activity must be a condition x animal cell array.');
[nc,na]=size(activity);
assert(istable(conditions)&&height(conditions)==nc&& ...
    ismember('conditionName',conditions.Properties.VariableNames), ...
    'neuralGeometry:Conditions','Provide one table row per input condition and conditionName.');
names=string(conditions.conditionName);
assert(iscolumn(names)&&all(~ismissing(names)&strlength(names)>0)&&numel(unique(names))==nc, ...
    'neuralGeometry:Conditions','conditionName must contain unique nonempty names.');
vars=string(cfg.variables(:));
if isempty(vars), vars=string(conditions.Properties.VariableNames)'; vars(vars=="conditionName")=[]; end
assert(~isempty(vars)&&numel(unique(vars))==numel(vars)&& ...
    all(ismember(vars,string(conditions.Properties.VariableNames)))&&~any(vars=="conditionName"), ...
    'neuralGeometry:Variables','Select unique factor columns other than conditionName.');
[design,columns,groups,levels]=factorDesign(conditions,vars);
nf=numel(vars); fullRank=rank(design)==size(design,2);
if ~fullRank
    warning('neuralGeometry:Confounded','Factor columns are confounded. Unique variable effects may be unidentifiable.');
end
if strcmp(cfg.method,'regression')
    assert(fullRank,'neuralGeometry:Confounded','Joint regression requires identifiable factor columns.');
end
[X,C,pooledMeans,pooledCov,normalization,neurons,audit,time,counts]=prepare(activity,cfg,model);
n=size(C,1); nt=numel(time); indices=cellfun(@(v)find(neurons.animalIndex==v), ...
    num2cell((1:na)'), 'UniformOutput',false);
assert(isempty(cfg.separationTimeWindow)||isempty(cfg.separationTimePoints), ...
    'neuralGeometry:SeparationTime','Use separationTimeWindow OR separationTimePoints, not both.');
separationMask=true(size(time));
if ~isempty(cfg.separationTimeWindow)
    validateattributes(cfg.separationTimeWindow,{'numeric'},{'vector','numel',2,'finite','real','nondecreasing'});
    separationMask=time>=cfg.separationTimeWindow(1)&time<=cfg.separationTimeWindow(2);
elseif ~isempty(cfg.separationTimePoints)
    validateattributes(cfg.separationTimePoints,{'numeric'},{'vector','finite','real'});
    assert(all(ismembertol(cfg.separationTimePoints,time,1e-9,'DataScale',1)), ...
        'neuralGeometry:SeparationTime','Every separationTimePoints value must match a bin in the analyzed time range.');
    separationMask=ismembertol(time,cfg.separationTimePoints,1e-9,'DataScale',1);
end
assert(any(separationMask),'neuralGeometry:SeparationTime','Separation time selection contains no analyzed bins.');
result=struct(); result.weights=[]; result.weightsRaw=[]; result.axisInfo=table();
result.neurons=neurons; result.conditions=conditions; result.variables=vars;
result.time=time; result.cfg=cfg; result.normalization=normalization;
result.separationTime=time(separationMask);
result.animalAudit=audit; result.trialCounts=counts; result.conditionMeans=C;
result.isPseudoPopulation=sum(audit.included)>1;
result.assumption='Cross-animal trial covariance is unavailable and assumed zero.';
result.estimation='In-sample descriptive fits; no significance or held-out variance claim.';
W=[]; axisVariable=strings(0,1); axisNumber=zeros(0,1); objective=zeros(0,1);
if isempty(model)
for f=1:nf
    g=groups{f}; L=numel(levels{f}); mu=zeros(n,L);
    for l=1:L, mu(:,l)=mean(pooledMeans(:,g==l),2); end
    D=(mu-mean(mu,2))/sqrt(L);
    blocks=cell(na,1); diagNoise=zeros(n,1);
    for a=1:na
        ix=indices{a}; if isempty(ix), continue; end
        if strcmp(cfg.covariance,'withinAnimal'), B=zeros(numel(ix)); else, B=zeros(numel(ix),1); end
        for c=1:nc
            weight=1/(L*sum(g==g(c))); d=pooledMeans(ix,c)-mu(ix,g(c));
            if strcmp(cfg.covariance,'withinAnimal')
                B=B+weight*(pooledCov{c,a}+d*d');
            else
                B=B+weight*(pooledCov{c,a}+d.^2);
            end
        end
        blocks{a}=B;
        if isvector(B)&&~strcmp(cfg.covariance,'withinAnimal'), diagNoise(ix)=B;
        else, diagNoise(ix)=diag(B); end
    end
    switch cfg.method
        case 'lda'
            target=D;
        case 'meanSquared'
            target=D;
        case 'regression'
            % Joint, effect-coded, time-pooled encoding regression. No QR
            % across factors: preserve their angles rather than forcing 90 deg.
            beta=design\pooledMeans';
            effect=(design(:,columns{f})*beta(columns{f},:))';
            target=(effect-mean(effect,2))/sqrt(nc);
    end
    base=mean(diagNoise); if base<=0, base=1; end
    ridge=cfg.ridge*base;
    if strcmp(cfg.covariance,'withinAnimal')
        for a=1:na
            if ~isempty(indices{a}), blocks{a}=chol(blocks{a}+ridge*eye(numel(indices{a})),'lower'); end
        end
    end
    inverse=@(V)solveNoise(V,blocks,indices,diagNoise+ridge,cfg.covariance);
    [U,score]=fitAxes(target,inverse,cfg);
    first=size(W,2)+1; W=[W U]; %#ok<AGROW>
    r=size(U,2); axisVariable=[axisVariable;repmat(vars(f),r,1)]; %#ok<AGROW>
    axisNumber=[axisNumber;(1:r)']; objective=[objective;score]; %#ok<AGROW>
    factor=struct('name',vars(f),'levels',levels{f},'weights',U, ...
        'axisIndices',first:first+r-1,'nAxes',r,'objective',score, ...
        'pooledLevelMeans',mu,'regularization',ridge,'stopReason',"requested number reached");
    if r<cfg.nAxes, factor.stopReason="no remaining pooled mean signal (or neuron dimensions)"; end
    result.factors(f)=factor;
end
else
    assert(isequal(neurons,model.neurons),'neuralGeometry:Model','Training and test neuron maps must agree.');
    W=model.weights; result.factors=model.factors;
    axisVariable=model.axisInfo.variable; axisNumber=model.axisInfo.axis; objective=model.axisInfo.fitObjective;
end
result.weights=W;
result.weightsRaw=W./normalization.scale;
result.projectionOffset=-W'*(normalization.offset./normalization.scale);
result.axisInfo=table(axisVariable,axisNumber,objective, ...
    'VariableNames',{'variable','axis','fitObjective'});
result.axisLabels=axisVariable+" "+string(axisNumber);
K=size(W,2);
P=reshape(W'*reshape(C,n,[]),K,nt,nc); V=zeros(K,nt,nc); populationNoise=zeros(nt,nc);
projectionMeanVariance=zeros(K,nt,nc); projectionTrialVariance=zeros(K,nt,nc);
% Sum independent animal contributions, preserving each animal's true trials.
for a=1:na
    ix=indices{a}; if isempty(ix), continue; end
    for c=1:nc
        Y=reshape(W(ix,:)'*reshape(X{c,a},numel(ix),[]),K,nt,counts(c,a));
        V(:,:,c)=V(:,:,c)+var(Y,1,3);
        % Use actual within-animal trials; do not pair trials across animals.
        sampleVariance=var(Y,0,3);
        projectionMeanVariance(:,:,c)=projectionMeanVariance(:,:,c)+sampleVariance/counts(c,a);
        projectionTrialVariance(:,:,c)=projectionTrialVariance(:,:,c)+sampleVariance;
        populationNoise(:,c)=populationNoise(:,c)+sum(var(X{c,a},1,3),1)';
    end
end
result.projection=struct('conditionMean',P,'withinConditionVariance',V, ...
    'conditionSEM',sqrt(projectionMeanVariance),'conditionSD',sqrt(projectionTrialVariance), ...
    'errorEstimation','Fixed-axis trial uncertainty; independent trials/animals assumed; no axis-fit or animal-level uncertainty.');
result.variance=varianceMetrics(P,V,C,design,columns,groups,nf);
result=fn_addNeuralGeometryTrialSEM(result);
result.variance.populationTotalVarianceByTime= ...
    result.variance.populationBetweenConditionVarianceByTime+mean(populationNoise,2)';
result.variance.axisFractionOfPopulationTotalByTime=safeDivide( ...
    result.variance.totalByTime,result.variance.populationTotalVarianceByTime);
result.variance.axisFractionOfPopulationTotal=safeDivide( ...
    result.variance.total,mean(result.variance.populationTotalVarianceByTime));
% Pool condition x time about ONE grand mean, retaining shared time dynamics.
% Conditions remain equally weighted even when their trial counts differ.
trialMeanProjected=var(reshape(P,K,nt*nc),1,2);
trialMeanPopulation=sum(var(reshape(C,n,nt*nc),1,2));
allTrialsProjected=trialMeanProjected+mean(V,[2 3]);
allTrialsPopulation=trialMeanPopulation+mean(populationNoise,'all');
result.variance.pooledTrialMeanProjectedVariance=trialMeanProjected;
result.variance.pooledTrialMeanPopulationVariance=trialMeanPopulation;
result.variance.pooledTrialMeanFraction=safeDivide(trialMeanProjected,trialMeanPopulation);
result.variance.pooledAllTrialsProjectedVariance=allTrialsProjected;
result.variance.pooledAllTrialsPopulationVariance=allTrialsPopulation;
result.variance.pooledAllTrialsFraction=safeDivide(allTrialsProjected,allTrialsPopulation);
% Recenter over the selected condition x time samples, including their noise.
separationPopulation=sum(var(reshape(C(:,separationMask,:),n,[]),1,2)) ...
    +mean(populationNoise(separationMask,:),'all');
result.variance.separationPopulationVariance=separationPopulation;
result.variance.variableUniquePooledPopulationFraction=safeDivide( ...
    reshape(mean(result.variance.variableUniqueEnergyByTime(:,separationMask,:),2),K,nf),separationPopulation);
result.variance.pooledWeighting='Equal conditions and time bins; equal trials within each animal-condition; unpaired animal residuals.';
if strcmp(cfg.separationSummary,'choiceTask')
    assert(isempty(cfg.separationTimeWindow)&&isempty(cfg.separationTimePoints), ...
        'neuralGeometry:SeparationTime','choiceTask uses fixed windows; leave separationTimeWindow and separationTimePoints empty.');
    actionIndex=find(strcmpi(vars,'action')|strcmpi(vars,'choice'));
    taskIndex=find(strcmpi(vars,'task'));
    assert(isscalar(actionIndex)&&isscalar(taskIndex),'neuralGeometry:SeparationVariables', ...
        'choiceTask requires one action (or choice) variable and one task variable.');
    variableIndex=[actionIndex taskIndex taskIndex];
    windows=[-.15 0;-.15 0;0 .5]; actualTimes=cell(3,1);
    fraction=zeros(K,3); denominator=zeros(1,3); energy=zeros(K,3);
    for b=1:3
        keep=time>=windows(b,1)-1e-9 & time<=windows(b,2)+1e-9;
        dt=median(diff(time));
        assert(any(keep)&&isfinite(dt)&&min(time)<=windows(b,1)+dt+1e-9 ...
            &&max(time)>=windows(b,2)-dt-1e-9,'neuralGeometry:SeparationTime', ...
            'The analyzed time grid must cover the choice and post-choice windows; extend cfg.timeWindow.');
        actualTimes{b}=time(keep);
        denominator(b)=sum(var(reshape(C(:,keep,:),n,[]),1,2))+mean(populationNoise(keep,:),'all');
        energy(:,b)=mean(result.variance.variableUniqueEnergyByTime(:,keep,variableIndex(b)),2);
        fraction(:,b)=safeDivide(energy(:,b),denominator(b));
    end
    result.separationBars=table(["Choice [-0.15, 0] s";"Task [-0.15, 0] s";"Task [0, 0.5] s"], ...
        vars(variableIndex(:)),windows(:,1),windows(:,2),actualTimes, ...
        'VariableNames',{'label','variable','startTime','endTime','actualTimes'});
    result.variance.windowedVariableFraction=fraction;
    result.variance.windowedVariableEnergy=energy;
    result.variance.windowedPopulationVariance=denominator;
end
% Variable signal on each axis, relative to ALL pooled neurons' variance.
populationTotal=result.variance.populationTotalVarianceByTime;
result.variance.variableUniquePopulationFractionByTime=safeDivide( ...
    result.variance.variableUniqueEnergyByTime,populationTotal);
result.variance.variableUniquePopulationFraction=safeDivide( ...
    reshape(mean(result.variance.variableUniqueEnergyByTime,2),K,nf),mean(populationTotal));
result.variance.allConditionPopulationFractionByTime=safeDivide( ...
    result.variance.conditionSignalByTime,populationTotal);
result.variance.allConditionPopulationFraction=safeDivide( ...
    mean(result.variance.conditionSignalByTime,2),mean(populationTotal));
[~,peak]=max(mean(C,3),[],2); [~,order]=sort(peak,'ascend');
result.sanity=struct('peakBin',peak,'neuronOrder',order, ...
    'sorting','Peak of the equal-condition mean PSTH; same order for all heatmaps.');
for f=1:nf
    ids=result.factors(f).axisIndices; g=groups{f}; L=numel(levels{f});
    means=zeros(K,nt,L); neuralMeans=zeros(n,nt,L);
    for l=1:L
        means(:,:,l)=mean(P(:,:,g==l),3);
        neuralMeans(:,:,l)=mean(C(:,:,g==l),3);
    end
    result.factors(f).marginalProjection=means(ids,:,:);
    signal=mean((neuralMeans-mean(neuralMeans,3)).^2,3);
    denom=sum(signal,1);
    energy=mean((means(ids,:,:)-mean(means(ids,:,:),3)).^2,3);
    result.factors(f).separationEnergy=energy;
    result.factors(f).separationCaptureByTime=safeDivide(energy,denom);
    result.factors(f).separationCapture=safeDivide(mean(energy,2),mean(denom));
    result.factors(f).cumulativeSeparationCapture=cumsum(result.factors(f).separationCapture);
    result.factors(f).totalSeparationEnergyByTime=denom;
end
cosine=max(-1,min(1,W'*W));
result.similarity=struct('cosine',cosine,'angleDegrees',acosd(abs(cosine)), ...
    'metric','Euclidean angles in the analyzed (optionally normalized) neuron coordinates');
if cfg.verbose
    fprintf('Pooled geometry: %d neurons, %d animals, %d conditions; %s, %d axes.\n', ...
        n,sum(audit.included),nc,cfg.method,K);
    disp(result.axisInfo);
end
[figures,result.plotFiles]=fn_plotNeuralGeometry(result,plotCfg);
end

function cfg=fillOptions(cfg,defaults)
assert(isstruct(cfg)&&isscalar(cfg),'neuralGeometry:Config','Configuration must be a scalar structure.');
extra=setdiff(fieldnames(cfg),fieldnames(defaults));
assert(isempty(extra),'neuralGeometry:Config','Unknown options: %s.',strjoin(extra,', '));
for name=fieldnames(defaults)'
    if ~isfield(cfg,name{1}), cfg.(name{1})=defaults.(name{1}); end
end
end

function [D,columns,groups,levels]=factorDesign(T,vars)
D=ones(height(T),1); columns=cell(numel(vars),1); groups=columns; levels=columns;
for f=1:numel(vars)
    raw=T.(vars(f)); s=string(raw);
    assert(iscolumn(s)&&all(~ismissing(s)&strlength(s)>0)&&~any(ismissing(raw),'all'), ...
        'neuralGeometry:Labels','Factor %s must have one nonmissing label per condition.',vars(f));
    [levels{f},~,g]=unique(s,'stable'); groups{f}=g; L=numel(levels{f});
    assert(L>=2,'neuralGeometry:Labels','Factor %s needs at least two levels.',vars(f));
    % Orthonormal contrasts of the categorical levels, independent of labels.
    H=null(ones(1,L)); block=H(g,:);
    columns{f}=size(D,2)+(1:size(block,2)); D=[D block]; %#ok<AGROW>
end
end

function [X,C,M,covariances,normInfo,neurons,audit,time,counts]=prepare(activity,cfg,model)
[nc,na]=size(activity); counts=zeros(nc,na); labels=string(cfg.animalLabels(:));
if isempty(labels), labels="animal"+string((1:na)'); end
assert(numel(labels)==na&&numel(unique(labels))==na&&all(~ismissing(labels)&strlength(labels)>0), ...
    'neuralGeometry:Labels','Supply one unique animal label per column.');
included=false(na,1); reason=strings(na,1); dropped=zeros(na,1);
X=cell(nc,na); meanCells=cell(na,1); poolCells=meanCells; covariances=X;
maps={}; offsets={}; scales={}; nTime=[]; time=[];
for a=1:na
    if any(cellfun(@isempty,activity(:,a)))
        assert(~strcmp(cfg.missingAnimal,'error'),'neuralGeometry:Missing','%s has an empty condition.',labels(a));
        reason(a)="empty condition; animal excluded"; continue;
    end
    nn=size(activity{1,a},1); nt=size(activity{1,a},2);
    if isempty(nTime), nTime=nt; end
    assert(nt==nTime,'neuralGeometry:Shape','Time-bin counts differ across animals.');
    if isempty(cfg.time)
        validateattributes(cfg.frameRate,{'numeric'},{'scalar','positive','finite'});
        validateattributes(cfg.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
        time=((1:nt)-cfg.eventFrame)/cfg.frameRate;
    else
        time=reshape(cfg.time,1,[]);
        assert(numel(time)==nt&&all(isfinite(time))&&all(diff(time)>0), ...
            'neuralGeometry:Time','cfg.time must be finite, increasing, and match the data.');
    end
    frames=1:nt;
    if ~isempty(cfg.timeWindow)
        validateattributes(cfg.timeWindow,{'numeric'},{'vector','numel',2,'finite','real'});
        assert(cfg.timeWindow(1)<=cfg.timeWindow(2),'neuralGeometry:Time','Invalid time window.');
        frames=find(time>=cfg.timeWindow(1)&time<=cfg.timeWindow(2));
    end
    assert(~isempty(frames),'neuralGeometry:Time','No time bins in the selected window.');
    valid=true(nn,1);
    for c=1:nc
        A=activity{c,a}; validateattributes(A,{'numeric'},{'real','nonempty'});
        assert(ndims(A)<=3&&size(A,1)==nn&&size(A,2)==nt,'neuralGeometry:Shape', ...
            'Within each animal all conditions must share neuron identities and time bins.');
        counts(c,a)=size(A,3);
        assert(counts(c,a)>=2,'neuralGeometry:Trials','At least two trials per condition/animal are needed.');
        X{c,a}=double(A(:,frames,:));
        valid=valid&all(reshape(isfinite(X{c,a}),nn,[]),2);
    end
    assert(cfg.dropNonfiniteNeurons||all(valid),'neuralGeometry:Nonfinite','Nonfinite neural activity.');
    dropped(a)=sum(~valid);
    if ~any(valid), reason(a)="no finite neurons"; X(:,a)={[]}; continue; end
    nr=sum(valid); sums=zeros(nr,1); squares=sums; N=0;
    for c=1:nc
        A=X{c,a}(valid,:,:); X{c,a}=A; flat=reshape(A,nr,[]);
        sums=sums+sum(flat,2); squares=squares+sum(flat.^2,2); N=N+size(flat,2);
    end
    offset=zeros(nr,1); scale=ones(nr,1);
    switch cfg.normalization
        case 'zscore'
            offset=sums/N; scale=sqrt(max(0,(squares-sums.^2/N)/(N-1)));
        case 'rms'
            scale=sqrt(squares/N);
    end
    if ~isempty(model)
        ids=find(model.neurons.animalIndex==a);
        offset=model.normalization.offset(ids); scale=model.normalization.scale(ids);
    end
    scale(scale==0)=1;
    mc=zeros(nr,numel(frames),nc); pm=zeros(nr,nc);
    for c=1:nc
        A=(X{c,a}-offset)./scale; X{c,a}=A;
        mc(:,:,c)=mean(A,3); flat=reshape(A,nr,[]); pm(:,c)=mean(flat,2);
        R=flat-pm(:,c);
        if strcmp(cfg.covariance,'withinAnimal'), covariances{c,a}=(R*R')/size(R,2);
        else, covariances{c,a}=mean(R.^2,2); end
    end
    meanCells{a}=mc; poolCells{a}=pm; included(a)=true;
    maps{end+1}=table(repmat(a,nr,1),repmat(labels(a),nr,1),find(valid), ...
        'VariableNames',{'animalIndex','animalLabel','rowInAnimal'}); %#ok<AGROW>
    offsets{end+1}=offset; scales{end+1}=scale; %#ok<AGROW>
end
assert(any(included),'neuralGeometry:Empty','No complete animals with finite neurons remain.');
time=time(frames); C=cat(1,meanCells{included}); M=cat(1,poolCells{included});
neurons=vertcat(maps{:}); normInfo=struct('method',cfg.normalization, ...
    'offset',vertcat(offsets{:}),'scale',vertcat(scales{:}));
audit=table((1:na)',labels,included,dropped,reason, ...
    'VariableNames',{'animalIndex','animalLabel','included','nDroppedNeurons','reason'});
if any(~included), warning('neuralGeometry:Excluded','Some animals were excluded; inspect result.animalAudit.'); end
end

function V=solveNoise(Y,blocks,indices,diagonal,method)
if strcmp(method,'diagonal'), V=Y./diagonal; return; end
V=zeros(size(Y));
for a=1:numel(indices)
    ix=indices{a}; if isempty(ix), continue; end
    L=blocks{a}; V(ix,:)=L'\(L\Y(ix,:));
end
end

function [U,scores]=fitAxes(D,inverse,cfg)
n=size(D,1); U=zeros(n,0); scores=zeros(0,1); base=norm(D,'fro');
if base==0, return; end
for k=1:min(cfg.nAxes,n)
    R=D-U*(U'*D);
    if norm(R,'fro')<=cfg.tolerance*base, break; end
    switch cfg.method
        case 'lda'
            % Constrained Fisher optimization, equivalent to projecting data
            % off preceding Euclidean axes and refitting in the complement.
            V=inverse(D);
            if ~isempty(U)
                Z=inverse(U); V=V-Z*((U'*Z)\(U'*V));
            end
            H=(D'*V+V'*D)/2; [Q,E]=eig(H,'vector');
            [score,j]=max(real(E)); u=V*Q(:,j);
        case {'meanSquared','regression'}
            [Q,S,~]=svd(R,'econ'); u=Q(:,1); score=S(1,1)^2;
    end
    u=u-U*(U'*u); magnitude=norm(u);
    if magnitude==0||~isfinite(magnitude), break; end
    u=u/magnitude; [~,j]=max(abs(u)); if u(j)<0, u=-u; end
    U(:,end+1)=u; scores(end+1,1)=max(0,score); %#ok<AGROW>
end
end

function out=varianceMetrics(P,V,C,D,columns,groups,nf)
[K,nt,nc]=size(P);
centered=P-mean(P,3); signal=mean(centered.^2,3); noise=mean(V,3);
total=signal+noise;
out=struct('totalByTime',total,'withinConditionByTime',noise, ...
    'conditionSignalByTime',signal,'total',mean(total,2));
% Contributions sum over conditions to conditionSignal/total at each bin.
contribution=centered.^2/nc;
out.conditionContributionByTime=safeDivide(contribution,total);
out.conditionContribution=safeDivide(reshape(mean(contribution,2),K,nc),mean(total,2));
out.conditionTotalVarianceByTime=V+centered.^2;
out.conditionTotalVariance=reshape(mean(out.conditionTotalVarianceByTime,2),K,nc);
out.allConditionFractionByTime=safeDivide(signal,total);
out.allConditionFraction=safeDivide(mean(signal,2),mean(total,2));
out.variableMarginalFractionByTime=nan(K,nt,nf);
out.variableUniqueFractionByTime=nan(K,nt,nf);
out.variableUniqueEnergyByTime=nan(K,nt,nf);
out.variableMarginalFraction=nan(K,nf); out.variableUniqueFraction=nan(K,nf);
out.variableIdentifiable=false(nf,1);
Y=reshape(permute(P,[3 1 2]),nc,[]);
Q=orth(D); fullResidual=Y-Q*(Q'*Y);
fullSSE=reshape(sum(fullResidual.^2,1)/nc,K,nt);
for f=1:nf
    g=groups{f}; fit=zeros(size(P));
    for l=1:max(g), fit(:,:,g==l)=repmat(mean(P(:,:,g==l),3),1,1,sum(g==l)); end
    marginal=mean((fit-mean(P,3)).^2,3);
    reduced=D; reduced(:,columns{f})=[]; Q=orth(reduced);
    residual=Y-Q*(Q'*Y);
    uniqueEnergy=max(0,reshape(sum(residual.^2,1)/nc,K,nt)-fullSSE);
    identifiable=rank(D)-rank(reduced)==numel(columns{f});
    if ~identifiable, uniqueEnergy(:)=NaN; end
    out.variableIdentifiable(f)=identifiable;
    out.variableUniqueEnergyByTime(:,:,f)=uniqueEnergy;
    out.variableMarginalFractionByTime(:,:,f)=safeDivide(marginal,total);
    out.variableUniqueFractionByTime(:,:,f)=safeDivide(uniqueEnergy,total);
    out.variableMarginalFraction(:,f)=safeDivide(mean(marginal,2),mean(total,2));
    out.variableUniqueFraction(:,f)=safeDivide(mean(uniqueEnergy,2),mean(total,2));
end
% Noise trace is added by the caller, not inferred from selected axes.
between=mean((C-mean(C,3)).^2,3);
out.populationBetweenConditionVarianceByTime=sum(between,1);
end

function y=safeDivide(a,b)
y=a./b; y=y+zeros(size(a)); y(~isfinite(y))=NaN;
end
