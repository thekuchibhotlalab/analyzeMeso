function [weights, proj, explained] = fn_pcaNeuronEvo(selRespMat)

nPeriod = size(selRespMat,2); nTrials = size(selRespMat,3); nNeuron = size(selRespMat,1);
tempPCA = reshape(selRespMat,nNeuron,nTrials*nPeriod);


[weights, proj, ~, ~, explained] = pca(tempPCA');

proj = reshape(proj,nPeriod,nTrials,[]);
figure; 
nPC = 8;
for i = 1:nPC
    subplot(3,nPC,i);
    temp = proj(:,:,i);
    tempMax =  max(temp(:));  tempMin =  min(temp(:)); tempHalf = max(abs(tempMax),abs(tempMin));
    plot(1:nPeriod,proj(:,1,i)+tempHalf*1.5,'o','Color',matlabColors(1)); hold on;
    plot(1:nPeriod,proj(:,2,i)+tempHalf*1.5,'o','Color',matlabColors(2)); 

    plot(1:nPeriod,proj(:,3,i)-tempHalf*1.5,'x','Color',matlabColors(1));
    plot(1:nPeriod,proj(:,4,i)-tempHalf*1.5,'x','Color',matlabColors(2)); 
    yline(0,'LineWidth',1.5); yline(tempHalf*1.5,'LineWidth',0.5); yline(-tempHalf*1.5,'LineWidth',0.5);
    
    ylim([-tempHalf*3 tempHalf*3]); yticks([-tempHalf*1.5 tempHalf*1.5]); yticklabels({'0','0'})
    xline(3.5); xline(6.5); xlim([0 8]); xticks([2 5 7]); xticklabels({'T1','T2','Int'});
    title(['PC' int2str(i) ' var=' int2str(explained(i)) '%'])

    subplot(3,nPC,i+nPC);
    temp = proj(:,:,i);
    tempMax =  max(temp(:));  tempMin =  min(temp(:)); tempHalf = max(abs(tempMax),abs(tempMin));
    plot(1:nPeriod,proj(:,1,i)+tempHalf*1.5,'o','Color',matlabColors(1)); hold on;
    plot(1:nPeriod,proj(:,3,i)+tempHalf*1.5,'X','Color',matlabColors(1)); 

    plot(1:nPeriod,proj(:,2,i)-tempHalf*1.5,'o','Color',matlabColors(2));
    plot(1:nPeriod,proj(:,4,i)-tempHalf*1.5,'X','Color',matlabColors(2)); 
    yline(0,'LineWidth',1.5); yline(tempHalf*1.5,'LineWidth',0.5); yline(-tempHalf*1.5,'LineWidth',0.5);
    
    ylim([-tempHalf*3 tempHalf*3]); yticks([-tempHalf*1.5 tempHalf*1.5]); yticklabels({'0','0'})
    xline(3.5); xline(6.5); xlim([0 8]); xticks([2 5 7]); xticklabels({'T1','T2','Int'});
    title(['PC' int2str(i) ' var=' int2str(explained(i)) '%, org. by. L/R'])

     subplot(3,nPC,i+nPC*2);
     histogram(weights(:,i)); xlabel('PC weights'); ylabel('nNeuron')


end


end
