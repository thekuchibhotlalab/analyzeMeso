
fileID = fopen([suite2ppath filesep 'data.bin'],'r'); % open binary file 

lx = 500; ly = 700; % pixels for x and y
k=0; %current frame to start reading
nFrame = 20000; % total number of frames
blksize = 2000; % nb of frames loaded at a time (depend on RAM)
to_read = min(blksize,nFrame-k);
while to_read>0
    A = fread(fileID,lx*ly*to_read,'*int16'); % read a 1-D array of size 500*700*2000
    A = reshape(A,lx*ly,[]); % reshape into 2-D array, 2nd dimension is nFrame
    A = reshape(A,lx,ly,[]); % reshape into 3-D array, 3nd dimension is nFrame

    k = k+to_read;
    to_read = min(blksize,nFrame-k);
end  