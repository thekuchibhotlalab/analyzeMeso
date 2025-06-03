%% check elastix

z = imread('G:\rockfish\ziyi\zz159_PPC\elastix\alignedElastix\zz159_PPC_session20.tiff');
A = fn_readBinSuite2p('G:\rockfish\ziyi\zz159_PPC\imagingSession\20240705\suite2p\plane0','data_elastix.bin',100,true);
B = nanmean(A,3);

implay(cat(3,B',z)./6000)

%% check cross session suite2p

A = fn_readBinSuite2p('G:\rockfish\ziyi\zz159_PPC\imagingSession\batch3\imagingSession\20240703\suite2p\plane0','data_suite2p.bin',100);
B = nanmean(A,3);
C = fn_readBinSuite2p('G:\rockfish\ziyi\zz159_PPC\elastix\alignedElastix\suite2p\plane0','data.bin',38);

implay(cat(3,B,C(:,:,1)')./6000)

