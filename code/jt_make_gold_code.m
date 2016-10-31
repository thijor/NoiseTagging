function [c] = jt_make_gold_code(n,a,b)
%[c] = jt_make_gold_code(m,a,b)
%Generates gold codes.
% 
% INPUT
%   n = [int] register length (6)
%   a = [1 p] array of p feedback tab points ([6 1])
%   b = [1 q] array of q feedback tab points ([6 5 2 1])
% 
% OUTPUT
%   c = [2^m-1 2^m+1] bits by codes

% Check input
if nargin<1||isempty(n); n=6; end
if nargin<2||isempty(a); a=[6 1]; end
if nargin<3||isempty(b); b=[6 5 2 1]; end

% Check if pair of fbtp is a preferred pair
if ~jt_isprefpair(n,a,b); 
    error('Invalid input: no preferred pair.'); 
end

% Generate two mls
u = jt_make_mls_code(n,a);
v = jt_make_mls_code(n,b);

% Generate gold codes
c = zeros(2^n-1,2^n+1); 
for i = 0:2^n-2
    c(:,i+1) = mod(u+circshift(v,[-i 0]),2);
end
c(:,end-1) = v;
c(:,end)   = u;