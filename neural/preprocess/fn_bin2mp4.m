filename = 'kimtech_001_001';

fileID = fopen('C:\Users\zzhu34\Documents\tempdata\zz159_patchwarp_test\suite2p\plane0\data.bin','r'); % open binary file 
lx = 450; ly = 510; to_read = 1000;
A = fread(fileID,lx*ly*to_read,'*int16');
A = double(reshape(A,lx,ly,1,[]));
A  = A - min(A(:)); A = A/prctile(A(:),99.999); A(A>=1) = 1;
fclose all;

% create the video writer with 1 fps
writerObj = VideoWriter('C:\Users\zzhu34\Documents\tempdata\zz159_patchwarp_test\ac_suite2p_10x.avi');
writerObj.FrameRate = 150;

% set the seconds per image
% open the video writer
open(writerObj);
% write the frames to the video
global info;
writeVideo(writerObj, double(A));
close(writerObj);