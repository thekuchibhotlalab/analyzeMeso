function mimg = enhancedImage(inputImg, zscoreLim,diameter)
    if nargin == 1; zscoreLim = 6; diameter = [3 3]; 
    elseif nargin == 2; diameter = [3 3];
    end 
        
    xrange = [1 size(inputImg,1)]; yrange = [1 size(inputImg,2)]; 

    I = double(inputImg);
    Ly = length(yrange(1):yrange(2));
    Lx = length(xrange(1):xrange(2));
    spatscale_pix = diameter(2); aspect = diameter(1)/diameter(2);
    diameter = 4*[spatscale_pix * aspect, spatscale_pix] + 1;
    Imed = medfilt2(I, diameter);
    I = I - Imed;
    Idiv = medfilt2(abs(I), diameter);
    I = I ./ (1e-10 + Idiv);

    mimg1 = -zscoreLim;
    mimg99 = zscoreLim;
    mimg0 = I;
    
    mimg0 = mimg0(xrange(1):xrange(2), yrange(1):yrange(2));
    mimg0 = (mimg0 - mimg1) / (mimg99 - mimg1);
    mimg0 = max(0,min(1,mimg0));
    mimg = min(mimg0) .* ones(Lx,Ly);
    mimg(xrange(1):xrange(2), yrange(1):yrange(2)) = mimg0;
end 