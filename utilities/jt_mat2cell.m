function [cell] = jt_mat2cell(matrix)
%[cell] = jt_mat2cell(matrix)
%Converts matrix to cell. 
%
%Each column will correspond to a cell in the cell-array.
%
% INPUT
%   matrix = [n m] matrix ontaining each cell in a column
%
% OUTPUT
%   cell = [n-cell] cell to be converted

% Convert to cell
[r,c] = size(matrix);
cell = mat2cell(matrix, r, ones(1,c));