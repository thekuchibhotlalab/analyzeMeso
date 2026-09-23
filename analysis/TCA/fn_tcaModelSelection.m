function [diagnostics,Mmat] = fn_tcaModelSelection(M,varargin)
%FN_TCAMODELSELECTION TCA rank-selection diagnostics across repeat fits.
%
%   [diagnostics,Mmat] = fn_tcaModelSelection(M)
%   [diagnostics,Mmat] = fn_tcaModelSelection(M,'VEpct',VEpct)
%
%   M may be either:
%       1) the normalized format: nRep x nModel cell, where M{rep,rank}
%          is a fitted ktensor model.
%       2) the older saved format: 1 x nRep or nRep x 1 cell, where each
%          M{rep} is a 1 x nModel cell of ktensor models.
%
%   The function computes tensortools-style stability diagnostics by
%   comparing models with the same rank across repeated random fits.
%   Similarity is the optimal component matching score after averaging
%   normalized factor-column correlations across all modes.

opts = parseInputs(varargin{:});
[Mmat,inputFormat] = normalizeModelCell(M);
[nRep,nModel] = size(Mmat);
rankList = inferRankList(Mmat);
VEpctMat = normalizeVEpct(opts.VEpct,nRep,nModel);

bestRep = nan(1,nModel);
similarityToBest = nan(nRep,nModel);
pairwiseSimilarityMean = nan(1,nModel);
pairwiseSimilarityMedian = nan(1,nModel);
pairwiseSimilarityAll = cell(1,nModel);
bestModel = cell(1,nModel);

for rankIdx = 1:nModel
    validRep = find(cellfun(@isTcaModel,Mmat(:,rankIdx)));
    if isempty(validRep)
        continue
    end

    if any(isfinite(VEpctMat(validRep,rankIdx)))
        [~,bestLocalIdx] = max(VEpctMat(validRep,rankIdx));
        bestRep(rankIdx) = validRep(bestLocalIdx);
    else
        bestRep(rankIdx) = validRep(1);
    end
    bestModel{rankIdx} = Mmat{bestRep(rankIdx),rankIdx};

    for repIdx = validRep(:)'
        similarityToBest(repIdx,rankIdx) = tcaModelSimilarity( ...
            bestModel{rankIdx},Mmat{repIdx,rankIdx});
    end

    pairwiseScores = [];
    for ii = 1:numel(validRep)
        for jj = (ii+1):numel(validRep)
            pairwiseScores(end+1,1) = tcaModelSimilarity( ...
                Mmat{validRep(ii),rankIdx},Mmat{validRep(jj),rankIdx}); %#ok<AGROW>
        end
    end

    pairwiseSimilarityAll{rankIdx} = pairwiseScores;
    pairwiseSimilarityMean(rankIdx) = nanmean(pairwiseScores);
    pairwiseSimilarityMedian(rankIdx) = nanmedian(pairwiseScores);
end

diagnostics = struct();
diagnostics.inputFormat = inputFormat;
diagnostics.MmatSize = size(Mmat);
diagnostics.nRep = nRep;
diagnostics.nModel = nModel;
diagnostics.rankList = rankList;
diagnostics.VEpctMat = VEpctMat;
diagnostics.bestRep = bestRep;
diagnostics.bestModel = bestModel;
diagnostics.similarityToBest = similarityToBest;
diagnostics.meanSimilarityToBest = nanmean(similarityToBest,1);
diagnostics.medianSimilarityToBest = nanmedian(similarityToBest,1);
diagnostics.pairwiseSimilarityAll = pairwiseSimilarityAll;
diagnostics.pairwiseSimilarityMean = pairwiseSimilarityMean;
diagnostics.pairwiseSimilarityMedian = pairwiseSimilarityMedian;

if opts.plotFlag
    plotDiagnostics(diagnostics);
end

end


function opts = parseInputs(varargin)
opts = struct();
opts.VEpct = [];
opts.plotFlag = true;

if isempty(varargin)
    return
end

if numel(varargin) == 1
    opts.VEpct = varargin{1};
    return
end

if mod(numel(varargin),2) ~= 0
    error('Optional inputs must be name-value pairs, or a single VEpct input.');
end

for ii = 1:2:numel(varargin)
    name = varargin{ii};
    value = varargin{ii+1};
    if ~ischar(name) && ~isstring(name)
        error('Optional input names must be character vectors or strings.');
    end

    switch lower(char(name))
        case 'vepct'
            opts.VEpct = value;
        case {'plot','plotflag','doplot'}
            opts.plotFlag = logical(value);
        otherwise
            error('Unknown optional input: %s',char(name));
    end
end
end


function [Mmat,inputFormat] = normalizeModelCell(M)
if ~iscell(M)
    error('M should be a cell array of fitted ktensor models.');
end

if all(cellfun(@isTcaModel,M(:)))
    Mmat = M;
    inputFormat = 'nRepByNModel';
    return
end

nOuter = numel(M);
isNested = cellfun(@iscell,M(:));
if all(isNested)
    nModel = max(cellfun(@numel,M(:)));
    Mmat = cell(nOuter,nModel);
    for repIdx = 1:nOuter
        temp = M{repIdx};
        for rankIdx = 1:numel(temp)
            Mmat{repIdx,rankIdx} = temp{rankIdx};
        end
    end
    inputFormat = 'oldNestedRepCell';
    return
end

error('Could not interpret M. Expected nRep x nModel cell of models, or old nested cell M{rep}{rank}.');
end


function tf = isTcaModel(model)
tf = false;
if isempty(model)
    return
