function fn_saveMP4(A,filename,framerate)
    if ~exist('framerate'); framerate = 15; end 
    A = double(reshape(A,size(A,1),size(A,2),1,[]));
    A  = A - min(A(:)); A = A/prctile(A(:),99.8); A(A>=1) = 1;
    writerObj = VideoWriter(filename,'MPEG-4');
    writerObj.FrameRate = framerate;
    open(writerObj);
    writeVideo(writerObj, double(A));
    close(writerObj);
end 