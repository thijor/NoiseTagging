function [range] = jt_lcs_eval(subset,xcors)
%[range] = jt_lcs_eval(subset,xcors)
% Evaluate least correlating subset.
%
% INPUT
%   subset = [n 1] subset
%   xcors  = [n n] cross-correlations of all variables
%
% OUTPUT
%   range = [1 4] Evaluations: min, max, mean, std

n = numel(subset);

% Ignore diagonal
xcors(logical(eye(n))) = NaN;

% Estimate range
range = [nanmax(xcors(:)) nanmean(xcors(:)) nanmin(xcors(:)) nanstd(xcors(:))];