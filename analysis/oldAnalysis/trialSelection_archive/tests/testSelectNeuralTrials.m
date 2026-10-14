function tests = testSelectNeuralTrials
tests = functiontests(localfunctions);
end

function setupOnce(t)
t.TestData.oldPath = path; addpath(fileparts(fileparts(mfilename('fullpath'))));
t.TestData.files = strings(2,1); t.TestData.sessions = cell(2,1);
t.TestData.trials = cell(2,1);
for a = 1:2
    [sessionInfo,trialInfo] = fixture(a);
    file = string(tempname)+".mat"; save(file,'sessionInfo','trialInfo');
    t.TestData.files(a) = file; t.TestData.sessions{a} = sessionInfo;
    t.TestData.trials{a} = trialInfo;
end
t.TestData.types = table(["one";"two"],[1;1],[1;2], ...
    'VariableNames',{'label','stimulus','action'});
end

function teardownOnce(t)
for file = t.TestData.files', delete(file); end
path(t.TestData.oldPath);
end

function testCellAxesAllMatchesAndEmptyGroups(t)
out = select(t);
verifySize(t,out,[3 2 2]);
for a = 1:2
    original = t.TestData.trials{a};
    for s = 1:3
        stages = ["T1L","T1E","absent"];
        for k = 1:2
            keep = string(original.dayLabel)==stages(s)&original.action==k ...
                &original.RT>=.35&original.RT<=.65;
            b = out{s,k,a};
            verifyEqual(t,b.sourceTrialRow,find(keep));
            values = b(:,original.Properties.VariableNames);
            values.Properties.Description = original.Properties.Description;
            verifyEqual(t,values,original(keep,:));
            verifyTrue(t,all(b.animalIndex==a));
        end
    end
end
end

function testSelectorNeedsOnlyTrialInfo(t)
file = [tempname '.mat']; cleanup = onCleanup(@()delete(file)); %#ok<NASGU>
trialInfo = t.TestData.trials{1}; save(file,'trialInfo');
out = fn_selectNeuralTrials(file,'LearningPeriods',["T1E","T1L"]);
verifyEqual(t,cellfun(@height,out),[24;12]);
verifyFalse(t,ismember('ishere',out{1}.Properties.VariableNames));
end

function testCharacterVectorLabelAndLearningPeriod(t)
out = fn_selectNeuralTrials(t.TestData.files(1), ...
    'AnimalLabels','zz172','LearningPeriods','T1E');
expected = fn_selectNeuralTrials(t.TestData.files(1), ...
    'AnimalLabels',"zz172",'LearningPeriods',"T1E");
verifyEqual(t,out,expected);
verifySize(t,out,[1 1]);
verifyEqual(t,height(out{1}),24);
verifyEqual(t,out{1}.animal,repmat("zz172",24,1));
end

function testCellArrayLabelsAndPeriods(t)
out = fn_selectNeuralTrials(t.TestData.files, ...
    'AnimalLabels',{'A','B'},'LearningPeriods',{'T1E','T1L'});
verifySize(t,out,[2 1 2]);
verifyEqual(t,out{1,1,1}.animal,repmat("A",24,1));
verifyEqual(t,out{2,1,2}.animal,repmat("B",12,1));
verifyError(t,@()fn_selectNeuralTrials(t.TestData.files,'AnimalLabels',{'A','A'}), ...
    'selectNeuralTrials:Labels');
end

function testActivityAndRawPresenceCorrespondExactly(t)
out = select(t);
[x,h] = fn_loadSelectedNeuralActivity(out,t.TestData.files,'FrameIndices',[3 1]);
verifySize(t,x,size(out)); verifySize(t,h,size(out));
for a = 1:2
    si = t.TestData.sessions{a};
    for s = 1:3
        for k = 1:2
            b = out{s,k,a}; z = x{s,k,a};
            verifyEqual(t,size(z,3),height(b));
            for r = 1:height(b)
                row = find(si.date==b.date(r)&string(si.sessionName)==string(b.sessionName(r)));
                verifyEqual(t,h{s,k,a}{r},si.ishere{row});
                if isempty(si.dffStim{row})
                    verifyTrue(t,all(isnan(z(:,:,r)),'all'));
                else
                    verifyEqual(t,z(:,:,r),si.dffStim{row}(:,[3 1],b.trialInSession(r)));
                end
            end
        end
    end
end
end

function testReorderedRowsAndSessionRecLookup(t)
out = select(t); out{1,1,1} = flipud(out{1,1,1});
for c = 1:numel(out), out{c}(:,{'date','sessionName'}) = []; end
x = fn_loadSelectedNeuralActivity(out,t.TestData.files);
b = out{1,1,1}; si = t.TestData.sessions{1};
for k = 1:height(b)
    row = find(si.sessionRec==b.sessionRec(k));
    verifyEqual(t,x{1,1,1}(:,:,k),si.dffStim{row}(:,:,b.trialInSession(k)));
end
end

