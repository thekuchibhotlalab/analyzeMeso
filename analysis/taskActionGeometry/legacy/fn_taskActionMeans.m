function [C,transform,Y]=fn_taskActionMeans(X,group,normalization,transform)
%FN_TASKACTIONMEANS Equal-weight 2x2 cell means and shared neuron scaling.
if nargin<4
    flat=reshape(X,size(X,1),[]);
    transform.offset=zeros(size(X,1),1); transform.scale=ones(size(X,1),1);
    if strcmp(normalization,'zscore')
        transform.offset=mean(flat,2); transform.scale=std(flat,0,2);
    elseif strcmp(normalization,'rms')
        transform.scale=sqrt(mean(flat.^2,2));
    end
    transform.scale(transform.scale<eps)=1;
end
Y=(X-transform.offset)./transform.scale;
C=zeros(size(X,1),size(X,2),4);
for g=1:4, C(:,:,g)=mean(Y(:,:,group==g),3); end
end
