function tests=testCrossvalidatedGeometry
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
[c,p]=fn_neuralGeometryConfig(); c.cvRepeats=2; c.verbose=false;
c.time=(-3:3)/15; c.normalization='zscore'; c.nAxes=2;
p.makePlot=false;
T=table(["S1L";"S2R";"S3L";"S4R"],["L";"R";"L";"R"], ...
    ["T1";"T1";"T2";"T2"],'VariableNames',{'conditionName','action','task'});
stream=RandStream('mt19937ar','Seed',23); X=cell(4,2);
for a=1:2
    for k=1:4
        action=2*(mod(k,2)==0)-1; task=2*(k>2)-1;
        X{k,a}=randn(stream,6,7,25+k)+ ...
            [2;1;.3;0;0;0]*action*[1 1 1 .4 .1 0 0]+[0;0;0;1.5;.5;0]*task;
    end
end
state=rng; r=fn_analyzeNeuralGeometry(X,T,c,p); assert(isequal(state,rng));
t.TestData=struct('X',{X},'T',T,'cfg',c,'plot',p,'r',r);
end
function testWholeTrialDisjointFolds(t)
r=t.TestData.r; X=t.TestData.X;
for a=1:2
    for c=1:4
        folds=r.crossValidation.assignments{c,a};
        verifySize(t,folds,[size(X{c,a},3) 2]);
        for rep=1:2
            verifyEqual(t,unique(folds(:,rep)),(1:5)');
            count=accumarray(folds(:,rep),1); verifyLessThanOrEqual(t,max(count)-min(count),1);
            for f=1:5
                d=r.decoding.splits{(rep-1)*5+f};
                verifyTrue(t,all(folds(d.sourceTrial{c,a},rep)==f));
            end
        end
    end
end
end
function testTrainingNormalizationAndHeldOutProjection(t)
r=t.TestData.r; X=t.TestData.X; m=r.crossValidation.models{1};
C=[];
for a=1:2
    ix=find(r.neurons.animalIndex==a); pooled=[];
    for c=1:4
        keep=r.crossValidation.assignments{c,a}(:,1)~=1;
        pooled=[pooled reshape(X{c,a}(:,:,keep),6,[])]; %#ok<AGROW>
    end
    verifyEqual(t,m.normalization.offset(ix),mean(pooled,2),'AbsTol',1e-12);
    verifyEqual(t,m.normalization.scale(ix),std(pooled,0,2),'AbsTol',1e-12);
    mask=r.crossValidation.assignments{1,a}(:,1)==1;
    C=[C;(mean(X{1,a}(:,:,mask),3)-m.normalization.offset(ix))./m.normalization.scale(ix)]; %#ok<AGROW>
end
verifyEqual(t,r.crossValidation.splits{1}.projection.conditionMean(:,:,1),m.weights'*C,'AbsTol',1e-11);
end
function testRepeatSEMAndMeanDirections(t)
r=t.TestData.r; cv=r.crossValidation;
v=cellfun(@(s)s.variance.pooledTrialMeanFraction,cv.splits,'UniformOutput',false);
v=cat(2,v{:}); repeat=reshape(mean(reshape(v,[],5,2),2),[],2);
verifyEqual(t,r.variance.pooledTrialMeanFraction,mean(repeat,2),'AbsTol',1e-12);
verifyEqual(t,cv.varianceSEM.pooledTrialMeanFraction,std(repeat,0,2)/sqrt(2),'AbsTol',1e-12);
verifyEqual(t,r.meanWeights,mean(cv.rawUnitWeightsBySplit,3),'AbsTol',1e-12);
verifyEqual(t,sum(r.weights.^2,1),ones(1,size(r.weights,2)),'AbsTol',1e-12);
for s=1:10
    W=cv.weightsBySplit(:,:,s);
    for f=1:2
        ids=find(r.axisInfo.variable==r.variables(f));
        verifyEqual(t,W(:,ids)'*W(:,ids),eye(numel(ids)),'AbsTol',1e-10);
    end
end
end
function testSingleNeuronSummariesAndTrainingRankings(t)
r=t.TestData.r; d=r.decoding.splits{1}; m=r.crossValidation.models{1};
verifyEqual(t,d.fractions,[.10 .25]);
verifyFalse(t,isfield(d,'populationTime')); verifyFalse(t,isfield(d,'populationSummary'));
for f=1:2
    if f==1
        win=1:3; verifyEqual(t,d.windowTime{f},[-3 -2 -1]/15,'AbsTol',1e-12);
    else
        win=1:7;
        % Whole-window task coefficients still match diagonal population LDA.
        w=d.singleWeights(:,f); w=w/norm(w);
        id=find(m.axisInfo.variable==r.variables(f)&m.axisInfo.axis==1);
        verifyEqual(t,w,m.weights(:,id),'AbsTol',1e-10);
    end
    verifyEqual(t,[d.windowStart(f) d.windowEnd(f)],[win(1) win(end)]);
    [~,rank]=sort(mean(d.trainingSingleAccuracy(:,win,f),2),'descend');
    verifyEqual(t,d.ranking(:,f),rank);
    verifyEqual(t,d.neuronSummary(:,f),mean(d.neuronTime(:,win,f),2),'AbsTol',1e-12);
    [~,displayOrder]=sort(r.decoding.mean.neuronSummary(:,f),'descend');
    verifyEqual(t,r.decoding.displayOrder(:,f),displayOrder);
end
verifyEqual(t,r.decoding.neuronTable.accuracy,r.decoding.mean.neuronSummary(:));
verifyGreaterThan(t,max(r.decoding.mean.neuronSummary(:,1)),.8);
verifyTrue(t,all(d.neuronTime>=0&d.neuronTime<=1+1e-12,'all'));
end
function testHeldOutPerturbationDoesNotSelectNeuronsOrWindows(t)
X=t.TestData.X; r=t.TestData.r; cfg=t.TestData.cfg; p=t.TestData.plot;
train=X; test=X;
for a=1:2
    for c=1:4
        mask=r.crossValidation.assignments{c,a}(:,1)==1;
        train{c,a}=X{c,a}(:,:,~mask); test{c,a}=X{c,a}(:,:,mask);
    end
end
m=fn_fitNeuralGeometry(train,t.TestData.T,cfg,p);
d1=fn_decodeNeuralGeometry(train,test,t.TestData.T,cfg,m,RandStream('mt19937ar','Seed',4));
test=cellfun(@(x)-100*x+1000,test,'UniformOutput',false);
d2=fn_decodeNeuralGeometry(train,test,t.TestData.T,cfg,m,RandStream('mt19937ar','Seed',4));
verifyEqual(t,d1.ranking,d2.ranking); verifyEqual(t,d1.windowStart,d2.windowStart);
verifyEqual(t,d1.singleWeights,d2.singleWeights); verifyEqual(t,d1.singleThreshold,d2.singleThreshold);
verifyEqual(t,d1.timeResolvedThreshold,d2.timeResolvedThreshold);
end
function testCVPlotsAndExport(t)
r=t.TestData.r; p=t.TestData.plot;
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
p.trialTypes=t.TestData.T.conditionName; p.trajectory='2d'; p.showConditionContribution=true;
before=findall(groot,'Type','figure'); [f,files]=fn_plotNeuralGeometry(r,p);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyTrue(t,isfield(files,'decodingTime')&&isfield(files,'decodingNeurons'));
for name=fieldnames(files)'
    verifyTrue(t,isfile(files.(name{1}))); verifyEmpty(t,f.(name{1}));
    file=files.(name{1}); verifyTrue(t,isfile([file(1:end-4) '.fig']));
end
end
function testExclusionProvenanceAndDecoderIndependentFolds(t)
cfg=t.TestData.cfg; cfg.decode=false;
r=fn_analyzeNeuralGeometry(t.TestData.X,t.TestData.T,cfg,t.TestData.plot);
verifyEqual(t,r.crossValidation.assignments,t.TestData.r.crossValidation.assignments);
X=t.TestData.X; X{1,2}=X{1,2}(:,:,1:9); X{1,1}(2,1,1)=NaN;
r=fn_analyzeNeuralGeometry(X,t.TestData.T,cfg,t.TestData.plot);
verifyEqual(t,r.neurons.rowInAnimal,[1;3;4;5;6]);
verifyEqual(t,r.neurons.animalIndex,ones(5,1));
verifyFalse(t,r.animalAudit.included(2)); verifyFalse(t,isfield(r,'decoding'));
end
function testNullDecodingNearChance(t)
cfg=t.TestData.cfg; cfg.nAxes=1; X=cell(4,1);
stream=RandStream('mt19937ar','Seed',42);
for c=1:4, X{c}=randn(stream,12,7,100); end
r=fn_analyzeNeuralGeometry(X,t.TestData.T,cfg,t.TestData.plot);
verifyLessThan(t,max(abs(r.decoding.mean.neuronSummary-.5),[],'all'),.12);
verifyLessThan(t,max(abs(r.decoding.mean.timeResolvedNeuronSummary-.5),[],'all'),.12);
% Every animal uses each real outer-test trial exactly once, no pseudo draws.
d=r.decoding.splits{1};
for c=1:4
    verifyEqual(t,d.sourceTrial{c,1},find(r.crossValidation.assignments{c,1}(:,1)==1));
end
end

function testTemporalBaselineDiagnostic(t)
[c,p]=fn_neuralGeometryConfig(); c.time=(-6:2)/15; c.normalization='none';
c.nAxes=1; c.verbose=false; p.makePlot=false;
T=table(["one";"two"],["T1";"T2"],'VariableNames',{'conditionName','task'});
stream=RandStream('mt19937ar','Seed',91); train=cell(2,1); test=train;
baseline=[-50*ones(1,6) 50*ones(1,3)];
for k=1:2
    train{k}=baseline+2*(2*k-3)+.1*randn(stream,2,9,40);
    test{k}=baseline+2*(2*k-3)+.1*randn(stream,2,9,40);
end
m=fn_fitNeuralGeometry(train,T,c,p);
d=fn_decodeNeuralGeometry(train,test,T,c,m,RandStream('mt19937ar','Seed',2));
verifyEqual(t,d.neuronSummary,.5*ones(2,1),'AbsTol',1e-12);
verifyGreaterThan(t,min(d.timeResolvedNeuronSummary),.99);
end
function testChoiceExcludesZeroAndPostChoiceAndUsesFixedFrames(t)
[c,p]=fn_neuralGeometryConfig(); c.time=(-3:3)/15; c.normalization='none';
c.nAxes=1; c.verbose=false; p.makePlot=false;
T=table(["one";"two"],["L";"R"],'VariableNames',{'conditionName','action'});
stream=RandStream('mt19937ar','Seed',12);
base=randn(stream,2,7,40); train={base;base}; test={base;base};
% Strong apparent selectivity at time zero and later must not enter choice accuracy.
train{2}(:,4:end,:)=train{2}(:,4:end,:)+100;
test{2}(:,4:end,:)=test{2}(:,4:end,:)+100;
m=fn_fitNeuralGeometry(train,T,c,p);
d=fn_decodeNeuralGeometry(train,test,T,c,m,RandStream('mt19937ar','Seed',1));
verifyEqual(t,d.neuronSummary,.5*ones(2,1),'AbsTol',1e-12);
verifyGreaterThan(t,min(d.timeResolvedNeuronTime(:,4:end,:),[],'all'),.99);
train{2}(:,1:3,:)=train{2}(:,1:3,:)+100;
test{2}(:,1:3,:)=test{2}(:,1:3,:)+100;
d=fn_decodeNeuralGeometry(train,test,T,c,m,RandStream('mt19937ar','Seed',1));
verifyGreaterThan(t,min(d.neuronSummary),.99);
c.timeWindow=[-1/15 .2]; m=fn_fitNeuralGeometry(train,T,c,p);
verifyError(t,@()fn_decodeNeuralGeometry(train,test,T,c,m,RandStream('mt19937ar','Seed',1)), ...
    'neuralGeometry:DecoderWindow');
end
