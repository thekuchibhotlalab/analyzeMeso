filename = 'kimtech_001_001';

fileID = fopen('D:\zz153\green_AC\20240523\suite2p\plane0\data.bin','r'); % open binary file 
lx = 450; ly = 488; to_read = 2000;
A = fread(fileID,lx*ly*to_read,'*int16');
A = double(reshape(A,lx,ly,1,[]));
A  = A - min(A(:)); A = A/prctile(A(:),99.999); A(A>=1) = 1;
fclose all;

% create the video writer with 1 fps
writerObj = VideoWriter('D:\zz153\green_AC\20240523\suite2p\plane0\movie_10x.avi');
writerObj.FrameRate = 150;

% set the seconds per image
% open the video writer
open(writerObj);
% write the frames to the video
global info;
writeVideo(writerObj, double(A));
close(writerObj);