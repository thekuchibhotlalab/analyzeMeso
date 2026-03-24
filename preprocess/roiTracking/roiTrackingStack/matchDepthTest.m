clear; tic;
roiOps.nROI = 2;
roiOps.yLen = [676 676];
stackOps.nSlice = 60; 
stackOps.nFrame = 20; 
%filename = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260125_stack_00001.tif'; 
filename = 'G:\ziyi\mesoData\zz179\0120\zz179_20260120_stack_00001.tif'; 
[filepath,tempname,~] = fileparts(filename);filename_save = [filepath filesep tempname '.mat'];
[refStack, refStackMean] = loadRef(filename,roiOps, stackOps);
save(filename_save,'refStack','refStackMean');
toc;
%% load the movies
%filename_match = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260117_PT_00001.tif'; 
filename_match = 'G:\ziyi\mesoData\zz179\0203\zz179_20260204_2AFC_00001.tif'; 

matchStack = TIFFStack(filename_match);
maxFrames = min([size(matchStack,3),200]); 
tempMovie = matchStack(:,:,end-maxFrames+1:end);
[matchMovies, ~] = fn_splitFOV(tempMovie, roiOps);

matchImg = {}; matchImgMean = {}; 
for i = 1:length(matchMovies)
    tempStack = matchMovies{i};
    temp = fn_fastAlign(tempStack);
    matchImgMean{i} = nanmean(temp,3); 
    %matchImgMean = imboxfilt(nanmean(temp,3),[3 3]);
    matchImg{i} = enhancedImage(matchImgMean{i},6);
end 
[filepath,tempname,~] = fileparts(filename_match); filename_save = [filepath filesep tempname '.mat'];
save(filename_save,'matchImg','matchImgMean');

%% get offsetmap
clear; 
filename_match = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260212_2AFC_00001.mat'; 
filename = 'C:\Users\zzhu34\Documents\tempdata\zz177\zz177_20260125_stack_00001.mat'; 
load(filename,'refStack','refStackMean');
load(filename_match,'matchImg','matchImgMean');

Pix = 100;

tempRefStack = refStack; offsetMap = {};
for i = 1:length(matchImg)
    tic; 
    for k = 1:size(tempRefStack,3)
        tempMatch = imboxfilt(matchImg{i},[3 3]);
        tempStack = imboxfilt(tempRefStack{i}(:,:,k),[3 3]);

        [tempAligned,tempShift] = fn_fastAlign(cat(3, tempMatch,tempStack),'center');
        tempRefStack{i}(:,:,k) = tempAligned(:,:,2);

    end 
    [offsetMap{i},offsetImg,offsetX,offsetY] = fn_registerImg2Stack(tempRefStack{i}, tempMatch , Pix);
    tempMeanOffset = nanmean(offsetMap{i}(:)) - 30;
    figure; imagesc(offsetMap{i}-30); colormap redblue; clim([-5 5]); title(['ROI ' int2str(i) ', offset ' num2str(tempMeanOffset) ' um deeper'])
    toc;
end 

%% test non-rigid code
[registered, tform]  = affineRegistrationIntensity(matchImg{1},refStack{1}(:,:,30));

[Ireg, dx, dy] = nonrigid_register_patch(matchImg{1}, registered, ...
                                         128, ...   % block size
                                         16, ...   % overlap
                                         15);  
%[reg_img, rigid_img, flow_map] = CalciumImagingRegistration(matchImg{1},refStack{1}(:,:,30), 50);


%% non-rigid alignment code

% load current image
 
% do fast alignment to check z-depth
%save([savingPath filesep 'session_' int2str(i) '.mat'],'offsetMap','offsetImg','offsetX','offsetY');

% 1. Load your data
% Example: Assuming 'target' and 'ref' are 2D double matrices
% If loading from TIF:
% ref = double(imread('my_data.tif', 1));
% target = double(imread('my_data.tif', 10));

% 2. Run Registration
% Block size 100 is typical for Suite2p, but adjust depending on the 
% density of your signal.
[reg_img, rigid_img, flow_map] = CalciumImagingRegistration(target, ref, 50);

% 3. Visualization
figure;
subplot(2,2,1); imagesc(ref); title('Reference'); axis image; colormap gray;
subplot(2,2,2); imagesc(target); title('Original Target'); axis image;
subplot(2,2,3); imagesc(rigid_img); title('Step 1: Rigid Only'); axis image;
subplot(2,2,4); imagesc(reg_img); title('Step 2: Non-Rigid (Final)'); axis image;

