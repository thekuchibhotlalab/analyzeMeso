function overlap=fn_taskActionOverlap(U,V)
%FN_TASKACTIONOVERLAP Principal angles between independently fitted bases.
c=min(1,max(0,svd(U'*V)));
overlap.principalAnglesDeg=acosd(c);
overlap.meanSquaredCosine=NaN;
if ~isempty(c), overlap.meanSquaredCosine=mean(c.^2); end
overlap.rankTask=size(U,2); overlap.rankAction=size(V,2);
% For independent random subspaces, E[||U'V||_F^2/min(p,q)]=max(p,q)/N.
overlap.randomOrientationExpectedOverlap=max(size(U,2),size(V,2))/size(U,1);
end
