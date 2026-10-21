function tests=testTrialProgression
tests=functiontests(localfunctions);
end
function setupOnce(t)
t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(fileparts(mfilename('fullpath')))));
end
function testVarianceAtFixedTimeAndConditionSelection(t)
[A,T,c,p]=fixture(); r=fn_analyzeTrialProgression(A,T,c,p);
S=r.byCondition(1); verifyEqual(t,S.nProgressionTrials,30);
verifyEqual(t,S.neurons.varianceScore(1),0,'AbsTol',1e-12); % Strong PSTH alone is not trial variance.
verifyEqual(t,S.neurons.varianceScore(2),var(1:30,0),'AbsTol',1e-12);
verifyEqual(t,S.neurons.varianceScore(3),4*var(1:30,0),'AbsTol',1e-12);
verifyEqual(t,find(S.selectedNeuronMask),3);
verifyEqual(t,find(r.byCondition(2).selectedNeuronMask),2);
verifyEqual(t,S.allPopulation.displayPsth(:,1),mean(A{1}(:,:,1),1)');
verifyEqual(t,S.allPopulation.endPsth,mean(mean(A{1}(:,:,36:40),3),1)');
verifyEqual(t,S.animalAudit.endTrials{1},36:40);
verifyFalse(t,isfield(r,'figures'));
end
function testProgressionDirectionAndComparison(t)
[A,T,c,p]=fixture(); c.selectionMethod='progression'; c.comparisonReference='progression';
r=fn_analyzeTrialProgression(A,T,c,p); S=r.byCondition(1);
verifyEqual(t,find(S.selectedNeuronMask),2); verifyEqual(t,S.animalAudit.endTrials{1},26:30);
verifyEqual(t,S.neurons.meanSlopePerTrial,[0;1;-2],'AbsTol',1e-12);
c.progressionDirection='negative'; c.endTrials=12:15;
r=fn_analyzeTrialProgression(A,T,c,p);
verifyEqual(t,find(r.byCondition(1).selectedNeuronMask),3);
verifyEqual(t,r.byCondition(1).animalAudit.endTrials{1},12:15);
end
function testPoolingAndShortTrials(t)
[A,T,c,p]=fixture(); A=[A A]; A{1,2}=A{1,2}(:,:,1:12); A{2,2}=[];
A{1,2}(1,1,1)=NaN; c.comparisonReference='progression';
r=fn_analyzeTrialProgression(A,T,c,p); S=r.byCondition(1);
verifyEqual(t,S.nProgressionTrials,12); verifyEqual(t,S.allPopulation.nNeurons,5);
verifyEqual(t,S.neurons.animalIndex,[1;1;1;2;2]);
verifyEqual(t,S.neurons.rowInAnimal,[1;2;3;2;3]);
verifyEqual(t,S.animalAudit.nDroppedNeurons,[0;1]);
verifyEqual(t,r.byCondition(2).allPopulation.nNeurons,3);
end
function testConstantAndHiddenPlots(t)
[A,T,c,p]=fixture(); A{2}=zeros(size(A{2}));
folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
p.makePlot=true; p.visible=false; p.savePath=folder.Folder;
before=findall(groot,'Type','figure'); [r,f]=fn_analyzeTrialProgression(A,T,c,p);
verifyFalse(t,any(r.byCondition(2).selectedNeuronMask));
verifyEqual(t,r.byCondition(2).selectedPopulation.nNeurons,0);
verifyTrue(t,isfile(r.plotFiles.allNeurons)); verifyTrue(t,isfile(r.plotFiles.selectedNeurons));
verifyEmpty(t,f.allNeurons); verifyEqual(t,findall(groot,'Type','figure'),before);
end
function [A,T,c,p]=fixture()
[c,p]=fn_trialProgressionConfig(); c.verbose=false; c.time=0:3;
c.nSelectedNeurons=1; p.makePlot=false;
T=table([1;2],'VariableNames',{'stimulus'}); A=cell(2,1);
base=[0 10 20 30];
for trial=1:40
    A{1}(:,:,trial)=[base;ones(1,4)*trial;-2*ones(1,4)*trial];
    A{2}(:,:,trial)=[base;3*ones(1,4)*trial;ones(1,4)*trial];
end
end
