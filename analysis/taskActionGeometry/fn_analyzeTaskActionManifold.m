function result=fn_analyzeTaskActionManifold(curated,opts)
%FN_ANALYZETASKACTIONMANIFOLD Geometry of task/action population trajectories.
% Each time bin is a POINT in neuron space, not an independent replicate.
% Quantitative distances use the full neuron space. PCA is display only.
% Input: 4 x animal cells (T1L,T1R,T2L,T2R), or a curated neural structure.
if nargin<2, opts=fn_taskActionGeometryConfig(); end
assert(~isfield(opts,'averageTime')||~opts.averageTime,'taskGeometry:Time', ...
    'Manifold analysis requires averageTime=false to retain trajectories.');
[data,opts]=fn_prepareTaskActionData(curated,opts);
[C,~,transform,W,noise]=fn_taskActionPopulationMeans(data,opts,[],true);
n=size(C,1); nt=size(C,2); P=reshape(C,n,[]); Z=W*P;
result.options=opts; result.data=rmfield(data,intersect(fieldnames(data),{'X','animalData'})); result.conditionMeans=C;
result.normalization=transform; result.noise=noise; result.metricTransform=W;
result.points=table(repelem(data.cellNames,nt),repmat(data.time(:),4,1), ...
    'VariableNames',{'condition','time'});
% Descriptive full-data geometry in the same metric used for distances.
CW=reshape(Z,n,nt,4); M=fn_taskActionMarginals(CW);
taskBasis=fn_taskActionBasis(M.task,opts.nComponents);
actionBasis=fn_taskActionBasis(M.action,opts.nComponents);
% These weights project normalized activity before noise whitening.
taskBasis.neuronWeights=W'*taskBasis.axes;
actionBasis.neuronWeights=W'*actionBasis.axes;
result.taskBasis=taskBasis; result.actionBasis=actionBasis;
result.taskActionOverlap=fn_taskActionOverlap(taskBasis.axes,actionBasis.axes);
result.timeGeometry=table(data.time(:), ...
    fn_angle(M.task,M.action)', ...
    fn_angle(CW(:,:,2)-CW(:,:,1),CW(:,:,4)-CW(:,:,3))', ...
    fn_angle(CW(:,:,3)-CW(:,:,1),CW(:,:,4)-CW(:,:,2))', ...
    sum(M.task.^2,1)'/n,sum(M.action.^2,1)'/n,sum(M.interaction.^2,1)'/n, ...
    'VariableNames',{'time','taskActionAngleDeg','actionAcrossTasksAngleDeg', ...
    'taskAcrossActionsAngleDeg','taskEnergy','actionEnergy','interactionEnergy'});
result.interactionFraction=sum(M.interaction.^2,'all')/max( ...
    sum(M.task.^2+M.action.^2+M.interaction.^2,'all'),eps);
% PCA only provides coordinates for a low-dimensional display.
center=mean(Z,2); [U,S,~]=svd(Z-center,'econ'); nPC=min(3,size(U,2));
coordinates=zeros(3,4*nt); coordinates(1:nPC,:)=U(:,1:nPC)'*(Z-center);
result.embedding=struct('method','PCA of noise-normalized means (display only)', ...
    'coordinates',reshape(coordinates,3,nt,4),'axes',U(:,1:nPC), ...
    'varianceFraction',diag(S).^2/max(sum(diag(S).^2),eps));
arc=zeros(4,1); turning=nan(4,1);
for g=1:4
    tangent=diff(CW(:,:,g),1,2); arc(g)=sum(sqrt(sum(tangent.^2,1)/n));
    if nt>2, turning(g)=mean(fn_angle(tangent(:,1:end-1),tangent(:,2:end)),'omitnan'); end
end
result.trajectoryShape=table(data.cellNames,arc,turning, ...
    'VariableNames',{'condition','arcLength','meanTurningAngleDeg'});
