%% Choice bias and neural geometry: load metadata, annotate, then select trials.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','choiceBiasGeometry'),fullfile(repo,'helper_function'));
addpath(genpath(fullfile(repo,'organizer','trialCuration')));
% Set your animal IDs and data location here; separate recordings remain separate.
aniPath='B:/animal';
animals = {'zz153_PPC','zz159_PPC',...
           'zz172_PPC1','zz172_PPC2','zz177_PPC','zz180_PPC'};
[analysisCfg,plotCfg]=fn_choiceBiasGeometryConfig();
plotCfg.savePath='B:/analysis/choiceBiasGeometry';
selectionCfg=fn_interleaveTrialSelectionConfig();
selectionCfg.neuralField='dffChoice'; selectionCfg.useRTFilter=false;
selectionCfg.requireCorrect=false; selectionCfg.excludeMiss=false;
% Eight combinations include BOTH correct and error choices (actual L/R).
selectionCfg.conditionDef=[];
for stimulus=1:4
    for action=1:2
        selectionCfg.conditionDef=[selectionCfg.conditionDef; ...
            fn_trialCondition(sprintf('Int_S%d_A%d',stimulus,action),'Int',[],stimulus,action)];
    end
end
% Existing cfg session-count and tracking selection still apply. Adjust if needed.
allAni=cell(size(animals)); allTrialsel=cell(size(animals));
for a=1:numel(animals)
    loaded=load(fullfile(aniPath,[animals{a} '_animal.mat']),'ani'); ani=loaded.ani;
    [ani.trialInfo,biasInfo]=fn_addChoiceBias(ani.trialInfo,analysisCfg.biasWindow);
    allAni{a}=ani; % Annotated full table remains available; source files are not overwritten.
    trialSel=ani.fn_prepareTrialData(selectionCfg,'MakePlot',true);
    allTrialsel{a}=ani.fn_prepareNeuralData(trialSel);
end
[choiceBiasGeometry,choiceBiasFigures]=fn_analyzeChoiceBiasGeometry(allTrialsel,analysisCfg,plotCfg);
% Replot without fitting: fn_plotChoiceBiasGeometry(choiceBiasGeometry,plotCfg).
% biasMagnitude=false changes the scatter x-axis from |bias| to signed bias.
