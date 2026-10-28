function tests=testEarlyLearningEmbedding
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath'))); analysis=fileparts(folder);
for path={folder,fullfile(analysis,'earlyLearningProgression'),fullfile(analysis,'taskActionGeometryEmbedding')}
    t.applyFixture(matlab.unittest.fixtures.PathFixture(path{1}));
end
end
function testExactOverlapAndPooledMeans(t)
[A,D,T,c,~]=fixture(); c.nBins=3;
[r,means]=fn_prepareEarlyLearningEmbedding(A,D,c,T);
verifyEqual(t,r.windows{1,1}.firstTrial,[1;41;81]);
verifyEqual(t,r.windows{1,1}.lastTrial,[60;100;140]);
verifyEqual(t,r.windows{1,1}.overlapWithPrevious(2:end),[1;1]/3,'AbsTol',1e-12);
verifySize(t,r.populationVectors,[12 13]);
verifyEqual(t,r.neurons.animalIndex,[ones(6,1);2*ones(7,1)]);
response=fn_analyzeStimRewardAlignment(A,D,c.response,struct('makePlot',false),T);
for a=1:2
    rows=r.neurons.animalIndex==a;
    for q=1:height(r.pointInfo)
        s=r.pointInfo.stimulus(q); b=r.pointInfo.learningBin(q); W=r.windows{s,a};
        idx=W.firstTrial(b):W.lastTrial(b);
        if r.pointInfo.responsePeriod(q)=="stimulus", X=response.byStimulus(s,a).stimulusActivity;
        else, X=response.byStimulus(s,a).rewardActivity; end
        expected=mean(X(:,idx),2);
        verifyEqual(t,r.populationVectors(q,rows),expected','AbsTol',1e-12);
        verifyEqual(t,means{q,a},expected,'AbsTol',1e-12);
    end
end
end
function testDefaultThirtyWindowsCoverEachAnimal(t)
[A,D,T,c,~]=fixture(); r=fn_prepareEarlyLearningEmbedding(A,D,c,T);
verifySize(t,r.populationVectors,[120 13]);
verifyEqual(t,r.pointInfo.learningBin,repmat((1:30)',4,1));
for a=1:2
    for s=1:2
        W=r.windows{s,a}; N=r.trialCounts(s,a);
        verifyEqual(t,height(W),30); verifyEqual(t,W.firstTrial(1),1);
        verifyEqual(t,W.lastTrial(end),N);
        verifyTrue(t,all(W.nTrials>=2)); verifyEqual(t,numel(unique(W.firstTrial)),30);
        verifyTrue(t,all(W.firstTrial(2:end)<=W.lastTrial(1:end-1)+1));
        verifyLessThanOrEqual(t,abs(W.overlapWithPrevious(2:end)-1/3),0.2*ones(29,1));
        verifyEqual(t,r.trialMap{s,a}.sourceTrialRow,sort(T{s,a}.sourceTrialRow));
    end
end
end
function testMissingAnimalAndFixedNeuronCohort(t)
[A,D,T,c,~]=fixture();
A{2,2}=[]; T{2,2}=[];
A{1,1}(1,:,:)=NaN; % Drop row 1 for every point, not just S1 stimulus points.
r=fn_prepareEarlyLearningEmbedding(A,D,c,T);
verifyEqual(t,r.animalAudit.included,[true;false]);
verifyEqual(t,r.neurons.rowInAnimal,(2:6)');
verifySize(t,r.populationVectors,[120 5]);
verifyEqual(t,r.animalAudit.nDroppedNeurons(1),1);
c.missingAnimal='error';
verifyError(t,@()fn_prepareEarlyLearningEmbedding(A,D,c,T),'earlyEmbedding:Animal');
c.missingAnimal='exclude'; A{1,1}=A{1,1}(:,:,1:10); T{1,1}=T{1,1}(1:10,:);
verifyError(t,@()fn_prepareEarlyLearningEmbedding(A,D,c,T),'earlyEmbedding:Empty');
end
function testSharedNormalization(t)
[A,D,T,c,~]=fixture(); c.response.normalization='zscore';
r=fn_prepareEarlyLearningEmbedding(A,D,c,T);
direct=fn_analyzeStimRewardAlignment(A,D,c.response,struct('makePlot',false),T);
verifyEqual(t,r.normalization,direct.normalization);
idx=r.windows{1,1}.firstTrial(1):r.windows{1,1}.lastTrial(1);
verifyEqual(t,r.populationVectors(1,1:6), ...
    mean(direct.byStimulus(1,1).stimulusActivity(:,idx),2)','AbsTol',1e-12);
end
function testActualUmapAndPlot(t)
assumeTrue(t,exist('run_umap','file')==2,'Install MATLAB run_umap for integration test.');
[A,D,T,c,p]=fixture(); c.umap.nEpochs=30; c.umap.nNeighbors=10;
c.umap.metric='euclidean'; c.umap.verbose=false;
state=rng; before=findall(groot,'Type','figure');
[r,figures]=fn_analyzeEarlyLearningEmbedding(A,D,c,p,T);
verifySize(t,r.embedding,[120 2]); verifyTrue(t,all(isfinite(r.embedding),'all'));
verifyEqual(t,r.backend.initialization,'random');
verifyLessThan(t,max(abs(r.embedding),[],'all'),1e6); % Reject the observed spectral blow-up.
verifyEqual(t,rng,state); verifyEmpty(t,fieldnames(figures));
verifyEqual(t,findall(groot,'Type','figure'),before);
verifyGreaterThanOrEqual(t,r.diagnostics.trustworthiness,0);
% Compare PCA against direct covariance, including the full-population denominator.
X=double(r.populationVectors); centered=X-mean(X,1);
verifySize(t,r.pca.scores,[120 3]); verifySize(t,r.pca.weights,[13 3]);
verifyEqual(t,r.pca.weights'*r.pca.weights,eye(3),'AbsTol',1e-12);
verifyEqual(t,r.pca.scores,centered*r.pca.weights,'AbsTol',1e-12);
eigenvalues=sort(eig(cov(X)),'descend');
verifyEqual(t,r.pca.latent,eigenvalues(1:3),'AbsTol',1e-10);
verifyEqual(t,r.pca.totalVariance,sum(var(X,0,1)),'AbsTol',1e-10);
verifyEqual(t,r.pca.explained,100*var(r.pca.scores,0,1)'/sum(var(X,0,1)),'AbsTol',1e-10);
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
[figures,files]=fn_plotEarlyLearningEmbedding(r,p);
verifyTrue(t,isfile(files.umap)); verifyEmpty(t,figures.umap);
verifyTrue(t,isfile(files.pca)); verifyEmpty(t,figures.pca);
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function [A,D,T,c,p]=fixture()
[c,p]=fn_earlyLearningEmbeddingConfig(); p.makePlot=false;
c.response.normalization='none'; c.response.animalLabels=["AC1","AC2"];
D=table(["S1";"S2"],[1;2],'VariableNames',{'conditionName','stimulus'});
A=cell(2,2); T=A; counts=[140 160;140 180]; phases=["T1E","T1M","T1L"];
for a=1:2
    nn=5+a; v=(1:nn)';
    for s=1:2
        N=counts(s,a); order=(N:-1:1)'; X=zeros(nn,45,N);
        sourceTrialRow=2*(order-1)+s;
        dayLabel=reshape(phases(min(3,ceil(3*order/N))),[],1);
        responseType=ones(N,1); stimulusFrame=sourceTrialRow*60;
        responseFrame=stimulusFrame+5+mod(order,2);
        for j=1:N
            q=order(j);
            stim=0.2*v+sin(v/3+q/17)+s*0.3;
            reward=cos(v/4+q/23)+0.01*q*v/nn+s*0.2;
            X(:,32:34,j)=repmat(stim,1,3);
            idx=31+responseFrame(j)-stimulusFrame(j)+(3:4);
            X(:,idx,j)=repmat(reward,1,2);
        end
        A{s,a}=X; T{s,a}=table(sourceTrialRow,dayLabel,responseType,stimulusFrame,responseFrame);
    end
end
end
