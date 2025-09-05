datapath = 'G:\rockfish\ziyi\zz159_PPC';
output = fn_dirfun(datapath, @loadSuite2pMeanImg);
%output = output(1:30); 
%%
output = cellfun(@enhancedImage, output,'UniformOutput',false);
output = fn_cell2mat(output,3); 
output = round(output*5000); 
%%
ref = output(:,:,16);
save([datapath filesep '\meanImg\zz159_refImg.mat'],'ref');
for i = 1:size(output,3)
    meanImg = output(:,:,i); 
    save([datapath filesep 'meanImg\sessionImg\zz159_session' int2str(i) '.mat'],'meanImg');

end 

%h5write('G:\rockfish\ziyi\zz159_PPC\meanImg\zz159_sessionMeanImg.h5','/data',output,[1 1 1],[510 900 32]);
%%
A = double(reshape(output,510,900,1,[]));
A  = A - min(A(:)); A = A/prctile(A(:),99.999); A(A>=1) = 1;
writerObj = VideoWriter('C:\Users\zzhu34\Documents\tempdata\mesoFig\zz159_AC_rigid.avi');
writerObj.FrameRate = 3;
open(writerObj);
writeVideo(writerObj, double(A));
close(writerObj);
%%
output2 = fn_dirFilefun([datapath filesep '\meanImg\registeredImg_simpleElastix\'], @readTiff, '*.tiff');
output2 = fn_cell2mat(output2,3);
%%
implay(output2./prctile(output2(:),99.8))
%%
A = double(reshape(output,510,450,1,[]));
A  = A - min(A(:)); A = A/prctile(A(:),99.8); A(A>=1) = 1;
writerObj = VideoWriter('C:\Users\zzhu34\Documents\tempdata\mesoFig\zz159_AC_meanImg.mp4','MPEG-4');
writerObj.FrameRate = 10;
open(writerObj);
writeVideo(writerObj, double(A));
close(writerObj);
%% all functions
function img = readTiff(x)
    img = imread(x);
end 
function meanImg = loadSuite2pMeanImg(suite2ppath)
datapath = [suite2ppath filesep 'suite2p' filesep 'plane0' filesep 'Fall.mat'];
load(datapath,'ops');
meanImg = ops.meanImg; 
end 