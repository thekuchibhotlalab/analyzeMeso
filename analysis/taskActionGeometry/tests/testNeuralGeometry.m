function tests=testNeuralGeometry
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
end
function testPooledAxesAndRawWeights(t)
[X,T,c,p]=fixture(); c.method='meanSquared'; c.nAxes=3;
r=fn_analyzeNeuralGeometry(X,T,c,p);
verifyEqual(t,height(r.neurons),6);
verifyEqual(t,r.neurons.animalIndex,[1;1;1;2;2;2]);
verifyEqual(t,[r.factors.nAxes],[1 1]);
verifyGreaterThan(t,abs(dot(r.factors(1).weights,[2;1;0;2;1;0]/sqrt(10))),1-1e-10);
verifyEqual(t,r.similarity.angleDegrees(1,2),90,'AbsTol',1e-8);
verifyEqual(t,r.weightsRaw,r.weights);
verifyEmpty(t,r.projectionOffset(r.projectionOffset~=0));
end
function testFisherAndSequentialDeflation(t)
[X,T,c,p]=fixture(); r=fn_analyzeNeuralGeometry(X,T,c,p);
D=[]; v=[];
for a=1:2
    mu=zeros(3,4); noise=zeros(3,4);
    for k=1:4
        A=reshape(X{k,a},3,[]); mu(:,k)=mean(A,2); noise(:,k)=var(A,1,2);
    end
    dm=(mean(mu(:,3:4),2)-mean(mu(:,1:2),2))/2;
    within=mean(noise,2)+[0;0;1]; % Action is a within-task nuisance.
    D=[D;dm]; v=[v;within]; %#ok<AGROW>
