function opts=fn_taskActionGeometryConfig()
%FN_TASKACTIONGEOMETRYCONFIG Options shared by linear and trajectory analyses.
opts.taskDefinition='stimulusSet'; % S1/S2=T1, S3/S4=T2; or 'context' (taskLabel).
opts.conditionNames=strings(0,1); % Subset of expert condition names; []=all.
opts.dayLabels=strings(0,1);      % e.g. "Int" to compare within one period.
opts.timeWindow=[];             % Seconds relative to alignment; []=whole trial.
opts.frameRate=15;              % Set to the recording's actual frame rate.
opts.eventFrame=[];             % Curated alignment, or frame 31 for cell input.
opts.averageTime=false;         % Linear only: average the selected window first.
opts.neuronIDs=[];              % []=all selected tracked neurons; otherwise a subset.
opts.dropNonfiniteNeurons=true; % Drop neurons with any NaN/Inf in analyzed samples.
opts.normalization='zscore';    % 'zscore', 'rms', or 'none'; fitted on training only.
opts.nComponents=5;
opts.nSplits=20;                % Repeated half splits; variation is NOT a CI.
opts.splitUnit='auto';          % Curated: session; raw cells: trial (no session IDs).
opts.animalLabels=strings(0,1); % Optional labels for columns of 4 x animal cells.
opts.minTrialsPerHalf=2;        % Per task x action cell in BOTH halves.
opts.seed=1;
opts.noiseMetric='diagonal';    % Crossnobis: 'diagonal', 'shrinkage', or 'identity'.
opts.noiseShrinkage=0.2;        % Full covariance shrunk toward its diagonal.
opts.noiseRidge=1e-4;           % Relative ridge to stabilize noise normalization.
opts.makePlots=true;
opts.verbose=true;
end
