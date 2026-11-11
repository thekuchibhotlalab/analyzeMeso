% Five modes: neuron x time x learning phase x action x task.
% Model numbers are CELL INDICES in M. Match component lists by position.
repo=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(repo,'analysis','TCA_truncateStimChoice'));
addpath(fullfile(repo,'helper_function'));
ppcFile='B:/analysis/TCA2026_concat/TCA-nonneg_allAni.mat';
acFile='B:/analysis/TCA2026_concat/TCA-nonneg_allAni_AC.mat';

% Edit here, or define tcaPlotOptions before running. Clear it to reset.
if ~exist('tcaPlotOptions','var'), tcaPlotOptions=struct(); end
if ~isfield(tcaPlotOptions,'ppcModel'), tcaPlotOptions.ppcModel=7; end
if ~isfield(tcaPlotOptions,'ppcComponents'), tcaPlotOptions.ppcComponents=[5 6]; end
if ~isfield(tcaPlotOptions,'acModel'), tcaPlotOptions.acModel=7; end
if ~isfield(tcaPlotOptions,'acComponents'), tcaPlotOptions.acComponents=[3 4]; end
% Each cell makes one grouped-component row, separately for AC/PPC.
if ~isfield(tcaPlotOptions,'ppcGroups'), tcaPlotOptions.ppcGroups={tcaPlotOptions.ppcComponents}; end
if ~isfield(tcaPlotOptions,'acGroups'), tcaPlotOptions.acGroups={tcaPlotOptions.acComponents}; end
% Example: tcaPlotOptions.ppcGroups={[2 5 6],[1 8 10]};
% tcaPlotOptions.visible=false;
if ~isfield(tcaPlotOptions,'savePath')
    tcaPlotOptions.savePath='B:/analysis/TCA2026_concat/component_figures';
end

tcaPlotOptions.ppcComponents=[1 2];
tcaPlotOptions.acComponents=[6 1];
tcaPlotOptions.ppcGroups={[5 6],[8 9 10 11 12]};
tcaPlotOptions.acGroups = {[3 8 4 10],[2], [5]};

ppcTCA=load(ppcFile,'M','VEpct'); acTCA=[];
if isfile(acFile)
    acTCA=load(acFile,'M','VEpct');
else
    fprintf('AC file not available; plotting PPC only: %s\n',acFile);
end
[tcaComponentSummary,tcaComponentFigures]=fn_plotTCAComponents(ppcTCA,acTCA,tcaPlotOptions);
