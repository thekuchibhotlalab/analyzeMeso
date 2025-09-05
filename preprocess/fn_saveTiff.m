function fn_saveTiff(img,tiffName, tiffPath)
if nargin == 2; tiffPath = '';
elseif nargin == 1; tiffPath = '';tiffName='img1.tiff';
end 

% Step 2: Normalize data (if necessary)
% TIFF files require data to be in specific ranges depending on the data type
img = uint16(rescale(img, 0, 65535));  % Convert to uint16 and scale to full range

% Step 3: Save as a TIFF file
imwrite(img, [tiffPath filesep tiffName]);  % Replace with desired output file name


end 