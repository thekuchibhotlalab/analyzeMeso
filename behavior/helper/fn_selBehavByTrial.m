function [selBeh,flag, varargout] = fn_selBehavByTrial(beh,criteria,varargin)
    p = inputParser;
    addParameter(p, 'plot', false);
    parse(p, varargin{:});

    nDays = max(beh(:,2));
    task1Stim = zeros(1,nDays);
    task2Stim = zeros(1,nDays);
    daySplit = {};
    for i = 1:nDays
        tempStim = beh(beh(:,2)==i,5);
        task1Stim(i) = mean(tempStim==1 | tempStim==2);
        task2Stim(i) = mean(tempStim==3 | tempStim==4);
        daySplit{i} = find(beh(:,2)==i);
    end
    task1Flag = find(task1Stim>0.65);
    tempDiff = diff(task1Flag); tempBreak = find(tempDiff>1);
    if ~isnan(tempBreak); task1Flag = task1Flag(1:tempBreak-1);task1retrain = task1Flag(tempBreak:end);
    else; task1retrain = []; end 
    task2Flag = find(task2Stim>0.65);
    interleaveFlag = find(task2Stim<=0.65 & task1Stim <=0.65);


    switch criteria
        case {'task1', 'task 1', 'Task1', 'Task 1'}
            flag = fn_cell2mat(daySplit(task1Flag),1);
            daySplitFlag = cellfun(@length,daySplit(task1Flag));daySplitFlag = cumsum(daySplitFlag);daySplitFlag = daySplitFlag(1:end-1);
            selBeh = beh(flag,:);
            summaryStat = makePlotTask1(selBeh,daySplitFlag,p.Results.plot); 
            varargout{1} = summaryStat;

        case {'task2', 'task 2', 'Task2', 'Task 2'}
            flag = fn_cell2mat(daySplit(task2Flag),1);
            daySplitFlag = cellfun(@length,daySplit(task2Flag));daySplitFlag = cumsum(daySplitFlag);daySplitFlag = daySplitFlag(1:end-1);
            selBeh = beh(flag,:);
            summaryStat = makePlotTask2(selBeh,daySplitFlag,p.Results.plot); 
            varargout{1} = summaryStat;

        case {'interleave', 'interleaved', 'Interleave', 'Interleaved'}
            flag = fn_cell2mat(daySplit(interleaveFlag),1);
            daySplitFlag = cellfun(@length,daySplit(interleaveFlag));daySplitFlag = cumsum(daySplitFlag);daySplitFlag = daySplitFlag(1:end-1);
            selBeh = beh(flag,:);
            [summaryStatT1, summaryStatT2] = makePlotInterleave(selBeh,daySplitFlag,p.Results.plot); 
            varargout = {summaryStatT1, summaryStatT2};
        case {'retrain'}
            if ~isempty(task1retrain)
                flag = fn_cell2mat(daySplit(task1retrain),1);
                daySplitFlag = cellfun(@length,daySplit(task1retrain));daySplitFlag = cumsum(task1retrain);daySplitFlag = daySplitFlag(1:end-1);
                selBeh = beh(flag,:);
                makePlotRetrain(selBeh,daySplitFlag,p.Results.plot); 
            end 
    end
end

function summaryStat = makePlotTask1(beh,daySplitFlag,plotFlag)
learningCurveBin = 450; 

[summaryStat.bias,summaryStat.acc,~,~,~,~,~,arL,arR] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),learningCurveBin,'task1');

[summaryStat.accPre, summaryStat.arPre, summaryStat.rtPre, summaryStat.accPost,...
    summaryStat.arPost, summaryStat.rtPost, summaryStat.biasPost] = fn_getStartEnd(beh,summaryStat.acc);
summaryStat.biasPre = max(abs(summaryStat.bias(1:1000)));
summaryStat.ar = arL/2+arR/2;

