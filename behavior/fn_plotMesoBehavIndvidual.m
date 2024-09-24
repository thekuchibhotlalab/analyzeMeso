function [summaryStatT1,summaryStatT2,summaryStatT1_interleave,summaryStatT2_interleave] = fn_plotMesoBehavIndvidual(mouse,datapath,plotFlag)

if ~exist("plotFlag"); plotFlag = false; end 

ops.mouse = mouse;
ops.datapath = datapath;
beh = fn_loadBehav(ops);

[~,~, summaryStatT1] = fn_selBehavByTrial(beh,'task1','plot',plotFlag);
[~,~, summaryStatT2] = fn_selBehavByTrial(beh,'task2','plot',plotFlag);
fn_selBehavByTrial(beh,'retrain','plot',plotFlag);
[~,~,summaryStatT1_interleave,summaryStatT2_interleave] = fn_selBehavByTrial(beh,'interleave','plot',plotFlag);

end 


