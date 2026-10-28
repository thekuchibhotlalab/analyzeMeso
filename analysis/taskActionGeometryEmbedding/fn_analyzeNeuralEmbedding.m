function [result,figures] = fn_analyzeNeuralEmbedding(activity,conditions,cfg,plotCfg)
%FN_ANALYZENEURALEMBEDDING One unsupervised 2D UMAP of condition x time means.
% Input: condition x animal cells of neuron x time x trial activity; a matching
% conditionName + categorical-factor table; independent analysis/plot configs.
% Neurons concatenate across animals. Labels NEVER enter the UMAP fit.
% Requires the Herzenberg MATLAB run_umap package on the path (see README.md).
[defaults,defaultPlots]=fn_neuralEmbeddingConfig();
if nargin<3, cfg=struct(); end
if nargin<4, plotCfg=struct(); end
cfg=fillOptions(cfg,defaults); plotCfg=fillOptions(plotCfg,defaultPlots);
cfg.normalization=validatestring(cfg.normalization,{'none','zscore','rms'});
cfg.metric=validatestring(cfg.metric,{'correlation','euclidean','cosine'});
cfg.init=validatestring(cfg.init,{'spectral','random'});
cfg.missingAnimal=validatestring(cfg.missingAnimal,{'exclude','error'});
validateattributes(cfg.nNeighbors,{'numeric'},{'scalar','integer','>=',3,'<=',199});
validateattributes(cfg.minDist,{'numeric'},{'scalar','positive','finite','<=',10});
validateattributes(cfg.spread,{'numeric'},{'scalar','positive','finite','<=',10,'>=',cfg.minDist});
validateattributes(cfg.nEpochs,{'numeric'},{'scalar','integer','>=',5,'finite'});
validateattributes(cfg.randomize,{'logical'},{'scalar'});
validateattributes(cfg.diagnosticNeighbors,{'numeric'},{'scalar','integer','positive','finite'});
if ~isempty(cfg.maxDiagnosticPoints)
    validateattributes(cfg.maxDiagnosticPoints,{'numeric'},{'scalar','integer','positive','finite'});
end
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity), ...
    'neuralEmbedding:Input','Use a condition x animal cell array.');
[nc,na]=size(activity);
assert(istable(conditions)&&height(conditions)==nc&&ismember('conditionName',conditions.Properties.VariableNames), ...
    'neuralEmbedding:Conditions','Provide one table row per activity condition, including conditionName.');
names=string(conditions.conditionName);
assert(iscolumn(names)&&numel(unique(names))==nc&&all(~ismissing(names)&strlength(names)>0), ...
    'neuralEmbedding:Conditions','conditionName must contain unique nonempty names.');
vars=string(cfg.variables(:));
if isempty(vars), vars=string(conditions.Properties.VariableNames)'; vars(vars=="conditionName")=[]; end
assert(numel(unique(vars))==numel(vars)&&all(ismember(vars,string(conditions.Properties.VariableNames))) ...
    &&~any(vars=="conditionName"),'neuralEmbedding:Variables','Choose unique factor columns other than conditionName.');
for v=1:numel(vars)
    x=conditions.(vars(v)); labels=string(x);
    assert(iscolumn(labels)&&numel(labels)==nc&&~any(ismissing(x),'all') ...
        &&all(~ismissing(labels)&strlength(labels)>0),'neuralEmbedding:Variables','Factor labels must be nonmissing scalar values.');
end
[X,neurons,audit,normInfo,time,frames,counts]=prepareMeans(activity,cfg);
nt=numel(time); nPoints=size(X,1);
assert(nPoints>=4,'neuralEmbedding:Points','At least four condition-time points are required.');
% Correlation/cosine distances are undefined for constant/zero population vectors.
if strcmp(cfg.metric,'correlation')
    assert(size(X,2)>=2&&all(sum((X-mean(X,2)).^2,2)>0), ...
        'neuralEmbedding:Distance','Correlation needs nonconstant population vectors at every point; use euclidean for constant vectors.');
elseif strcmp(cfg.metric,'cosine')
    assert(all(sum(X.^2,2)>0),'neuralEmbedding:Distance','Cosine distance needs nonzero population vectors.');
end
assert(any(any(X~=X(1,:))),'neuralEmbedding:Constant','All condition-time population vectors are identical.');
assert(exist('run_umap','file')==2,'neuralEmbedding:Dependency', ...
    'Add the Herzenberg MATLAB UMAP package to your path; see taskActionGeometryEmbedding/README.md.');
