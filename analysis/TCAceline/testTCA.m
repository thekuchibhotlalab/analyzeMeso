%% do the nan masking, use z-scored data

[respMat.mat, respMat.std, respMat.flag,respMat.dprime, respMat.info] = ...
    fn_reduceStimByPeriod(trialTypeInfoStim.dffStim, ...
    'periodIdx', 1:7, 'trialTypes', [1 4 5 8], ...
    'stimWindow', 21:22, 'baseWindow', 1:19, ...
    'detrendWin', [], ...
    'zscoreAll',  false, ...
    'frameAgg','sum', 'dprimeThresh', 0);


X = respMat.mat; 
%Xmean = nanmean(nanmean(X,3),2);
%X = X - repmat(Xmean,[1 size(X,2) size(X,3)]);

X = reshape(X,[size(X,1) size(X,2) 2 2]);
nanFlag = isnan(X);
X(nanFlag) = 0; 
W = double(~nanFlag);

%%
% Suppose W is a logical/0-1 mask the same size as X
Wtt  = tensor(W);           % or sptensor if very sparse
Xobs = tensor(X);      % zero out the missing entries

R = 6;
[M,k0,info] = cp_wopt(Xobs, Wtt, R, 'init','rand',...
    'skip_zeroing',true);
% compute model fit
Xhat = double(full(M));

SSEw = sum( ((X - Xhat) .* W).^2, 'all' );   % weighted residual sum of squares
SSTw = sum( (X .* W).^2, 'all' );            % total (weighted) sum of squares

R2   = 1 - SSEw / SSTw;                      % weighted variance explained (R^2)
Fit  = 1 - norm((X - Xhat).*W, 'fro') / norm(X.*W, 'fro');   % "Tensor Toolbox" fit
VEpct = 100*R2;     % percent variance explained

%% visualize the data
lambda = M.lambda;
neuronLoading = M.U{1};
timeLoading = M.U{2};
choiceLoading = M.U{3}; 
taskLoading = M.U{4}; 

TzProj =  fn_projectTableOnWeights(trialTypeInfoStim.dffStim, neuronLoading);
figure; imagesc(corr(neuronLoading)); colorbar 
nTC = 1;

fn_plotNeuronByPeriod(TzProj,nTC,'sameAxis',true); 
figure; subplot(1,2,1);
plot(timeLoading(:,nTC),'o'); yline(0); xlim([0 8]); xline([3.5 6.5])
xticks(1:7); xticklabels({'T1E','T1M','T1L','T2E','T2M','T2L','Int'});
subplot(1,4,3);
plot(choiceLoading(:,nTC),'o'); yline(0); title('choice');xlim([0 3]); ylim([-1.2 1.2])
xticks([1 2]); xticklabels({'L', 'R'});
subplot(1,4,4);
plot(taskLoading(:,nTC),'o'); yline(0); title('task');xlim([0 3]); ylim([-1.2 1.2])
xticks([1 2]); xticklabels({'Task 1' , 'Task 2'});

%% rearrange to look at the aligned learning period of both tasks

X = respMat.mat; 
Xnew = {}; Xnew{1} = X(:,1:3,1:2); Xnew{2} = X(:,4:6,3:4);
Xnew = fn_cell2mat(Xnew,3);
Xnew = cat(2,Xnew,X(:,7,:));

[M,VEpct,TzProj] = fn_runTCA(Xnew,trialTypeInfoStim.dffStim);

%%
nModel = 5; 
figure; imagesc(corr(M{nModel}.U{1})); colorbar 
nTC = 1;

%fn_plotNeuronByPeriod(TzProj{nModel},nTC,'sameAxis',true); 
figure; subplot(1,2,1);
plot(M{nModel}.U{2}(:,nTC),'o'); yline(0); xlim([0 5]); xline(3.5)
xticks(1:4); xticklabels({'E','M','L','Int'});
subplot(1,2,2);
plot(M{nModel}.U{3}(:,nTC),'o'); yline(0); title('choice');xlim([0 5]); ylim([-1.2 1.2])
xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});
%subplot(1,4,4);
%plot(taskLoading(:,nTC),'o'); yline(0); title('task');xlim([0 3]); ylim([-1.2 1.2])
%xticks([1 2]); xticklabels({'Task 1' , 'Task 2'});


%% cp_orth_als for orthogonalized TCA

cp_orth_als;cp_apr;
%% run TCA without masking. old

R = 9; % choose components
[M,info] = cp_als(Xtt, R, ...
    'tol',1e-6, 'maxiters',500, 'printitn',10, 'init','nvecs');

% M is a ktensor with factor matrices M.U{1}, M.U{2}, M.U{3}
% Reconstruct / residual / fit:
Xhat = full(M);
relerr = norm(Xtt - Xhat) / norm(Xtt);
fit = 1 - relerr;  % explained fraction