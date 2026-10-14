function [A,B,transform,W,noise,split]=fn_taskActionPopulationMeans(data,opts,stream,withNoise)
%FN_TASKACTIONPOPULATIONMEANS Concatenate neuron means, never unrelated trials.
% stream=[] fits all trials. Otherwise split independently within each animal.
if nargin<3, stream=[]; end
if nargin<4, withNoise=false; end
if isfield(data,'animalData'), pop=data.animalData; else, pop={data}; end
As=cell(size(pop)); Bs=As; transforms=As; Ws=As; noises=As; splits=As;
for a=1:numel(pop)
    d=pop{a}; train=true(numel(d.group),1); test=[];
    if ~isempty(stream), [train,test]=fn_taskActionSplit(d,opts,stream); end
    [As{a},transforms{a},Y]=fn_taskActionMeans(d.X(:,:,train),d.group(train),opts.normalization);
    if ~isempty(stream)
        Bs{a}=fn_taskActionMeans(d.X(:,:,test),d.group(test),opts.normalization,transforms{a});
        splits{a}=struct('trainRows',find(train),'testRows',find(test), ...
            'trainSessionRec',unique(d.trials.sessionRec(train)), ...
            'testSessionRec',unique(d.trials.sessionRec(test)));
        if isfield(d,'animalLabel'), splits{a}.animalLabel=d.animalLabel; end
    end
    if withNoise, [Ws{a},noises{a}]=fn_taskActionNoiseMetric(Y,d.group(train),As{a},opts); end
end
A=cat(1,As{:}); B=cat(1,Bs{:}); W=[];
if withNoise, W=blkdiag(Ws{:}); end % Cross-animal noise covariance is unobserved.
transform=transforms; noise=noises; split=struct('animals',{splits});
if ~isfield(data,'animalData')
    transform=transforms{1}; noise=noises{1}; split=splits{1};
end
end
