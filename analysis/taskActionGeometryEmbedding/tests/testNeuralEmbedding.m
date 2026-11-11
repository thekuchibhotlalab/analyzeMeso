function tests=testNeuralEmbedding
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))),'helper_function')));
end
function testActualUmapAndPointMapping(t)
assumeTrue(t,exist('run_umap','file')==2,'Install MATLAB run_umap for this integration test.');
[X,T,c,p]=fixture(); state=rng; before=findall(groot,'Type','figure');
[r,figs]=fn_analyzeNeuralEmbedding(X,T,c,p);
verifyEqual(t,rng,state); verifyEmpty(t,fieldnames(figs));
verifyEqual(t,findall(groot,'Type','figure'),before);
verifySize(t,r.embedding,[32 3]); verifyEqual(t,r.backend.nComponents,3);
verifySize(t,r.populationVectors,[32 6]);
for k=1:4
    rows=(k-1)*8+(1:8);
    verifyEqual(t,r.populationVectors(rows,:),[mean(X{k,1},3);mean(X{k,2},3)]','AbsTol',1e-12);
    verifyEqual(t,r.pointInfo.conditionIndex(rows),repmat(k,8,1));
    verifyEqual(t,r.pointLabels.action(rows),repmat(T.action(k),8,1));
end
verifyEqual(t,r.neurons.animalIndex,[1;1;1;2;2;2]);
verifyGreaterThanOrEqual(t,r.diagnostics.trustworthiness,0);
verifyLessThanOrEqual(t,r.diagnostics.trustworthiness,1);
% Changing labels must not change the unsupervised fit.
T.action=flipud(T.action); r2=fn_analyzeNeuralEmbedding(X,T,c,p);
verifyEqual(t,r.embedding,r2.embedding,'AbsTol',1e-8);
% One shared embedding in the label/time panels; hidden exports close.
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder; p.connectTime=true;
[figs,files]=fn_plotNeuralEmbedding(r,p);
verifyEmpty(t,figs.umap); verifyTrue(t,isfile(files.umap));
verifyTrue(t,isfile([files.umap(1:end-4) '.fig']));
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function testMissingNonfiniteNormalizationAndWindow(t)
assumeTrue(t,exist('run_umap','file')==2,'Install MATLAB run_umap for this integration test.');
[X,T,c,p]=fixture(); X{1,2}=[]; c.timeWindow=[2 6]; c.normalization='zscore'; X{2,1}(1,4,1)=NaN;
r=fn_analyzeNeuralEmbedding(X,T,c,p);
verifyFalse(t,r.animalAudit.included(2)); verifyEqual(t,r.neurons.rowInAnimal,[2;3]);
A=cat(3,X{:,1}); A=A(2:3,2:6,:); A=reshape(A,2,[]);
verifyEqual(t,r.normalization.offset,mean(A,2),'AbsTol',1e-12);
verifyEqual(t,r.normalization.scale,std(A,0,2),'AbsTol',1e-12);
verifyEqual(t,r.time,2:6); verifySize(t,r.embedding,[20 3]);
c.missingAnimal='error'; verifyError(t,@()fn_analyzeNeuralEmbedding(X,T,c,p),'neuralEmbedding:Missing');
end
function testActualTwoDimensionalFit(t)
assumeTrue(t,exist('run_umap','file')==2,'Install MATLAB run_umap for this integration test.');
[X,T,c,p]=fixture(); c.nComponents=2;
r=fn_analyzeNeuralEmbedding(X,T,c,p);
verifySize(t,r.embedding,[32 2]); verifyEqual(t,r.backend.nComponents,2);
end
function testInvalidDistanceAndLabels(t)
[X,T,c,p]=fixture(); c.metric='correlation'; X=cellfun(@(a)ones(size(a)),X,'UniformOutput',false);
verifyError(t,@()fn_analyzeNeuralEmbedding(X,T,c,p),'neuralEmbedding:Distance');
[X,T,c,p]=fixture(); T.conditionName(2)=T.conditionName(1);
verifyError(t,@()fn_analyzeNeuralEmbedding(X,T,c,p),'neuralEmbedding:Conditions');
end
function [X,T,c,p]=fixture()
[c,p]=fn_neuralEmbeddingConfig(); c.nNeighbors=6; c.nEpochs=30;
c.metric='euclidean'; c.verbose=false; c.time=1:8; p.makePlot=false;
T=table(["T1L";"T1R";"T2L";"T2R"],["L";"R";"L";"R"], ...
    ["T1";"T1";"T2";"T2"],["E";"E";"Int";"Int"], ...
    'VariableNames',{'conditionName','action','task','learning'});
stream=RandStream('mt19937ar','Seed',19); X=cell(4,2);
for a=1:2
    for k=1:4
        phase=linspace(0,pi,8);
        X{k,a}=[sin(phase)+2*(k>2);cos(phase)+mod(k,2);phase]+0.1*randn(stream,3,8,4+k);
    end
end
end
