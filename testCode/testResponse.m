img = double(tiffreadVolume('zz128_010423_WF_00001.tif'));


%%
imgN = img / mean(img(:));
implay(imgN)

%%

K = (1/100)*ones(10);imgSmooth = zeros(size(img));
for i = 1:size(img,3)
    temp = img(:,:,i);temp = temp / prctile(temp(:),95);
    imgSmooth(:,:,i) = conv2(temp,K,'same');
end
levels = -7:1:10;

%%
figure; imagesc(mean(imgSmooth,3))
%%
roi1 = squeeze(mean(mean(imgSmooth(2950:3000,250:450,:),1),2));
roi2 = squeeze(mean(mean(imgSmooth(2600:2650,150:350,:),1),2));

roi1 = roi1-mean(roi1);
roi2 = roi2-mean(roi2);
figure; plot(smoothdata(roi1,'movmean',10)); hold on; plot(smoothdata(roi2,'movmean',10));

legend('presumable PPC','presumable AC'); xlabel('frames'); ylabel('df/f')

%%
clear; 
img = double(tiffreadVolume('zz128_010423_AC_PPC_zstack_WF_00001.tif'));
%%
imgN = mean(img(:,:,200:2:220),3);
tempCell = cell(1,7); order = [2 1 3 4 5 6 7];
for i = 1:7
    tempCell{order(i)} = imgN( (1+(512+122)*(i-1)):(512+(512+122)*(i-1)),:);
end
imgReshape = fn_cell2mat(tempCell,2);
figure; imagesc(imgReshape/mean(imgReshape(:))); colormap gray;clim([0 6])
figure; imagesc(adapthisteq(imgReshape/mean(imgReshape(:)))); colormap gray;clim([0 2])


%%
clear; 
img = double(tiffreadVolume('AC_poke_011723_00001.tif'));
%%
imgN = mean(img(:,:,1:1:1000),3); 
imgReshape = nan(512*2,512*3);
for i = 1:2
    for j = 1:3
        tempIdx = ((i-1)*3+j);
        imgReshape((i-1)*512+(1:512),(j-1)*512+(1:512)) = imgN( (1+(512+50)*(tempIdx-1)):(512+(512+50)*(tempIdx-1)),:);
    end
end
figure; imagesc(imgReshape/mean(imgReshape(:))); colormap gray;clim([0 6])
