function tests=testTaskActionDecoding
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
if exist('fn_runDecoder','file')~=2
    repo=fileparts(fileparts(folder));
    t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(fileparts(repo),'ziyiFunction','analysis')));
end
stream=RandStream('mt19937ar','Seed',21);
A=randn(stream,23,4)+[1.2 .6 .1 0]; B=randn(stream,41,4)-[1.2 .6 .1 0];
options={'Repeats',2,'TopFractions',[.1 .5 1],'Seed',17};
before=rng; d=fn_runDecoder(A,B,.8,options{:});
assert(isequal(before,rng));
t.TestData=struct('A',A,'B',B,'options',{options},'decoder',d);
end
function testUnequalCountsAndLdaMath(t)
d=t.TestData.decoder; A=t.TestData.A; B=t.TestData.B;
verifyEqual(t,d.cv.classCounts,[23 41]);
for rep=1:2
    for cls=1:2
        ids=d.cv.foldAssignments{cls}(:,rep); verifyEqual(t,unique(ids),(1:5)');
        for trial=1:numel(ids), verifyEqual(t,sum(ids(trial)==1:5),1); end
    end
end
i=d.cv.foldAssignments{1}(:,1)~=1; j=d.cv.foldAssignments{2}(:,1)~=1;
variance=(var(A(i,:),0,1)+var(B(j,:),0,1))/2;
expected=(mean(A(i,:),1)-mean(B(j,:),1))./(variance+d.options.Ridge*mean(variance));
mid=(mean(A(i,:),1)+mean(B(j,:),1))/2;
verifyEqual(t,d.cellWBySplit(:,1),expected','AbsTol',1e-12);
verifyEqual(t,d.cellThresholdBySplit(:,1),mid','AbsTol',1e-12);
correct1=sum((A(~i,:)-mid).*expected>0,1)'; correct2=sum((B(~j,:)-mid).*expected<0,1)';
verifyEqual(t,d.cellAccBySplit(:,1,2),.5*(correct1/sum(~i)+correct2/sum(~j)),'AbsTol',1e-12);
% Each class contributes 50%, not its raw share of trials.
for rep=1:2
    ids=(rep-1)*5+(1:5);
    expected=.5*(sum(d.cv.cellCorrect(:,ids,2,1),2)/23+sum(d.cv.cellCorrect(:,ids,2,2),2)/41);
    verifyEqual(t,d.cellAccByRepeat(:,rep,2),expected,'AbsTol',1e-12);
end
end
function testSvmRawWeightReconstructionAndSubset(t)
d=t.TestData.decoder; data={t.TestData.A,t.TestData.B};
for q=1:numel(d.population.fractions)
    number=d.population.nNeurons(q); chosen=d.cv.ranking(1:number,1);
    w=d.population.weightsBySplit(:,q,1); bias=d.population.biasBySplit(q,1);
    verifyEqual(t,w(setdiff(1:4,chosen)),zeros(4-number,1));
    score=0;
    for cls=1:2
        held=d.cv.foldAssignments{cls}(:,1)==1; margin=data{cls}(held,:)*w+bias;
        if cls==2, margin=-margin; end
        score=score+.5*mean(double(margin>0)+.5*double(margin==0));
    end
    verifyEqual(t,d.population.accuracyBySplit(q,1,2),score,'AbsTol',1e-12);
end
verifyEqual(t,d.popAcc,d.population.accuracy(end,:));
verifyGreaterThan(t,d.popAcc(2),.8);
end
function testTestSetCannotChooseNeuronsOrWeights(t)
d=t.TestData.decoder; A=t.TestData.A; B=t.TestData.B;
A(d.cv.foldAssignments{1}(:,1)==1,:)=1000; B(d.cv.foldAssignments{2}(:,1)==1,:)=-1000;
altered=fn_runDecoder(A,B,.8,t.TestData.options{:});
verifyEqual(t,altered.cv.ranking(:,1),d.cv.ranking(:,1));
verifyEqual(t,altered.cellWBySplit(:,1),d.cellWBySplit(:,1));
verifyEqual(t,altered.population.weightsBySplit(:,:,1),d.population.weightsBySplit(:,:,1),'AbsTol',1e-12);
verifyEqual(t,altered.population.biasBySplit(:,1),d.population.biasBySplit(:,1),'AbsTol',1e-12);
end
function testOneNeuronConstantAndShuffle(t)
d=fn_runDecoder(ones(11,1),ones(17,1),.8,'Repeats',2,'TopFractions',1,'Shuffle',true);
verifySize(t,d.cellAcc,[1 2]); verifyEqual(t,d.cellAcc,[.5 .5]);
verifyEqual(t,d.popAcc,[.5 .5]); verifyEqual(t,d.cellAccShuf,[.5 .5]);
verifyEqual(t,d.popAccShuf,[.5 .5]); verifyTrue(t,all(isfinite(d.cellW)));
end
function testDistributedSignalAndNullPopulation(t)
stream=RandStream('mt19937ar','Seed',73);
A=randn(stream,100,12)+.35; B=randn(stream,160,12)-.35;
d=fn_runDecoder(A,B,.8,'Repeats',2,'TopFractions',[1/12 .5 1],'Seed',4);
verifyGreaterThan(t,d.popAcc(2),.8);
verifyGreaterThan(t,d.popAcc(2),mean(d.cellAcc(:,2))+.1);
% No labels in the features: selection must not manufacture high test accuracy.
d=fn_runDecoder(randn(stream,100,12),randn(stream,160,12),.8, ...
    'Repeats',2,'TopFractions',[1/12 .5 1],'Seed',4);
verifyLessThan(t,max(abs(d.population.accuracy(:,2)-.5)),.15);
end
function testRemoveBestNeuronsUsesTrainingRankingAndSvm(t)
A=t.TestData.A; B=t.TestData.B;
opts=[t.TestData.options,{'RemoveTopFractions',[0 .25 .5 .75]}];
d=fn_runDecoder(A,B,.8,opts{:});
verifyEqual(t,d.population.method,'linear SVM');
verifyEqual(t,d.population.removedFractions,[0 .25 .5 .75]);
verifyEqual(t,d.population.nRemoved,[0 1 2 3]);
verifyEqual(t,d.population.nNeurons,[4 3 2 1]);
verifyEqual(t,d.popAcc,d.population.accuracy(1,:));
verifyEqual(t,d.popW,d.population.weights(:,1));
for q=1:4
    chosen=d.cv.ranking(q:end,1); w=d.population.weightsBySplit(:,q,1);
    verifyEqual(t,w(d.cv.ranking(1:q-1,1)),zeros(q-1,1));
    expected=0; data={A,B};
    for cls=1:2
        held=d.cv.foldAssignments{cls}(:,1)==1;
        margin=data{cls}(held,:)*w+d.population.biasBySplit(q,1);
        if cls==2, margin=-margin; end
        expected=expected+.5*mean(double(margin>0)+.5*double(margin==0));
    end
    verifyEqual(t,d.population.accuracyBySplit(q,1,2),expected,'AbsTol',1e-12);
    verifyEqual(t,nnz(ismember(d.cv.ranking(:,1),chosen)),5-q);
end
% Test observations must not determine removal, weights, or LDA parameters.
A(d.cv.foldAssignments{1}(:,1)==1,:)=1000;
B(d.cv.foldAssignments{2}(:,1)==1,:)=-1000;
altered=fn_runDecoder(A,B,.8,opts{:});
verifyEqual(t,altered.cv.ranking(:,1),d.cv.ranking(:,1));
verifyEqual(t,altered.population.weightsBySplit(:,:,1),d.population.weightsBySplit(:,:,1),'AbsTol',1e-12);
verifyEqual(t,altered.cellWBySplit(:,1),d.cellWBySplit(:,1));
end

function testAccuracyOnlyAnalysisAndPlots(t)
[cfg,p]=fn_taskActionDecodingConfig(); cfg.repeats=2; cfg.topFractions=[.25 1]; cfg.verbose=false;
cfg.animalLabels=["mouseA","mouseB"]; p.makePlot=false;
T=table(["T1L";"T1R";"T2L";"T2R"],["L";"R";"L";"R"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','action','task'});
stream=RandStream('mt19937ar','Seed',55); X=cell(4,2);
for a=1:2
    for c=1:4
        X{c,a}=randn(stream,4,40,10+3*c)+[1;1;0;0]*(2*(mod(c,2)==1)-1)+[0;0;1;1]*(2*(c<3)-1);
    end
end
X{4,2}=[]; X{1,1}(2,28,1)=NaN;
r=fn_analyzeTaskActionDecoding(X,T,cfg,p);
verifySize(t,r.fits,[6 2]); verifyEmpty(t,r.fits{2,2}); verifyNotEmpty(t,r.fits{1,2});
verifyFalse(t,isfield(r,'weights')); % No pooled population or projection axes.
verifyEqual(t,r.choicePairs.rowInAnimal,[1;3;4]);
fit=r.fits{1,1}; rows=fit.neuronRows;
A=reshape(mean(X{1,1}(rows,28:30,:),2),numel(rows),[])';
B=reshape(mean(X{2,1}(rows,28:30,:),2),numel(rows),[])';
expected=fn_runDecoder(A,B,.8,'Repeats',2,'TopFractions',[.25 1],'Seed',cfg.seed);
verifyEqual(t,fit.decoder.cellAcc,expected.cellAcc,'AbsTol',1e-12);
verifyEqual(t,fit.sourceClass1.trialInCondition,(1:size(A,1))');
verifyEqual(t,r.fits{6,1}.comparison.frames,16:37);
verifyEqual(t,r.fits{1,1}.decoder.population.removedFractions,cfg.removeTopFractions);
verifyTrue(t,all(diff(r.population.nNeurons(r.population.animalIndex==1 & ...
    r.population.comparison=="choice_T1"))<=0));
% Input counts are [13 16 19 22]: task decoding must retain [13 13 19 19].
verifyEqual(t,r.fits{3,1}.trialBalance.nAvailable,[13;16;19;22]);
verifyEqual(t,r.fits{3,1}.trialBalance.nSelected,[13;13;19;19]);
verifyEqual(t,r.fits{3,1}.decoder.cv.classCounts,[26 38]);
for k=3:6
    verifyEmpty(t,r.fits{k,2}); % Missing T2-R cannot give a balanced task class.
    fitTask=r.fits{k,1};
    verifyEqual(t,fitTask.sourceClass1,r.fits{3,1}.sourceClass1);
    verifyEqual(t,fitTask.sourceClass2,r.fits{3,1}.sourceClass2);
    for cls=1:2
        source=fitTask.(sprintf('sourceClass%d',cls));
        ids=[source.conditionRow,source.trialInCondition];
        verifyEqual(t,size(unique(ids,'rows'),1),height(source)); % No replacement.
        for row=unique(source.conditionRow)'
            verifyTrue(t,all(source.trialInCondition(source.conditionRow==row)<=size(X{row,1},3)));
        end
    end
end
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
before=findall(groot,'Type','figure'); [figures,files]=fn_plotTaskActionDecoding(r,p);
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyEqual(t,sort(fieldnames(files)),{'choiceAccuracy';'populationSVM';'taskAccuracy'});
for key=fieldnames(files)'
    file=files.(key{1}); verifyTrue(t,isfile(file)); verifyEmpty(t,figures.(key{1}));
    verifyTrue(t,isfile([file(1:end-4) '.fig']));
end
reopened=openfig([files.populationSVM(1:end-4) '.fig'],'new','invisible');
cleanup=onCleanup(@()close(reopened));
axesList=findall(reopened,'Type','axes');
verifyTrue(t,all(arrayfun(@(ax)strcmp(ax.XLabel.String,'Top-ranked neurons removed (%)'),axesList)));
clear cleanup
p.populationXAxis='count'; p.prefix='counts'; fn_plotTaskActionDecoding(r,p);
% Balancing is deterministic and does not modify the caller's random stream.
p.makePlot=false; beforeRng=rng;
again=fn_analyzeTaskActionDecoding(X,T,cfg,p);
verifyEqual(t,rng,beforeRng);
verifyEqual(t,again.fits{3,1}.sourceClass2,r.fits{3,1}.sourceClass2);
cfg.balanceTaskActions=false;
legacy=fn_analyzeTaskActionDecoding(X,T,cfg,p);
verifyEqual(t,legacy.fits{3,1}.decoder.cv.classCounts,[29 41]);
verifyNotEmpty(t,legacy.fits{3,2});
end
