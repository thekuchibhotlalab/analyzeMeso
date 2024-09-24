function zstack_aligned = fn_fastAlignStack(ztack)
zstack_aligned = nan(size(ztack));
for i = 1:size(ztack,4)
    [~,transform_coord1] = sbxalignxMat(ztack(:,:,:,i),1:size(ztack,3));
    for j=1:size(ztack,3); zstack_aligned(:,:,j,i) = circshift(ztack(:,:,j,i),transform_coord1(j,:)); end
end
zstack_aligned = squeeze(mean(zstack_aligned,3));


end