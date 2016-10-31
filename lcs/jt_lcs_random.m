function [subset,value] = jt_lcs_random(x,n,option)
%[subset,value] = jt_lcs_random(x,n,option)
%Random subset.
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

% Select subset
index = randperm(numvar);

% Compute output
subset = index(1:n);
value = nanmax(nanmax(correlations(subset, subset)));