nNeighbors=min(cfg.nNeighbors,nPoints-1);
if nNeighbors<cfg.nNeighbors
    warning('neuralEmbedding:Neighbors','nNeighbors reduced from %d to %d for %d points.',cfg.nNeighbors,nNeighbors,nPoints);
end
if cfg.verbose
    fprintf('UMAP: %d condition-time means, %d pooled neurons, %d animals; %s distance.\n', ...
        nPoints,size(X,2),sum(audit.included),cfg.metric);
end
state=rng; restoreRng=onCleanup(@()rng(state)); %#ok<NASGU>
warningState=warning; restoreWarnings=onCleanup(@()warning(warningState)); %#ok<NASGU>
% One output avoids optional clustering. No labels, templates, or supervision.
embedding=run_umap(X,'n_neighbors',nNeighbors,'n_components',2, ...
    'min_dist',cfg.minDist,'spread',cfg.spread,'metric',cfg.metric, ...
    'n_epochs',cfg.nEpochs,'randomize',cfg.randomize,'init',cfg.init,'method',cfg.backendMethod, ...
    'sgd_tasks',1,'verbose','none','ask_to_save_template',false);
assert(isequal(size(embedding),[nPoints 2])&&all(isfinite(embedding),'all'), ...
    'neuralEmbedding:Backend','run_umap returned an invalid embedding.');
conditionIndex=repelem((1:nc)',nt); timeIndex=repmat((1:nt)',nc,1);
result=struct('embedding',embedding,'populationVectors',X,'conditions',conditions, ...
    'variables',vars,'time',time,'cfg',cfg);
result.pointInfo=table((1:nPoints)',conditionIndex,timeIndex,reshape(frames(timeIndex),[],1), ...
    reshape(time(timeIndex),[],1),'VariableNames',{'pointIndex','conditionIndex','timeIndex','frameIndex','time'});
result.pointLabels=conditions(conditionIndex,:);
result.neurons=neurons; result.animalAudit=audit; result.trialCounts=counts;
result.normalization=normInfo;
result.backend=struct('name','Herzenberg MATLAB run_umap','file',which('run_umap'), ...
    'version',UMAP.VERSION,'matlabVersion',version, ...
    'method',cfg.backendMethod,'nNeighborsUsed',nNeighbors,'nComponents',2, ...
    'randomize',cfg.randomize,'nEpochs',cfg.nEpochs,'initialization',cfg.init);
result.diagnostics=diagnostics(X,embedding,cfg);
result.estimation='Unsupervised embedding of trial means; labels are only annotations. No trial-level inference.';
[figures,result.plotFiles]=fn_plotNeuralEmbedding(result,plotCfg);
end

function cfg=fillOptions(cfg,defaults)
if isempty(cfg), cfg=struct(); end
assert(isstruct(cfg)&&isscalar(cfg),'neuralEmbedding:Config','Use a scalar config struct.');
extra=setdiff(fieldnames(cfg),fieldnames(defaults));
assert(isempty(extra),'neuralEmbedding:Config','Unknown options: %s.',strjoin(extra,', '));
for name=fieldnames(defaults)'
    if ~isfield(cfg,name{1}), cfg.(name{1})=defaults.(name{1}); end
end
end

