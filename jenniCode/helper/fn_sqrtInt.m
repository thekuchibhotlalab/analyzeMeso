function [out1, out2] = fn_sqrtInt(int1)
%fn_sqrtInt - return two int closest to the sqrt of the input number
%
% Syntax: [out1, out2] = fn_sqrtInt(int1)
%
% Long description
    
out1 = floor(sqrt(int1));
out2 = ceil(int1/out1);

end