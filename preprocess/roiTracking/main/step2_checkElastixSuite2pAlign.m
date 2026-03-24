function [alignedOps] = step2_checkElastixSuite2pAlign(datapath,suite2pDoubleFlag)

     
    load([datapath filesep 'ops.mat'],'ops');
    meanImgAlignedPath = [ops.elastixPath filesep 'alignedElastix'];
    alignedOps.suite2ppath = [meanImgAlignedPath filesep 'suite2p/plane0/'];

    temp = load([meanImgAlignedPath filesep 'suite2p/plane0/Fall.mat'],'ops');
    alignedOps.ops = temp.ops; 


    fileID = fopen([alignedOps.suite2ppath filesep 'data.bin'],'r'); % open binary file 
    output = fread(fileID,inf,'*int16');
    output = double(reshape(output,alignedOps.ops.Lx,alignedOps.ops.Ly,[]));
    output = permute(output, [2, 1, 3]); %output = output(:,:,1:2:end);
    output = output/5000;

    if ~exist('suite2pDoubleFlag')
        if size(output,3) < 120
            suite2pDoubleFlag = true;
            disp('images in suite2p is doubled')
        else
            suite2pDoubleFlag = false; 
        end 
    end 

    fclose(fileID);
    if suite2pDoubleFlag; output = output(:,:,1:2:end); end 
    alignedOps.suite2pImg = output; 
    %implay(output)

    temp = fn_dirFilefun([ops.elastixPath filesep 'alignedElastix' filesep],@imread,'*.tiff');
    temp2 = cellfun(@(x)(x{1}),temp,'UniformOutput',false); temp2 = fn_cell2mat(temp2,3);
    if suite2pDoubleFlag; temp2 = temp2(:,:,1:2:end); end 

    alignedOps.elastixImg = temp2; 

    save([datapath filesep 'alignedOps.mat' ],'alignedOps');

    % now save the 
    imagingPath = [datapath '\imagingSession\'];
    % Get all subfolders (including nested ones)
    items = dir(imagingPath);
    % Filter only directories (and exclude '.' and '..')
    subfolders = items([items.isdir] & ~ismember({items.name}, {'.', '..'}));
    
    if length(alignedOps.ops.xoff) < 140; duplicateFlag = 2; else; duplicateFlag = 1; end 
    nSession = length(alignedOps.ops.xoff) / duplicateFlag;
    
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


function output = loadSuite2p(suite2ppath)
    suite2ppath = [suite2ppath filesep '\suite2p\plane0'];
    load([suite2ppath filesep 'Fall.mat'],'ops','ops_matlab'); if ~exist('ops'); ops = ops_matlab; end
    
    fileID = fopen([suite2ppath filesep 'data.bin'],'r'); % open binary file 
    output = fread(fileID,inf,'*int16');
    output = double(reshape(output,ops.Lx,ops.Ly,[]));
    output = permute(output, [2, 1, 3]); %output = output(:,:,1:2:end);
    output = output/5000;
end 