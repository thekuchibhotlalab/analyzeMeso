function tests=testLearningProgressionEmbedding
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath')));
t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(fileparts(folder),'taskActionGeometryEmbedding')));
end
function testSelectionChronologyAndExactBinMeans(t)
[A,C,c,p,T]=fixture(); c.select=struct('task',"T2"); c.runUMAP=false;
[r,figures]=fn_analyzeLearningProgressionEmbedding(A,C,c,p,T);
verifyEmpty(t,fieldnames(figures)); verifySize(t,r.populationVectors,[12 11]);
verifyEqual(t,r.groupLabels.stimulus,["S3";"S4"]);
verifyEqual(t,r.pointInfo.learningBin,repmat((1:3)',4,1));
verifySize(t,r.pca.scores,[12 3]);
rewardCfg=c; rewardCfg.responsePeriods="reward";
reward=fn_prepareLearningProgressionEmbedding(A,C,rewardCfg,T);
verifyEqual(t,reward.populationVectors,r.populationVectors(r.pointInfo.responsePeriod=="reward",:),'AbsTol',1e-12);
for a=1:2
    feature=r.neurons.animalIndex==a;
    for g=1:2
        M=r.trialMap{g,a}; W=r.windows{g,a};
        verifyEqual(t,M.dayLabel,[repmat("T2E",12,1);repmat("Int",12,1)]);
        verifyEqual(t,M.sourceTrialRow,sort(M.sourceTrialRow));
        verifyEqual(t,W.firstTrial,[1;9;17]); verifyEqual(t,W.lastTrial,[8;16;24]);
        verifyEqual(t,W.phaseCounts(:,4),[8;4;0]); verifyEqual(t,W.phaseCounts(:,7),[0;4;8]);
        for b=1:3
            for e=1:2
                expected=[];
                for j=W.firstTrial(b):W.lastTrial(b)
                    row=M.sourceCondition(j); tr=M.sourceTrial(j); frames=5:7;
                    if e==2, frames=9:10; end
                    expected=[expected mean(A{row,a}(:,frames,tr),2)]; %#ok<AGROW>
                    verifyEqual(t,r.sourceMetadata{row,a}.sourceTrialRow(M.metadataRow(j)),M.sourceTrialRow(j));
                end
                point=(g-1)*6+(e-1)*3+b;
                verifyEqual(t,r.populationVectors(point,feature),mean(expected,2)','AbsTol',1e-12);
            end
        end
    end
end
end
function testPhaseTypeAndOutcomeFilters(t)
[A,C,c,~,T]=fixture(); c.learningPeriods="Int"; c.select=struct('task',"T2");
c.trialTypes=["Int_S3","Int_S4"]; c.responseTypes=2; c.nBins=2; c.minTrialsPerBin=1;
r=fn_prepareLearningProgressionEmbedding(A,C,c,T);
verifyEqual(t,r.trialCounts,3*ones(2,2));
verifyEqual(t,C.conditionName(r.selectedConditionMask),["Int_S3";"Int_S4"]);
for a=1:2
    for g=1:2
        M=r.trialMap{g,a}; verifyTrue(t,all(M.dayLabel=="Int"));
        for j=1:height(M), verifyEqual(t,T{M.sourceCondition(j),a}.responseType(M.sourceTrial(j)),2); end
    end
end
c.select.task="not_a_task";
verifyError(t,@()fn_prepareLearningProgressionEmbedding(A,C,c,T),'learningEmbedding:Selection');
end
function testMissingPhasesGroupsAndNonfiniteNeurons(t)
[A,C,c,~,T]=fixture(); c.select=struct('task',"T2");
A{3,1}=[]; T{3,1}=[]; % Missing Int S3, but T2E S3 supplies usable bins.
A{4,2}=[]; A{8,2}=[]; % Animal 2 has no S4 group in either phase.
A{7,1}(1,5,:)=NaN;
r=fn_prepareLearningProgressionEmbedding(A,C,c,T);
verifyEqual(t,r.animalAudit.included,[true;false]);
verifyEqual(t,r.neurons.rowInAnimal,(2:5)');
verifyEqual(t,r.trialCounts(1,1),12);
c.missingAnimal='error';
verifyError(t,@()fn_prepareLearningProgressionEmbedding(A,C,c,T),'learningEmbedding:Animal');
end
function testResponsePeriodsNormalizationAndDuplicateDetection(t)
[A,C,c,~,T]=fixture(); c.select=struct('task',"T2"); c.responsePeriods="stimulus";
T=cellfun(@(x)removevars(x,{'stimulusFrame','responseFrame'}),T,'UniformOutput',false);
r=fn_prepareLearningProgressionEmbedding(A,C,c,T); verifySize(t,r.populationVectors,[6 11]);
c.normalization='zscore'; z=fn_prepareLearningProgressionEmbedding(A,C,c,T);
for a=1:2
    samples=[];
    for row=find(r.selectedConditionMask)'
        samples=[samples reshape(mean(A{row,a}(:,5:7,:),2),size(A{row,a},1),[])]; %#ok<AGROW>
    end
    ix=z.neurons.animalIndex==a;
    verifyEqual(t,z.normalization.offset{a},mean(samples,2),'AbsTol',1e-12);
    verifyEqual(t,z.populationVectors(:,ix), ...
        (r.populationVectors(:,ix)-mean(samples,2)')./std(samples,0,2)','AbsTol',1e-12);
end
c.responsePeriods="reward";
verifyError(t,@()fn_prepareLearningProgressionEmbedding(A,C,c,T),'learningEmbedding:Timing');
c.responsePeriods="stimulus"; T{4,1}.sourceTrialRow=T{3,1}.sourceTrialRow;
verifyError(t,@()fn_prepareLearningProgressionEmbedding(A,C,c,T),'learningEmbedding:DuplicateTrial');
end
function testOverlapGroupingAndInvalidRewardWindows(t)
[A,C,c,~,T]=fixture(); c.select=struct('task',"T2"); c.groupBy="task"; c.overlap=1/3;
T{3,1}.responseFrame(1)=1e6;
r=fn_prepareLearningProgressionEmbedding(A,C,c,T);
verifyEqual(t,height(r.groupLabels),1); verifyEqual(t,r.groupLabels.stimulus,"mixed");
verifyEqual(t,r.windows{1,1}.firstTrial,[1;15;28]);
verifyEqual(t,r.windows{1,1}.lastTrial,[21;34;48]);
verifyEqual(t,height(r.trialMap{1,1}),48); % Bad timing stays in its ordinal position.
verifyEqual(t,sum(~all(r.trialMap{1,1}.validWindow,2)),1);
verifyTrue(t,all(isfinite(r.populationVectors),'all'));
end
function testActualUmapAndExports(t)
assumeTrue(t,exist('run_umap','file')==2,'Install MATLAB run_umap for integration test.');
[A,C,c,p,T]=fixture(); c.select=struct('task',"T2"); c.nBins=6; c.overlap=1/3;
c.umap.metric='euclidean'; c.umap.nNeighbors=6; c.umap.nEpochs=30; c.umap.verbose=false;
before=findall(groot,'Type','figure'); state=rng;
r=fn_analyzeLearningProgressionEmbedding(A,C,c,p,T);
verifySize(t,r.embedding,[24 2]); verifyTrue(t,all(isfinite(r.embedding),'all'));
verifyEqual(t,rng,state);
verifyEqual(t,r.neurons.animalIndex,[ones(5,1);2*ones(6,1)]);
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
[figures,files]=fn_plotLearningProgressionEmbedding(r,p);
verifyTrue(t,isfile(files.umap)&&isfile(files.pca));
for key=fieldnames(files)'
    file=files.(key{1}); verifyTrue(t,isfile([file(1:end-4) '.fig']));
end
verifyEmpty(t,figures.umap); verifyEmpty(t,figures.pca);
verifyEqual(t,findall(groot,'Type','figure'),before);
end
function [A,C,c,p,T]=fixture()
[c,p]=fn_learningProgressionEmbeddingConfig(); c.eventFrame=4; c.nBins=3; c.overlap=0;
c.animalLabels=["AC1","AC2"]; p.makePlot=false;
phases=["Int","T2E"]; N=12; A=cell(8,2); T=A;
C=table(strings(8,1),strings(8,1),strings(8,1),strings(8,1), ...
    'VariableNames',{'conditionName','stimulus','action','task'});
for ph=1:2
    for s=1:4
        row=(ph-1)*4+s; C.conditionName(row)=phases(ph)+"_S"+s;
        C.stimulus(row)="S"+s; if mod(s,2), C.action(row)="L"; else, C.action(row)="R"; end
        if s<=2, C.task(row)="T1"; else, C.task(row)="T2"; end
        for a=1:2
            nn=4+a; sourceTrialRow=(2-ph)*48+(s-1)*N+(N:-1:1)';
            dayLabel=repmat(phases(ph),N,1); responseType=ones(N,1); responseType(4:4:N)=2;
            stimulusFrame=sourceTrialRow*30; responseFrame=stimulusFrame+2;
            T{row,a}=table(sourceTrialRow,dayLabel,responseType,stimulusFrame,responseFrame);
            X=zeros(nn,14,N);
            for j=1:N
                v=(1:nn)'; q=sourceTrialRow(j);
                X(:,5:7,j)=repmat(0.2*v+sin(q/11+v/2)+s/3,1,3);
                X(:,9:10,j)=repmat(cos(q/17+v/3)+s*v/8,1,2);
            end
            A{row,a}=X;
        end
    end
end
end
