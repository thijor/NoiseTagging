function [range] = jt_lcl_eval(layout,xcors)
%[range] = jt_lcl_eval(layout,xcors)
% Evaluate least correlating layout.
%
% INPUT
%   layout = [n n]     Layout matrix 
%            [n^2 1]   Layout vector
%   xcors  = [n^2 n^2] cross-correlations of all variables
%
% OUTPUT
%   range = [1 4] Evaluations: min, max, mean, std

n = sqrt(numel(layout));
if rem(n,1)~=0; error('Input x is not a square matrix: [%d %d].',size(x)); end
if any(size(layout)==1); layout=reshape(layout,[n n]); end

% Find neighbouring pairs
[neighbours] = jt_findneighbours(layout);

% Compute correlations between neighbours
correlations = xcors(sub2ind([n^2 n^2],neighbours(:,1),neighbours(:,2)));

% Estimate range
range = [max(correlations) mean(correlations) min(correlations) std(correlations)];