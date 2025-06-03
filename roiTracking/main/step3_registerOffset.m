function step3_registerOffset(datapath)

load([datapath filesep 'ops.mat'],'ops');
load([datapath filesep 'alignedOps.mat' ],'alignedOps');


refpath = [ops.roiTrackingPath filesep 'refStack' ];
refName = dir([refpath filesep '*.h5']);  refName = refName(1).name;
ops.refStackPath = [refpath filesep refName];
refStack = loadRef(ops.refStackPath);
savingPath = [ops.roiTrackingPath filesep 'offsetEvaluation'];
mkdir(savingPath);
Pix = 100;

tic;
for i= 1:size(alignedOps.suite2pImg,3)
    for k = 1:size(refStack,3)
        [tempAligned,tempShift] = fn_fastAlign(cat(3, alignedOps.suite2pImg(:,:,i),refStack(:,:,k)),'center');
        refStack(:,:,k) = tempAligned(:,:,2);
    end 
    [offsetMap,offsetImg,offsetX,offsetY] = fn_registerImg2Stack(refStack, alignedOps.suite2pImg(:,:,i), Pix);
    t = toc; disp(['day ' int2str(i) ', time = ' num2str(t) ' sec'])
    save([savingPath filesep 'session_' int2str(i) '.mat'],'offsetMap','offsetImg','offsetX','offsetY');
end 


end 

function [meanStack_enhanced,meanStack] = loadRef(refname)
    if strcmp(refname(end-1:end),'h5')
        refStack = double(h5read(refname, '/data', [1 1 1], [Inf Inf Inf]));
    else; disp('FILENAME IS NOT h5, check'); end
    
    framePerPlane = 20;
    refStack = reshape(refStack,size(refStack,1),size(refStack,2),framePerPlane,[]);
    meanStack = nan(size(refStack,1),size(refStack,2),size(refStack,3));
    meanStack_enhanced = nan(size(refStack,1),size(refStack,2),size(refStack,3));
    for i = 1:size(refStack,4)
        tempStack = fn_fastAlign(refStack(:,:,:,i));
        meanStack(:,:,i) = imboxfilt(nanmean(tempStack,3),[3 3]);
        meanStack_enhanced(:,:,i) = enhancedImage(meanStack(:,:,i),6);
    end 
    meanStack = fn_fastAlign(meanStack,'center');
    meanStack_enhanced = fn_fastAlign(meanStack_enhanced,'center');
end 

