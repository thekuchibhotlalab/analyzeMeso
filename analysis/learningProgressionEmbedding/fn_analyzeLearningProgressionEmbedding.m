function [r,figures]=fn_analyzeLearningProgressionEmbedding(intAct,conditions,cfg,plotCfg,trialInfo)
%FN_ANALYZELEARNINGPROGRESSIONEMBEDDING Shared UMAP/PCA of selected learning bins.
if nargin<3, cfg=struct(); end
if nargin<4, plotCfg=struct(); end
assert(nargin>=5,'learningEmbedding:TrialInfo','Pass matching trialInfoNeural tables as input 5.');
[r,means]=fn_prepareLearningProgressionEmbedding(intAct,conditions,cfg,trialInfo);
r.embedding=[];
if r.cfg.runUMAP
    u=r.cfg.umap;
    assert(~isfield(u,'normalization')||strcmp(u.normalization,'none'), ...
        'learningEmbedding:Normalization','Use cfg.normalization; leave cfg.umap.normalization=''none''.');
    u.time=0; u.timeWindow=[]; u.normalization='none';
    u.variables=["stimulus","action","task","responsePeriod","learningBin"];
    u.animalLabels=r.cfg.animalLabels; u.missingAnimal='exclude'; u.dropNonfiniteNeurons=true;
    embedded=fn_analyzeNeuralEmbedding(means,r.pointInfo,u,struct('makePlot',false));
    assert(isequal(embedded.populationVectors,r.populationVectors), ...
        'learningEmbedding:Mapping','Embedding backend changed pooled neuron/point order.');
    r.embedding=embedded.embedding; r.backend=embedded.backend;
    r.diagnostics=embedded.diagnostics; r.embeddingConfig=embedded.cfg;
end
X=double(r.populationVectors); r.pca.mean=mean(X,1); X=X-r.pca.mean;
[~,S,V]=svd(X,'econ'); latent=diag(S).^2/(size(X,1)-1);
nPC=min([3,size(V,2),size(X,1)-1]); r.pca.weights=V(:,1:nPC);
r.pca.scores=X*r.pca.weights; r.pca.latent=latent(1:nPC); r.pca.totalVariance=sum(latent);
r.pca.explained=nan(nPC,1);
if r.pca.totalVariance>0, r.pca.explained=100*r.pca.latent/r.pca.totalVariance; end
[figures,r.plotFiles]=fn_plotLearningProgressionEmbedding(r,plotCfg);
end