% Visualize the Shift Map
figure;
imagesc(flow_map(:,:,1)); colorbar; title('X-shifts (pixels)');
%% FUNCTION
function [registered, tform] = affineRegistrationIntensity(fixed, moving)

    % Convert to grayscale if needed
    if size(fixed,3) == 3
        fixed = rgb2gray(fixed);
    end
    if size(moving,3) == 3
        moving = rgb2gray(moving);
    end

    % Convert to double (recommended)
    fixed  = im2double(fixed);
    moving = im2double(moving);

    % Similarity metric (like Elastix)
    [optimizer, metric] = imregconfig('multimodal');
    % Use 'monomodal' if images are same modality

    % Estimate affine transform
    tform = imregtform(moving, fixed, ...
                       'affine', ...
                       optimizer, ...
                       metric);

    % Warp moving image
    Rfixed = imref2d(size(fixed));
    registered = imwarp(moving, tform, 'OutputView', Rfixed);
end


function [meanStack_enhanced,meanStack] = loadRef(refname, roiOps, stackOps)
    
    refstack = TIFFStack(refname);

    [roiMovies, ~] = fn_splitFOV(refstack, roiOps);
    meanStack = {}; meanStack_enhanced = {};
    for i = 1:length(roiMovies)
        tempStack = roiMovies{i};
        tempStack = reshape(tempStack,size(tempStack,1),size(tempStack,2),stackOps.nFrame,stackOps.nSlice);
        meanStack_temp = nan(size(tempStack,1),size(tempStack,2),size(tempStack,4));
        meanStack_enhanced_temp = nan(size(tempStack,1),size(tempStack,2),size(tempStack,4));
        for j = 1:size(tempStack,4)
            temp = fn_fastAlign(tempStack(:,:,:,j));
            meanStack_temp(:,:,j) = imboxfilt(nanmean(temp,3),[3 3]);
            meanStack_enhanced_temp(:,:,j) = enhancedImage(meanStack_temp(:,:,j),6);
        end 
        meanStack{i} = fn_fastAlign(meanStack_temp,'center');
        meanStack_enhanced{i} = fn_fastAlign(meanStack_enhanced_temp,'center');

    end 

end 


