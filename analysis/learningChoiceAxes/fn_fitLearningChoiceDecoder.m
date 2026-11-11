function model=fn_fitLearningChoiceDecoder(X,y,cfg)
%FN_FITLEARNINGCHOICEDECODER Training-only scaling; raw-coordinate L -> R axis.
% X is trials x fixed tracked neurons; y is -1 (L), +1 (R).
offset=mean(X,1); scale=std(X,0,1); scale(scale<1e-12)=1;
Z=(X-offset)./scale;
if strcmpi(cfg.decoder,'svm')
    classifier=fitcsvm(Z,y,'KernelFunction','linear','BoxConstraint',cfg.svmBoxConstraint, ...
        'Standardize',false,'ClassNames',[-1;1],'Prior','uniform');
    w=classifier.Beta; bias=classifier.Bias;
else
    left=Z(y==-1,:); right=Z(y==1,:);
    muL=mean(left,1); muR=mean(right,1);
    variance=((size(left,1)-1)*var(left,0,1)+(size(right,1)-1)*var(right,0,1)) ...
        /(size(Z,1)-2);
    ridge=cfg.ldaRidge*max(mean(variance),eps);
    w=((muR-muL)./(variance+ridge))'; bias=-(muR+muL)*w/2;
end
raw=w./scale'; rawBias=bias-offset*raw;
if norm(raw)>0, axis=raw/norm(raw); else, axis=nan(size(raw)); end
model=struct('weights',raw,'bias',rawBias,'axis',axis,'offset',offset,'scale',scale);
end
