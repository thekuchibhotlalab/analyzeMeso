%% select model and components
load('TCA-nonneg_zz151_zz153_159_AC_spkNorm.mat','M','VEpct');
nModel = 15; M= M{nModel};
TCs = [2 3 9];

M2 = load('TCA-nonneg_zz153_159PPC_spkNorm_cluster1.mat','M','VEpct');
VEpct2 =M2.VEpct; M2 = M2.M;
nModel = 12; M2 = M2{nModel};
TCs2 = [10 7 9];


%%
figure; tempVar = [0 VEpct];
RTtemp = 0.6; %RTtemp = nanmean(matchedRT(:));

for i = 1:length(TCs)
    nTC = TCs(i);
    subplot(length(TCs)*2,4,1 + 8*(i-1));hold on;
    bar(M.lambda,'EdgeColor','none',"FaceColor",[0.8 0.8 0.8]);  
    bar(nTC,M.lambda(nTC),'EdgeColor','none',"FaceColor",matlabColors(4,0.9)); 
    xticks(''); yticks('')
    %[sortedW] = sort(M.U{1}(:,nTC),'ascend'); hold on;
    %plot((1:length(sortedW))/length(sortedW),sortedW,'LineWidth',2,'Color',matlabColors(1)); yline(0); 

    subplot(length(TCs)*2,4,5+ 8*(i-1));hold on;
    bar(M2.lambda,'EdgeColor','none',"FaceColor",[0.8 0.8 0.8]); 
    bar(TCs2(i),M2.lambda(TCs2(i)),'EdgeColor','none',"FaceColor",matlabColors(2,0.9)); 
    %[sortedW2] = sort(M2.U{1}(:,nTC),'ascend'); hold on;
    %plot((1:length(sortedW2))/length(sortedW2),sortedW2,'LineWidth',2,'Color',matlabColors(2)); yline(0); 
    %title('Neural Weight'); 
    xticks('');yticks('')
    %title(['TC' int2str(nTC) ' lambda=' num2str(M{nModel}.lambda(nTC))]);
    %ylim([0 0.025])

    subplot(length(TCs),4,2 + 4*(i-1));hold on;
    nTime = size(M.U{2}(:,nTC),1); timeAxis = ((1:nTime)-10)/15;
    plot(timeAxis,M.U{2}(:,nTC),'Linewidth',2,'Color',matlabColors(4,0.9)); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    hold on; 
    plot(timeAxis,M2.U{2}(:,TCs2(i)),'Linewidth',2,'Color',matlabColors(2,0.9)); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    ylim([0 0.2])
    xline(RTtemp,'--')

    subplot(length(TCs),4,3 + 4*(i-1));hold on;
    plot(M.U{3}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(4,0.9) ); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])
    hold on; xticks(1:4); xticklabels({'E','M','L','Int'}); title('Learning Phase'); ylim([0 1])
    plot(M2.U{3}(:,TCs2(i)),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(2,0.9)); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])


    subplot(length(TCs),4,4 + 4*(i-1));hold on;
    plot(M.U{4}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(4,0.9)); yline(0); title('Trial Type');xlim([0 5]); ylim([0 1.2])
    hold on; xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});ylim([0 1])
    plot(M2.U{4}(:,TCs2(i)),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(2,0.9)); yline(0); title('Trial Type');xlim([0 5]); ylim([0 1.2])
    xline(2.5)

end 



%% PPC common plot
M = load('TCA-nonneg_zz153_zz159_PPC_spkNorm_choice.mat','M');
M = M.M;
nModel = 10; M = M{nModel};
TCs = [4 11 5 6];
TCs = [1 2]; 


figure;
RTtemp = 0.6; %RTtemp = nanmean(matchedRT(:));

