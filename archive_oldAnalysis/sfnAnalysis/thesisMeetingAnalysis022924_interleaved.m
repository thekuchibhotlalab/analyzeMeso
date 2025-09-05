%% 0.1 --- load suite2p data
datapath = 'D:\zz142\committee\110423_111223\green_PPC\suite2p_110623_111223\plane0';
%datapath = 'D:\zz142\committee\111623_112923\tifs\green_PPC\suite2p\plane0'; 
data = struct();
try
    data = load([datapath filesep 'Fall.mat']);
catch
    data.ops = readNPY([datapath filesep 'ops.npy']); % apparently this does not work for dictionaries. need to load the ops for AC when it does not work for PPC
    data.F = readNPY([datapath filesep 'F.npy']);
    data.stat = readNPY([datapath filesep 'stat.npy']);
    data.iscell = readNPY([datapath filesep 'iscell.npy']);
end
%% 0.2 --- get the list of sessions and frames
Fops = struct(); 
nFrames = data.ops.nframes_per_folder;
Fops.nFramesSum = double([0 cumsum(nFrames)]);
Fops.dayList = []; Fops.sessionList = {}; Fops.sessionListNum = [];
for i= 1:size(data.ops.filelist,1)
    tempStr = strsplit(data.ops.filelist(i,:),'\'); tempStr = tempStr{2};
    tempStr = strsplit(tempStr,'_'); 
    tempDay = tempStr{2}; Fops.dayList(i) = str2num(tempDay); 

    tempSession = tempStr{3}; tempSessionNum = str2num(tempSession(end));
    if ~isempty(tempSessionNum); Fops.sessionList{i}= tempSessionNum; Fops.sessionListNum(i) = tempSessionNum;
    else; Fops.sessionList{i} = tempSession; Fops.sessionListNum(i) = nan; end 
end 
%% 0.2.1 --- Correct for high-movement frames
F = data.F(data.iscell(:,1)==1,:);
notNanFlag = ~(sum(isnan(F),2)>0);F = F(notNanFlag,:);
moveX = double(data.ops.xoff);  moveY = double(data.ops.yoff); 
[Fnew,motionMetric] = fn_correctForMotionFrames(F,moveX,moveY,nFramesSum);
%figure; i = 10; plot(F(i,:)); hold on; plot(Fnew(i,:))

%% 0.3 --- get behavioral data
behOps = struct(); 
behOps.mouse = 'zz142'; behOps.datapath = ['G:\ziyi\mesoData\' behOps.mouse '_behavior\matlab\']; 
%behOps.dayRange = [20231107,20231117];
%behOps.dayRange = [20231118,20231122]; behOps.interleaved = true;
%behOps.dayRange = [20231020,20231106];
%behOps.date = {'20231116','20231117','20231118','20231119','20231121','20231122','20231125','20231127','20231128','20231129'};
behOps.date = {'20231104','20231105','20231106','20231107','20231108','20231109','20231112'};
behOps.dateNum = cellfun(@(x)(str2num(x)),behOps.date);
behOps.plot = true;
beh = fn_getBehav(behOps);

%% 1 -- Select a session to analyze
if any(112123==Fops.dayList); Fops.sessionListNum(17:21) = [1 2 3 4 5]; Fops.sessionList(17:21) = {1,2,3,4,5}; end

[dffStimList, dffChoiceList, selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps);
%% 1.1 -- get trial aligned F and movement
selectedDff = fn_getDff(selectedF','method', 'movMean','dffWindow', 3000)';

[dffStim,dffChoice] = fn_parseTrialTC(selectedDff,selectedBeh);
[motionStim,motionChoice] = fn_parseTrialFromTC(selectedMotion,selectedBeh);
%% 1.2 -- plot movement around stimulus or choice
stimL = selectedBeh(:,5)==3; stimR = selectedBeh(:,5)==4;
choiceL = selectedBeh(:,6)==1; choiceR = selectedBeh(:,6)==2;
flagList = {stimL & choiceL, stimL & choiceR; stimR & choiceR, stimR & choiceL};
figure; 
for i = 1:4; subplot(2,2,i);
fn_plotMeanErrorbar(1:size(motionChoice,2),squeeze(motionChoice(:,:,flagList{i}))',...
    matlabColors(1),matlabColors(1,0.6),{},{'facealpha',0.2});
end 
% The major movement around x,y is large at sound onset, but does not necessarily produce shift in z, 
% It should be the reward movement that cause the issue. need to produce an average movie to check exactly when bad motion happens
% For now, keep the movie uncorrected.


%%
stimL = selectedBeh(:,5)==3; stimR = selectedBeh(:,5)==4;
choiceL = selectedBeh(:,6)==1; choiceR = selectedBeh(:,6)==2; miss = selectedBeh(:,6)==0;
flagList = {stimL & choiceL, stimL & choiceR, stimR & choiceR, stimR & choiceL};
titleList = {'stimL; choiceL','stimL; choiceR','stimR; choiceR','stimR; choiceL'};

sortF = sum(nanmean(dffStim(:,31:70,stimL & choiceL),3),2); 
[~,sortIdx] = sort(sortF,'descend');

xdata = ((1:size(dffStim,2))-30)/15; 

figure; 
for i = 1:4
    subplot(2,2,i);
    fn_plotPSTH(dffStim,'sortIdx', sortIdx, 'selFlag', flagList{i},'xaxis',xdata,'xlim',[-2 6],'title',titleList{i}); 
end 

stimL = selectedBeh(:,5)==1; stimR = selectedBeh(:,5)==2;
choiceL = selectedBeh(:,6)==1; choiceR = selectedBeh(:,6)==2; miss = selectedBeh(:,6)==0;
flagList = {stimL & choiceL, stimL & choiceR; stimR & choiceR, stimR & choiceL};

figure; 
for i = 1:4
    subplot(2,2,i);
    fn_plotPSTH(dffStim,'sortIdx', sortIdx, 'selFlag', flagList{i},'xaxis',xdata,'xlim',[-2 6],'title',['Task1 ' titleList{i}]); 
end 


%%

nFramePCA = 120;
flagCell = {stimL&choiceL, stimL&choiceR, stimR&choiceL, stimR&choiceR}; 
tempColors = [matlabColors(1);matlabColors(1); matlabColors(2);matlabColors(2)];
tempLine = {'-' ,'--','-','--'};
%proj = run_PCA(dffStim(PPCflag&~inhFlag,:,:),flagCell,tempColors,tempLine,nFramePCA);
%proj = run_PCA(dffStim(ACflag&inhFlag,:,:),flagCell,tempColors,tempLine,nFramePCA);
[projS,basisS] = run_PCA(dffStim,flagCell,tempColors,tempLine,nFramePCA);
%% all functions
function [proj,basis] = run_PCA(dff,flagCell,tempColors,tempLine,nFramePCA)

dffStimPCA = cellfun(@(x)(squeeze(nanmean(dff(:,1:nFramePCA,x),3))), flagCell,'UniformOutput',false);
dffStimPCAFlat = fn_cell2mat(cellfun(@(x)(smoothdata(x,2,'movmean',10)),dffStimPCA,'UniformOutput',false),2);
[basis, varExp, proj, covMat] = fn_pca(dffStimPCAFlat,'zscore',true);

figure; 
for j = 1:6
    subplot(2,4,j);
    hold on;
    
    for i = 1:length(flagCell)
        plot(smoothdata(proj(j,(i-1)*nFramePCA+1:(i)*nFramePCA),'movmean',1),tempLine{i},'Color',tempColors(i,:)); 
    end
end

subplot(2,4,7);
plot(varExp,'-o'); xlim([1 20])

subplot(2,4,8);
plot(cumsum(varExp)); xlim([1 20]); ylim([0 1])
end

