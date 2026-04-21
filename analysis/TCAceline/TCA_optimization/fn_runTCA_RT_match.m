datapath = 'C:\Users\zzhu34\Documents\tempdata\'; 
ID = 'zz159'; 
aniPPC = [ID '_PPC']; 
dataPPC = load([datapath aniPPC filesep aniPPC '_trialTypeInfo_spkNorm.mat' ]);
load([datapath aniPPC filesep aniPPC '_trialTypeInfo.mat'], 'clusterLabel');

[outDff,~,outCounts,matchedRT] = fn_matchRT(dataPPC.trialTypeInfo);

outDff = cellfun(@(x)(nanmean(x,3)), outDff,'UniformOutput',false);
outDffMat= nan(size(outDff{1,1},1),size(outDff{1,1},2),size(outDff,1),size(outDff,2));

for i = 1:size(outDff,1)
    for j = 1:size(outDff,2)
        outDffMat(:,:,i,j) = outDff{i,j};
    end 
end 
outDffMat = outDffMat(clusterLabel~=1,:,:,:);

save('outDffMat_PPC_zz159_spkNorm_choice.mat',"outDffMat");

%%
[M,VEpct,TzProj] = fn_runTCA_nonneg(outDffMat + 1e-6);

save('TCA-nonneg_zz153_zz159_PPC_spkNorm_choice.mat');
%% plot the TCA components
nModel = 10;

% percentageExp = []; 
% for i = 1:nModel
%     recon = full(M{nModel}); 
%     total_var = var(recon(:));
%     T_reconstructed = fn_constructTensor({M{nModel}.U{1}(:,i),...
%         M{nModel}.U{2}(:,i),M{nModel}.U{3}(:,i),M{nModel}.U{4}(:,i)},M{nModel}.lambda(i));
%     percentageExp(i) = var(T_reconstructed(:)) / total_var;
% end 
 
figure; plot(VEpct)
figure; subplot(1,2,1);plot(M{nModel}.lambda); xlabel('nTC'); ylabel('lambda');
subplot(1,2,2); imagesc(corr(M{nModel}.U{1})); colorbar;
title('Correlation matrix of the stimulus weights')

subtitles = {'neural','time','learning phase','trial type'};
figure;
for i = 1:4
    subplot(1,4,i);
    temp = M{nModel}.U{i}'; 
    imagesc(temp); colorbar; clim([prctile(temp(:),5) prctile(temp(:),95)])
    xlabel(subtitles{i})
    ylabel('nTC')
    if i==2; xline(10); end 
end 

%%

%TCs = [1 2 3 5 8];
%TCs = [4 7 9 13];
%TCs = [6 11 12 15];

%TCs = [1 3];
%TCs = [2 4 5 8 12 15];
%TCs = [6 7 9 11 13 14];

%TCs = [2 4 5 8 12 15];

TCs = [1 2];
%TCs = [2 3 4 5 6 7 12 13];
%TCs = [5 6 13];
%TCs = [7 8];
%TCs = [9 10 14];
%TCs = [11];

%TCs = [1 4 5 7];

%TCs = [2 8 11];
%TCs = [10 14];
%TCs = [6 9 10 12];


%TCs = [2 4 6];
%TCs = [3 8];


%TCs = [6 7 9 8];
%TCs = [9 10];
%TCs = [6 7 8 9 12];
%TCs = [3 8];
figure; tempVar = [0 VEpct];
RTtemp = 0.6; %RTtemp = nanmean(matchedRT(:));

for i = 1:length(TCs)
    nTC = TCs(i);
    subplot(length(TCs),4,1 + 4*(i-1));
    histogram(M{nModel}.U{1}(:,nTC)); yline(0); 
    title('Neural Weight');
    %title(['TC' int2str(nTC) ' lambda=' num2str(M{nModel}.lambda(nTC))]);
    xlim([0 0.02])

    subplot(length(TCs),4,2 + 4*(i-1));
    nTime = size(M{nModel}.U{2}(:,nTC),1); timeAxis = ((1:nTime)-10)/15;
    plot(timeAxis,M{nModel}.U{2}(:,nTC),'Linewidth',2,'Color',[0.6 0.6 0.6]); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    ylim([0 0.2])
    xline(RTtemp,'--')

    subplot(length(TCs),4,3 + 4*(i-1));
    plot(M{nModel}.U{3}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',[0.6 0.6 0.6]); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])
    xticks(1:4); xticklabels({'E','M','L','Int'}); title('Learning Phase')


    subplot(length(TCs),4,4 + 4*(i-1));
    plot(M{nModel}.U{4}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',[0.6 0.6 0.6]); yline(0); title('Trial Type');xlim([0 5]); ylim([0 1.2])
    xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});
    xline(2.5)

end 

