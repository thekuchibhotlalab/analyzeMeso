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
    verifyEqual(t,cosd(r.angleDegrees),r.cosine,'AbsTol',1e-12);
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
verifyTrue(t,isfile(files.similarity)); verifyEmpty(t,figures.similarity);
for key=fieldnames(files)'
    file=files.(key{1}); verifyTrue(t,isfile([file(1:end-4) '.fig']));
end
verifyEqual(t,findall(groot,'Type','figure'),before);
for q=1:4, A{q,1}(:)=1; A{q,2}(:)=1; end
r=fn_analyzeTaskStimGeometry(A,C,c,struct('makePlot',false),T);
verifyFalse(t,any(r.axisInfo.valid)); verifyTrue(t,all(isnan(r.weights),'all'));
end
function testEmptyAnimalSkippedBeforeMetadataAndKeepsLabels(t)
[A,C,c,p,T]=fixture(); c.period='reward'; c.animalLabels=["zz151_AC1","other_AC"];
A{4,1}=zeros(3,14,0); % Empty S4 trials in the first animal, as in the reported case.
T(:,1)={[]}; % Excluded animal must not trigger reward metadata validation.
r=fn_analyzeTaskStimGeometry(A,C,c,p,T);
verifyEqual(t,r.includedAnimalIndices,2);
verifyEqual(t,r.includedAnimalLabels,"other_AC");
verifyEqual(t,r.animalAudit.animalLabel,["zz151_AC1";"other_AC"]);
verifyEqual(t,r.animalAudit.included,[false;true]);
verifyEqual(t,r.animalAudit.reason(1),"Empty activity for: c4");
verifyTrue(t,all(cellfun(@isempty,r.reducedActivity(:,1))));
verifyTrue(t,all(r.neurons.animalIndex==2));
verifyTrue(t,all(r.neurons.animalLabel=="other_AC"));
verifyEqual(t,r.projection.animalIndices,2);
single=c; single.animalLabels="other_AC";
expected=fn_analyzeTaskStimGeometry(A(:,2),C,single,p,T(:,2));
verifyEqual(t,r.weights,expected.weights,'AbsTol',1e-12);
verifyEqual(t,r.projection.scores,expected.projection.scores);
verifyEqual(t,r.projection.sourceTrial{1},(1:size(A{1,2},3))');
end
function testExampleUsesSelectedConditionNames(t)
[A,~,~,~,T]=fixture();
animals={'AC1','AC2'};
intNames=["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R"];
lateNames=["Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"];
intAct=cell(size(A)); allTrialsel=cell(1,2);
for a=1:2
    for q=1:4
        intAct{q,a}=zeros(size(A{q,a},1),45,size(A{q,a},3));
        intAct{q,a}(:,32:34,:)=A{q,a}(:,5:7,:);
        allTrialsel{a}.neuralSelection(q).name=intNames(q);
        allTrialsel{a}.neuralSelection(q).trialInfoNeural=T{q,a};
        allTrialsel{a}.neuralSelection(q+4).name=lateNames(q);
        allTrialsel{a}.neuralSelection(q+4).trialInfoNeural=T{q,a}(1:3,:);
    end
end
folder=fileparts(fileparts(mfilename('fullpath')));
code=fileread(fullfile(folder,'example_taskStimGeometry.m'));
% Execute the example's actual label/metadata wiring; suppress only graphics.
code=strrep(code,'[taskStim,figures]=fn_analyzeTaskStimGeometry', ...
    'plotCfg.makePlot=false; [taskStim,figures]=fn_analyzeTaskStimGeometry');
eval(code);
verifyEqual(t,taskStim.conditions.conditionName,intNames');
verifyEqual(t,taskStim.trialCounts,cellfun(@(x)size(x,3),intAct));
verifyEqual(t,taskStim.trialMap{1,2}.metadata,T{1,2});
end
function testSixAxesAndSecondRow(t)
[A,C,c,p,T]=fixture(); [defaults,~]=fn_taskStimGeometryConfig();
c.comparisons=defaults.comparisons;
C.stimS1S3=["S1";"";"S3";""];
C.stimS2S4=["";"S2";"";"S4"];
C.action=["L";"R";"L";"R"];
r=fn_analyzeTaskStimGeometry(A,C,c,p,T);
verifySize(t,r.weights,[7 6]); verifySize(t,r.cosine,[6 6]);
verifyEqual(t,r.axisInfo.negativeClass,["S1";"S3";"T1";"S1";"S2";"L"]);
verifyEqual(t,r.axisInfo.positiveClass,["S2";"S4";"T2";"S3";"S4";"R"]);
for ids={[1 2 3],[4 5 6]}
    subset=c; subset.comparisons=c.comparisons(ids{1});
    expected=fn_analyzeTaskStimGeometry(A,C,subset,p,T);
    verifyEqual(t,r.weights(:,ids{1}),expected.weights,'AbsTol',1e-12);
    verifyEqual(t,r.projection.scores{1}(:,ids{1}),expected.projection.scores{1},'AbsTol',1e-12);
end
verifyEqual(t,r.cosine,r.weights'*r.weights,'AbsTol',1e-12);
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
p.axisColors=p.axisColors(1:3,:); % Existing three-color configs extend automatically.
before=findall(groot,'Type','figure');
[figures,files]=fn_plotTaskStimGeometry(r,p);
verifyTrue(t,isfile(files.projections)&&isfile(files.similarity));
verifyEmpty(t,figures.projections); verifyEmpty(t,figures.similarity);
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function [A,C,c,p,T]=fixture()
[c,p]=fn_taskStimGeometryConfig(); c.eventFrame=4; p.makePlot=false;
c.comparisons=["stimT1","stimT2","task"]; % Also exercise compatibility with three-axis analyses.
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
