function step8_evaluateElastixSuite2p(datapath)
    %'G:\rockfish\Jenni\fz017\elastix_plane2\'
    alignpath = [datapath filesep 'imagingSession'];
    tiffpath = [datapath filesep 'elastix'];
    
    A = fn_dirfun(alignpath, @loadBin);

    temp = fn_dirFilefun([tiffpath filesep 'alignedElastix' filesep],@imread,'*.tiff');
    temp2 = cellfun(@(x)(x{1}),temp,'UniformOutput',false); tiffImg = fn_cell2mat(temp2,3);

end 


function [A] = loadBin(filePath)
    suite2ppath = [filePath '/suite2p/plane1/'];
    A = fn_readBinSuite2p(suite2ppath,'data_elastix_chan2.bin',100);
    A = fn_fastAlign(A);
    A = nanmean(A,3);

end 