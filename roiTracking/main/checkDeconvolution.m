

datapath = 'G:\rockfish\ziyi\zz159_AC\imagingSession\20240727'; 

load([datapath '\suite2p\plane0\data_dff.mat'])
load([datapath '\suite2p\plane0\data_C.mat'])
load([datapath '\suite2p\plane0\data_spkOps.mat'])

correctedDff = dff(:,1)-repmat(b,[size(dff,1), 1]);

residual = C - correctedDff; 
t_half = log(0.5) ./ log(g) * 1000/15;


figure; histogram(t_half)

