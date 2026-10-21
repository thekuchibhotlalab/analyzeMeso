function result=fn_taskActionBasis(M,nComponents)
%FN_TASKACTIONBASIS Ordered axes maximize captured marginal signal energy.
[U,S,~]=svd(M,'econ'); values=diag(S); energy=sum(values.^2);
tolerance=max(size(M))*eps(max([values;1]));
r=min(nComponents,sum(values>tolerance));
U=U(:,1:r);
for k=1:r
    [~,idx]=max(abs(U(:,k))); if U(idx,k)<0, U(:,k)=-U(:,k); end
end
result=struct('axes',U,'rank',r,'singularValues',values, ...
    'marginalEnergy',energy,'varianceFraction',zeros(r,1),'cumulativeVariance',zeros(r,1));
if energy>0
    result.varianceFraction=values(1:r).^2/energy;
    result.cumulativeVariance=cumsum(result.varianceFraction);
end
end