for i = 1:length(TCs)
    nTC = TCs(i);
    %subplot(length(TCs),4,1 + 4*(i-1));
    %[sortedW] = sort(M.U{1}(:,nTC),'ascend'); hold on;
    %plot((1:length(sortedW))/length(sortedW),sortedW,'LineWidth',2,'Color',matlabColors(1)); yline(0); 

    %title('Neural Weight');
    %title(['TC' int2str(nTC) ' lambda=' num2str(M{nModel}.lambda(nTC))]);
    %ylim([0 0.025])
    subplot(length(TCs),4,1 + 4*(i-1));hold on;
    bar(M.lambda,'EdgeColor','none',"FaceColor",[0.8 0.8 0.8]);  
    bar(nTC,M.lambda(nTC),'EdgeColor','none',"FaceColor",matlabColors(2,0.9)); 


    subplot(length(TCs),4,2 + 4*(i-1));hold on;
    nTime = size(M.U{2}(:,nTC),1); timeAxis = ((1:nTime)-10)/15;
    plot(timeAxis,M.U{2}(:,nTC),'Linewidth',2,'Color',matlabColors(2,0.9)); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    hold on; 
    ylim([0 0.4])
    xline(RTtemp,'--')

    subplot(length(TCs),4,3 + 4*(i-1));hold on;
    plot(M.U{3}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(2,0.9) ); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])
    hold on; xticks(1:4); xticklabels({'E','M','L','Int'}); title('Learning Phase'); ylim([0 1])


    subplot(length(TCs),4,4 + 4*(i-1));hold on;
    plot(M.U{4}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(2,0.9)); yline(0); title('Trial Type');xlim([0 5]); ylim([0 1.2])
    hold on; xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});ylim([0 1])
    xline(2.5)

end 

%% AC common component plot
M = load('TCA-nonneg_zz151_zz153_159_AC_spkNorm.mat','M');
M = M.M;
nModel = 15; M = M{nModel};
TCs = [1 11 13];
%TCs = [1 3]; 


figure;
RTtemp = 0.6; %RTtemp = nanmean(matchedRT(:));

for i = 1:length(TCs)
    nTC = TCs(i);
    %subplot(length(TCs),4,1 + 4*(i-1));
    %[sortedW] = sort(M.U{1}(:,nTC),'ascend'); hold on;
    %plot((1:length(sortedW))/length(sortedW),sortedW,'LineWidth',2,'Color',matlabColors(1)); yline(0); 

    %title('Neural Weight');
    %title(['TC' int2str(nTC) ' lambda=' num2str(M{nModel}.lambda(nTC))]);
    %ylim([0 0.025])
    subplot(length(TCs),4,1 + 4*(i-1));hold on;
    bar(M.lambda,'EdgeColor','none',"FaceColor",[0.8 0.8 0.8]);  
    bar(nTC,M.lambda(nTC),'EdgeColor','none',"FaceColor",matlabColors(4,0.9)); 


    subplot(length(TCs),4,2 + 4*(i-1));hold on;
    nTime = size(M.U{2}(:,nTC),1); timeAxis = ((1:nTime)-10)/15;
    plot(timeAxis,M.U{2}(:,nTC),'Linewidth',2,'Color',matlabColors(4,0.9)); yline(0); title('Temporal Dynamic');xlim([-0.6 1.33]);  xline(0)
    hold on; 
    ylim([0 0.5])
    xline(RTtemp,'--')

    subplot(length(TCs),4,3 + 4*(i-1));hold on;
    plot(M.U{3}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(4,0.9) ); yline(0); xlim([0 5]); xline(3.5);ylim([0 1.2])
    hold on; xticks(1:4); xticklabels({'E','M','L','Int'}); title('Learning Phase'); ylim([0 1])


    subplot(length(TCs),4,4 + 4*(i-1));hold on;
    plot(M.U{4}(:,nTC),'o','MarkerSize',4,'LineWidth',2,'Color',matlabColors(4,0.9)); yline(0); title('Trial Type');xlim([0 5]); ylim([0 1.2])
    hold on; xticks([1 2 3 4]); xticklabels({'T1L', 'T1R','T2L', 'T2R'});ylim([0 1])
    xline(2.5)

end 