function [data, beh, behOps]= fn_loadBehNeuroData(behOps)

% load the data
[Fnew, beh, Fops,behOps] = fn_loadData(behOps);
[data.dffStimList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps,'stim');
[data.dffChoiceList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps,'choice');


end