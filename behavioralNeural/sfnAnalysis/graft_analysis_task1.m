%% to process zz159
clear;

ops.mouse = 'zz159';
ops.area = 'AC'; ops.task = 'task2';
ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
%ops.dayRange = {'20240613','20240629'};
ops.dayRange = {'20240629','20240726'};

ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
%data = fn_loadBehNeuroData(ops);
[Fnew, beh, Fops,behOps] = fn_loadData(ops);


%% to process zz151
clear;

ops.mouse = 'zz151';
ops.area = 'AC'; ops.task = 'task1';
ops.Fpath = ['C:\Users\zzhu34\Documents\tempdata\' ops.mouse '_' ops.area filesep ops.task filesep ];
ops.dayRange = {'20240325','20240417'};
ops.behavPath = ['G:\ziyi\mesoData\' ops.mouse '_behavior\matlab\']; 
%data = fn_loadBehNeuroData(ops);
[Fnew, beh, Fops,behOps] = fn_loadData(ops);

%%

[data.dffStimList, data.selectedBehList,behOps] = fn_parseTrial(Fnew, beh, Fops, behOps,'stim'); clear Fnew; 


%% split data into stimulus and action types
data = fn_analyzeTaskTransition(data,behOps);

%%

decodingLim = 100;
%grouping = {[1],[2,3,4,5], [6 7 8 9 10], [ 11 12 13]};
grouping = {[1,2,3,4,5],[9,10,11 12], [13,14,15,16]};

s1a1 = getDataGrouping (data,grouping,'s1a1',true);
s2a2 = getDataGrouping (data,grouping,'s2a2',true);
%%

figure; 
for j = 1:36
    subplot(6,6,j);
    j = j+100;
    for i = 1:3
        hold on; 
        tempDay2 = nanmean(s2a2{i},3); 
        tempDay1 = nanmean(s1a1{i},3);
        
        plot(smoothdata(tempDay1(j,1:100)-tempDay2(j,1:100),2,'movmean',4))
    end 
end 
% 159, neuron 6, 10, 18, 25, 33, 65, 133 for selectivity change
% 151, neuron 17, 104, 122, 135, for selectivity change
%%
figure; temp = nanmean(s2a2{1}(:,1:100,:),3);
imagesc(temp); clim([-prctile(temp(:),99) prctile(temp(:),99)])

%%
neuron = 122;xFrameLim = 100;
xAxisStim = ((1:xFrameLim)-30)/15; % axis for plotting
xtickVal = -3:5; xtickStr = strsplit(num2str(xtickVal));

figure; 

for i = 1:3
    subplot(1,3,i);
fn_plotMeanErrorbar(xAxisStim,smoothdata(squeeze(s1a1{i}(neuron,1:xFrameLim,:)),1,'movmean',3)', multitaskColors('s1a1'),...
     multitaskColors('s1a1'),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
fn_plotMeanErrorbar(xAxisStim,smoothdata(squeeze(s2a2{i}(neuron,1:xFrameLim,:)),1,'movmean',3)',multitaskColors('s2a2'),...
    multitaskColors('s2a2'),{'LineWidth',2}, {'Facealpha',0.2}); hold on;
xticks(xtickVal);  xticklabels(xtickStr); xlim([-1 2]); ylim([-0.15 0.4])
xlabel('time after stim onset (s)'); ylabel('df/f'); %title('Naive')
legend('','stim L, act L','','stim R, act R')
end 
%%
day = 14; tempDay = nanmean(data.s2a2{1}{day},3);
figure; imagesc(tempDay); clim([-prctile(tempDay(:),99) prctile(tempDay(:),99)]); xlim([0 100])
figure; plot(mean(tempDay(:,1:100),1))
%% decoding
[tempAcc, topNeuronIdx,neuronW,neuronAcc,tempAccShuf] = runDecoder(data1,data2,subSample);





%%
function outCell = getDataGrouping (data,grouping,fldname,catRT)
    if ~exist('catRT'); catRT = true; end 
    outCell = cell(1,length(grouping));
    for i = 1:length(grouping)
        tempCell = {};
        for j = 1:length(grouping{i})
            if catRT
                tempCell{j} = cat(3,data.(fldname){1}{grouping{i}(j)},data.(fldname){2}{grouping{i}(j)});
            else
                tempCell{j} = cat(3,data.(fldname){1}{grouping{i}(j)});
            end 
    
        end 
    
        outCell{i} = fn_cell2mat(tempCell,3);

    end 


end 