end

try
    tf = iscell(model.U) && ~isempty(model.U);
catch
    tf = false;
end
end


function rankList = inferRankList(Mmat)
nModel = size(Mmat,2);
rankList = nan(1,nModel);

for rankIdx = 1:nModel
    modelIdx = find(cellfun(@isTcaModel,Mmat(:,rankIdx)),1,'first');
    if isempty(modelIdx)
        rankList(rankIdx) = rankIdx;
    else
        rankList(rankIdx) = size(Mmat{modelIdx,rankIdx}.U{1},2);
    end
end
end


function VEpctMat = normalizeVEpct(VEpct,nRep,nModel)
VEpctMat = nan(nRep,nModel);
if isempty(VEpct)
    return
end

if isnumeric(VEpct)
    if isvector(VEpct)
        n = min(numel(VEpct),nModel);
        VEpctMat(1,1:n) = VEpct(1:n);
    else
        nRow = min(size(VEpct,1),nRep);
        nCol = min(size(VEpct,2),nModel);
        VEpctMat(1:nRow,1:nCol) = VEpct(1:nRow,1:nCol);
    end
    return
end

if iscell(VEpct)
    if all(cellfun(@isnumeric,VEpct(:)))
        if isvector(VEpct) && numel(VEpct) == nRep
            for repIdx = 1:nRep
                temp = VEpct{repIdx};
                n = min(numel(temp),nModel);
                VEpctMat(repIdx,1:n) = temp(1:n);
            end
        else
            nRow = min(size(VEpct,1),nRep);
            nCol = min(size(VEpct,2),nModel);
            for repIdx = 1:nRow
                for rankIdx = 1:nCol
                    temp = VEpct{repIdx,rankIdx};
                    if ~isempty(temp)
                        VEpctMat(repIdx,rankIdx) = temp(1);
                    end
                end
            end
        end
        return
    end
end

error('Could not interpret VEpct. Expected numeric matrix/vector or cell array of numeric vectors.');
end


function sim = tcaModelSimilarity(M1,M2)
if numel(M1.U) ~= numel(M2.U)
    error('Models have different number of modes: %d vs %d.',numel(M1.U),numel(M2.U));
end

nMode = numel(M1.U);
R1 = size(M1.U{1},2);
R2 = size(M2.U{1},2);
if R1 ~= R2
    error('Model ranks differ: %d vs %d. Compare models with the same rank.',R1,R2);
end

componentScore = zeros(R1,R2,nMode);
for modeIdx = 1:nMode
    A = double(M1.U{modeIdx});
    B = double(M2.U{modeIdx});
    if size(A,1) ~= size(B,1)
        error('Mode %d size differs: %d vs %d.',modeIdx,size(A,1),size(B,1));
    end

    A = normalizeColumns(A);
    B = normalizeColumns(B);
    componentScore(:,:,modeIdx) = abs(A' * B);
end

pairScore = mean(componentScore,3);
[~,matchedScore] = bestComponentAssignment(pairScore);
sim = mean(matchedScore);
end


function A = normalizeColumns(A)
colNorm = sqrt(sum(A.^2,1));
colNorm(colNorm == 0 | isnan(colNorm)) = 1;
A = A ./ colNorm;
end


function [assignment,matchedScore] = bestComponentAssignment(scoreMat)
% Uses matchpairs when available. Otherwise falls back to greedy matching.
R = size(scoreMat,1);

if exist('matchpairs','file') == 2
    pairs = matchpairs(-scoreMat,1e6);
    assignment = nan(R,1);
    matchedScore = nan(R,1);
    for ii = 1:size(pairs,1)
        assignment(pairs(ii,1)) = pairs(ii,2);
        matchedScore(pairs(ii,1)) = scoreMat(pairs(ii,1),pairs(ii,2));
    end
else
    assignment = nan(R,1);
    matchedScore = nan(R,1);
    usedRow = false(R,1);
    usedCol = false(R,1);
    for ii = 1:R
        temp = scoreMat;
        temp(usedRow,:) = -Inf;
        temp(:,usedCol) = -Inf;
        [matchedScore(ii),idx] = max(temp(:));
        [rowIdx,colIdx] = ind2sub([R R],idx);
        assignment(rowIdx) = colIdx;
        usedRow(rowIdx) = true;
        usedCol(colIdx) = true;
    end
end
end


function plotDiagnostics(diagnostics)
rankList = diagnostics.rankList;

figure('Name','TCA model selection diagnostics','Color','w');
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile;
if any(isfinite(diagnostics.VEpctMat(:)))
    plot(rankList,diagnostics.VEpctMat','o-','Color',[0.65 0.65 0.65]);
    hold on
    plot(rankList,nanmax(diagnostics.VEpctMat,[],1),'k-o','LineWidth',2);
    ylabel('Variance explained (%)');
else
    text(0.5,0.5,'No VEpct input','HorizontalAlignment','center');
    ylabel('Variance explained (%)');
end
xlabel('nComponents');
title('Reconstruction');
box off

nexttile;
plot(rankList,diagnostics.similarityToBest','o-','Color',[0.65 0.65 0.65]);
hold on
plot(rankList,diagnostics.meanSimilarityToBest,'k-o','LineWidth',2);
%plot(rankList,diagnostics.pairwiseSimilarityMean,'r-o','LineWidth',1.5);
ylim([0 1.05]);
xlabel('nComponents');
ylabel('Model similarity');
%legend({'replicate to best','mean to best','mean pairwise'},'Location','southwest');
title('Stability');
box off
end
