function [outDffMat,nNeuron,saveFile,outDffMatZ] = fn_combineOutDffMatAnimals(animalLabels,dataDir,varargin)
% fn_combineOutDffMatAnimals Concatenate per-animal outDffMat files.
%
%   [outDffMat,nNeuron,saveFile,outDffMatZ] = ...
%       fn_combineOutDffMatAnimals(animalLabels,dataDir)
%
% Example:
%   animalLabels = {'zz153_PPC','zz159_PPC','zz172_PPC2'};
%   dataDir = 'B:\analysis\sfn2025Plot\choiceAligned';
%   fn_combineOutDffMatAnimals(animalLabels,dataDir);
%
% Each input file is expected to be:
%   outDffMat_<animalName>_spkNorm_choice.mat
%
% and should contain a 4-D variable named outDffMat. The function
% concatenates all animals along dimension 1 and saves outDffMat, nNeuron,
% animalLabels, and outDffMatZ in the same directory.

if nargin < 2 || isempty(dataDir)
    dataDir = pwd;
end

p = inputParser;
addParameter(p,'actName','spkNorm',@(x) ischar(x) || isstring(x));
addParameter(p,'alignName','choice',@(x) ischar(x) || isstring(x));
addParameter(p,'saveName','',@(x) ischar(x) || isstring(x));
addParameter(p,'saveZscore',true,@islogical);
addParameter(p,'zscoreDim',2,@(x) isnumeric(x) && isscalar(x));
parse(p,varargin{:});

animalLabels = normalizeLabels(animalLabels);
dataDir = char(dataDir);
actName = char(p.Results.actName);
alignName = char(p.Results.alignName);

nAnimal = numel(animalLabels);
outDffCell = cell(nAnimal,1);
nNeuron = nan(1,nAnimal);
refTrailingSize = [];

for iAnimal = 1:nAnimal
    animalName = animalLabels{iAnimal};
    filePath = findAnimalFile(dataDir,animalName,actName,alignName);
    fprintf('Loading %s\n',filePath);

    loaded = load(filePath,'outDffMat');
    if ~isfield(loaded,'outDffMat')
        error('File does not contain variable outDffMat: %s',filePath);
    end

    tempMat = loaded.outDffMat;
    if ndims(tempMat) ~= 4
        error('Expected outDffMat to be 4-D in %s, but ndims=%d.',filePath,ndims(tempMat));
    end

    tempSize = size(tempMat);
    if isempty(refTrailingSize)
        refTrailingSize = tempSize(2:4);
    elseif ~isequal(tempSize(2:4),refTrailingSize)
        error(['Size mismatch in %s. Expected dimensions 2-4 to be [%s], ' ...
            'but found [%s].'],filePath,num2str(refTrailingSize),num2str(tempSize(2:4)));
    end

    outDffCell{iAnimal} = tempMat;
    nNeuron(iAnimal) = tempSize(1);
    fprintf('  %s: %d neurons, size [%s]\n',animalName,nNeuron(iAnimal),num2str(tempSize));
end

outDffMat = cat(1,outDffCell{:});
fprintf('Combined outDffMat size: [%s]\n',num2str(size(outDffMat)));
fprintf('nNeuron: [%s]\n',num2str(nNeuron));

if p.Results.saveZscore
    outDffMatZ = fn_zscoreByChunkAllDim(outDffMat,p.Results.zscoreDim);
else
    outDffMatZ = [];
end

saveName = char(p.Results.saveName);
if isempty(saveName)
    animalNamePart = strjoin(animalLabels,'_');
    saveName = sprintf('outDffMat_%s_%s_%s.mat',animalNamePart,actName,alignName);
end
if ~endsWith(saveName,'.mat','IgnoreCase',true)
    saveName = [saveName '.mat'];
end
saveFile = fullfile(dataDir,saveName);

if p.Results.saveZscore
    save(saveFile,'outDffMat','outDffMatZ','nNeuron','animalLabels','-v7.3');
else
    save(saveFile,'outDffMat','nNeuron','animalLabels','-v7.3');
end
fprintf('Saved combined file to:\n%s\n',saveFile);
end


function labels = normalizeLabels(labels)
if ischar(labels) || isstring(labels)
    labels = cellstr(labels);
end
if ~iscell(labels)
    error('animalLabels must be a cell array, string array, or character vector.');
end
labels = labels(:)';
labels = cellfun(@char,labels,'UniformOutput',false);
end


function filePath = findAnimalFile(dataDir,animalName,actName,alignName)
candidateNames = { ...
    sprintf('outDffMat_%s_%s_%s.mat',animalName,actName,alignName), ...
    sprintf('outDffMat_%s_%s_%s.mat',animalName,lower(actName),alignName), ...
    sprintf('outDffMat_%s_%s_%s.mat',animalName,upper(actName),alignName)};

for iCandidate = 1:numel(candidateNames)
    filePath = fullfile(dataDir,candidateNames{iCandidate});
    if exist(filePath,'file') == 2
        return
    end
end

pattern = fullfile(dataDir,sprintf('outDffMat_%s_*_%s.mat',animalName,alignName));
matched = dir(pattern);
matched = matched(~contains({matched.name},'_trial'));
if numel(matched) == 1
    filePath = fullfile(dataDir,matched(1).name);
    return
elseif numel(matched) > 1
    error('Found multiple matching files for %s:\n%s', ...
        animalName,strjoin({matched.name},newline));
end

error('Could not find outDffMat file for %s in %s.',animalName,dataDir);
end
