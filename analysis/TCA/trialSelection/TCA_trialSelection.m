%%
animalAreas = {'zz153_PPC','zz159_PPC','zz172_PPC1','zz172_PPC2'};

for i = 1:length(animalAreas)
    tic;
    [TCmeanNorm,TCnorm,trials,trialTypeInfoT1,trialTypeInfoT2] = fn_selectTrialTCA_perAni(animalAreas{i});
    toc;
end 

%%
animalAreas = {'zz153_PPC','zz159_PPC','zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};

outDffCell = cell(4,4);
axisLabel = {'E,S1,L', 'E,S2,R', 'E,S3,L','E,S4,R';...
    'M,S1,L', 'M,S2,R', 'M,S3,L','M,S4,R';...
    'L,S1,L', 'L,S2,R', 'L,S3,L','L,S4,R';...
    'Int,S1,L', 'Int,S2,R', 'Int,S3,L','Int,S4,R'};
nNeuron = [];
for i = 1:length(animalAreas)
    load(['B:\analysis\TCA2026_RTmatch\' animalAreas{i} '_TCA_choice.mat'],'TCmeanNorm');
    outDffCell = cellfun(@(x,y)(cat(1,x,y)), outDffCell,TCmeanNorm,'UniformOutput',false);
    nNeuron = cat(1,nNeuron,size(TCmeanNorm{1,1},1));

end 
axisLabel = reshape(axisLabel,4,2,2);
outDffCell = reshape(outDffCell,16,1);
outDffMat = fn_cell2mat(outDffCell,3);

outDffMat = reshape(outDffMat,size(outDffMat,1),size(outDffMat,2),4,2,2);

%%
animalAreas = {'zz151_AC1','zz153_AC','zz159_AC','zz170_AC1','zz170_AC2','zz180_AC'};

outDffCell = cell(1,2);

nNeuron = [];
for i = 1:length(animalAreas)
    load(['B:\analysis\TCA2026_RTmatch\' animalAreas{i} '_TCA_T1EM.mat'],'TCmeanNorm');
    outDffCell = cellfun(@(x,y)(cat(1,x,y)), outDffCell,TCmeanNorm,'UniformOutput',false);
    nNeuron = cat(1,nNeuron,size(TCmeanNorm{1,1},1));

end 

outDffMat = fn_cell2mat(outDffCell,4);

%%
timeWindow = 21:55;
[M,VEpct,TzProj] = fn_runTCA_nonneg(outDffMat(:,timeWindow,:,:,:) + 1e-6);
save('B:\analysis\TCA2026_RTmatch\TCAfit_stim_AC_T1EM_M8.mat','outDffMat',...
    'M','VEpct','TzProj','nNeuron','axisLabel','timeWindow');