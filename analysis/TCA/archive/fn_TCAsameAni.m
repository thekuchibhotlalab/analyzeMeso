%%
datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz153'; 
aniPPC = [ID '_PPC']; aniAC = [ID '_AC'];
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo.mat' ]);
dataAC = load([datapath aniAC filesep aniAC '_trialTypeInfo.mat' ]);

[TzPPC] = fn_zscoreTable(dataPPC.trialTypeInfo.dffStim, 'detrendWin', 15); 
[TzAC] = fn_zscoreTable(dataAC.trialTypeInfo.dffStim, 'detrendWin', 15); 
%%
[respMatPPC.mat, respMatPPC.std, respMatPPC.flag,respMatPPC.dprime, respMatPPC.info] = fn_reduceStimByPeriod(TzPPC, ...
    'periodIdx', 1:7, 'trialTypes', [1 4 5 8], ...
    'stimWindow', 21:22, 'baseWindow', 1:19, ...
    'detrendWin', [], ...
    'zscoreAll',  false, ...
    'frameAgg','sum', 'dprimeThresh', 0);

[respMatAC.mat, respMatAC.std, respMatAC.flag,respMatAC.dprime, respMatAC.info] = fn_reduceStimByPeriod(TzAC, ...
    'periodIdx', 1:7, 'trialTypes', [1 4 5 8], ...
    'stimWindow', 21:22, 'baseWindow', 1:19, ...
    'detrendWin', [], ...
    'zscoreAll',  false, ...
    'frameAgg','sum', 'dprimeThresh', 0);

%%
maxPPC = prctile(respMatPPC.mat(:),99); maxAC = prctile(respMatAC.mat(:),99);


%X = cat(1,respMatPPC.mat / maxPPC,respMatAC.mat / maxAC); 
X = cat(1,respMatPPC.mat / maxPPC); 

Xnew = {}; Xnew{1} = X(:,[1:3 7],1:2); Xnew{2} = X(:,4:7,3:4);
Xnew = fn_cell2mat(Xnew,3);

[M,VEpct,TzProj] = fn_runTCA(Xnew,TzPPC);


%%
nModel = 10; 
figure; subplot(1,2,1);plot(VEpct)
subplot(1,2,2); imagesc(corr(M{nModel}.U{1})); colorbar;

figure;
for i = 1:3
    subplot(1,3,i);
    imagesc((M{nModel}.U{i})); colorbar; 
end 


nTC = 4;

figure; subplot(1,2,1);
plot(M{nModel}.U{2}(:,nTC),'o'); yline(0); xlim([0 5]); xline(3.5)
xticks(1:4); xticklabels({'E','M','L','Int'});
subplot(1,2,2);
plot(M{nModel}.U{3}(:,nTC),'o'); yline(0); title('choice');xlim([0 5]); ylim([-1.2 1.2])
xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});