end
expected=D./(v+c.ridge*mean(v)); expected=expected/norm(expected);
U=r.factors(1).weights;
verifyGreaterThan(t,abs(dot(U(:,1),expected)),1-1e-9);
verifyGreaterThanOrEqual(t,size(U,2),2);
verifyEqual(t,U'*U,eye(size(U,2)),'AbsTol',1e-9);
% Orthogonal residuals retain some signal because noise-weighted first axis
% is not parallel to the mean difference. Each subsequent fit removes it.
verifyLessThan(t,norm(D-U*(U'*D)),norm(D));
c.covariance='withinAnimal'; r=fn_analyzeNeuralGeometry(X,T,c,p);
verifyTrue(t,all(isfinite(r.weights),'all'));
end
function testVarianceIdentities(t)
[X,T,c,p]=fixture(); r=fn_analyzeNeuralGeometry(X,T,c,p); v=r.variance;
verifyEqual(t,sum(v.conditionContribution,2),v.allConditionFraction,'AbsTol',1e-10);
verifyEqual(t,sum(v.conditionContributionByTime,3),v.allConditionFractionByTime,'AbsTol',1e-10);
verifyEqual(t,sum(v.variableUniqueFraction,2),v.allConditionFraction,'AbsTol',1e-9);
verifyEqual(t,v.totalByTime,v.withinConditionByTime+v.conditionSignalByTime,'AbsTol',1e-10);
for f=1:2
    verifyLessThanOrEqual(t,max(r.factors(f).cumulativeSeparationCapture),1+1e-9);
end
end
function testProjectionTrialUncertainty(t)
[X,T,c,p]=fixture(); r=fn_analyzeNeuralGeometry(X,T,c,p);
K=size(r.weights,2); nt=numel(c.time);
expectedMeanVariance=zeros(K,nt,4); expectedTrialVariance=expectedMeanVariance;
for a=1:2
    ids=find(r.neurons.animalIndex==a);
    for k=1:4
        nTrials=size(X{k,a},3);
        Y=reshape(r.weights(ids,:)'*reshape(X{k,a},numel(ids),[]),K,nt,nTrials);
        expectedTrialVariance(:,:,k)=expectedTrialVariance(:,:,k)+std(Y,0,3).^2;
        expectedMeanVariance(:,:,k)=expectedMeanVariance(:,:,k)+(std(Y,0,3)/sqrt(nTrials)).^2;
    end
end
verifyEqual(t,r.projection.conditionSEM,sqrt(expectedMeanVariance),'AbsTol',1e-12);
verifyEqual(t,r.projection.conditionSD,sqrt(expectedTrialVariance),'AbsTol',1e-12);
verifyGreaterThan(t,min(r.projection.conditionSD-r.projection.conditionSEM,[],'all'),0);
verifyEqual(t,p.projectionError,'sem');
end
function testJointRegressionAndConfounding(t)
[X,T,c,p]=fixture(); c.method='regression'; r=fn_analyzeNeuralGeometry(X,T,c,p);
verifyEqual(t,[r.factors.nAxes],[1 1]);
T.duplicate=T.task;
verifyError(t,@()fn_analyzeNeuralGeometry(X,T,c,p),'neuralGeometry:Confounded');
end
function testVariableFractionOfPopulation(t)
[X,T,c,p]=fixture(); c.method='meanSquared';
r=fn_analyzeNeuralGeometry(X,T,c,p); v=r.variance;
% Known pooled condition signals: task [2;1;0;2;1;0], action [0;0;1;0;0;1].
% Their variance energies are 10 and 2, respectively; trial noise adds to
% the population denominator, never to the variable's numerator.
populationTotal=12*ones(1,numel(c.time));
for a=1:2
    for k=1:4
        populationTotal=populationTotal+sum(var(X{k,a},1,3),1)/4;
    end
end
energy=zeros(2,numel(c.time),2); energy(1,:,1)=10; energy(2,:,2)=2;
verifyEqual(t,v.populationTotalVarianceByTime,populationTotal,'AbsTol',1e-10);
verifyEqual(t,v.variableUniqueEnergyByTime,energy,'AbsTol',1e-10);
verifyEqual(t,v.variableUniquePopulationFractionByTime,energy./populationTotal,'AbsTol',1e-10);
verifyEqual(t,v.variableUniquePopulationFraction,[10 0;0 2]/mean(populationTotal),'AbsTol',1e-10);
verifyEqual(t,v.variableUniquePooledPopulationFraction, ...
    [10 0;0 2]/v.pooledAllTrialsPopulationVariance,'AbsTol',1e-10);
verifyEqual(t,sum(v.variableUniquePopulationFractionByTime,3), ...
    v.allConditionPopulationFractionByTime,'AbsTol',1e-10);
verifyLessThan(t,v.variableUniquePopulationFraction(1,1),v.variableUniqueFraction(1,1));
end
function testPooledNormalization(t)
[X,T,c,p]=fixture(); c.normalization='zscore'; r=fn_analyzeNeuralGeometry(X,T,c,p);
A=cat(3,X{:,1}); flat=reshape(A,3,[]);
verifyEqual(t,r.normalization.offset(1:3),mean(flat,2),'AbsTol',1e-10);
verifyEqual(t,r.normalization.scale(1:3),std(flat,0,2),'AbsTol',1e-10);
verifyEqual(t,r.weightsRaw,r.weights./r.normalization.scale,'AbsTol',1e-10);
% Reconstruct condition projections directly from raw arrays.
rawMean=cat(1,mean(X{1,1},3),mean(X{1,2},3));
verifyEqual(t,r.weightsRaw'*rawMean+r.projectionOffset, ...
    r.projection.conditionMean(:,:,1),'AbsTol',1e-10);
end
function testPooledTimeVariance(t)
[X,T,c,p]=fixture(); X=X(:,1); c.animalLabels="a";
% Equal trial counts allow a direct flattened-data reference calculation.
% A large shared temporal response must survive grand-mean centering.
for k=1:4
    X{k}=X{k}(:,:,1:10)+[1;0.5;1.5]*linspace(-10,10,8);
end
r=fn_analyzeNeuralGeometry(X,T,c,p);
flat=reshape(cat(3,X{:}),3,[]);
projected=var(r.weights'*flat,1,2); population=sum(var(flat,1,2));
verifyEqual(t,r.variance.pooledAllTrialsProjectedVariance,projected,'AbsTol',1e-9);
verifyEqual(t,r.variance.pooledAllTrialsPopulationVariance,population,'AbsTol',1e-9);
verifyEqual(t,r.variance.pooledAllTrialsFraction,projected/population,'AbsTol',1e-10);
means=cellfun(@(a)mean(a,3),X,'UniformOutput',false); flat=cat(2,means{:});
projected=var(r.weights'*flat,1,2); population=sum(var(flat,1,2));
verifyEqual(t,r.variance.pooledTrialMeanFraction,projected/population,'AbsTol',1e-10);
verifyEqual(t,r.variance.pooledTrialMeanPopulationVariance,population,'AbsTol',1e-9);
verifyGreaterThan(t,r.variance.pooledAllTrialsPopulationVariance, ...
    mean(r.variance.populationTotalVarianceByTime)+100);
verifyGreaterThan(t,r.variance.pooledAllTrialsPopulationVariance,population);
end
function testMissingAndNonfinite(t)
[X,T,c,p]=fixture(); X{1,2}=[]; r=fn_analyzeNeuralGeometry(X,T,c,p);
verifyEqual(t,height(r.neurons),3); verifyFalse(t,r.animalAudit.included(2));
c.missingAnimal='error'; verifyError(t,@()fn_analyzeNeuralGeometry(X,T,c,p),'neuralGeometry:Missing');
[X,T,c,p]=fixture(); X{1,1}(2,1,1)=NaN;
r=fn_analyzeNeuralGeometry(X,T,c,p); verifyEqual(t,height(r.neurons),5);
verifyEqual(t,r.animalAudit.nDroppedNeurons,[1;0]);
end
function testTimePoolingCancelsOppositeSignals(t)
T=table(["one";"two"],["a";"b"],'VariableNames',{'conditionName','task'});
X={repmat([1 -1],1,1,4);repmat([-1 1],1,1,6)};
[c,p]=fn_neuralGeometryConfig(); c.crossValidate=false; c.verbose=false; p.makePlot=false;
r=fn_analyzeNeuralGeometry(X,T,c,p); verifyEqual(t,size(r.weights,2),0);
end
function testThreeFactorsAndThreeLevels(t)
[task,action,period]=ndgrid(1:3,1:2,1:2);
T=table("condition"+string((1:12)'),task(:),action(:),period(:), ...
    'VariableNames',{'conditionName','task','action','period'});
X=cell(12,2); H=null(ones(1,3));
for a=1:2
    for k=1:12
        signal=[H(task(k),:)';2*action(k)-3;2*period(k)-3];
        X{k,a}=repmat(signal,1,5,4+a);
    end
end
[c,p]=fn_neuralGeometryConfig(); c.crossValidate=false; c.method='regression'; c.verbose=false; p.makePlot=false;
r=fn_analyzeNeuralGeometry(X,T,c,p);
verifyEqual(t,[r.factors.nAxes],[2 1 1]);
verifyEqual(t,height(r.neurons),8);
verifyEqual(t,sum(r.variance.variableUniqueFraction,2),ones(4,1),'AbsTol',1e-10);
verifyEqual(t,r.factors(1).cumulativeSeparationCapture(end),1,'AbsTol',1e-10);
end
function testHiddenPlotsAndNoFiguresInData(t)
[X,T,c,p]=fixture();
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
p.trialTypes=T.conditionName; p.trajectory='both';
before=findall(groot,'Type','figure');
[r,figs]=fn_analyzeNeuralGeometry(X,T,c,p);
verifyFalse(t,isfield(r,'figures')); verifyEqual(t,findall(groot,'Type','figure'),before);
verifyEqual(t,sort(fieldnames(r.plotFiles)),{'activity';'projections';'trajectories';'variance'});
verifyEqual(t,sort(fieldnames(figs)),{'activity';'projections';'trajectories';'variance'});
for name=fieldnames(r.plotFiles)'
    verifyTrue(t,isfile(r.plotFiles.(name{1}))); verifyEmpty(t,figs.(name{1}));
    file=r.plotFiles.(name{1}); figFile=[file(1:end-4) '.fig'];
    verifyTrue(t,isfile(figFile));
    reopened=openfig(figFile,'new','invisible');
    cleanup=onCleanup(@()close(reopened));
    verifyNotEmpty(t,findall(reopened,'Type','axes'));
    clear cleanup
end
save(fullfile(folder.Folder,'result.mat'),'r');
% Old saved results can recover both pooled summaries from stored moments.
fields=fieldnames(r.variance); r.variance=rmfield(r.variance, ...
    [fields(startsWith(fields,'pooled')); {'variableUniquePooledPopulationFraction';'variableUniqueEnergyByTime'}]);
p.prefix='legacy'; [~,files]=fn_plotNeuralGeometry(r,p);
verifyEqual(t,imread(files.variance),imread(r.plotFiles.variance));
end
function [X,T,c,p]=fixture()
[c,p]=fn_neuralGeometryConfig(); c.crossValidate=false; c.verbose=false; p.makePlot=false;
c.time=linspace(-0.3,0.4,8); c.animalLabels=["a","b"];
T=table(["T1L";"T1R";"T2L";"T2R"],["T1";"T1";"T2";"T2"], ...
    ["L";"R";"L";"R"],'VariableNames',{'conditionName','task','action'});
stream=RandStream('mt19937ar','Seed',7); X=cell(4,2);
for a=1:2
    for k=1:4
        nr=12+2*k+a; task=2*(k>2)-1; action=2*(mod(k,2)==0)-1;
        noise=randn(stream,3,8,nr); noise=noise-mean(noise,3);
        noise=noise.*[4;0.3;0.5];
        X{k,a}=[2*task;task;action]+noise;
    end
end
end
