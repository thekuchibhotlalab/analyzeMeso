%% load data of 5 rep tones
clear;
load('D:\labData\2pData_meso\zz131\052223\AC_PPC\suite2p\plane0\Fall.mat')
dffArg = {'method', 'movMean','dffWindow',2000,'baselineCorrectionPostDff',...
    false,'baselineCorrectionWindow',2000};
%tempTC = F(:,18001:38000)'; 
tempTC = F(:,10201:30200)'; 

tempTC = tempTC(:,iscell(:,1)==1);
tempTC = circshift(tempTC,1,1);
tempTC = fn_getDff(tempTC,dffArg{:});
tempTC = smoothdata(tempTC,1,'movmean',5);
nNeuron = size(tempTC,2);

TC_reshape = reshape(tempTC,40,50,10,nNeuron);
TC_reshape = squeeze(mean(TC_reshape,3));
%TC_reshape = reshape(TC_reshape,40,5,10,nNeuron);
%%
pretoneFrames = 10; peakFrameBin = 10;
toneMean = squeeze(mean(TC_reshape,2));

[peakAct,peakFrames] = max(toneMean(pretoneFrames+1:pretoneFrames+peakFrameBin,:),[],1);
preAct = mean(toneMean(1:pretoneFrames,:),1);
toneAct = [];
for i = 1:nNeuron
    toneAct(:,i) = squeeze(TC_reshape(pretoneFrames+peakFrames(i),:,i)-mean(TC_reshape(1:pretoneFrames,:,i),1));
end

toneAct = reshape(toneAct,5,10,nNeuron);
toneOrder = [2 4 3 1 5]; toneAct = toneAct(toneOrder,:,:);
%%
cellSelFlag = peakFrames>=2 & peakFrames<=6;
freqMean = squeeze(mean(toneAct(:,:,cellSelFlag),2));
figure; 
imagesc(freqMean);
figure; plot(mean(freqMean,2))


%% look at location of responsive neurons

figure;      
imagesc(ops.meanImg);colormap gray;hold on;
ylim([0 size(ops.meanImgE,1)]);xlim([0 size(ops.meanImgE,2)]);
stat2 = stat(iscell(:,1)==1);

for j = 1:size(freqMean,2)
    bound = boundary(double(stat2{j}.xpix)', double(stat2{j}.ypix)',1); % restricted bound
    tempCoord = [stat2{j}.xpix(bound);stat2{j}.ypix(bound)];
    try
        if freqMean(1,j)>0.02
            patch(tempCoord(1,:),tempCoord(2,:),[1 0 0],'EdgeColor','none');
        else
            patch(tempCoord(1,:),tempCoord(2,:),[0.8 0.8 0.8],'EdgeColor','none');
        end
    catch; disp(j)
    end 

end
xticks([]);yticks([]);

