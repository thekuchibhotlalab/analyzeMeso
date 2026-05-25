nShuffle = 10;
M = {};VEpct = {};TzProj = {};
for i = 1:nShuffle
    t1=tic;
    tempOutMatDffReshape = reshape(tempOutMatDff,size(tempOutMatDff,1),size(tempOutMatDff,2),16);
    tempOutMatDffShuffle = zeros(size(tempOutMatDffReshape));
    for j = 1:size(tempOutMatDffShuffle,1)
        newLabel = randperm(16);
        tempOutMatDffShuffle(j,:,:) = tempOutMatDffReshape(j,:,newLabel);
    end 
    %for j = 1:4
    %    for k = 1:4
    %        newLabel = randperm(size(tempOutMatDff,1));
    %        tempOutMatDffShuffle(:,:,j,k) = tempOutMatDff(newLabel,:,j,k);
    %    end
    %end 
    tempOutMatDffShuffle = reshape(tempOutMatDffShuffle,size(tempOutMatDff,1),size(tempOutMatDff,2),4,4);
    [M{i},VEpct{i},TzProj{i}] = fn_runTCA_nonneg(tempOutMatDffShuffle + 1e-6);
    t2 = toc;
    disp(t2-t1)
end

save('TCA-nonneg_shuffle_learning.mat','M','VEpct','TzProj');
%%

figure; 
for i = 1:4
    subplot(1,5,i)

    imagesc(M{2}{1}.U{i}')
end 
subplot(1,5,5)
bar(M{2}{1}.lambda)