function [X,neurons,audit,normInfo,time,frames,counts]=prepareMeans(activity,cfg)
[nc,na]=size(activity); counts=zeros(nc,na); labels=string(cfg.animalLabels(:));
if isempty(labels), labels="animal"+string((1:na)'); end
assert(numel(labels)==na&&numel(unique(labels))==na&&all(~ismissing(labels)&strlength(labels)>0), ...
    'neuralEmbedding:Labels','Provide one unique animal label per column.');
included=false(na,1); dropped=zeros(na,1); reason=strings(na,1);
blocks=cell(na,1); maps=blocks; offsets=blocks; scales=blocks; ntAll=[];
for a=1:na
    if any(cellfun(@isempty,activity(:,a)))
        assert(~strcmp(cfg.missingAnimal,'error'),'neuralEmbedding:Missing','%s has an empty condition.',labels(a));
        reason(a)="empty condition; whole animal excluded"; continue;
    end
    nn=size(activity{1,a},1); nt=size(activity{1,a},2);
    if isempty(ntAll), ntAll=nt; end
    assert(nt==ntAll,'neuralEmbedding:Shape','Time-bin counts must match across animals.');
    if isempty(cfg.time)
        validateattributes(cfg.frameRate,{'numeric'},{'scalar','positive','finite'});
        validateattributes(cfg.eventFrame,{'numeric'},{'scalar','integer','positive','finite'});
        time=((1:nt)-cfg.eventFrame)/cfg.frameRate;
    else
        time=reshape(cfg.time,1,[]);
        assert(numel(time)==nt&&all(isfinite(time))&&all(diff(time)>0), ...
            'neuralEmbedding:Time','time must be finite, increasing, and match the input bins.');
    end
    frames=1:nt;
    if ~isempty(cfg.timeWindow)
        validateattributes(cfg.timeWindow,{'numeric'},{'vector','numel',2,'finite','real'});
        assert(cfg.timeWindow(1)<=cfg.timeWindow(2),'neuralEmbedding:Time','Invalid time window.');
        frames=find(time>=cfg.timeWindow(1)&time<=cfg.timeWindow(2));
    end
    assert(~isempty(frames),'neuralEmbedding:Time','No selected time bins.');
    means=zeros(nn,numel(frames),nc); valid=true(nn,1);
    sums=zeros(nn,1); squares=sums; N=0;
    for c=1:nc
        A=activity{c,a}; validateattributes(A,{'numeric'},{'real','nonempty'});
        assert(ndims(A)<=3&&size(A,1)==nn&&size(A,2)==nt,'neuralEmbedding:Shape', ...
            'Neuron identity/order and time bins must match across conditions within each animal.');
        A=double(A(:,frames,:)); counts(c,a)=size(A,3); flat=reshape(A,nn,[]);
        valid=valid&all(isfinite(flat),2); means(:,:,c)=mean(A,3);
        sums=sums+sum(flat,2); squares=squares+sum(flat.^2,2); N=N+size(flat,2);
    end
    assert(cfg.dropNonfiniteNeurons||all(valid),'neuralEmbedding:Nonfinite','Nonfinite neural activity.');
    dropped(a)=sum(~valid);
    if ~any(valid), reason(a)="no finite neurons"; continue; end
    offset=zeros(sum(valid),1); scale=ones(sum(valid),1);
    switch cfg.normalization
        case 'zscore'
            offset=sums(valid)/N;
            scale=sqrt(max(0,(squares(valid)-sums(valid).^2/N)/(N-1)));
        case 'rms'
            scale=sqrt(squares(valid)/N);
    end
    scale(scale==0)=1;
    means=(means(valid,:,:)-offset)./scale;
    % Time varies fastest within each condition. Animals concatenate as columns.
    blocks{a}=reshape(means,sum(valid),[])'; included(a)=true;
    maps{a}=table(repmat(a,sum(valid),1),repmat(labels(a),sum(valid),1),find(valid), ...
        'VariableNames',{'animalIndex','animalLabel','rowInAnimal'});
    offsets{a}=offset; scales{a}=scale;
end
assert(any(included),'neuralEmbedding:Empty','No complete animals with finite neurons remain.');
X=cat(2,blocks{included}); neurons=vertcat(maps{included}); time=time(frames);
normInfo=struct('method',cfg.normalization,'offset',vertcat(offsets{included}),'scale',vertcat(scales{included}));
audit=table((1:na)',labels,included,dropped,reason, ...
    'VariableNames',{'animalIndex','animalLabel','included','nDroppedNeurons','reason'});
if any(~included), warning('neuralEmbedding:Excluded','Some animals were excluded; inspect result.animalAudit.'); end
end

function d=diagnostics(X,Y,cfg)
n=size(X,1); k=min(cfg.diagnosticNeighbors,floor((n-1)/2));
d=struct('nNeighbors',k,'neighborOverlap',NaN,'trustworthiness',NaN,'status','not computed');
if ~isempty(cfg.maxDiagnosticPoints)&&n>cfg.maxDiagnosticPoints
    d.status='skipped: nPoints exceeds maxDiagnosticPoints'; return;
end
% Compare input-space neighbors (chosen metric) with 2D Euclidean neighbors.
DX=pdist2(X,X,cfg.metric); DY=pdist2(Y,Y,'euclidean');
DX(1:n+1:end)=-Inf; DY(1:n+1:end)=-Inf;
[~,hi]=sort(DX,2); [~,lo]=sort(DY,2); penalty=0; overlap=0;
for i=1:n
    h=hi(i,2:k+1); l=lo(i,2:k+1); overlap=overlap+numel(intersect(h,l))/k;
    ranks=zeros(1,n); ranks(hi(i,:))=0:n-1;
    intrusion=setdiff(l,h); penalty=penalty+sum(ranks(intrusion)-k);
end
d.neighborOverlap=overlap/n;
d.trustworthiness=1-2*penalty/(n*k*(2*n-3*k-1)); d.status='computed';
end
