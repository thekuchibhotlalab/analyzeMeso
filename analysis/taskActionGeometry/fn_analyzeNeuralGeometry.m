function [result,figures] = fn_analyzeNeuralGeometry(activity,conditions,cfg,plotCfg)
%FN_ANALYZENEURALGEOMETRY Pooled geometry; repeated held-out LDA by default.
% activity: condition x animal cells of neuron x time x real trials.
[defaults,plots]=fn_neuralGeometryConfig();
if nargin<3 || isempty(cfg), cfg=struct(); end
if nargin<4 || isempty(plotCfg), plotCfg=struct(); end
cfg=fill(cfg,defaults); plotCfg=fill(plotCfg,plots);
cfg.method=validatestring(cfg.method,{'lda','meanSquared','regression'});
cfg.normalization=validatestring(cfg.normalization,{'none','zscore','rms'});
cfg.covariance=validatestring(cfg.covariance,{'diagonal','withinAnimal'});
cfg.missingAnimal=validatestring(cfg.missingAnimal,{'exclude','error'});
if strcmpi(cfg.method,'lda') && cfg.crossValidate
    [result,figures]=fn_crossvalidateNeuralGeometry(activity,conditions,cfg,plotCfg);
else
    [result,figures]=fn_fitNeuralGeometry(activity,conditions,cfg,plotCfg);
end
end
function s=fill(s,d)
assert(isstruct(s)&&isscalar(s),'neuralGeometry:Config','Use scalar configurations.');
extra=setdiff(fieldnames(s),fieldnames(d));
assert(isempty(extra),'neuralGeometry:Config','Unknown options: %s.',strjoin(extra,', '));
for k=fieldnames(d)'
    if ~isfield(s,k{1}), s.(k{1})=d.(k{1}); end
end
end
