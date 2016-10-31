function [matrix] = jt_cell2mat(cell)
%[matrix] = jt_cell2mat(cell)
%Converts cell to matrix. 
%
% INPUT
%   cell = [cell] cell to be converted
%
% OUTPUT
%   matrix = [n m] matrix containing each cell in a column

% Make sure cells contain equal sized vectors
numvars = numel(cell);
lenvars = cellfun(@numel, cell);
if numel(unique(lenvars))>1
    multiple = jt_lcm(lenvars);
    for i=1:numvars
        cell{i} = double(repmat(cell{i}, [multiple/lenvars(i), 1]));
    end
end

% Convert to matrix
matrix = cell2mat(cell);

