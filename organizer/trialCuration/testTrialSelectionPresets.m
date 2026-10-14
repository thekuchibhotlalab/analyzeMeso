function tests=testTrialSelectionPresets
tests=functiontests(localfunctions);
end

function setupOnce(t)
root=fileparts(mfilename('fullpath'));
for folder={'','config','helper','tracking'}
    t.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root,folder{1})));
end
end

function testTCAConditionsAndOrder(t)
[T,S]=fn_fixture(); cfg=fn_defaultTrialSelectionConfig();
c=fn_select(T,S,cfg);
verifyEqual(t,numel(c.selection),16);
verifyEqual(t,string({c.selection.name}), ...
    ["T1E_S1_L","T1E_S2_R","T2E_S3_L","T2E_S4_R", ...
     "T1M_S1_L","T1M_S2_R","T2M_S3_L","T2M_S4_R", ...
     "T1L_S1_L","T1L_S2_R","T2L_S3_L","T2L_S4_R", ...
     "Int_S1_L","Int_S2_R","Int_S3_L","Int_S4_R"]);
verifyEqual(t,[c.selection.nAfterRT],2*ones(1,16)); % Rewarded + probe.
selected=vertcat(c.selection.trials);
verifyEqual(t,numel(unique(selected.sourceTrialRow)),height(selected));
end

function testExpertPreservesOriginalConditions(t)
cfg=fn_expertTrialSelectionConfig();
verifyEqual(t,string({cfg.conditionDef.name}), ...
    ["T1_S1_L","T1_S2_R","T2_S3_L","T2_S4_R", ...
     "T2probe_S1_L","T2probe_S2_R","RetrainT1_S1_L","RetrainT1_S2_R", ...
     "IntT1_S1_L","IntT1_S2_R","IntT2_S3_L","IntT2_S4_R"]);
verifyEqual(t,unique(vertcat(cfg.conditionDef.dayLabels)),["Int";"T1L";"T1R";"T2L"]);
verifyTrue(t,all(cellfun(@isempty,{cfg.conditionDef.responseTypes})));
end

function testEarlyT1RewardAndProbeSeparation(t)
[T,S]=fn_fixture(); c=fn_select(T,S,fn_earlyT1TrialSelectionConfig());
verifyEqual(t,numel(c.selection),12);
verifyEqual(t,[c.selection.nAfterRT],repmat([1 2 2 1 1 1],1,2));
selected=vertcat(c.selection.trials);
verifyEqual(t,unique(selected.dayLabel),["T1E";"T1M"]);
verifyEqual(t,unique(selected.stimuli),[1;2]);
fn_checkProbes(t,c);
% Missing rewardFrame cannot turn a coded rewarded trial into a probe.
verifyTrue(t,all(isnan(c.selection(1).trials.rewardFrame)));
verifyEqual(t,c.selection(1).trials.responseType,1);
end

function testEarlyT2IncludesBothTasks(t)
[T,S]=fn_fixture();
% In early T2, S1/S2 may appear in blocks labeled T1.
T.taskLabel(ismember(T.dayLabel,["T2E","T2M"]) & T.stimuli<=2)="T1";
c=fn_select(T,S,fn_earlyT2TrialSelectionConfig());
verifyEqual(t,numel(c.selection),24);
verifyEqual(t,[c.selection.nAfterRT],repmat([1 2 2 1 1 2 2 1 1 1 1 1],1,2));
selected=vertcat(c.selection.trials);
verifyEqual(t,unique(selected.dayLabel),["T2E";"T2M"]);
verifyEqual(t,unique(selected.stimuli),(1:4)');
fn_checkProbes(t,c);
end

function testProbeFieldRequiredOnlyForOutcomeFilters(t)
[T,S]=fn_fixture(); T=removevars(T,'responseType');
verifyError(t,@()fn_select(T,S,fn_earlyT1TrialSelectionConfig()), ...
    'trialCuration:MissingResponseType');
c=fn_select(T,S,fn_defaultTrialSelectionConfig());
verifyEqual(t,numel(c.selection),16);
end

function fn_checkProbes(t,c)
selected=vertcat(c.selection.trials);
verifyEqual(t,numel(unique(selected.sourceTrialRow)),height(selected));
verifyFalse(t,any(selected.action==0));
for k=1:numel(c.selection)
    item=c.selection(k);
    if endsWith(item.name,"_probe")
        verifyTrue(t,all(item.trials.responseType==2));
        verifyTrue(t,all(item.trials.action==1+mod(item.trials.stimuli+1,2)));
    end
end
end

function c=fn_select(T,S,cfg)
cfg.makePlots=false; cfg.verbose=false; cfg.selectSessionsByTracking=false;
c=fn_prepareTrialData(T,S,cfg);
end

function [T,S]=fn_fixture()
stages=["T1E";"T1M";"T1L";"T2E";"T2M";"T2L";"Int"];
S=table((1:7)',stages,true(7,1),'VariableNames',{'sessionRec','dayLabel','goodTracking'});
T=table();
for stage=1:7
    for stimulus=1:4
        correctAction=1+mod(stimulus+1,2);
        action=[correctAction;3-correctAction;correctAction;3-correctAction;0;0];
        responseType=[1;-1;2;2;0;2];
        task="T1"; if startsWith(stages(stage),"T2"), task="T2"; end
        if stages(stage)=="Int", task="Mixed"; end
        chunk=table(repmat(stage,6,1),(1:6)'+6*(stimulus-1), ...
            repmat(stages(stage),6,1),repmat(task,6,1),repmat(stimulus,6,1), ...
            action,responseType,repmat(0.5,6,1),nan(6,1), ...
            'VariableNames',{'sessionRec','trialInSession','dayLabel','taskLabel', ...
            'stimuli','action','responseType','RT','rewardFrame'});
        T=[T;chunk]; %#ok<AGROW>
    end
end
end
