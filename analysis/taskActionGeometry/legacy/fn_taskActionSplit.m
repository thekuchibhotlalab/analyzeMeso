function [train,test]=fn_taskActionSplit(data,opts,stream)
%FN_TASKACTIONSPLIT Split whole trials/sessions, never individual time samples.
group=data.group; n=numel(group); train=false(n,1);
if strcmp(opts.splitUnit,'trial')
    for g=1:4
        rows=find(group==g); rows=rows(randperm(stream,numel(rows)));
        train(rows(1:floor(numel(rows)/2)))=true;
    end
else
    sessions=unique(data.trials.sessionRec);
    for attempt=1:1000
        order=randperm(stream,numel(sessions));
        train=ismember(data.trials.sessionRec,sessions(order(1:floor(numel(sessions)/2))));
        if all(accumarray(group(train),1,[4 1])>=opts.minTrialsPerHalf)&& ...
                all(accumarray(group(~train),1,[4 1])>=opts.minTrialsPerHalf), break; end
    end
end
test=~train;
assert(all(accumarray(group(train),1,[4 1])>=opts.minTrialsPerHalf)&& ...
    all(accumarray(group(test),1,[4 1])>=opts.minTrialsPerHalf), ...
    'taskGeometry:Split','Cannot split sessions with all four cells in both halves. Use more sessions, or explicitly set splitUnit=''trial''.');
end
