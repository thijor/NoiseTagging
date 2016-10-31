function [grid] = jt_mkgrid(layout,correlations)
%[grid] = jt_mkgrid(layout,correlations)
%
% INPUT
%   layout       = [n n]     configuration of the grid
%                = [n^2 1]
%   correlations = [n^2 n^2] cross correlations of the n^2 variables
%
% OUTPUT
%   grid = [n*2-1 n*2-1] grid with maximum pairwise crosscorrelations
%                        between all points (horizontal, vertical and
%                        diagonal)

n = sqrt(size(correlations,2));
if any(size(layout)==1); layout=reshape(layout,[n,n]); end

% Fill in layout in grid with cells in between
grid = zeros(n*2-1,n*2-1);
grid(1:2:end,1:2:end) = layout;

% Compute vertical correlations (up down)
r_vert = correlations(sub2ind([n^2 n^2],layout,circshift(layout,[-1  0])));
grid(2:2:end,1:2:end) = r_vert(1:end-1,:);

% Compute horizontal correlations (left right)
r_horz = correlations(sub2ind([n^2 n^2],layout,circshift(layout,[ 0 -1]))); 
grid(1:2:end,2:2:end) = r_horz(:,1:end-1);

% Compute diagonal correlations
% (up-left down-right)
r_diag1 = correlations(sub2ind([n^2 n^2],layout,circshift(layout,[-1 -1]))); 
% (down-left up-right)
r_diag2 = correlations(sub2ind([n^2 n^2],layout,circshift(layout,[ 1 -1]))); 
grid(2:2:end,2:2:end) = max(cat(3,r_diag1(1:end-1,1:end-1),r_diag2(2:end,1:end-1)),[],3);

% Put NaNs at non correlation points
grid(1:2:end,1:2:end) = NaN;