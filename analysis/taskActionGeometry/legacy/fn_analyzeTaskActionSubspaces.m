function result=fn_analyzeTaskActionSubspaces(curated,opts)
%FN_ANALYZETASKACTIONSUBSPACES Ranked task/action axes from balanced contrasts.
% Input: 4 x animal cells of neuron x time x trials, ordered T1L,T1R,T2L,T2R.
% Also accepts the output of a.fn_prepareNeuralData(curated).
% SVD maximizes contrast energy, not classification accuracy. Each factor has
% its own orthonormal basis; task and action bases are NOT forced orthogonal.
if nargin<2, opts=[]; end
[data,opts]=fn_prepareTaskActionData(curated,opts);
[C,~,transform]=fn_taskActionPopulationMeans(data,opts);
M=fn_taskActionMarginals(C); factors={'task','action','interaction','time'};
result.options=opts; result.data=rmfield(data,intersect(fieldnames(data),{'X','animalData'}));
result.conditionMeans=C; result.normalization=transform; result.marginals=M;
energy=zeros(4,1);
for f=1:4
    name=factors{f}; energy(f)=sum(M.(name).^2,'all');
    result.(name)=fn_taskActionBasis(M.(name),opts.nComponents);
    U=result.(name).axes;
    result.(name).trajectories=reshape(U'*reshape(C,size(C,1),[]),size(U,2),size(C,2),4);
end
fraction=energy/max(sum(energy),eps);
result.variance=table(string(factors(:)),energy,fraction, ...
    'VariableNames',{'factor','energy','fractionOfConditionMeanVariance'});
% Leakage/cross-capture is meaningful because bases were fit independently.
capture=nan(3,3);
for f=1:3
    U=result.(factors{f}).axes;
    for g=1:3
        if energy(g)>0, capture(f,g)=sum((U'*M.(factors{g})).^2,'all')/energy(g); end
    end
end
result.crossCapture=array2table(capture,'VariableNames',factors(1:3),'RowNames',factors(1:3));
result.taskActionOverlap=fn_taskActionOverlap(result.task.axes,result.action.axes);
stream=RandStream('mt19937ar','Seed',opts.seed);
scores=nan(opts.nSplits,opts.nComponents,3); splits=cell(opts.nSplits,1);
for s=1:opts.nSplits
    [A,B,~,~,~,splits{s}]=fn_taskActionPopulationMeans(data,opts,stream);
    MA=fn_taskActionMarginals(A); MB=fn_taskActionMarginals(B);
    for f=1:3
        name=factors{f}; fit=fn_taskActionBasis(MA.(name),opts.nComponents);
        denominator=sum(MB.(name).^2,'all');
        for r=1:fit.rank
            U=fit.axes(:,1:r); prediction=U*(U'*MA.(name));
            if denominator>0
                scores(s,r,f)=1-sum((MB.(name)-prediction).^2,'all')/denominator;
            end
        end
    end
end
result.cv=struct('factorNames',{factors(1:3)},'predictiveVariance',scores, ...
    'meanPredictiveVariance',reshape(mean(scores,1,'omitnan'),opts.nComponents,3), ...
    'sdPredictiveVariance',reshape(std(scores,0,1,'omitnan'),opts.nComponents,3), ...
    'splits',{splits});
result.figures=[];
if opts.makePlots
    result.figures=figure('Name','Task/action linear subspaces','Color','w','Position',[100 100 1100 750]);
    tiledlayout(2,2,'TileSpacing','compact');
    nexttile; bar(1:4,fraction); xticks(1:4); xticklabels(factors);
    ylabel('Fraction of condition-mean variance');
    title('Balanced variance decomposition');
    nexttile; hold on;
    for f=1:3
        fit=result.(factors{f}); plot(1:fit.rank,fit.cumulativeVariance,'o-');
    end
    xlabel('Number of axes'); ylabel('Cumulative marginal variance'); legend(factors(1:3),'Location','best');
    title('In-sample contrast energy'); ylim([0 1.05]);
    nexttile; hold on;
    for f=1:3
        errorbar(1:opts.nComponents,result.cv.meanPredictiveVariance(:,f), ...
            result.cv.sdPredictiveVariance(:,f),'o-');
    end
    yline(0,':'); xlabel('Number of axes'); ylabel('Held-out predictive variance');
    title('Mean +/- split SD (not a CI)');
    nexttile; imagesc(capture,[0 1]); colorbar; axis square;
    xticks(1:3); xticklabels(factors(1:3)); yticks(1:3); yticklabels(factors(1:3));
    xlabel('Signal being projected'); ylabel('Basis used'); title('Cross-capture of marginal energy');
end
if opts.verbose
    disp(result.variance);
    fprintf('Task/action principal angles (degrees): %s\n',num2str(result.taskActionOverlap.principalAnglesDeg'));
end
end
