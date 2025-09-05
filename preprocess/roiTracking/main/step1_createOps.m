%% STEP 1 -- get the meanImg
function ops = step1_createOps(datapath,refIdx, refImg)
% first save ops file
ops.datapath = datapath;
mouseArea = strsplit(datapath,'\'); ops.mouseArea = mouseArea{end};
temp = strsplit(ops.mouseArea,'_'); ops.mouse = temp{1}; ops.area = temp{2};
ops.imagingPath = [datapath filesep 'imagingSession'];

% create processing path
ops.roiTrackingPath = [datapath filesep 'roiTracking'];
if ~exist(ops.roiTrackingPath,"dir"); mkdir(ops.roiTrackingPath); mkdir([ops.roiTrackingPath filesep 'refStack']); end 

ops.elastixPath = [ops.datapath filesep 'elastix'];
if ~exist(ops.elastixPath,"dir"); mkdir(ops.elastixPath); end 
mkdir([ops.elastixPath filesep 'rawElastix']);
mkdir([ops.elastixPath filesep 'alignedElastix']);
mkdir([ops.elastixPath filesep 'alignedElastix_param']);

% process mean image from suite2p if necessary, ignore this step now
%fn_splitSuite2pSessionImg(ops.imagingPath, ops.roiTrackingPath);
output = fn_dirfun(ops.imagingPath,@saveSuite2pMeanImg);

meanImgEnhanced = cellfun(@(x)(x{1}),output,'UniformOutput',false);
meanImgEnhanced = fn_cell2mat(meanImgEnhanced,3); 
if exist('refImg')
    [meanImgEnhanced,initial_transform_coord] = fn_fastAlign(meanImgEnhanced,'refImg',refImg);
else
    [meanImgEnhanced,initial_transform_coord] = fn_fastAlign(meanImgEnhanced,'center');
end 
ops.meanImgEnhanced = round(meanImgEnhanced*5000); 

ops.imagingFilename = cellfun(@(x)(x{2}),output,'UniformOutput',false);
tempCorr = reshape(meanImgEnhanced,size(meanImgEnhanced,1)*size(meanImgEnhanced,2),[]);
tempCorr = corr(tempCorr);
[~,tempIdx] = max(sum(tempCorr,1));

if ~exist('refIdx');  refIdx = tempIdx; end 
ops.refIdx = refIdx;
ref = ops.meanImgEnhanced(:,:,refIdx);ops.ref = ref; ops.refName = ops.imagingFilename{refIdx};

% save data
save([ops.datapath filesep '\ops.mat'],'ops','initial_transform_coord');
for i = 1:size(ops.meanImgEnhanced,3)
    meanImg = ops.meanImgEnhanced(:,:,i); 
    save([ops.elastixPath filesep 'rawElastix'  filesep ops.mouseArea '_session' num2str(i,'%02d') '.mat'],'meanImg');
end 
save([ops.elastixPath filesep '\refImg.mat'],'ref');
fn_saveMP4(ops.meanImgEnhanced,[ops.elastixPath filesep 'rawElastix' filesep ops.mouseArea '_enhancedImg.mp4']);

    function [meanImgEnhanced,filepath] = saveSuite2pMeanImg(suite2ppath)
        filepath = suite2ppath;
        suite2ppath = [suite2ppath filesep 'suite2p' filesep 'plane0' filesep 'Fall.mat'];
        suite2pOps = load(suite2ppath,'ops');
        meanImg = suite2pOps.ops.meanImg'; 
        meanImgEnhanced = enhancedImage(meanImg);    
    end 

end 




