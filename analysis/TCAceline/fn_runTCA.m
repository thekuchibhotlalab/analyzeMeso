function [M,VEpct,TzProj] = fn_runTCA(TCAmatrix,Tz)

% mean-center the data
X = TCAmatrix; 

Xmean = reshape(X,size(X,1),[]);
Xmean = nanmean(Xmean,2);

X = X - repmat(Xmean,[1 size(X,2) size(X,3) size(X,4)]);

% deal with nan
nanFlag = isnan(X);
X(nanFlag) = 0; 
W = double(~nanFlag);


R = 1:15; 
M = {}; VEpct = []; TzProj = {};
for i = 1:length(R)
    [M{i},k0,info,VEpct(i),TzProj{i}] = runTCA(X,W,R(i),Tz);

end

end 


function [M,k0,info,VEpct,TzProj] = runTCA(X,W,R,Tz)
    % loop through 
    %R = 6;
    % Construct tensor
    Wtt  = tensor(W);           % or sptensor if very sparse
    Xobs = tensor(X);      % zero out the missing entries

    %[M,k0,info] = cp_wopt(Xobs, Wtt, R, 'init','rand',...
    %    'skip_zeroing',true);

    [M,k0,info] = cp_als(Xobs,R);
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
    %taskLoading = M.U{4}; 
    TzProj = []; 
    %TzProj =  fn_projectTableOnWeights(Tz, neuronLoading);



end 