function [final_reg_img, rigid_reg_img, displacement_field] = CalciumImagingRegistration(moving_img, fixed_img, blockSize)
% CALCIUMIMAGINGREGISTRATION Aligns 2D calcium images using a 2-step process.
%
%   [final, rigid, flow] = CalciumImagingRegistration(moving, fixed, blockSize)
%
%   INPUTS:
%       moving_img: The 2D image to be aligned (double or single).
%       fixed_img:  The 2D reference image (double or single).
%       blockSize:  (Optional) Size of blocks for non-rigid step (default 100).
%                   Can be scalar (square) or [rows cols].
%
%   OUTPUTS:
%       final_reg_img:      The final non-rigidly aligned image.
%       rigid_reg_img:      The result after Step 1 (Rigid Affine only).
%       displacement_field: The X/Y shift map used for the non-rigid warp.

    if nargin < 3
        blockSize = [100 100];
    elseif isscalar(blockSize)
        blockSize = [blockSize blockSize];
    end

    % Ensure images are double for calculation
    moving_img = double(moving_img);
    fixed_img = double(fixed_img);

    % STEP 1: Rigid Affine Transformation
    % Mimics SimpleElastix rigid/affine alignment using MATLAB's optimizer
    fprintf('Step 1: Computing Rigid Affine Transformation...\n');
    
    % Configure optimizer (Monomodal is standard for same-modality images)
    [optimizer, metric] = imregconfig('monomodal');
    
    % Tune optimizer for better convergence on calcium data
    optimizer.MaximumIterations = 200;
    optimizer.MinimumStepLength = 1e-4;
    
    % Compute Affine Transform (Translation, Rotation, Scale, Shear)
    tform = imregtform(moving_img, fixed_img, 'affine', optimizer, metric);
    
    % Apply Rigid Transform
    Rfixed = imref2d(size(fixed_img));
    rigid_reg_img = imwarp(moving_img, tform, 'OutputView', Rfixed);

    % STEP 2: Fast Non-Rigid Block Matching (Suite2p Style)
    fprintf('Step 2: Computing Non-Rigid Block Alignment...\n');
    
    [h, w] = size(rigid_reg_img);
    by = blockSize(1);
    bx = blockSize(2);
    
    % Define Grid centers
    num_y = ceil(h / by);
    num_x = ceil(w / bx);
    
    % Pre-allocate shift vectors for blocks
    grid_shifts_x = zeros(num_y, num_x);
    grid_shifts_y = zeros(num_y, num_x);
    
    % Coordinates of block centers
    grid_cy = zeros(num_y, 1);
    grid_cx = zeros(num_x, 1);
    
    % Gaussian Window to prevent edge artifacts in FFT
    win = window2(by, bx, @hann); 

    % Loop through blocks
    for i = 1:num_y
        for j = 1:num_x
            % Define block boundaries
            y_start = (i-1)*by + 1;
            y_end = min(i*by, h);
            x_start = (j-1)*bx + 1;
            x_end = min(j*bx, w);
            
            % Save Center points for interpolation later
            grid_cy(i) = (y_start + y_end) / 2;
            grid_cx(j) = (x_start + x_end) / 2;
            
            % Extract blocks
            block_mov = rigid_reg_img(y_start:y_end, x_start:x_end);
            block_fix = fixed_img(y_start:y_end, x_start:x_end);
            
            % Handle edge cases (last blocks might be smaller)
            [curr_h, curr_w] = size(block_mov);
            if curr_h ~= by || curr_w ~= bx
                 curr_win = window2(curr_h, curr_w, @hann);
            else
                 curr_win = win;
            end
            
            % --- Phase Correlation ---
            % 1. Apply Window
            b_mov_w = (block_mov - mean(block_mov(:))) .* curr_win;
            b_fix_w = (block_fix - mean(block_fix(:))) .* curr_win;
            
            % 2. FFT
            F_mov = fft2(b_mov_w);
            F_fix = fft2(b_fix_w);
            
            % 3. Cross Power Spectrum
            R = F_fix .* conj(F_mov);
            R = R ./ (abs(R) + eps); % Normalize magnitude (Phase Correlation)
            
            % 4. Cross Correlation Map
            cc = fftshift(real(ifft2(R)));
            
            % 5. Find Peak with Subpixel Accuracy
            [dy, dx] = find_subpixel_peak(cc);
            
            grid_shifts_y(i, j) = dy;
            grid_shifts_x(i, j) = dx;
        end
    end
    
    % Smooth the vector field (Optional but recommended for stability)
    % Suite2p does this via NRsm; here we use a gaussian filter on the grid
    grid_shifts_x = imgaussfilt(grid_shifts_x, 0.5); 
    grid_shifts_y = imgaussfilt(grid_shifts_y, 0.5);

    %% Create Dense Pixel Shift Map (Interpolation)
    fprintf('Step 3: Interpolating and Warping...\n');
    
    [X_grid, Y_grid] = meshgrid(grid_cx, grid_cy);
    [X_full, Y_full] = meshgrid(1:w, 1:h);
    
    % Interpolate sparse grid shifts to full image resolution
    % Use 'spline' or 'cubic' for smooth transitions
    disp_x = interp2(X_grid, Y_grid, grid_shifts_x, X_full, Y_full, 'spline');
    disp_y = interp2(X_grid, Y_grid, grid_shifts_y, X_full, Y_full, 'spline');
    
    % Handle NaN values at edges (from extrapolation)
    disp_x(isnan(disp_x)) = 0;
    disp_y(isnan(disp_y)) = 0;

    % Store displacement field (Dx, Dy)
    displacement_field = cat(3, disp_x, disp_y);
    
    %% Apply Non-Rigid Warp
    final_reg_img = imwarp(rigid_reg_img, displacement_field, 'linear');

    fprintf('Registration Complete.\n');
end


