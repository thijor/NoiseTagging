function [layout,xcorr] = jt_lcl_random(x,doplot)
%[layout,xcorr] = jt_lcl_random(x,doplot)
%Random layout.
%
% INPUT
%   x       = [m n] n variables of m samples
%   doplot  = [int] 1 if plot, 0 otherwise (0)
%
% OUTPUT
%   layout = [n n] optimal layout
%   xcorr  = [flt] max pairwise correlation in layout

n = sqrt(size(x,2));
if rem(n,1)~=0; error('Input x is not sufficient for a square matrix: [%d %d].',size(x)); end
if nargin<1; doplot=0; end

% Compute cross correlations
correlations = jt_correlation(x,x,'fix');

% Random layout
layout = randperm(n^2)';
neighbours = jt_findneighbours(layout);
xcorr = jt_findworstneighbours(neighbours,correlations);

% Reshape layout
layout = reshape(layout,[1 n^2]);

if doplot>0
    figure;
    jt_plotlcl(layout,correlations);
    title('Random')
end