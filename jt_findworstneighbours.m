function [value,pair] = jt_findworstneighbours(p,r)
%[value pair] = jt_findworstneighbours(p,r)
%
% INPUT
%   p = [m 2]     all neighbour pairs
%   r = [n^2 n^2] cross correlations of the n variables
%
% OUTPUT
%   value = [flt]     the worst correlation
%   pair  = [int int] the two labels of the worst neighbouring pair

n = sqrt(size(r,2));
[value,idx] = max(r(sub2ind([n^2 n^2],p(:,1),p(:,2))));
pair = p(idx,:);