function [dy, dx] = find_subpixel_peak(cc)
    % Finds the peak of cross-correlation and refines using Gaussian fit
    [max_val, idx] = max(cc(:));
    [y_peak, x_peak] = ind2sub(size(cc), idx);
    
    [h, w] = size(cc);
    center_y = ceil(h/2);
    center_x = ceil(w/2);
    
    % Integer shift relative to center
    dy_int = y_peak - center_y;
    dx_int = x_peak - center_x;
    
    % Boundary check for subpixel fit
    if y_peak > 1 && y_peak < h && x_peak > 1 && x_peak < w
        % Extract 3x3 patch around peak
        patch = cc(y_peak-1:y_peak+1, x_peak-1:x_peak+1);
        
        % Gaussian Fit approximation (using log of data)
        % 1D gaussian fit on X and Y axes of the patch
        try
            x_vec = patch(2, :); % Center row
            y_vec = patch(:, 2); % Center col
            
            % Subpixel offset formula using log of intensities (Gaussian assumption)
            % d = (ln(left) - ln(right)) / (2*ln(left) - 4*ln(center) + 2*ln(right))
            eps_val = 1e-6; % Prevent log(0)
            lx = log(max(x_vec, eps_val));
            ly = log(max(y_vec, eps_val));
            
            delta_x = (lx(1) - lx(3)) / (2*lx(1) - 4*lx(2) + 2*lx(3));
            delta_y = (ly(1) - ly(3)) / (2*ly(1) - 4*ly(2) + 2*ly(3));
            
            % Sanity check: delta should be within [-1, 1]
            if abs(delta_x) > 1; delta_x = 0; end
            if abs(delta_y) > 1; delta_y = 0; end
            
            dx = dx_int + delta_x;
            dy = dy_int + delta_y;
        catch
            dx = dx_int;
            dy = dy_int;
        end
    else
        dx = dx_int;
        dy = dy_int;
    end
end

function win = window2(rows, cols, winfunc)
    % Creates a 2D window (e.g. Hann)
    wc = winfunc(cols);
    wr = winfunc(rows);
    [maskr, maskc] = meshgrid(wc, wr);
    win = maskr .* maskc;
end

function [dy, dx] = phasecorr2d(I1, I2, maxShift)

F1 = fft2(I1);
F2 = fft2(I2);

R = F1 .* conj(F2);
R = R ./ (abs(R) + eps);

cc = real(ifft2(R));
cc = fftshift(cc);

center = floor(size(cc)/2) + 1;

% Limit search window
ymin = center(1) - maxShift;
ymax = center(1) + maxShift;
xmin = center(2) - maxShift;
xmax = center(2) + maxShift;

cc_crop = cc(ymin:ymax, xmin:xmax);

[~, idx] = max(cc_crop(:));
[py, px] = ind2sub(size(cc_crop), idx);

dy = py - (maxShift+1);
dx = px - (maxShift+1);

end

function [Ireg, dx_full, dy_full] = nonrigid_register_patch(Iref, Imov, blockSize, overlap, maxShift)

% Convert to double
Iref = im2double(Iref);
Imov = im2double(Imov);

[Ly, Lx] = size(Iref);

% ---- 1. Create block grid ----
ystart = 1:(blockSize-overlap):(Ly-blockSize+1);
xstart = 1:(blockSize-overlap):(Lx-blockSize+1);

ny = length(ystart);
nx = length(xstart);

dx_block = zeros(ny, nx);
dy_block = zeros(ny, nx);

% ---- 2. Phase correlation per block ----
for iy = 1:ny
    for ix = 1:nx
        
        y = ystart(iy);
        x = xstart(ix);
        
        refPatch = Iref(y:y+blockSize-1, x:x+blockSize-1);
        movPatch = Imov(y:y+blockSize-1, x:x+blockSize-1);
        
        [dy, dx] = phasecorr2d(refPatch, movPatch, maxShift);
        
        dx_block(iy,ix) = dx;
        dy_block(iy,ix) = dy;
    end
end

% ---- 3. Smooth motion field ----
dx_block = imgaussfilt(dx_block, 1);
dy_block = imgaussfilt(dy_block, 1);

% ---- 4. Upsample to full resolution ----
[xb, yb] = meshgrid(xstart + blockSize/2, ystart + blockSize/2);
[X, Y] = meshgrid(1:Lx, 1:Ly);

dx_full = interp2(xb, yb, dx_block, X, Y, 'linear', 0);
dy_full = interp2(xb, yb, dy_block, X, Y, 'linear', 0);

% ---- 5. Warp image ----
Xnew = X + dx_full;
Ynew = Y + dy_full;

Ireg = interp2(X, Y, Imov, Xnew, Ynew, 'linear', 0);

end

