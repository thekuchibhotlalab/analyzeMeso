function [mat] = fn_cell2matFillNan(C)

maxLen1 = 0; maxLen2 = 0;

for i = 1:length(C)
    tempC = C{i};
    len1 = size(tempC,1); len2 = size(tempC,2);
    maxLen1 = max(maxLen1, len1); maxLen2 = max(maxLen2, len2);
end

if maxLen1 == 1; selectdim = 2; 
elseif maxLen2 == 1; selectdim = 1; 
else error('ERROR -- Check matrix size in cell, should be 1xn or nx1');
end


if selectdim == 1; mat = nan(maxLen1,length(C));
elseif selectdim == 2; mat = nan(length(C),maxLen2);
end

for i = 1:length(C)
    tempC = C{i};
    if ~isempty(tempC)
        if selectdim == 1
            len1 = size(tempC,1);
            mat(1:len1,i) = tempC;
        elseif selectdim == 2
            len2 = size(tempC,2);
            mat(i,1:len2) = tempC;  
        end
    end
end


end