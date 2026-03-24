function [M,VEpct,TzProj] = fn_runTCA_nonneg(TCAmatrix)

% mean-center the data
X = TCAmatrix; 
% deal with nan
nanFlag = isnan(nanmean(nanmean(nanmean(X,2),3),4));
X(nanFlag,:,:,:) = []; 

R = 1:15; 
M = {}; VEpct = []; TzProj = {};
for i = 1:length(R)
    [M{i},k0,info,VEpct(i),TzProj{i}] = runTCA(X,R(i));
end

end 


function [M,k0,info,VEpct,TzProj] = runTCA(X,R)
    % loop through 
    %R = 6;
    % Construct tensor
    %Wtt  = tensor(W);           % or sptensor if very sparse
    Xobs = tensor(X);      % zero out the missing entries

    %[M,k0,info] = cp_wopt(Xobs, Wtt, R, 'init','rand',...
    %    'skip_zeroing',true);

    [M,k0,info] = cp_apr(Xobs,R,'maxiters',300);
    % compute model fit
    Xhat = double(full(M));
    
    SSEw = sum( ((X - Xhat) ).^2, 'all' );   % weighted residual sum of squares
    SSTw = sum( (X).^2, 'all' );            % total (weighted) sum of squares
    
    R2   = 1 - SSEw / SSTw;                      % weighted variance explained (R^2)
    Fit  = 1 - norm((X - Xhat), 'fro') / norm(X, 'fro');   % "Tensor Toolbox" fit
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

function TCAvar(Xobs,M)

% --- Assume you have already run cp_apr ---
% R = 5; % Number of components
% Xobs = tensor(rand(10,20,30)); % Your data tensor
% [M, k0, info] = cp_apr(Xobs, R);

% 1. Calculate the total sum of squares of the original data
total_variance = norm(Xobs)^2;

% Get the number of components from the model
R = ncomponents(M); 
fprintf('Total variance (SST) in data: %.4f\n', total_variance);
fprintf('Found %d components.\n\n', R);

% 2. Calculate variance explained by each component
variance_explained = zeros(R, 1);
for r = 1:R
    % Create a ktensor for just this single component
    % This involves taking the r-th column from each factor matrix
    component_factors = cell(ndims(Xobs), 1);
    for mode = 1:ndims(Xobs)
        component_factors{mode} = M.U{mode}(:,r);
    end
    
    % The ktensor for the single component (don't forget the weight M.lambda)
    P_r = ktensor(M.lambda(r), component_factors);
    
    % Calculate its norm and the variance it explains
    variance_explained(r) = norm(P_r)^2 / total_variance;
end

% Display the results
disp('--- Variance Explained per Component ---');
for r = 1:R
    fprintf('Component %d: %.4f%% of total variance\n', r, variance_explained(r) * 100);
end

% The total variance explained by the full model is often in info.fit
% Note: The sum of individual variances will NOT equal the total fit
% because the components are not orthogonal.
fprintf('\nTotal Fit of the full model (from info.fit): %.4f%%\n', info.fit(end) * 100);
fprintf('Sum of individual component variances: %.4f%%\n', sum(variance_explained) * 100);


end 