%% Start from your expert curation output and existing Animal object a.
% Add analysis/taskActionGeometry to your MATLAB path.
% If selection has already run, KEEP that curated output and its sessions.
% Otherwise:
% cfg=fn_expertTrialSelectionConfig();
% curated=a.fn_prepareTrialData(cfg);
%
% Load neural arrays once (this is the step that reads the large neural file).
if ~curated.neuralLoaded
    curated=a.fn_prepareNeuralData(curated);
end

%% Compare stimulus sets and choices within the interleaved period.
opts=fn_taskActionGeometryConfig();
opts.taskDefinition='stimulusSet'; % S1/S2 vs S3/S4; alternative: 'context'
opts.dayLabels="Int";             % Reduces the T1-late vs T2-late stage confound.
opts.frameRate=15;                % Set this to YOUR recording's actual rate.
opts.timeWindow=[-0.7 0.5];         % Relative to cfg.alignedEventFrame; []=all frames.
opts.nComponents=5;
opts.nSplits=20;
opts.splitUnit='session';         % Each held-out set contains whole sessions.
opts.normalization='zscore';      % One scale/neuron, pooled training trials/time.
linear=fn_analyzeTaskActionSubspaces(curated,opts);
geometry=fn_analyzeTaskActionManifold(curated,opts);

%% Inspect ranked axes and held-out performance.
taskAxes=linear.task.axes;         % neuron x axis; rows: linear.data.neuronIDs
actionAxes=linear.action.axes;
varianceTable=linear.variance;
cvByRank=linear.cv.meanPredictiveVariance; % rank x [task action interaction]
principalAngles=geometry.taskActionOverlap.principalAnglesDeg;
timeGeometry=geometry.timeGeometry;
distances=geometry.cv.rdm;         % Rows/columns identified by geometry.points.

%% Optional: one static axis per binary factor, after window averaging.
% staticOpts=opts;
% staticOpts.averageTime=true;
% staticResult=fn_analyzeTaskActionSubspaces(curated,staticOpts);

%% Optional: compare recorded context for the SAME T1 stimuli.
% This is a different question and includes a learning-period/session confound.
% contextOpts=opts;
% contextOpts.taskDefinition='context';
% contextOpts.dayLabels=[];
% contextOpts.conditionNames=["T1_S1_L","T1_S2_R", ...
%     "T2probe_S1_L","T2probe_S2_R"];
% contextLinear=fn_analyzeTaskActionSubspaces(curated,contextOpts);
% contextGeometry=fn_analyzeTaskActionManifold(curated,contextOpts);
