function [v] = jt_upsample(v,rate,dim)
%[v] = jt_upsample(v,rate,dim)
%Upsamples an array or matrix with a certain rate directly
%
% INPUT
%   v    = [N-D]  matrix to be upsampled
%        = [cell] cell to be upsampled
%   rate = [int]  rate at which to upsample 
%   dim  = [int]  dimension along which to upsample (1)
% 
% OUTPUT
%   v = [N-D]  upsampled matrix
%       [cell] cell with individual upsampled variables

if nargin<3||isempty(dim); dim=1; end

% variables
[r,c] = size(v);

% Upsample
if iscell(v)
    for i = 1:numel(v)
        v{i} = jt_upsample(v{i}, rate, dim);
    end
else
    if dim == 1
        v = reshape(permute(repmat(v, [1 1 rate]), [3 1 2]), rate*r, c);
    else
        v = reshape(permute(repmat(v, [1 1 rate]), [1 3 2]), r, rate*c);
    end
end