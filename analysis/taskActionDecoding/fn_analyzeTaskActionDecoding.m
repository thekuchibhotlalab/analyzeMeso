function [result,figures]=fn_analyzeTaskActionDecoding(activity,conditions,cfg,plotCfg)
%FN_ANALYZETASKACTIONDECODING Per-animal LDA cells and linear-SVM populations.
% activity: condition x animal cells, each neuron x time x REAL trials.
% conditions: conditionName/action/task. Input is choice-aligned dffChoice.
% Each trial is reduced to ONE mean response per neuron in the chosen frames.
% Neuron row identities must match across conditions within each animal.
[defaults,plots]=fn_taskActionDecodingConfig();
if nargin<3||isempty(cfg), cfg=struct(); end
if nargin<4||isempty(plotCfg), plotCfg=struct(); end
cfg=fill(cfg,defaults); plotCfg=fill(plotCfg,plots);
validateattributes(cfg.balanceTaskActions,{'logical'},{'scalar'});
validateattributes(cfg.trainFraction,{'numeric'},{'scalar','>',0,'<',1,'finite'});
folds=round(1/(1-cfg.trainFraction));
assert(folds>=2&&abs(cfg.trainFraction-(1-1/folds))<1e-10,'taskActionDecoding:Fraction', ...
    'trainFraction must be 1-1/K, e.g. .8 for five folds.');
validateattributes(cfg.seed,{'numeric'},{'scalar','integer','nonnegative','finite'});
assert(exist('fn_runDecoder','file')==2,'taskActionDecoding:Dependency', ...
    'Add ziyiFunction/analysis to your MATLAB path.');
assert(iscell(activity)&&ismatrix(activity)&&~isempty(activity),'taskActionDecoding:Input', ...
    'Use a condition x animal activity cell.');
[nc,na]=size(activity);
assert(istable(conditions)&&height(conditions)==nc&& ...
    all(ismember({'conditionName','action','task'},conditions.Properties.VariableNames)), ...
    'taskActionDecoding:Conditions','Supply matching conditionName, action, task columns.');
for key=["conditionName","action","task"]
    values=string(conditions.(key));
    assert(iscolumn(values)&&all(~ismissing(values)&strlength(values)>0), ...
        'taskActionDecoding:Labels','Condition labels must be nonempty scalar values.');
    conditions.(key)=values;
end
assert(numel(unique(conditions.conditionName))==nc,'taskActionDecoding:Labels','Condition names must be unique.');
tasks=string(cfg.taskLabels(:)); actions=string(cfg.actionLabels(:));
assert(numel(tasks)==2&&numel(unique(tasks))==2&&numel(actions)==2&&numel(unique(actions))==2, ...
    'taskActionDecoding:Labels','Specify two task and two action labels.');
assert(all(ismember(conditions.task,tasks))&&all(ismember(conditions.action,actions)), ...
    'taskActionDecoding:Labels','All condition rows must match the configured task/action labels.');
