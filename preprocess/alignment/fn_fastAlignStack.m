function zstack_aligned = fn_fastAlignStack(zstack)
zstack_aligned = nan(size(zstack));
for i = 1:size(zstack,4)
    [~,transform_coord1] = sbxalignxMat(zstack(:,:,:,i),1:size(zstack,3));
    for j=1:size(zstack,3); zstack_aligned(:,:,j,i) = circshift(zstack(:,:,j,i),transform_coord1(j,:)); end
end
zstack_aligned = squeeze(mean(zstack_aligned,3));


end