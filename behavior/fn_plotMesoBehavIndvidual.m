function [beh,summaryStatT1,summaryStatT2,summaryStatT1_interleave,summaryStatT2_interleave,block,blockType] = fn_plotMesoBehavIndvidual(mouse,datapath,plotFlag)

if ~exist("plotFlag"); plotFlag = false; end 

ops.mouse = mouse;
ops.datapath = datapath;
tic; 
beh = fn_loadBehav(ops);
t = toc; disp(['Loading beh done, t = ' num2str(t,'%0.3f') ' secs']);

[~,~, summaryStatT1] = fn_selBehavByTrial(beh,'task1','plot',plotFlag);

[~,~, summaryStatT2] = fn_selBehavByTrial(beh,'task2','plot',plotFlag);
%fn_selBehavByTrial(beh,'retrain','plot',plotFlag);
%summaryStatT1 = [];summaryStatT2 = [];
[~,~,summaryStatT1_interleave,summaryStatT2_interleave,block,blockType] = fn_selBehavByTrial(beh,'interleave','plot',plotFlag);

end 


