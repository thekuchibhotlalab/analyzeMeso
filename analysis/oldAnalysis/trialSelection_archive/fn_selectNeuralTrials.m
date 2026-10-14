function trialTypeInfo = fn_selectNeuralTrials(files, varargin)
%FN_SELECTNEURALTRIALS Select saved trialInfo without loading neural data.
% trialTypeInfo = fn_selectNeuralTrials(files,...)
% Output: nLearningPeriod x nTrialType x nAnimal cell array of tables.
% Axis order follows LearningPeriods, TrialTypes rows, and files, respectively.
% Empty combinations contain zero-row tables. Every matching row is retained;
% overlapping trial types are evaluated independently in their own cells.
%
% Only load(file,'trialInfo') is used. Original columns (including ishere if
% saved in trialInfo) are preserved. No sessionInfo or neural arrays are read.
% Adds animal, animalIndex, sourceFile, sourceTrialRow, and trialType.
%
% Options:
% AnimalLabels    One unique label per file (default filename stems).
% RT              Inclusive range in seconds ([0 Inf]); excludes nonfinite RT.
% LearningPeriods Ordered dayLabel values ([] discovers their stable union).
% TrialTypes      Table with label, stimulus, action; each row is one type.
%                 Alternatively label plus predicate cells, @(trialInfo) mask.
%                 Empty means a single type named "all".
%
% Load corresponding signals separately:
% activity = fn_loadSelectedNeuralActivity(trialTypeInfo,files,...);
% size(activity{s,t,a},3) == height(trialTypeInfo{s,t,a}).

p = inputParser;
addParameter(p,'AnimalLabels',[]);
addParameter(p,'RT',[0 Inf]);
addParameter(p,'LearningPeriods',[]);
addParameter(p,'TrialTypes',table(),@istable);
parse(p,varargin{:}); o = p.Results;
files = string(files); files = files(:);
assert(~isempty(files)&&~any(ismissing(files)|files==""), ...
    'selectNeuralTrials:Files','Provide one MAT filename per animal.');
validateattributes(o.RT,{'numeric'},{'vector','numel',2,'nonnegative','nonnan'});
assert(o.RT(2)>=o.RT(1),'selectNeuralTrials:RT','RT must be nondecreasing.');
nAnimal = numel(files); labels = strings(nAnimal,1);
for a = 1:nAnimal
    [ok,info] = fileattrib(char(files(a)));
    assert(ok,'selectNeuralTrials:File','Cannot access %s.',files(a));
    files(a) = string(info.Name);
    [~,stem] = fileparts(files(a)); labels(a) = erase(string(stem),'_parsedTrial');
end
if ~isempty(o.AnimalLabels)
    labels = string(o.AnimalLabels); labels = labels(:);
end
assert(numel(labels)==nAnimal&&numel(unique(labels))==nAnimal ...
    &&~any(ismissing(labels)|labels==""),'selectNeuralTrials:Labels', ...
    'Provide one unique nonempty AnimalLabels entry per file.');
types = o.TrialTypes;
if isempty(types)
    types = table("all",{@(b)true(height(b),1)},'VariableNames',{'label','predicate'});
end
assert(ismember('label',types.Properties.VariableNames), ...
    'selectNeuralTrials:Types','TrialTypes needs a label column.');
types.label = string(types.label);
assert(numel(unique(types.label))==height(types)&&~any(ismissing(types.label)|types.label==""), ...
    'selectNeuralTrials:Types','Trial type labels must be unique and nonempty.');
custom = ismember('predicate',types.Properties.VariableNames);
assert(custom||all(ismember({'stimulus','action'},types.Properties.VariableNames)), ...
    'selectNeuralTrials:Types','TrialTypes needs stimulus/action or predicate columns.');
data = cell(nAnimal,1); discovered = strings(0,1);
for a = 1:nAnimal
    d = load(char(files(a)),'trialInfo');
    assert(isfield(d,'trialInfo')&&istable(d.trialInfo), ...
        'selectNeuralTrials:Table','%s must contain a trialInfo table.',files(a));
    b = d.trialInfo;
    assert(all(ismember({'RT','dayLabel','trialInSession'},b.Properties.VariableNames)), ...
        'selectNeuralTrials:Columns','trialInfo needs RT, dayLabel and trialInSession.');
    reserved = {'animal','animalIndex','sourceFile','sourceTrialRow','trialType'};
    assert(~any(ismember(reserved,b.Properties.VariableNames)), ...
        'selectNeuralTrials:Columns','Saved trialInfo contains reserved selector columns.');
    b.animal = repmat(labels(a),height(b),1);
    b.animalIndex = repmat(a,height(b),1);
    b.sourceFile = repmat(files(a),height(b),1);
    b.sourceTrialRow = (1:height(b))';
    data{a} = b;
    discovered = unique([discovered;string(b.dayLabel)],'stable');
end
stages = string(o.LearningPeriods); stages = stages(:);
if isempty(stages), stages = discovered; end
assert(numel(unique(stages))==numel(stages),'selectNeuralTrials:Stages', ...
    'LearningPeriods must not contain duplicate labels.');
trialTypeInfo = cell(numel(stages),height(types),nAnimal);
for a = 1:nAnimal
    b = data{a}; rt = isfinite(b.RT)&b.RT>=o.RT(1)&b.RT<=o.RT(2);
    if ~custom
        if ismember('stimuli',b.Properties.VariableNames), stimulus = b.stimuli;
        else
            assert(ismember('stimulus',b.Properties.VariableNames), ...
                'selectNeuralTrials:Columns','trialInfo needs stimuli or stimulus.');
            stimulus = b.stimulus;
        end
        assert(ismember('action',b.Properties.VariableNames), ...
            'selectNeuralTrials:Columns','trialInfo needs action.');
    end
    for t = 1:height(types)
        if custom
            mask = types.predicate{t}(b);
            assert(islogical(mask)&&numel(mask)==height(b)&& ...
                (isvector(mask)||isempty(mask)), ...
                'selectNeuralTrials:Predicate','Predicate must return one logical per trial.');
            mask = mask(:);
        else
            mask = stimulus==types.stimulus(t)&b.action==types.action(t);
        end
        for s = 1:numel(stages)
            stageMask = string(b.dayLabel)==stages(s);
            if ismissing(stages(s)), stageMask = ismissing(string(b.dayLabel)); end
            part = b(rt&mask&stageMask,:);
            part.trialType = repmat(types.label(t),height(part),1);
            % Labels remain discoverable even in an empty table.
            part.Properties.Description = char(labels(a)+" / "+stages(s)+" / "+types.label(t));
            trialTypeInfo{s,t,a} = part;
        end
    end
end
end

