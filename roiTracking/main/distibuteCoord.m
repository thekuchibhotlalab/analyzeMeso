datapath = 'G:\rockfish\ziyi\zz151_AC1';
load([datapath '\elastix\alignedElastix\suite2p\plane0\Fall.mat'])

imagingPath = [datapath '\imagingSession\'];
% Get all subfolders (including nested ones)
items = dir(imagingPath);

% Filter only directories (and exclude '.' and '..')
subfolders = items([items.isdir] & ~ismember({items.name}, {'.', '..'}));

if length(ops.xoff) < 140; duplicateFlag = 2; else; duplicateFlag = 1; end 

nSession = length(ops.xoff) / duplicateFlag;

if length(subfolders) ~= nSession; error('Session number not correct!'); end 

for i = 1:length(subfolders)
    subfolderPath = fullfile(imagingPath, subfolders(i).name);
    fprintf('Subfolder %d: %s\n', i, subfolderPath);
    xoff = ops.xoff(i*duplicateFlag);
    yoff = ops.yoff(i*duplicateFlag);
    xoff1 = ops.xoff1(i*duplicateFlag,:);
    yoff1 = ops.yoff1(i*duplicateFlag,:);
    save([subfolderPath filesep 'crossSessionSuite2p.mat'],'yoff1','xoff1','yoff','xoff');
    
end

