function newImg = fn_applyPadding(img,desizedSize)
    pad1 = (desizedSize(1)-size(img,1))/2;
    pad2 = (desizedSize(2)-size(img,2))/2;
    newImg = zeros(desizedSize(1),desizedSize(2));
    newImg(pad1+1:end-pad1,pad2+1:end-pad2) = img;
end
