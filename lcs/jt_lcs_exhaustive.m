function [subset,value] = jt_lcs_exhaustive(x,n,option)
%[subset,value] = jt_lcs_exhaustive(x,n,option)
%Finds the Least Correlating Subset in an exhaustive manner.
%All possible combinations of n elements are being validated.
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

% Compute all combinations
combinations = combnk(1:numvar, n);

% Compute LCS
subset = [];
value = Inf;
for i = 1:size(combinations,1)
    tmp = nanmax(nanmax(correlations(combinations(i,:),combinations(i,:))));
    if tmp<value
        value = tmp;
        subset = combinations(i,:);
    end
end