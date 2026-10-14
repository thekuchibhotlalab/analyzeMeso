function [W,info]=fn_taskActionNoiseMetric(Y,group,C,opts)
%FN_TASKACTIONNOISEMETRIC Estimate one noise metric from training trials only.
% Residuals subtract each task/action/time mean. Time samples contribute to
% covariance estimation, but are never treated as independent CV partitions.
n=size(Y,1); R=Y;
for g=1:4, R(:,:,group==g)=Y(:,:,group==g)-C(:,:,g); end
R=reshape(R,n,[]);
dof=size(Y,2)*(size(Y,3)-4);
variance=sum(R.^2,2)/max(dof,1);
positive=variance(variance>0); base=1;
if ~isempty(positive), base=mean(positive); end
ridge=opts.noiseRidge*base;
switch opts.noiseMetric
    case 'diagonal'
        W=diag(1./sqrt(variance+ridge));
    case 'shrinkage'
        S=(R*R')/max(dof,1);
        S=(1-opts.noiseShrinkage)*S+opts.noiseShrinkage*diag(diag(S))+ridge*eye(n);
        W=chol((S+S')/2,'lower')\eye(n);
    case 'identity'
        W=eye(n);
end
info=struct('method',opts.noiseMetric,'residualVariance',variance, ...
    'ridge',ridge,'shrinkage',opts.noiseShrinkage);
end