if plotFlag
    % plotting
    figure; subplot(3,1,1); hold on; 

    xlimm = [0 length(summaryStat.acc)];ylimm = [min([0.3 min(summaryStat.acc)]) 1];
    fn_plotVertLine(daySplitFlag,ylimm);ylim(ylimm)
    plot(xlimm, [0.5 0.5],'Color',[0.8 0.8 0.8]);
    plot(summaryStat.acc,'LineWidth',2,'Color',matlabColors(2));
    
    xlim(xlimm); ylabel('accruacy')
    
    
    subplot(3,1,2);  hold on; ylimm = [-1 1];
    fn_plotVertLine(daySplitFlag,ylimm);ylim(ylimm)
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8]); 
    plot(summaryStat.bias,'LineWidth',2,'Color',matlabColors(2));
    
    xlim(xlimm); ylabel('bias')
    
    subplot(3,1,3);  hold on; ylimm = [0 1];
    fn_plotVertLine(daySplitFlag,ylimm);ylim(ylimm)
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8])
    plot(arL/2+arR/2,'LineWidth',2,'Color',matlabColors(2)); 
    
    xlim(xlimm); ylabel('actionRate')
end 

end 

function summaryStat = makePlotRetrain(beh,daySplitFlag,plotFlag)
learningCurveBin = 450; 

[summaryStat.bias,summaryStat.acc,~,~,~,~,~,arL,arR] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),learningCurveBin,'task1');
summaryStat.ar = arL/2+arR/2;

if plotFlag
    % plotting
    figure; subplot(3,1,1); hold on; 

    xlimm = [0 length(summaryStat.acc)];ylimm = [min([0.3 min(summaryStat.acc)]) 1];
    fn_plotVertLine(daySplitFlag,ylimm);ylim(ylimm)
    plot(xlimm, [0.5 0.5],'Color',[0.8 0.8 0.8]);
    plot(summaryStat.acc,'LineWidth',2,'Color',matlabColors(2));
    
    xlim(xlimm); ylabel('accruacy')
    
    
    subplot(3,1,2);  hold on; ylimm = [-1 1];
    fn_plotVertLine(daySplitFlag,ylimm);ylim(ylimm)
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8]); 
    plot(summaryStat.bias,'LineWidth',2,'Color',matlabColors(2));
    
    xlim(xlimm); ylabel('bias')
    
    subplot(3,1,3);  hold on; ylimm = [0 1];
    fn_plotVertLine(daySplitFlag,ylimm);ylim(ylimm)
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8])
    plot(arL/2+arR/2,'LineWidth',2,'Color',matlabColors(2)); 
    
    xlim(xlimm); ylabel('actionRate')
end 

end 

function summaryStat = makePlotTask2(beh,daySplitFlag,plotFlag)
learningCurveBin = 450; 

[summaryStat.bias,summaryStat.acc,~,~,~,~,~,arL,arR] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),learningCurveBin,'task2');

[summaryStat.accPre, summaryStat.arPre, summaryStat.rtPre, summaryStat.accPost,...
    summaryStat.arPost, summaryStat.rtPost, summaryStat.biasPost] = fn_getStartEnd(beh,summaryStat.acc);
summaryStat.biasPre = max(abs(summaryStat.bias(1:1000)));
summaryStat.ar = arL/2+arR/2;
if plotFlag
    % plotting
    figure; subplot(3,1,1); hold on;
    
    xlimm = [0 length(summaryStat.acc)]; ylimm = [min([0.3 min(summaryStat.acc)]) 1];
    fn_plotVertLine(daySplitFlag,ylimm);
    plot(xlimm, [0.5 0.5],'Color',[0.8 0.8 0.8]);
    plot(summaryStat.acc,'LineWidth',2,'Color',matlabColors(3));
    
    xlim(xlimm); ylabel('accruacy'); ylim(ylimm)
    
    subplot(3,1,2);  hold on; ylimm = [-1 1];
    fn_plotVertLine(daySplitFlag,ylimm);
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8])
    plot(summaryStat.bias,'LineWidth',2,'Color',matlabColors(3));

    xlim(xlimm); ylabel('bias'); ylim(ylimm)
    
    subplot(3,1,3);  hold on; ylimm = [0 1];
    fn_plotVertLine(daySplitFlag,ylimm);
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8])
    plot(arL/2+arR/2,'LineWidth',2,'Color',matlabColors(3)); 
    
    xlim(xlimm); ylabel('actionRate'); ylim(ylimm)
end 


end 

