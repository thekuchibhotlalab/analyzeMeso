function curated = fn_prepareNeuralData(curated,sessionInfoFile,varargin)
%FN_PREPARENEURALDATA Load neural activity only after trials/sessions are chosen.
% Accepts a parsedTrial.mat path or an already-loaded sessionInfo table.
% All neuron rows are retained; tracking.selectedNeuronIDs gives common cells.
% 'DataPath','': override the neural source with a MAT file or containing folder.
% A folder uses the original source filename (or animalID_parsedTrial.mat when
% no source filename is available). Relative paths are relative to pwd.
% The actual file loaded is recorded in curated.neuralSourceFile.
% 'ShowPlots',false: display neural QC figures (default: no display).
% 'PlotSavePath','': folder for PNGs (default: no saving).
% A save folder alone generates PNGs using hidden figures, then closes them.
% Includes the tracking tradeoff curve and selected session count, if available.
% Trial-selection plots are controlled separately by fn_prepareTrialData's
% MakePlot argument. Saved filenames are in curated.plotFiles.
p=inputParser;
if nargin<2, sessionInfoFile=[]; end
addParameter(p,'DataPath','',@(x)(ischar(x)&&(isrow(x)||isempty(x)))|| ...
    (isstring(x)&&isscalar(x)&&~ismissing(x)));
addParameter(p,'ShowPlots',false,@(x)islogical(x)&&isscalar(x));
addParameter(p,'PlotSavePath','',@(x)(ischar(x)&&isrow(x))|| ...
    (ischar(x)&&isempty(x))||(isstring(x)&&isscalar(x)&&~ismissing(x)));
parse(p,varargin{:});
showPlots=p.Results.ShowPlots;
plotSavePath=char(p.Results.PlotSavePath);
assert(~curated.neuralLoaded,'trialCuration:AlreadyLoaded','Neural activity is already loaded.');
sessionInfoFile=fn_resolveNeuralSource(sessionInfoFile,p.Results.DataPath,curated);
sessionInfo=fn_loadTrialTable(sessionInfoFile,'sessionInfo');
curated.neuralSourceFile=''; % Empty for an already-loaded table.
if ischar(sessionInfoFile)||isstring(sessionInfoFile)
    curated.neuralSourceFile=char(java.io.File(char(sessionInfoFile)).getCanonicalPath());
end
cfg=curated.cfg;
selection=fn_extractSelectedNeuralTrials(sessionInfo,curated.selection,cfg);
selection=fn_normalizeNeuralData(selection,cfg);
curated.neuralSelection=selection;
curated.byCondition=fn_organizeConditionData(selection);
curated.qc=fn_makeTrialCountQCTable(selection,cfg);
curated.sessionAudit=fn_makeSessionAuditTable(selection);
curated.droppedTrialReport=fn_makeDroppedTrialReport(selection);
if cfg.runTrackedNeuronQC
    curated.trackedNeuronQC=fn_trackedNeuronQC(sessionInfo,selection);
end
curated.neuralPlotOptions=struct('ShowPlots',showPlots,'PlotSavePath',plotSavePath);
curated.plotFiles=struct();
if showPlots || ~isempty(plotSavePath)
    visibility='off'; if showPlots, visibility='on'; end
    if ~isempty(plotSavePath)&&~isfolder(plotSavePath), mkdir(plotSavePath); end
    prefix='neural';
    if isfield(curated,'animalID')&&strlength(string(curated.animalID))>0
        prefix=[matlab.lang.makeValidName(char(curated.animalID)) '_neural'];
    end
    names={'trialCounts','meanTC','sessionAmplitude'};
    plotters={@()fn_plotTrialCountQC(curated.qc,cfg,visibility), ...
        @()fn_plotMeanTCQC(curated.byCondition,cfg,visibility), ...
        @()fn_plotSessionAmplitudeQC(selection,visibility)};
    if isfield(curated.tracking,'curve') && ~isempty(curated.tracking.curve)
        names{end+1}='trackingCurve';
        plotters{end+1}=@()fn_plotTrackingQC(curated.tracking,visibility);
    end
    for k=1:numel(names)
        fig=plotters{k}();
        if ~showPlots, cleanup=onCleanup(@()fn_closePlot(fig)); end
        if ~isempty(plotSavePath)
            file=fullfile(plotSavePath,[prefix '_' names{k} '.png']);
            exportgraphics(fig,file,'Resolution',150);
            curated.plotFiles.(names{k})=file;
        end
        if showPlots
            curated.figures.(names{k})=fig;
        else
            clear cleanup % Close only the hidden figure created by this step.
            curated.figures.(names{k})=[];
        end
    end
end

curated.neuralLoaded=true;
if cfg.verbose, disp(curated.qc); end
if ~isempty(cfg.saveFile), save(cfg.saveFile,'curated','-v7.3'); end
end

function fn_closePlot(fig)
if isgraphics(fig), close(fig); end
end

function source=fn_resolveNeuralSource(source,dataPath,curated)
if strlength(string(dataPath))==0, return; end
dataPath=char(dataPath);
if isfolder(dataPath)
    stem=''; ext='';
    if (ischar(source)||isstring(source)) && isscalar(string(source))
        % Accept a saved Windows path even when loading on another OS.
        [~,stem,ext]=fileparts(strrep(char(source),'\','/'));
    end
    if isempty(stem)
        assert(isfield(curated,'animalID')&&strlength(string(curated.animalID))>0, ...
            'trialCuration:DataPath','Provide a MAT-file path when the source filename and animalID are unavailable.');
        stem=[char(curated.animalID) '_parsedTrial']; ext='.mat';
    end
    source=fullfile(dataPath,[stem ext]);
else
    source=dataPath;
end
assert(isfile(source),'trialCuration:DataPath','Neural file not found: %s.',source);
end
