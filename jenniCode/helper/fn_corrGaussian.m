function weighted_corr = fn_corrGaussian(patch1, patch2)
sz = size(patch1);
[X, Y] = meshgrid(1:sz(2), 1:sz(1));
cx = (sz(2)+1)/2;  % center x
cy = (sz(1)+1)/2;  % center y
sigma = min(sz)/5;
W = exp(-((X - cx).^2 + (Y - cy).^2) / (2*sigma^2));  % Gaussian weight

% Step 2: Flatten
x = patch1(:);
y = patch2(:);
w = W(:);

% Step 3: Weighted means
wx_mean = sum(w .* x) / sum(w);
wy_mean = sum(w .* y) / sum(w);

% Step 4: Weighted covariance and variances
cov_xy = sum(w .* (x - wx_mean) .* (y - wy_mean)) / sum(w);
var_x = sum(w .* (x - wx_mean).^2) / sum(w);
var_y = sum(w .* (y - wy_mean).^2) / sum(w);

% Step 5: Weighted correlation
weighted_corr = cov_xy / sqrt(var_x * var_y);

%fprintf('Weighted correlation: %.4f\n', weighted_corr);

end 