function [matrix] = jt_mksymmat(n)
%[matrix] = jt_mksymmat(n)
%Generates a matrix of a certain size n which is symmetrical to the diagonal.
%It can be used, for example, as syntethic correlations.
%
% INPUT
%   n = [int] size of the square symmetrical matrix
%
% OUTPUT
%   matrix = [n n] random but symmetrical matrix

tmp = rand(n);
matrix = triu(tmp) + triu(tmp,1)';