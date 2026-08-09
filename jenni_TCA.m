
S_plus = fn_cell2mat(cellfun(@(x)(squeeze(nanmean(x(1:20,:,:),1))),pseudopop,'UniformOutput',false),3);
S_minus = fn_cell2mat(cellfun(@(x)(squeeze(nanmean(x(61:80,:,:),1))),pseudopop,'UniformOutput',false),3);
S = cat(4,S_plus,S_minus);

S = permute(S,[2 1 3 4]);

figure; imagesc(S(:,:,1,1))

%%
R = 3;
Stensor = tensor(S);
[M,k0,info] = cp_als(Stensor,R,'maxiters',100);

%%
figure; 
subplot(1,4,1);
imagesc(corr(M.U{1})); caxis([-1 1]); colorbar

subplot(1,4,2);
imagesc(M.U{2}')

subplot(1,4,3);
imagesc(M.U{3}')

subplot(1,4,4);
imagesc(M.U{4}')

figure; plot(M.U{2})