function [summaryStatT1, summaryStatT2] = makePlotInterleave(beh,daySplitFlag,plotFlag)
learningCurveBin = 200; 
[bias1,acc1,~,~,~,~,~,arL1,arR1] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),learningCurveBin,'task1');
[bias2,acc2,~,~,~,~,~,arL2,arR2] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),learningCurveBin,'task2');
tempT1 = beh(:,5) <=2; 
[summaryStatT1.acc, summaryStatT1.ar, summaryStatT1.rt,summaryStatT1.bias] = fn_getStartEndInterleave(beh(tempT1,:),'task1');
tempT2 = beh(:,5) >=3; 
[summaryStatT2.acc, summaryStatT2.ar, summaryStatT2.rt,summaryStatT2.bias] = fn_getStartEndInterleave(beh(tempT2,:),'task2');

if plotFlag
    % plotting
    figure; subplot(3,1,1); hold on; 
    
    xlimm = [0 length(acc1)]; ylimm = [min([0.3 min(acc1) min(acc2)]) 1];
    fn_plotVertLine(daySplitFlag,ylimm);
    plot(xlimm, [0.5 0.5],'Color',[0.8 0.8 0.8]);
    plot(acc1,'LineWidth',2,'Color',matlabColors(2)); plot(acc2,'LineWidth',2,'Color',matlabColors(3));

    xlim(xlimm); ylabel('accruacy');ylim(ylimm)
    
    subplot(3,1,2);  hold on;  ylimm = [-1 1];
    fn_plotVertLine(daySplitFlag,ylimm);
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8])
    plot(bias1,'LineWidth',2,'Color',matlabColors(2)); plot(bias2,'LineWidth',2,'Color',matlabColors(3));
    xlim(xlimm); ylabel('bias');ylim(ylimm)
    
    subplot(3,1,3);  hold on; ylimm = [0 1];
    fn_plotVertLine(daySplitFlag,ylimm);
    plot(xlimm, [0 0],'Color',[0.8 0.8 0.8])
    plot(arL1/2+arR1/2,'LineWidth',2,'Color',matlabColors(2)); plot(arL2/2+arR2/2,'LineWidth',2,'Color',matlabColors(3)); 
    
    xlim(xlimm); ylabel('actionRate');ylim(ylimm)
end 

end 

function [accPre, arPre, rtPre,accPost, arPost, rtPost,biasPost] = fn_getStartEnd(beh,acc)

tempBin = 300; start = 1;
preLearningTrial = start:start+tempBin-1;
[accPre, arPre, rtPre] = getAcc(beh, preLearningTrial);

[~, tempEndIdx] = max(acc(end-1000+1:end-200)); 
tempEndIdx = length(acc)-1000+tempEndIdx; 
endIdx = tempEndIdx-tempBin/2:tempEndIdx+tempBin/2;
[accPost, arPost, rtPost,biasPost] = getAcc(beh, endIdx);


    function [accPre, arPre, rtPre,biasPre] = getAcc(beh, idx)
        tempBeh = beh(idx,:);
        [biasPre,accPre,~,~,~,~,arL,arR] = fn_getAccBias(tempBeh(:,5),tempBeh(:,7)==1, tempBeh(:,7)==0); 
        arPre = arL/2 + arR/2; rt = tempBeh(:,9) - tempBeh(:,8); rtPre = mean(rt(tempBeh(:,7)~=0));
        biasPre = abs(biasPre);
    end 
end 

function [acc, ar, rt,bias] = fn_getStartEndInterleave(beh,task)

[~,tempAcc,~,~,~,~,~,~,~] = fn_getAccBiasSmooth(beh(:,5),beh(:,7),30,task);
[~,tempIdx] = max(tempAcc);
preLearningTrial = max([1 tempIdx-30]):min([tempIdx+30 size(beh,1)]);
[acc, ar, rt,bias] = getAcc(beh, preLearningTrial);

    function [accPre, arPre, rtPre,biasPre] = getAcc(beh, idx)
        tempBeh = beh(idx,:);
        [biasPre,accPre,~,~,~,~,arL,arR] = fn_getAccBias(tempBeh(:,5),tempBeh(:,7)==1, tempBeh(:,7)==0); 
        arPre = arL/2 + arR/2; rtPre = tempBeh(:,9) - tempBeh(:,8); rtPre = mean(rtPre(tempBeh(:,7)~=0));
        biasPre = abs(biasPre);
    end 
end 