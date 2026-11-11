function band=fn_neuralGeometryTrialSEM(r,k,rows)
% Trial SEM conditional on fitted axes. Equal-condition marginalization.
% Combine disjoint held-out folds; RMS across repeats (trials are reused).
assert(~isempty(rows),'neuralGeometry:TrialSEM','Select at least one condition.');
if isfield(r.projection,'conditionTrialSEM')
    band=reshape(sqrt(sum(r.projection.conditionTrialSEM(k,:,rows).^2,3))/numel(rows),1,[]);
    return;
end
if isfield(r,'crossValidation')&&r.crossValidation.enabled
    cv=r.crossValidation; F=cv.nFolds; R=cv.nRepeats;
    assert(numel(cv.splits)==F*R,'neuralGeometry:TrialSEM','Incomplete CV splits.');
    variance=zeros(numel(r.time),F*R);
    for s=1:F*R
        p=cv.splits{s}.projection;
        assert(isfield(p,'conditionSEM'),'neuralGeometry:TrialSEM','Saved splits lack trial SEM; rerun geometry analysis.');
        variance(:,s)=reshape(sum(p.conditionSEM(k,:,rows).^2,3)/numel(rows)^2,[],1);
    end
    repeatVariance=reshape(sum(reshape(variance,[],F,R),2)/F^2,[],R);
    band=sqrt(mean(repeatVariance,2))';
else
    band=reshape(sqrt(sum(r.projection.conditionSEM(k,:,rows).^2,3))/numel(rows),1,[]);
end
end
