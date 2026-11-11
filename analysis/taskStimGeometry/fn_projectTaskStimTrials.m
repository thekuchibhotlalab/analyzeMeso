function P=fn_projectTaskStimTrials(X,maps,W,thresholds,indices,cfg,nc,na)
%FN_PROJECTTASKSTIMTRIALS Trial provenance and pooled population projections.
stream=RandStream('mt19937ar','Seed',cfg.seed); animals=find(~cellfun(@isempty,indices));
P=struct('scores',{cell(nc,1)},'margins',{cell(nc,1)},'sourceTrial',{cell(nc,1)}, ...
    'sourceRowInReduced',{cell(nc,1)},'animalIndices',animals(:)', ...
    'animalContribution',{cell(nc,na)},'isPseudoPopulation',numel(animals)>1);
P.sampling='allTrials';
if ~isempty(cfg.nPseudoTrials)&&numel(animals)>1, P.sampling='fixedCount'; end
% Shorter animals repeat shuffled cycles; default mode covers every valid trial.
for c=1:nc
    counts=cellfun(@(x)size(x,2),X(c,animals));
    if numel(animals)==1
        N=counts(1); % With one animal show every actual trial, no resampling.
    elseif isempty(cfg.nPseudoTrials), N=max(counts);
    else, N=cfg.nPseudoTrials; end
    scores=zeros(N,size(W,2)); source=zeros(N,numel(animals)); reduced=source;
    for j=1:numel(animals)
        a=animals(j); contribution=X{c,a}'*W(indices{a},:);
        P.animalContribution{c,a}=contribution;
        if numel(animals)==1, rows=(1:N)';
        elseif isempty(cfg.nPseudoTrials)
            rows=[];
            while numel(rows)<N
                rows=[rows;randperm(stream,counts(j))']; %#ok<AGROW>
            end
            rows=rows(1:N);
        else, rows=randi(stream,counts(j),N,1); end
        scores=scores+contribution(rows,:);
        reduced(:,j)=rows; source(:,j)=maps{c,a}.sourceTrial(rows);
    end
    P.scores{c}=scores; P.margins{c}=scores-thresholds;
    P.sourceTrial{c}=source; P.sourceRowInReduced{c}=reduced;
end
end


