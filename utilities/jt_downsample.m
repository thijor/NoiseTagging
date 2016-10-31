function [v] = jt_downsample(v,rate,dim)
%[v] = jt_downsample(v,rate,dim)
%Downsamples a cell, array or matrix with a certain rate directly 
%Note: no filters involved
%
% INPUT
%   v    = [N-D]  matrix to be downsampled
%        = [cell] cell to be downsampled
%   rate = [int]  rate at which to downsample 
%   dim  = [int]  dimension along which to downsample (2)
% 
% OUTPUT
%   v = [N-D]  downsampled matrix
%       [cell] cell with individual downsampled variables

if nargin<3||isempty(dim); dim=2; end

% Downsample
if iscell(v)
    for i = 1:numel(v)
        v{i} = jt_downsample(v{i}, rate, dimension);
    end
else
    if dim == 2
        v = v(1:rate:end,:); %downsaple columns
    else
        v = v(:,1:rate:end); %downsample rows
    end
end