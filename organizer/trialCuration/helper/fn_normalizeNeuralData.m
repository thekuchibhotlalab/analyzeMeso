function neuralSelection = fn_normalizeNeuralData(neuralSelection,cfg)
%FN_NORMALIZENEURALDATA Interface for Ziyi's later normalization.
for k=1:numel(neuralSelection)
    X=neuralSelection(k).neuralRaw;
    if isempty(X)
        neuralSelection(k).neuralNorm=[];
        neuralSelection(k).normalizationApplied="none";
        continue;
    end

    if isempty(cfg.normalizationFcn)
        neuralSelection(k).neuralNorm=X;
        neuralSelection(k).normalizationApplied="none";
    else
        meta=struct('conditionName',neuralSelection(k).name, ...
                    'sessionRowsUsed',neuralSelection(k).sessionRowsUsed);
        Xn=cfg.normalizationFcn(X,neuralSelection(k).trialInfoNeural,meta,cfg);
        if ~isequal(size(Xn),size(X))
            error('Normalization must preserve neurons x time x trials.');
        end
        neuralSelection(k).neuralNorm=Xn;
        neuralSelection(k).normalizationApplied="custom";
    end
end
end
