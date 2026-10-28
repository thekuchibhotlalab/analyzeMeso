function [result,figures]=fn_analyzeEarlyLearningEmbedding(activity,conditions,cfg,plotCfg,trialInfo)
%FN_ANALYZEEARLYLEARNINGEMBEDDING Shared UMAP and PCA across learning chunks.
if nargin<3, cfg=struct(); end
if nargin<4, plotCfg=struct(); end
assert(nargin>=5,'earlyEmbedding:TrialInfo','Pass trialInfoNeural cells as input 5.');
[result,means]=fn_prepareEarlyLearningEmbedding(activity,conditions,cfg,trialInfo);
u=result.cfg.umap;
assert(~isfield(u,'normalization')||strcmp(u.normalization,'none'), ...
    'earlyEmbedding:Normalization','Use cfg.response.normalization; leave cfg.umap.normalization=''none''.');
% Encode each chunk/event as one condition with one time bin. This reuses the
% existing unsupervised backend and diagnostics without refitting by label.
u.time=0; u.timeWindow=[]; u.normalization='none';
u.variables=["stimulus","responsePeriod","learningBin"];
u.animalLabels=result.cfg.response.animalLabels;
u.missingAnimal='exclude'; u.dropNonfiniteNeurons=true;
conditions=result.pointInfo(:,{'conditionName','stimulus','responsePeriod','learningBin'});
embedded=fn_analyzeNeuralEmbedding(means,conditions,u,struct('makePlot',false));
result.embedding=embedded.embedding; result.backend=embedded.backend;
result.diagnostics=embedded.diagnostics;
result.embeddingConfig=embedded.cfg;
% Center each neuron across the same chunk/event points used for UMAP.
% SVD needs no Statistics Toolbox and does not apply any additional scaling.
X=double(result.populationVectors);
mu=mean(X,1); X=X-mu;
[~,S,V]=svd(X,'econ'); eigenvalues=diag(S).^2/(size(X,1)-1);
nPC=min([3,size(V,2),size(X,1)-1]);
result.pca.mean=mu;
result.pca.weights=V(:,1:nPC); % Rows correspond to result.neurons.
result.pca.scores=X*result.pca.weights; % Rows correspond to result.pointInfo.
result.pca.latent=eigenvalues(1:nPC);
result.pca.totalVariance=sum(eigenvalues);
if result.pca.totalVariance>0
    result.pca.explained=100*result.pca.latent/result.pca.totalVariance;
else
    result.pca.explained=nan(nPC,1); % No variance to explain.
end
[figures,result.plotFiles]=fn_plotEarlyLearningEmbedding(result,plotCfg);
end
