T = tensor(zmat_full);
%% Run TCA
saveresults = true;
plotstats = true;

% Initialize variables
addfits = nan(length(addf),1);
permrep = nchoosek(1:nrepeats,2);   
nComparisons = size(permrep,1);
nComps = nrepeats-1;
fits = nan(nR,nrepeats);
% scores = nan(nR,nComparisons); 
scores_tobestfit = nan(nR,nComparisons); 
models = cell(nR,nrepeats);
inits = cell(nR,nrepeats);
outputs = cell(nR,nrepeats);
for R=8:nR % loop through ranks
    for r = 1:nrepeats   
        disp(['# components = ' num2str(R) ', iteration ' num2str(r)]);
        [K,k0,outpt,fit] = cp_als(T,R); 
        % Run cp_als: estimate of the best rank-R CP model of T (tensor) 
        % using an alternating least-squares algorithm
        fits(R,r) = fit;
        models{R,r} = K;
        inits{R,r} = k0;
        outputs{R,r} = outpt;
    end
%     for j=1:nComparisons
%         scores(R,j) = score(models{R,permrep(j,1)},models{R,permrep(j,2)});
%     end
end

if ~isempty(addf)
    for j=1:length(addf)
        [~,~,~,fit] = cp_als(T,addf(j)); 
        addfits(j) = fit;
    end
end