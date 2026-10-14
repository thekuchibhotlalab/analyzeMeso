function qc = fn_trackedNeuronQC(sessionInfo,neuralSelection)
%FN_TRACKEDNEURONQC Descriptive neuron-availability QC across selected sessions.
% QC ONLY: no neuron filtering is applied.

if ~ismember('ishere',sessionInfo.Properties.VariableNames)
    warning('sessionInfo.ishere missing; tracked-neuron QC skipped.');
    qc=struct(); return;
end

sessionRows=[];
for k=1:numel(neuralSelection)
    sessionRows=[sessionRows; neuralSelection(k).sessionRowsUsed(:)]; %#ok<AGROW>
end
sessionRows=unique(sessionRows,'stable');

if isempty(sessionRows)
    qc=struct(); return;
end

nNeuron=[];
for i=1:numel(sessionRows)
    v=fn_getIshere(sessionInfo,sessionRows(i));
    if ~isempty(v), nNeuron=numel(v); break; end
end
if isempty(nNeuron), qc=struct(); return; end

M=nan(numel(sessionRows),nNeuron);
Date=nan(numel(sessionRows),1);
SessionName=strings(numel(sessionRows),1);
SessionRec=nan(numel(sessionRows),1);
NPresent=zeros(numel(sessionRows),1);
NZero=zeros(numel(sessionRows),1);
NNaN=zeros(numel(sessionRows),1);

for i=1:numel(sessionRows)
    s=sessionRows(i);
    v=double(fn_getIshere(sessionInfo,s));
    v=v(:)';

    if numel(v)~=nNeuron
        error('ishere length differs across selected sessions.');
    end

    M(i,:)=v;
    Date(i)=fn_getNum(sessionInfo,'date',s,NaN);
    SessionName(i)=fn_getText(sessionInfo,'sessionName',s,"");
    SessionRec(i)=fn_getNum(sessionInfo,'sessionRec',s,NaN);
    NPresent(i)=sum(v==1);
    NZero(i)=sum(v==0);
    NNaN(i)=sum(isnan(v));
end

present=M==1;
presentAllMask=all(present,1);
presentFraction=mean(present,1);
present80Mask=presentFraction>=0.80;

qc=struct();
qc.selectedSessionRows=sessionRows;
qc.totalGlobalNeurons=nNeuron;
qc.sessionPresenceMatrix=present;
qc.presentFraction=presentFraction;
qc.presentAllMask=presentAllMask;
qc.nPresentAllSessions=sum(presentAllMask);
qc.presentAtLeast80PctMask=present80Mask;
qc.nPresentAtLeast80Pct=sum(present80Mask);

qc.sessionTable=table(sessionRows,Date,SessionName,SessionRec, ...
    NPresent,NZero,NNaN, ...
    'VariableNames',{'SessionInfoRow','Date','SessionName','SessionRec', ...
    'NPresent','NZero','NNaN'});
end

function v=fn_getIshere(T,row)
x=T.ishere; if iscell(x), v=x{row}; else, v=x(row,:); end
end

function x=fn_getNum(T,name,row,defaultVal)
if ~ismember(name,T.Properties.VariableNames), x=defaultVal; return; end
v=T.(name); if iscell(v), v=v{row}; else, v=v(row); end
x=double(v);
end

function x=fn_getText(T,name,row,defaultVal)
if ~ismember(name,T.Properties.VariableNames), x=string(defaultVal); return; end
v=T.(name); if iscell(v), v=v{row}; else, v=v(row); end
x=string(v);
end
