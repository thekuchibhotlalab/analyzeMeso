function data = fn_loadBehNeuroData(ops)

% load the data
[Fnew, beh, Fops,behOps] = fn_loadData(ops.mouse, ops.Fpath,ops.behavPath,ops.behavDates);
[data.dffStimList, data.dffChoiceList, data.selectedBehList] = fn_parseTrial(Fnew, beh, Fops, behOps);

end