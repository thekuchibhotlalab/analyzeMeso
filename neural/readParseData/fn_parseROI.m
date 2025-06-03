function fn_parseROI(mousePath,roiOrder,roiSize)
temp = dir(mousePath);
for k = 1:length(roiOrder)
    mkdir([mousePath filesep 'green_' roiOrder{k}]);
end 

for i = 1:length(temp)     
    tiffPath  = [mousePath filesep temp(i).name];
    fileNames = dir([tiffPath filesep '*.tif']);
    fileName = {fileNames.name};
    
    for j = 1:length(fileName)
        disp(fileName{j})
        try
            fn_saveh5(mousePath,tiffPath,fileName{j},roiOrder,roiSize);
        catch

            disp([fileName{j} ' not done!'])
        end
    end
end 

end




