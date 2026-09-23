function outputFile = step7_evaluateSpkDeconv(rootDir)
%STEP7_EVALUATESPKDECONV Summarize every imagingSession subfolder.
% Run step7_evaluateSpkDeconv from the animal directory, or supply its path.
% Output: session_deconv_stats.mat in rootDir, containing:
%   sessionNames                   nSession x 1 cell array (alphabetical order)
%   b, g, lam                      nSession x nNeuron
%   dffPercentiles                 nSession x nNeuron x 5 (F or dff)
%   allTracesPercentiles           nSession x nNeuron x 5 (allTraces)
%   SPercentiles                   nSession x nNeuron x 5 (data_S.mat: S)
%   spkPercentiles                 alias of SPercentiles
%   percentileLevels               [5 25 50 75 95]
%   nFrames                        nSession x 3, in signalNames order
%   signalNames, dffVariableNames  provenance for each input signal/session
% All sessions must have the same neuron columns in the same order.
% Only one signal matrix is loaded at a time. prctile omits NaN values.

if nargin < 1 || isempty(rootDir); rootDir = pwd; end
rootDir = char(rootDir);
sessionRoot = fullfile(rootDir,'imagingSession');
if ~isfolder(sessionRoot)
    error('DeconvStats:MissingFolder','Folder does not exist: %s',sessionRoot);
end
folders = dir(sessionRoot);
folders = folders([folders.isdir] & ~ismember({folders.name},{'.','..'}));
[~,order] = sort({folders.name}); folders = folders(order);
if isempty(folders)
    error('DeconvStats:NoSessions','No session subfolders found in %s.',sessionRoot);
end
sessionNames = {folders.name}';
nSession = numel(folders);
percentileLevels = [5 25 50 75 95];
signalNames = {'dff','allTraces','S'};
signalFiles = {'data_dff.mat','data_F.mat','data_S.mat'};
variableCandidates = {{'F','dff'},{'allTraces'},{'S'}};
dffVariableNames = cell(nSession,1);
nFrames = zeros(nSession,3);

for i = 1:nSession
    planeDir = fullfile(sessionRoot,sessionNames{i},'suite2p','plane0');
    parameters = load(fullfile(planeDir,'data_spkOps.mat'),'b','g','lam');
    for field = {'b','g','lam'}
        name = field{1};
        if ~isfield(parameters,name)
            error('DeconvStats:MissingParameter','Session %s: missing %s in data_spkOps.mat.',sessionNames{i},name);
        end
        validateattributes(parameters.(name),{'numeric'},{'vector','nonempty','real'},mfilename,name);
    end
    if i == 1
        nNeuron = numel(parameters.b);
        b = nan(nSession,nNeuron); g = b; lam = b;
        dffPercentiles = nan(nSession,nNeuron,5);
        allTracesPercentiles = nan(nSession,nNeuron,5);
        SPercentiles = nan(nSession,nNeuron,5);
    end
    if any([numel(parameters.b),numel(parameters.g),numel(parameters.lam)] ~= nNeuron)
        error('DeconvStats:NeuronCount','Session %s: b, g and lam must each contain %d neurons.',sessionNames{i},nNeuron);
    end
    b(i,:) = parameters.b(:)';
    g(i,:) = parameters.g(:)';
    lam(i,:) = parameters.lam(:)';

    for j = 1:3
        filename = fullfile(planeDir,signalFiles{j});
        contents = whos('-file',filename);
        candidates = variableCandidates{j};
        found = candidates(ismember(candidates,{contents.name}));
        if isempty(found)
            error('DeconvStats:MissingVariable','%s must contain %s.',filename,strjoin(candidates,' or '));
        end
        variable = found{1};
        loaded = load(filename,variable);
        values = loaded.(variable);
        clear loaded
        validateattributes(values,{'single','double'},{'2d','real','nonempty'},mfilename,variable);
        if size(values,2) ~= nNeuron
            error('DeconvStats:NeuronCount','%s: %s has %d columns; expected %d neurons.',filename,variable,size(values,2),nNeuron);
        end
        nFrames(i,j) = size(values,1);
        % prctile returns 5 x nNeuron; permute to 1 x nNeuron x 5.
        percentiles = permute(prctile(values,percentileLevels,1),[3 2 1]);
        clear values
        switch j
            case 1
                dffPercentiles(i,:,:) = percentiles;
                dffVariableNames{i} = variable;
            case 2
                allTracesPercentiles(i,:,:) = percentiles;
            case 3
                SPercentiles(i,:,:) = percentiles;
        end
    end
    if any(nFrames(i,:) ~= nFrames(i,1))
        error('DeconvStats:FrameCount','Session %s: dff, allTraces and S have different frame counts.',sessionNames{i});
    end
    fprintf('Summarized %d/%d: %s (%d frames, %d neurons)\n', ...
        i,nSession,sessionNames{i},nFrames(i,1),nNeuron);
end

% Retain the earlier descriptive variable name while exposing a name that
% directly matches variable S in data_S.mat.
spkPercentiles = SPercentiles;
outputFile = fullfile(rootDir,'session_deconv_stats.mat');
save(outputFile,'sessionNames','b','g','lam','dffPercentiles', ...
    'allTracesPercentiles','SPercentiles','spkPercentiles', ...
    'percentileLevels','nFrames', ...
    'signalNames','dffVariableNames','-v7.3');
fprintf('Saved %s\n',outputFile);
end
