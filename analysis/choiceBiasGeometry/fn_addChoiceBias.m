function [T,info]=fn_addChoiceBias(T,window)
%FN_ADDCHOICEBIAS Task-specific accuracy bias BEFORE any neural/trial filtering.
% Matches fn_getAccBiasSmooth's centered indexing and accuracy definition.
% Windows contain WINDOW trials of the same task within the same session.
if nargin<2, window=40; end
validateattributes(window,{'numeric'},{'scalar','integer','>=',4,'even'});
assert(istable(T)&&all(ismember({'stimuli','responseType','trialInSession'},T.Properties.VariableNames)), ...
    'choiceBias:Metadata','Need stimuli, responseType and trialInSession.');
n=height(T); task=zeros(n,1); task(ismember(T.stimuli,[1 2]))=1; task(ismember(T.stimuli,[3 4]))=2;
if all(ismember({'date','sessionName'},T.Properties.VariableNames))
    key=string(T.date)+"/"+string(T.sessionName);
elseif ismember('sessionRec',T.Properties.VariableNames)
    key=string(T.sessionRec);
    assert(all(isfinite(T.sessionRec)),'choiceBias:Session','Missing sessionRec: provide date and sessionName.');
else
    error('choiceBias:Session','Need date/sessionName or finite sessionRec.');
end
session=findgroups(key);
T.choiceBias=nan(n,1); T.choiceBiasT1=nan(n,1); T.choiceBiasT2=nan(n,1);
T.choiceBiasAccL=nan(n,1); T.choiceBiasAccR=nan(n,1);
T.choiceBiasTask=task; T.choiceBiasBlock=nan(n,1); T.choiceBiasBlockValue=nan(n,1);
T.choiceBiasBlockN=zeros(n,1); block=0;
for s=unique(session)'
    for k=1:2
        rows=find(session==s&task==k); [~,order]=sort(T.trialInSession(rows)); rows=rows(order);
        assert(numel(unique(T.trialInSession(rows)))==numel(rows),'choiceBias:Order','Duplicate trialInSession within session/task.');
        for j=window:numel(rows)
            ids=rows(j-window+1:j); center=rows(j-window/2);
            [b,l,r]=biasValue(T,ids,window);
            T.choiceBias(center)=b; T.choiceBiasAccL(center)=l; T.choiceBiasAccR(center)=r;
            T.(sprintf('choiceBiasT%d',k))(center)=b;
        end
        for first=1:window:numel(rows)
            ids=rows(first:min(first+window-1,numel(rows))); block=block+1;
            T.choiceBiasBlock(ids)=block; T.choiceBiasBlockN(ids)=numel(ids);
            if numel(ids)==window, T.choiceBiasBlockValue(ids)=biasValue(T,ids,window); end
        end
    end
end
info=struct('window',window,'sign','accuracyLeft - accuracyRight', ...
    'scope','Centered windows of same-task trials within session; before selection', ...
    'edges','First window/2-1 and last window/2 task trials remain NaN', ...
    'responseConvention','responseType==1 correct; 0/NaN missed; other types incorrect', ...
    'blocks','Nonoverlapping full windows for correlation; incomplete blocks have NaN bias');
end
function [b,l,r]=biasValue(T,ids,w)
s=T.stimuli(ids); y=T.responseType(ids); left=ismember(s,[1 3]); right=ismember(s,[2 4]);
valid=y~=0&~isnan(y); l=NaN; r=NaN; b=NaN;
% Match helper's strict minimum stimulus counts (> ceil(window/10)).
if sum(left)<=ceil(w/10)||sum(right)<=ceil(w/10)||~any(left&valid)||~any(right&valid), return; end
l=sum(y==1&left)/sum(valid&left); r=sum(y==1&right)/sum(valid&right); b=l-r;
end
