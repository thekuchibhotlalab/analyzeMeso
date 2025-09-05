function out = fn_fastAlignTwoImgPatchwarp(refImg, targImg)

patchwarp_results = patchwarp_across_sessions(refImg, targImg,'euclidean','affine', 6, 0.15, 0);

out = patchwarp_results.image2_warp2;

end 