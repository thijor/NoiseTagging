function [subset,value] = jt_lcs_incremental(x,n,option)
%[subset,value] = jt_lcs_incremental(x,n,option)
%Finds the Least Correlating Subset in an incremental manner.
%
%First the least correlating couple is found. At each following the element
%that correlates the least with the current subset is added.
%
% INPUT
%   x = [t m] t samples of m variables
%   n = [int] number of variables in subset
%
% OPTIONS
%   option = [str] lock|shift correlations (lock)
%
% OUTPUT
%   subset = [1 n] positions of the subset in x
%   value  = [flt] correlation value of the subset

if nargin<3||isempty(option); option='fix'; end;
numvar = size(x,2);
if n>numvar; error('x does not hold n variables!'); end

% Compute correlations
correlations = jt_correlation(x,x,option);
correlations = max(correlations,[],3);
correlations(logical(eye(numvar))) = NaN; %ignore diagonal

% Determine first element
[~,p] = nanmin(correlations(:));
[el1,el2] = ind2sub(size(correlations),p);
subset = [el1,el2];

% Determine entire LCS
if n>2
    stack  = find(~ismember(1:numvar, subset));
    for i = 1:n-2
        matrix = correlations(stack, subset);
        [~,p] = nanmin(nanmax(matrix),[],2);
        [r,~] = ind2sub(size(matrix),p);
        subset = cat(2,subset,stack(r));
        stack  = find(~ismember(1:numvar, subset)); 
    end
end

% Compute output
subset = sort(subset,'ascend');
value = nanmax(nanmax(correlations(subset, subset)));