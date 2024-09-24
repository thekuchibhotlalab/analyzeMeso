function mimg = enhancedImage(inputImg, xrange,yrange)
I = double(inputImg);
Ly = length(yrange(1):yrange(2));
Lx = length(xrange(1):xrange(2));
diameter = [12,12];
spatscale_pix = diameter(2); aspect = diameter(1)/diameter(2);
diameter = 4*[spatscale_pix * aspect, spatscale_pix] + 1;
Imed = medfilt2(I, diameter);
I = I - Imed;
Idiv = medfilt2(abs(I), diameter);
I = I ./ (1e-10 + Idiv);
mimg1 = -6;
mimg99 = 6;
mimg0 = I;

mimg0 = mimg0(xrange(1):xrange(2), yrange(1):yrange(2));
mimg0 = (mimg0 - mimg1) / (mimg99 - mimg1);
mimg0 = max(0,min(1,mimg0));
mimg = min(mimg0) .* ones(Lx,Ly);
mimg(xrange(1):xrange(2), yrange(1):yrange(2)) = mimg0;