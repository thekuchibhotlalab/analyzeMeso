function tests=testTaskStimGeometry
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
end
function testDirectLdaAndPseudoTrialProvenance(t)
[A,C,c,p,T]=fixture(); state=rng;
for mode=["withinAnimal","diagonal"]
    c.covariance=char(mode); [r,f]=fn_analyzeTaskStimGeometry(A,C,c,p,T);
    verifyEmpty(t,fieldnames(f)); verifyEqual(t,rng,state);
    verifyEqual(t,sum(r.weights.^2,1),ones(1,3),'AbsTol',1e-12);
    for k=1:3
        labels=string(C.(c.comparisons(k))); levels=unique(labels(labels~=""),'stable');
        mu=zeros(7,2); covariance=zeros(7); means=r.conditionMeans;
        for l=1:2, mu(:,l)=mean(means(:,labels==levels(l)),2); end
        for q=find(labels~="")'
            l=find(levels==labels(q)); B=zeros(7);
            for a=1:2
                ix=r.neurons.animalIndex==a; Z=r.reducedActivity{q,a};
                local=cov(Z'); if mode=="diagonal", local=diag(diag(local)); end
                B(ix,ix)=local;
            end
            d=means(:,q)-mu(:,l);
            covariance=covariance+(B+d*d')/(2*sum(labels==levels(l)));
        end
        lambda=c.ridge*mean(diag(covariance));
        w=(covariance+lambda*eye(7))\(mu(:,2)-mu(:,1)); w=w/norm(w);
        verifyEqual(t,r.weights(:,k),w,'AbsTol',1e-10);
        verifyEqual(t,r.thresholds(k),w'*mean(mu,2),'AbsTol',1e-10);
    end
    for q=1:4
        verifySize(t,r.projection.scores{q},[12+q 3]);
        joined=[];
        for a=1:2
            ids=r.projection.sourceTrial{q}(:,a);
            verifyEqual(t,numel(unique(ids)),numel(ids));
            Z=reshape(mean(A{q,a}(:,5:7,ids),2),size(A{q,a},1),[]);
            joined=[joined;Z]; %#ok<AGROW>
            row=r.projection.sourceRowInReduced{q}(:,a);
            verifyEqual(t,r.trialMap{q,a}.metadata.sourceTrialRow(row),T{q,a}.sourceTrialRow(ids));
        end
        verifyEqual(t,r.projection.scores{q},joined'*r.weights,'AbsTol',1e-12);
    end
end
end
function testRewardTimingAndNormalization(t)
[A,C,c,p,T]=fixture(); c.period='reward'; c.normalization='zscore';
T{1,1}.responseFrame(end)=10000; c.nPseudoTrials=40;
r=fn_analyzeTaskStimGeometry(A,C,c,p,T);
verifyEqual(t,r.trialMap{1,1}.invalidWindowTrials,size(A{1,1},3));
verifyEqual(t,r.trialCounts(1,1),size(A{1,1},3)-1);
for a=1:2
    allReduced=[];
    for q=1:4
        ids=r.trialMap{q,a}.sourceTrial; Z=zeros(size(A{q,a},1),numel(ids));
        for j=1:numel(ids)
            tr=ids(j); center=4+T{q,a}.responseFrame(tr)-T{q,a}.stimulusFrame(tr);
            Z(:,j)=mean(A{q,a}(:,center+(3:4),tr),2);
        end
        allReduced=[allReduced Z]; %#ok<AGROW>
    end
    ix=r.neurons.animalIndex==a;
    verifyEqual(t,r.normalization.offset(ix),mean(allReduced,2),'AbsTol',1e-12);
    verifyEqual(t,r.normalization.scale(ix),std(allReduced,0,2),'AbsTol',1e-12);
end
for q=1:4
    verifySize(t,r.projection.scores{q},[40 3]); raw=[];
    for a=1:2
        ix=r.neurons.animalIndex==a; ids=r.projection.sourceRowInReduced{q}(:,a);
        raw=[raw;r.reducedActivity{q,a}(:,ids).*r.normalization.scale(ix)+r.normalization.offset(ix)]; %#ok<AGROW>
    end
    verifyEqual(t,raw'*r.weightsRaw-r.thresholdsRaw,r.projection.margins{q},'AbsTol',1e-11);
end
r2=fn_analyzeTaskStimGeometry(A,C,c,p,T);
verifyEqual(t,r.projection.sourceTrial,r2.projection.sourceTrial);
verifyError(t,@()fn_analyzeTaskStimGeometry(A,C,c,p),'taskStim:TrialInfo');
end
function testMissingAnimalsAndNeuronMask(t)
[A,C,c,p,T]=fixture(); A{4,2}=[]; T{4,2}=[]; A{2,1}(1,5,:)=NaN;
r=fn_analyzeTaskStimGeometry(A,C,c,p,T);
verifyEqual(t,r.animalAudit.included,[true;false]);
verifyEqual(t,r.neurons.rowInAnimal,[2;3]);
verifyFalse(t,r.projection.isPseudoPopulation);
verifyEqual(t,r.projection.sourceTrial{1},(1:size(A{1,1},3))');
c.missingAnimal='error';
verifyError(t,@()fn_analyzeTaskStimGeometry(A,C,c,p,T),'taskStim:Animal');
end
function testFlexibleLabelsAndPlot(t)
[A,C,c,p,T]=fixture();
C.Properties.VariableNames(3:5)={'tonesA','tonesB','context'};
c.comparisons=["tonesA","tonesB","context"];
C.stimulus=["tone a";"tone b";"tone c";"tone d"];
C.tonesA=["low";"high";"";""];
r=fn_analyzeTaskStimGeometry(A,C,c,p,T);
verifyEqual(t,r.axisInfo.negativeClass(1),"low");
verifyEqual(t,r.axisInfo.positiveClass(1),"high");
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
before=findall(groot,'Type','figure'); p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
[figures,files]=fn_plotTaskStimGeometry(r,p);
verifyTrue(t,isfile(files.projections)); verifyEmpty(t,figures.projections);
verifyEqual(t,findall(groot,'Type','figure'),before);
for q=1:4, A{q,1}(:)=1; A{q,2}(:)=1; end
r=fn_analyzeTaskStimGeometry(A,C,c,struct('makePlot',false),T);
verifyFalse(t,any(r.axisInfo.valid)); verifyTrue(t,all(isnan(r.weights),'all'));
end
function [A,C,c,p,T]=fixture()
[c,p]=fn_taskStimGeometryConfig(); c.eventFrame=4; p.makePlot=false;
C=table(["c1";"c2";"c3";"c4"],["S1";"S2";"S3";"S4"], ...
    ["S1";"S2";"";""],["";"";"S3";"S4"],["T1";"T1";"T2";"T2"], ...
    'VariableNames',{'conditionName','stimulus','stimT1','stimT2','task'});
stream=RandStream('mt19937ar','Seed',42); A=cell(4,2); T=A;
for a=1:2
    nn=a+2;
    for q=1:4
        nt=12+q+(a-1)*3; A{q,a}=zeros(nn,14,nt);
        sourceTrialRow=(1:nt)'+100*q;
        stimulusFrame=100*(1:nt)'; responseFrame=stimulusFrame+2+mod((1:nt)',2);
        T{q,a}=table(sourceTrialRow,stimulusFrame,responseFrame);
        for j=1:nt
            z=(1:nn)'*(q-2.5)+randn(stream,nn,1);
            A{q,a}(:,5:7,j)=repmat(z,1,3);
            center=4+responseFrame(j)-stimulusFrame(j);
            A{q,a}(:,center+(3:4),j)=repmat(-z+0.4*randn(stream,nn,1),1,2);
        end
    end
end
end