function testOverlappingTypesAreSeparateGroups(t)
types = t.TestData.types; types.action(:) = 1;
out = select(t,'TrialTypes',types);
for a = 1:2
    for s = 1:3
        verifyEqual(t,out{s,1,a}.sourceTrialRow,out{s,2,a}.sourceTrialRow);
    end
end
end

function testMissingActivityAndStaleMappingErrors(t)
out = select(t);
verifyError(t,@()fn_loadSelectedNeuralActivity(out,t.TestData.files, ...
    'MissingActivity','error'),'loadSelectedNeuralActivity:MissingActivity');
b = out; b{1,1,1}.RT(1) = 99;
verifyError(t,@()fn_loadSelectedNeuralActivity(b,t.TestData.files), ...
    'loadSelectedNeuralActivity:StaleTrials');
verifyError(t,@()fn_loadSelectedNeuralActivity(out,flipud(t.TestData.files)), ...
    'loadSelectedNeuralActivity:Source');
b = out; b{1,1,1}.trialInSession(1) = 999;
verifyError(t,@()fn_loadSelectedNeuralActivity(b,t.TestData.files), ...
    'loadSelectedNeuralActivity:TrialIndex');
end

function testPredicateAndOriginalPresenceColumn(t)
file = [tempname '.mat']; cleanup = onCleanup(@()delete(file)); %#ok<NASGU>
trialInfo = t.TestData.trials{1}; trialInfo.ishere = repmat({[0 NaN 1]},height(trialInfo),1);
save(file,'trialInfo');
types = table("chosen",{@(b)b.action==2},'VariableNames',{'label','predicate'});
out = fn_selectNeuralTrials(file,'TrialTypes',types,'LearningPeriods',"T1L");
verifyEqual(t,height(out{1}),6);
verifyEqual(t,out{1}.ishere,repmat({[0 NaN 1]},6,1));
end

function testSingleAnimalWithMultiplePeriodsAndTypes(t)
out = fn_selectNeuralTrials(t.TestData.files(1), ...
    'LearningPeriods',["T1E","T1L"],'TrialTypes',t.TestData.types);
verifySize(t,out,[2 2]); % MATLAB omits trailing singleton dimensions.
verifyEqual(t,size(out,3),1);
x = fn_loadSelectedNeuralActivity(out,t.TestData.files(1));
verifySize(t,x,[2 2]);
for s = 1:2
    for k = 1:2
        verifyEqual(t,size(x{s,k,1},3),height(out{s,k,1}));
        verifyTrue(t,all(out{s,k,1}.animalIndex==1));
    end
end
end

function testSinglePeriodAndTypeWithMultipleAnimals(t)
out = fn_selectNeuralTrials(t.TestData.files,'LearningPeriods',"T1L", ...
    'TrialTypes',t.TestData.types(1,:));
verifySize(t,out,[1 1 2]);
x = fn_loadSelectedNeuralActivity(out,t.TestData.files);
for a = 1:2
    verifyTrue(t,all(out{1,1,a}.animalIndex==a));
    verifyEqual(t,x{1,1,a},t.TestData.sessions{a}.dffStim{1}(:,:,1:2:12));
end
end

function testEmptySelectionDoesNotLoadNeuralFile(t)
out = select(t,'LearningPeriods',"absent");
[x,h] = fn_loadSelectedNeuralActivity(out,["not-a-file";"also-not-a-file"]);
verifyTrue(t,all(cellfun(@isempty,x),'all'));
verifyTrue(t,all(cellfun(@isempty,h),'all'));
end

function out = select(t,varargin)
out = fn_selectNeuralTrials(t.TestData.files,'AnimalLabels',["A","B"], ...
    'LearningPeriods',["T1L","T1E","absent"],'TrialTypes',t.TestData.types, ...
    'RT',[.35 .65],varargin{:});
end

function [si,trialInfo] = fixture(a)
si = table([20260102;20260101;20260103],{'2AFC2';'2AFC1';'2AFC1'}, ...
    [90;11;300],{'T1L';'T1E';'T1E'},cell(3,1),cell(3,1),cell(3,1), ...
    'VariableNames',{'date','sessionName','sessionRec','dayLabel','behSel','dffStim','ishere'});
trialInfo = table();
for row = [2 1 3]
    b = table(ones(12,1),repmat([1;2],6,1),repmat([.35;.40;.45;.50;.55;.65],2,1), ...
        'VariableNames',{'stimuli','action','RT'});
    si.behSel{row} = b;
    si.ishere{row} = [1 NaN zeros(1,a)];
    si.dffStim{row} = single(reshape(1:(a+2)*3*12,[a+2 3 12])+a*10000+row*1000);
    part = [si(repmat(row,12,1),{'date','sessionName','sessionRec','dayLabel'}) b];
    part.trialInSession = (1:12)';
    trialInfo = [trialInfo;part]; %#ok<AGROW>
end
si.dffStim{3} = []; % Behavior-only session; its trials must retain their rows.
end

