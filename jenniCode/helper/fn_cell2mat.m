function [mat,cellSize] = fn_cell2mat(C,dim)

if nargin == 1; dim = 1; end

mat = [];
cellSize = cell(length(C));

for i = 1:length(C)
    tempC = C{i};
    mat = cat(dim,mat,tempC);
    cellSize{i} = size(C{i});
end

end