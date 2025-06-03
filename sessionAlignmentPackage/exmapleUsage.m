datapath = 'C:\Users\zzhu34\Documents\tempdata\zz166\andread_tuning_test';
filename = 'AS059_001_006';
global info;
sbxread([datapath filesep filename],0,1);

frames = sbxread([datapath filesep filename],0,1000);

%%

frames_chan1 = double(squeeze(frames(1,:,101:end-50,:)));

[mat_aligned, transform_coord] = fn_fastAlign(frames_chan1);
figure; imagesc(nanmean(mat_aligned,3)); colormap gray
figure; hold on; plot(transform_coord(:,1)); plot(transform_coord(:,2))
