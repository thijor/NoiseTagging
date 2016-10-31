function [w,s,i] = jt_swapmat(v, dim)
%[w,s,i] = jt_swapmat(v, dim)
%Swaps values to make sure t=0 is in front, then t=1, then t=-1, then
%t=2, then t=-2, etc. 
%
% INPUT
%   v = [N-D] matrix of multiple dimensions
%
% OPTIONS
%   dim = [int] dimension to swap (3)
%
% OUTPUT
%   w = [N-D] the swapped matrix
%   s = [1-D] the swap values
%   i = [1-D] original positions of w in v allong dim

if nargin<2; dim=3; end;

% Set swaps
n = size(v,dim);
z = ceil(n/2);
if mod(n,2)==0
    i = [0 reshape([1:z-1 ; n-1:-1:z+1],[1 n-2]) z];
else
    i = [0 reshape([1:z-1 ; n-1:-1:z],[1 n-1])];
end

% Swap
switch(dim)
    case 1
        w = v(i+1,:,:);
    case 2
        w = v(:,i+1,:);
    case 3
        w = v(:,:,i+1);
end

% Return swap values
s = i;
s(3:2:end) = s(3:2:end)-n;
i=i+1;