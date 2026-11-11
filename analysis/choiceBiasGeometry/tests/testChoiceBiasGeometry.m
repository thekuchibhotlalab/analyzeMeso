function tests=testChoiceBiasGeometry
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(fileparts(mfilename('fullpath'))); repo=fileparts(fileparts(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(folder));
t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'helper_function')));
end
function testBiasDefinitionAndSessionBoundaries(t)
[S,c,p]=fixture(); T=S{1}.neuralSelection.trialInfoNeural;
verifyEqual(t,T.choiceBiasBlockValue(T.choiceBiasBlock==1),repmat(.6,40,1),'AbsTol',1e-12);
verifyEqual(t,T.choiceBiasBlockValue(T.choiceBiasBlock==2),zeros(40,1),'AbsTol',1e-12);
for task=1:2
    ix=find(T.choiceBiasTask==task);
    verifyTrue(t,all(isnan(T.choiceBias(ix(1:19)))));
    verifyTrue(t,all(isnan(T.choiceBias(ix(end-19:end)))));
    verifyEqual(t,T.choiceBias(ix(20)),.6,'AbsTol',1e-12);
    other=3-task; verifyTrue(t,all(isnan(T.(sprintf('choiceBiasT%d',other))(ix))));
end
U=T; U.sessionName(:)="second";
V=fn_addChoiceBias([T;U],40);
verifyEqual(t,V.choiceBias(1:height(T)),V.choiceBias(height(T)+(1:height(T))));
% Do not change caller RNG while fitting.
state=rng; r=fn_analyzeChoiceBiasGeometry(S,c,p); verifyEqual(t,rng,state);
verifyEqual(t,r.preFrameIndices,1:15); verifyEqual(t,r.choiceFrameIndices,28:30);
verifyEqual(t,height(r.bins),12); % Two animals x two tasks x three full bins.
end
function testHeldOutFitsAndWindowMeans(t)
[S,c,p]=fixture(); r=fn_analyzeChoiceBiasGeometry(S,c,p); E=r.entries(1);
verifyTrue(t,all(isfinite(E.projection),'all'));
verifyEqual(t,E.preProjection,mean(E.projection(:,1:15),2),'AbsTol',1e-12);
verifyEqual(t,E.choiceProjection,mean(E.projection(:,28:30),2),'AbsTol',1e-12);
f=E.fold(1); row=E.trialInfo.sourceTrialRow(1);
S{1}.neuralSelection.neuralRaw(:,28:30,row)=S{1}.neuralSelection.neuralRaw(:,28:30,row)+20;
q=fn_analyzeChoiceBiasGeometry(S,c,p);
verifyEqual(t,q.entries(1).foldModels{f},E.foldModels{f}); % Held-out trial never trained its own axis.
verifyGreaterThan(t,abs(q.entries(1).choiceProjection(1)-E.choiceProjection(1)),.01);
end
function testPlotExports(t)
[S,c,p]=fixture(); r=fn_analyzeChoiceBiasGeometry(S,c,p);
% Optional metadata can differ across animals; plotting only needs bias/action.
for k=find([r.entries.animalIndex]==2)
    r.entries(k).trialInfo.extraAnimalMetadata=ones(height(r.entries(k).trialInfo),1);
end
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
[figs,files]=fn_plotChoiceBiasGeometry(r,p);
verifyEmpty(t,figs.projections); verifyEmpty(t,figs.correlations);
verifyTrue(t,isfile(files.projections.png)&&isfile(files.projections.fig));
verifyTrue(t,isfile(files.correlations.png)&&isfile(files.correlations.fig));
end
function [S,c,p]=fixture()
[c,p]=fn_choiceBiasGeometryConfig(); p.makePlot=false; c.minBinTrialsPerAction=3;
stream=RandStream('mt19937ar','Seed',4); S=cell(1,2);
for animal=1:2
    n=240; stimuli=repmat([1;3;2;4],60,1); action=zeros(n,1); responseType=zeros(n,1);
    task=1+(stimuli>2);
    for k=1:2
        rows=find(task==k);
        for b=1:3
            ids=rows((b-1)*40+(1:40)); left=ids(ismember(stimuli(ids),[1 3])); right=setdiff(ids,left,'stable');
            nCorrect=[20 8;16 16;8 20];
            action(left)=1; action(right)=2; responseType(ids)=1;
            wrong=[left(nCorrect(b,1)+1:end);right(nCorrect(b,2)+1:end)];
            action(wrong)=3-action(wrong); responseType(wrong)=3;
        end
    end
    trialInSession=(1:n)'; date=repmat(20260101,n,1); sessionName=repmat("session1",n,1);
    dayLabel=repmat("Int",n,1); sourceTrialRow=(1:n)';
    T=table(stimuli,action,responseType,trialInSession,date,sessionName,dayLabel,sourceTrialRow);
    T=fn_addChoiceBias(T,40); X=randn(stream,5,100,n)*.4;
    for j=1:n
        sign=3-2*action(j);
        X(1,28:30,j)=X(1,28:30,j)+sign;
        X(1,1:15,j)=X(1,1:15,j)+sign*(.2+abs(T.choiceBiasBlockValue(j)));
    end
    S{animal}=struct('animalID',"animal"+animal,'cfg',struct('neuralField','dffChoice'), ...
        'tracking',struct('selectedNeuronMask',true(5,1)), ...
        'neuralSelection',struct('neuralRaw',X,'trialInfoNeural',T));
end
end