labels=string(cfg.animalLabels(:)); if isempty(labels), labels="animal"+string((1:na)'); end
assert(numel(labels)==na&&numel(unique(labels))==na&&all(~ismissing(labels)&strlength(labels)>0), ...
    'taskActionDecoding:Labels','Supply one unique animal label per input column.');
assert(iscell(cfg.taskWindows)&&~isempty(cfg.taskWindows)&&numel(cfg.taskWindows)==numel(cfg.taskWindowNames), ...
    'taskActionDecoding:Windows','Match taskWindows and taskWindowNames.');
allWindows=[{cfg.choiceFrames},reshape(cfg.taskWindows,1,[])];
for win=allWindows
    validateattributes(win{1},{'numeric'},{'vector','nonempty','positive','integer','finite'});
    assert(numel(unique(win{1}))==numel(win{1}),'taskActionDecoding:Windows','Frame lists must be unique.');
end
comparisons=struct('name',{},'kind',{},'frames',{},'class1Rows',{},'class2Rows',{},'positiveClass',{},'negativeClass',{});
for k=1:2
    comparisons(k)=struct('name',"choice_"+tasks(k),'kind',"choice",'frames',cfg.choiceFrames, ...
        'class1Rows',find(conditions.task==tasks(k)&conditions.action==actions(1)), ...
        'class2Rows',find(conditions.task==tasks(k)&conditions.action==actions(2)), ...
        'positiveClass',actions(1),'negativeClass',actions(2));
end
for k=1:numel(cfg.taskWindows)
    comparisons(end+1)=struct('name',"task_"+string(cfg.taskWindowNames(k)),'kind',"task", ...
        'frames',cfg.taskWindows{k},'class1Rows',find(conditions.task==tasks(1)), ...
        'class2Rows',find(conditions.task==tasks(2)),'positiveClass',tasks(1),'negativeClass',tasks(2)); %#ok<AGROW>
end
K=numel(comparisons); fits=cell(K,na); neuronTables={}; populationTables={};
auditAnimal=zeros(K*na,1); auditComparison=strings(K*na,1); n1=zeros(K*na,1); n2=n1;
included=false(K*na,1); reason=strings(K*na,1); nKept=n1; index=0;
for a=1:na
    present=find(~cellfun(@isempty,activity(:,a)));
    if ~isempty(present)
        nn=size(activity{present(1),a},1); nt=size(activity{present(1),a},2);
        for c=reshape(present,1,[])
            X=activity{c,a}; validateattributes(X,{'numeric'},{'real','nonempty'});
            assert(ndims(X)<=3&&size(X,1)==nn&&size(X,2)==nt,'taskActionDecoding:Shape', ...
                'Animal %s: neuron identities/row counts and time frames must match across conditions.',labels(a));
        end
    end
    for k=1:K
        index=index+1; cmp=comparisons(k); auditAnimal(index)=a; auditComparison(index)=cmp.name;
        if isempty(present), reason(index)="no activity"; continue; end
        assert(max(cmp.frames)<=nt,'taskActionDecoding:Frames','Requested frame exceeds input time length.');
        [A,source1]=reduce(activity(:,a),cmp.class1Rows,cmp.frames,nn);
        [B,source2]=reduce(activity(:,a),cmp.class2Rows,cmp.frames,nn);
        trialBalance=table();
        if cmp.kind=="task"&&cfg.balanceTaskActions
            % Reset private streams across windows so every window uses the same
            % trial subset. Selection depends on labels/counts, never responses.
            [A,source1,count1]=balanceActions(A,source1,conditions,actions, ...
                mod(cfg.seed+1000*(a-1),2^32),tasks(1));
            [B,source2,count2]=balanceActions(B,source2,conditions,actions, ...
                mod(cfg.seed+1000*(a-1)+1,2^32),tasks(2));
            trialBalance=[count1;count2];
        end
        n1(index)=size(A,1); n2(index)=size(B,1);
        if min(n1(index),n2(index))<folds
            reason(index)="too few trials in one class"; continue;
        end
        keep=all(isfinite(A),1)&all(isfinite(B),1); rows=find(keep)'; nKept(index)=sum(keep);
        if ~any(keep), reason(index)="no finite matched neurons"; continue; end
        if cfg.verbose, fprintf('Decoding %s, %s: %d / %d trials, %d neurons.\n',labels(a),cmp.name,size(A,1),size(B,1),sum(keep)); end
        d=fn_runDecoder(A(:,keep),B(:,keep),cfg.trainFraction,'Repeats',cfg.repeats, ...
            'InnerFolds',cfg.innerFolds,'TopFractions',cfg.topFractions, ...
            'BoxConstraint',cfg.svmBoxConstraint,'Ridge',cfg.ldaRidge, ...
            'Seed',mod(cfg.seed+1000*(a-1)+k-1,2^32),'Shuffle',cfg.shuffle);
        assert(isfield(d,'population')&&isfield(d,'cv'),'taskActionDecoding:Dependency', ...
            'MATLAB is using an old fn_runDecoder. Run which fn_runDecoder -all.');
        fits{k,a}=struct('decoder',d,'neuronRows',rows,'sourceClass1',source1, ...
            'sourceClass2',source2,'animalIndex',a,'animalLabel',labels(a),'comparison',cmp, ...
            'trialBalance',trialBalance);
        N=numel(rows);
        neuronTables{end+1}=table(repmat(a,N,1),repmat(labels(a),N,1),rows, ...
            repmat(cmp.name,N,1),d.cellAcc(:,2),d.cellAccSEM(:,2),d.cellW,d.cellThreshold,d.popW, ...
            'VariableNames',{'animalIndex','animalLabel','rowInAnimal','comparison','accuracy','sem','ldaWeight','ldaThreshold','svmAllWeight'}); %#ok<AGROW>
        Q=numel(d.population.fractions);
        populationTables{end+1}=table(repmat(a,Q,1),repmat(labels(a),Q,1),repmat(cmp.name,Q,1), ...
            d.population.fractions(:),d.population.nNeurons(:),d.population.accuracy(:,2),d.population.sem(:,2), ...
            'VariableNames',{'animalIndex','animalLabel','comparison','fraction','nNeurons','accuracy','sem'}); %#ok<AGROW>
        included(index)=true;
    end
end
assert(any(included),'taskActionDecoding:Empty','No comparison/animal has sufficient usable trials and neurons.');
result=struct('cfg',cfg,'conditions',conditions,'comparisons',comparisons,'fits',{fits}, ...
    'animalLabels',labels,'neurons',vertcat(neuronTables{:}),'population',vertcat(populationTables{:}));
result.audit=table(auditAnimal,auditComparison,n1,n2,nKept,included,reason, ...
    'VariableNames',{'animalIndex','comparison','nClass1','nClass2','nNeurons','included','reason'});
left=result.neurons(result.neurons.comparison==comparisons(1).name,{'animalIndex','animalLabel','rowInAnimal','accuracy'});
right=result.neurons(result.neurons.comparison==comparisons(2).name,{'animalIndex','rowInAnimal','accuracy'});
left.Properties.VariableNames{4}='accuracyT1'; right.Properties.VariableNames{3}='accuracyT2';
result.choicePairs=innerjoin(left,right,'Keys',{'animalIndex','rowInAnimal'});
result.estimation='Per-animal real-trial CV; no cross-animal population. Pooled cell plots are descriptive, not independent animal inference.';
[figures,result.plotFiles]=fn_plotTaskActionDecoding(result,plotCfg);
end
function [X,source,counts]=balanceActions(X,source,conditions,actions,seed,task)
trialActions=conditions.action(source.conditionRow);
available=arrayfun(@(j)sum(trialActions==actions(j)),(1:2)');
n=min(available); selected=zeros(2*n,1);
stream=RandStream('mt19937ar','Seed',seed);
for j=1:2
    ids=find(trialActions==actions(j));
    selected((j-1)*n+(1:n))=ids(randperm(stream,numel(ids),n));
end
selected=sort(selected); % Preserve original condition/trial order for provenance.
X=X(selected,:); source=source(selected,:);
counts=table(repmat(task,2,1),actions,available,repmat(n,2,1), ...
    'VariableNames',{'task','action','nAvailable','nSelected'});
end
function [X,source]=reduce(activity,conditions,frames,nn)
X=zeros(0,nn); c=[]; trial=[];
for row=reshape(conditions,1,[])
    A=activity{row}; if isempty(A), continue; end
    N=size(A,3); X=[X;reshape(mean(A(:,frames,:),2),nn,N)']; %#ok<AGROW>
    c=[c;repmat(row,N,1)]; trial=[trial;(1:N)']; %#ok<AGROW>
end
source=table(c,trial,'VariableNames',{'conditionRow','trialInCondition'});
end
function x=fill(x,d)
assert(isstruct(x)&&isscalar(x),'taskActionDecoding:Config','Use scalar configurations.');
extra=setdiff(fieldnames(x),fieldnames(d));
assert(isempty(extra),'taskActionDecoding:Config','Unknown options: %s.',strjoin(extra,', '));
for key=fieldnames(d)', if ~isfield(x,key{1}), x.(key{1})=d.(key{1}); end; end
end
