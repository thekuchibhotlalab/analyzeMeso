function audit = fn_makeSessionAuditTable(neuralSelection)
%FN_MAKESESSIONAUDITTABLE Show exactly which sessions contribute to each condition.

rows={};

for k=1:numel(neuralSelection)
    T=neuralSelection(k).trialInfoNeural;
    if isempty(T), continue; end

    key=[double(T.sessionRec),double(T.sessionInfoRow)];
    [u,~,grp]=unique(key,'rows','stable');

    for g=1:size(u,1)
        Tg=T(grp==g,:);

        Condition=string(neuralSelection(k).name);
        Date=fn_firstNum(Tg,'date',NaN);
        SessionName=fn_firstText(Tg,'sessionName',"");
        SessionRec=fn_firstNum(Tg,'sessionRec',NaN);
        SessionInfoRow=fn_firstNum(Tg,'sessionInfoRow',NaN);
        TaskLabel=fn_firstText(Tg,'taskLabel',"");
        DayLabel=fn_firstText(Tg,'dayLabel',"");
        NNeuralTrials=height(Tg);

        rt=Tg.RT(isfinite(Tg.RT));
        if isempty(rt), MedianRT=NaN; else, MedianRT=median(rt); end

        rows(end+1,:)={Condition,Date,SessionName,SessionRec, ...
            SessionInfoRow,TaskLabel,DayLabel,NNeuralTrials,MedianRT}; %#ok<AGROW>
    end
end

if isempty(rows)
    audit=table();
else
    audit=cell2table(rows,'VariableNames',{ ...
        'Condition','Date','SessionName','SessionRec','SessionInfoRow', ...
        'TaskLabel','DayLabel','NNeuralTrials','MedianRT'});
end
end

function x=fn_firstNum(T,name,defaultVal)
if ~ismember(name,T.Properties.VariableNames), x=defaultVal; return; end
v=T.(name); if iscell(v), v=v{1}; else, v=v(1); end
x=double(v);
end

function x=fn_firstText(T,name,defaultVal)
if ~ismember(name,T.Properties.VariableNames), x=string(defaultVal); return; end
v=T.(name); if iscell(v), v=v{1}; else, v=v(1); end
x=string(v);
end
