function fn_clearTrialInfoWheel(folderPath)
%FN_CLEARTRIALINFOWHEEL Empty wheel traces in saved trialInfo tables.
% fn_clearTrialInfoWheel() uses B:\analysis\animal.
% fn_clearTrialInfoWheel(folderPath) uses another folder.
% Updates *_parsedTrial.mat files in place. Each wheel column becomes an
% nTrial-by-1 cell array containing [] in every row. Other trialInfo columns
% and other saved variables (including sessionInfo) are preserved.

if nargin < 1 || isempty(folderPath)
    folderPath = 'B:\analysis\animal';
end
assert(isfolder(folderPath),'clearTrialInfoWheel:Folder', ...
    'Folder does not exist: %s',folderPath);
files = dir(fullfile(folderPath,'*_parsedTrial.mat'));
if isempty(files)
    warning('clearTrialInfoWheel:NoFiles','No *_parsedTrial.mat files in %s.',folderPath);
    return
end

for k = 1:numel(files)
    filePath = fullfile(files(k).folder,files(k).name);
    data = load(filePath,'trialInfo');
    if ~isfield(data,'trialInfo') || ~istable(data.trialInfo)
        warning('clearTrialInfoWheel:MissingTable', ...
            'Skipping %s: no trialInfo table.',files(k).name);
        continue
    end
    trialInfo = data.trialInfo;
    trialInfo.wheelStim = repmat({[]},height(trialInfo),1);
    trialInfo.wheelChoice = repmat({[]},height(trialInfo),1);
    trialInfo.wheelReward = repmat({[]},height(trialInfo),1);
    save(filePath,'trialInfo','-append');
    fprintf('Updated %s (%d trials).\n',files(k).name,height(trialInfo));
end
end
