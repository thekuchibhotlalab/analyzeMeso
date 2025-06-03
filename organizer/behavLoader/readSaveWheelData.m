function readSaveWheelData(mouseName)
    
datapath = ['G:\ziyi\mesoData\' mouseName '_behavior'];
sessionTable = fn_organizeTxt([datapath filesep 'txt']);

for i = 1:height(sessionTable)
    tic;
    [wheelFrame, wheelTime] = fn_readWheel(sessionTable.CoreFilename{i});
    sessionTable.wheelFrame{i} = single(wheelFrame);
    sessionTable.wheelTime{i} = single(wheelTime);
    disp(['session ' int2str(i) ' done!'])
    toc; 
end 

save([datapath filesep mouseName '_wheelData.mat'],'sessionTable')


end 