% Crossvalidated distance: (muA_i-muA_j)' Pnoise (muB_i-muB_j)/n.
% Retain negative estimates; zero means no reliable separation.
stream=RandStream('mt19937ar','Seed',opts.seed);
rdm=zeros(4*nt); cellDistance=nan(4,4,nt,opts.nSplits);
factorEnergy=nan(nt,3,opts.nSplits); actionGeneralization=nan(nt,opts.nSplits);
splits=cell(opts.nSplits,1);
for s=1:opts.nSplits
    [A,B,~,Ws,~,splits{s}]=fn_taskActionPopulationMeans(data,opts,stream,true);
    Aw=reshape(Ws*reshape(A,n,[]),n,nt,4);
    Bw=reshape(Ws*reshape(B,n,[]),n,nt,4);
    G=reshape(Aw,n,[])'*reshape(Bw,n,[]);
    d=diag(G); D=(d+d'-G-G')/n;
    D(1:size(D,1)+1:end)=0; rdm=rdm+D/opts.nSplits;
    for t=1:nt
        idx=t+(0:3)*nt; cellDistance(:,:,t,s)=D(idx,idx);
    end
    MA=fn_taskActionMarginals(Aw); MB=fn_taskActionMarginals(Bw);
    fields={'task','action','interaction'};
    for f=1:3, factorEnergy(:,f,s)=sum(MA.(fields{f}).*MB.(fields{f}),1)'/n; end
    actionGeneralization(:,s)=(sum((Aw(:,:,2)-Aw(:,:,1)).*(Bw(:,:,4)-Bw(:,:,3)),1) ...
        +sum((Bw(:,:,2)-Bw(:,:,1)).*(Aw(:,:,4)-Aw(:,:,3)),1))'/(2*n);
end
result.cv=struct('rdm',rdm,'distanceByTime',mean(cellDistance,4), ...
    'distanceByTimeSplits',cellDistance,'factorNames',{{'task','action','interaction'}}, ...
    'factorEnergy',mean(factorEnergy,3),'factorEnergySplits',factorEnergy, ...
    'actionGeneralization',mean(actionGeneralization,2), ...
    'actionGeneralizationSplits',actionGeneralization,'splits',{splits});
result.figures=[];
if opts.makePlots
    result.figures=figure('Name','Task/action trajectory geometry','Color','w','Position',[100 100 1350 760]);
    tiledlayout(2,3,'TileSpacing','compact');
    nexttile; hold on; colors=lines(4); coords=result.embedding.coordinates;
    for g=1:4
        plot3(coords(1,:,g),coords(2,:,g),coords(3,:,g),'Color',colors(g,:),'LineWidth',1.5);
        plot3(coords(1,1,g),coords(2,1,g),coords(3,1,g),'o','Color',colors(g,:),'HandleVisibility','off');
    end
    xlabel('PC1'); ylabel('PC2'); zlabel('PC3'); view(3); grid on;
    legend(data.cellNames,'Location','best','Interpreter','none'); title('Mean trajectories (circle=start)');
    nexttile; imagesc(rdm); axis image; colorbar;
    ticks=(0:3)*nt+(nt+1)/2;
    xticks(ticks); xticklabels(data.cellNames); yticks(ticks); yticklabels(data.cellNames);
    set(gca,'TickLabelInterpreter','none');
    title('Crossvalidated squared distances'); xlabel('Condition, then time');
    nexttile; plot(data.time,result.cv.factorEnergy,'LineWidth',1.4); yline(0,':');
    xlabel('Time (s)'); ylabel('Crossvalidated contrast energy / neuron');
    legend('Task','Action','Interaction','Location','best'); title('Reliable factor separation');
    nexttile; plot(data.time,result.timeGeometry{:,2:4},'LineWidth',1.4); yline(90,':');
    xlabel('Time (s)'); ylabel('Angle (degrees)'); ylim([0 180]);
    legend('Task vs action','Action across tasks','Task across actions','Location','best');
    title('Descriptive contrast angles');
    nexttile; plot(data.time,result.cv.actionGeneralization,'LineWidth',1.4); yline(0,':');
    xlabel('Time (s)'); ylabel('Cross-task action inner product / neuron');
    title('Shared action coding across tasks');
    nexttile; plot(result.taskActionOverlap.principalAnglesDeg,'o-'); ylim([0 90]);
    xlabel('Principal angle index'); ylabel('Angle (degrees)');
    title({'Task/action subspaces',sprintf('Interaction fraction %.3f',result.interactionFraction)});
end
end

function angle=fn_angle(A,B)
denominator=sqrt(sum(A.^2,1).*sum(B.^2,1));
c=sum(A.*B,1)./denominator; c(denominator<=eps)=NaN;
angle=acosd(max(-1,min(1,c)));
angle(isnan(c))=NaN;
end
