function [alignedOps] = step2_saveAlignOps(dataPath,suite2pDuplication)
    %
    elastixPath = [dataPath filesep 'elastix'];
    alignedOps.suite2ppath = [elastixPath filesep 'alignedElastix/suite2p/plane0/'];
    temp = load([alignedOps.suite2ppath '/Fall.mat'],'ops');
    alignedOps.ops = temp.ops; 


    fileID = fopen([alignedOps.suite2ppath filesep 'data.bin'],'r'); % open binary file 
    output = fread(fileID,inf,'*int16');
    output = double(reshape(output,alignedOps.ops.Lx,alignedOps.ops.Ly,[]));
    output = permute(output, [2, 1, 3]); %output = output(:,:,1:2:end);
    output = output/5000;

    fclose(fileID);
    if suite2pDuplication; output = output(:,:,1:suite2pDuplication:end); end 
    alignedOps.suite2pImg = output; 
    %implay(output)

    temp = fn_dirFilefun([elastixPath filesep 'alignedElastix' filesep],@imread,'*.tiff');
    temp2 = cellfun(@(x)(x{1}),temp,'UniformOutput',false); temp2 = fn_cell2mat(temp2,3);
    temp2 = temp2(:,:,1:suite2pDuplication:end); 

    alignedOps.elastixImg = temp2; 

    save([dataPath filesep 'alignedOps.mat' ],'alignedOps');

    % now save the suite2p coordinates
    imagingPath = [dataPath '\imagingSession\'];
    % Get all subfolders (including nested ones)
    items = dir(imagingPath);
    % Filter only directories (and exclude '.' and '..')
    subfolders = items([items.isdir] & ~ismember({items.name}, {'.', '..'}));
    
    nSession = length(alignedOps.ops.xoff) / suite2pDuplication;
    
    if length(subfolders) ~= nSession; error('Session number not correct!'); end 
    
    for i = 1:length(subfolders)
        subfolderPath = fullfile(imagingPath, subfolders(i).name);
        fprintf('Subfolder %d: %s\n', i, subfolderPath);
        xoff = alignedOps.ops.xoff(i*duplicateFlag);
        yoff = alignedOps.ops.yoff(i*duplicateFlag);
        xoff1 = alignedOps.ops.xoff1(i*duplicateFlag,:);
        yoff1 = alignedOps.ops.yoff1(i*duplicateFlag,:);
        save([subfolderPath filesep 'crossSessionSuite2p.mat'],'yoff1','xoff1','yoff','xoff');
        
    end
end 