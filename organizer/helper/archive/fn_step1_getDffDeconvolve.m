%function fn_step1_parseData(animalDir, animalID)
clear; 
animalID = 'zz153_PPC'; animalDir = 'C:\Users\zzhu34\Documents\tempdata\zz153_PPC';
animalFile = fullfile(animalDir, [animalID '_TC.mat']);
load(animalFile, 'allTracesCell', 'sessionInfo', 'animalID');
run([animalID '_param.m']);


%% compute dff
sessionInfo = dealExceptions(sessionInfo,myOps.mouse);
sessionInfo.SessionImgIdx = (1:size(sessionInfo,1))';
TC = dffByDay(allTracesCell);
%% deconvolve
%if length(TC) > 150
%    [TC,sessionInfo] = organizeByDay(TC, sessionInfo);
%end 

%%
[spk,deconv_ops] = deconvolveDay(TC,myOps); 

%TC = splitBySession(TC, sessionInfo);
%spk = splitBySession(spk, sessionInfo);

save( fullfile(animalDir, [animalID '_dff_matlab.mat']), 'F','-v7.3');
save( fullfile(animalDir, [animalID '_spk_matlab.mat']), 'spk','deconv_ops','-v7.3');

%%

function [allTracesConcat,sessionInfo] = organizeByDay(allTracesCell,sessionInfo)

    correspondingIdx = fn_getUniqueTableEntry(sessionInfo, 'SessionDate');
    allTracesConcat = cell(1, length(correspondingIdx));
    temp = zeros(length(correspondingIdx),1);
    for i = 1:length(correspondingIdx)
        for j = 1: length(correspondingIdx{i})
            temp (correspondingIdx{i}(j)) = i; 
        end 
        allTracesConcat{i} = fn_cell2mat(allTracesCell(correspondingIdx{i}),2);    
    end
    sessionInfo.SessionDay = temp;
end 

function TC = dffByDay(allTracesCell)
TC = cell(1,length(allTracesCell));
for j= 1:length(allTracesCell)
    F = fn_getDff(allTracesCell{j},'method', 'perc25','baselineCorrectionPostDff', true, 'dffWindow',1000)';
    TC{j} = single(F); 
end 
end

function [spk,deconv_ops] = deconvolveDay(allTracesCell,myOps)
spk = cell(1,length(allTracesCell));
deconv_ops = cell(1,length(allTracesCell));

for j= 1:length(allTracesCell)
    disp(['Processing session' int2str(j)])
    [tempSpk,c,p] = fn_deconvolveMeso(allTracesCell{j}); 
    b = cellfun(@(x)(x.b),p,'UniformOutput',false); b = fn_cell2mat(b);
    pars = cellfun(@(x)(x.pars),p,'UniformOutput',false);  pars = fn_cell2mat(pars);
    t_half = -log(2) ./ log(pars);
    t_half = t_half * 1000 / myOps.frameRate;

    spk{j} = single(tempSpk);
    
    deconv_ops{j}.pars = pars; 
    deconv_ops{j}.t_half = t_half; 
    deconv_ops{j}.b = b; 
end 

end 


function allTracesSession = splitBySession(targetCell, sessionInfo)
    correspondingIdx = fn_getUniqueTableEntry(sessionInfo, 'SessionDay');
    allTracesSession = cell(1,size(sessionInfo,1)); 
    for i = 1:length(correspondingIdx)
        tempFrames = sessionInfo.SessionFrames(correspondingIdx{i});
        tempReadIdx = [0;cumsum(tempFrames)];
        for j = 1:length(correspondingIdx{i})
            allTracesSession{correspondingIdx{i}(j)} = targetCell{i}(:,1+tempReadIdx(j):tempReadIdx(j+1));    
        end 
    end

end 







%end
