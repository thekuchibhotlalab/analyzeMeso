function img = fn_readTiff(filename,frame)
if nargin == 1; frame = inf; end 
    
img = tiffreadVolume(filename,'PixelRegion', {[1 inf], [1 inf], frame});

end 