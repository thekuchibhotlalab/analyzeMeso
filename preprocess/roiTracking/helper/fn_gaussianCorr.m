function [corr_val, G] = fn_gaussianCorr(imgA, imgB, sigma_factor)
% weighted_corr2 computes the 2D Pearson correlation coefficient weighted 
% by a 2D Gaussian kernel centered on the image.
%
% Inputs:
%   imgA - First 2D matrix (image).
%   imgB - Second 2D matrix (image), must be the same size as imgA.
%   sigma_factor - (Optional) Controls the width of the Gaussian. 
%                  Sigma is calculated as min(rows, cols) * sigma_factor.
%                  Default: 0.25 (so the Gaussian is 1/4 of the min dim).
%
% Outputs:
%   corr_val - The weighted 2D Pearson correlation coefficient.
%   G        - The 2D Gaussian kernel used for weighting.

    if ~isequal(size(imgA), size(imgB))
        error('Input images must be the same size.');
    end
    
    if nargin < 3
        sigma_factor = 0.4; % Default sigma factor
    end

    % Get image dimensions
    [rows, cols] = size(imgA);

    % --- 1. Create the 2D Gaussian Weighting Kernel ---
    
    % Create coordinate grids
    [X, Y] = meshgrid(1:cols, 1:rows);
    
    % Find center
    centerX = cols / 2;
    centerY = rows / 2;
    
    % Define Gaussian width (sigma)
    sigma = min(rows, cols) * sigma_factor;
    
    % Calculate the Gaussian kernel
    G = exp(-(((X - centerX).^2) + ((Y - centerY).^2)) / (2 * sigma^2));
    
    % Normalize the kernel (optional, but good practice for weighted mean)
    G = G / sum(G(:)); 

    % --- 2. Calculate Weighted Pearson Correlation ---
    
    % Ensure inputs are double
    A = double(imgA);
    B = double(imgB);

    % Calculate weighted means
    meanA_w = sum(G(:) .* A(:)) / sum(G(:));
    meanB_w = sum(G(:) .* B(:)) / sum(G(:));

    % Calculate centered (mean-subtracted) values
    A_centered = A - meanA_w;
    B_centered = B - meanB_w;

    % Calculate weighted covariance (numerator)
    cov_w = sum(G(:) .* A_centered(:) .* B_centered(:));

    % Calculate weighted standard deviations (for denominator)
    stdA_w = sqrt(sum(G(:) .* A_centered(:).^2));
    stdB_w = sqrt(sum(G(:) .* B_centered(:).^2));

    % Calculate the final weighted correlation
    corr_val = cov_w / (stdA_w * stdB_w);

end