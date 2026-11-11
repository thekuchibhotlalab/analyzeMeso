function r=fn_addNeuralGeometryTrialSEM(r)
%FN_ADDNEURALGEOMETRYTRIALSEM Add explicit axis x time x condition trial SEM.
% Also upgrades saved geometry structures without reloading neural trials.
if isfield(r,'crossValidation')&&r.crossValidation.enabled
    cv=r.crossValidation; F=cv.nFolds; R=cv.nRepeats;
    assert(numel(cv.splits)==F*R,'neuralGeometry:TrialSEM','Incomplete CV splits.');
    variance=zeros(size(r.projection.conditionMean));
    for s=1:F*R
        p=cv.splits{s}.projection;
        assert(isfield(p,'conditionSEM'),'neuralGeometry:TrialSEM','Saved splits lack trial SEM; rerun geometry analysis.');
        assert(isequal(size(p.conditionSEM),size(variance)),'neuralGeometry:TrialSEM','Split dimensions disagree.');
        variance=variance+p.conditionSEM.^2;
    end
    r.projection.conditionTrialSEM=sqrt(variance./(F^2*R));
    r.projection.trialSEMEstimation='Fixed-axis trial SEM: combine disjoint held-out folds, RMS across repeats; no sqrt(repeats) reduction for reused trials. Not axis-fit or between-animal uncertainty.';
else
    r.projection.conditionTrialSEM=r.projection.conditionSEM;
    r.projection.trialSEMEstimation='Fixed-axis trial SEM; independent trial/animal contributions, not axis-fit or between-animal uncertainty.';
end
end
