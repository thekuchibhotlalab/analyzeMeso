function A = fn_readBinSuite2p(binPath,filename,to_read,dimensionReverseFlag)
if ~exist('dimensionReverseFlag'); dimensionReverseFlag = false; end 
load([binPath filesep 'Fall.mat'],'ops');

fileID = fopen([binPath filesep filename],'rb'); % open binary file 

if ~exist('to_read') || isempty(to_read) || to_read > ops.nframes
    to_read = ops.nframes; 
end 

A = fread(fileID,ops.Ly*ops.Lx*to_read,'*int16');
if dimensionReverseFlag
    A = double(reshape(A,ops.Ly,ops.Lx,[]));
else
    A = double(reshape(A,ops.Lx,ops.Ly,[]));
end 


fclose(fileID);


end 