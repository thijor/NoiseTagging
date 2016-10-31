function [c] = jt_make_mls_code(n,a)
%[c] = jt_make_mls_code(m,a)
%Generates a maximum length sequence.
% 
% INPUT
%   n = [int] register length (6)
%   a = [1 p] array of p feedback tab points ([6 1])
% 
% OUTPUT
%   c = [2^n-1 1] bits by codes

% Check input
if nargin<1||isempty(n); n=6; end
if nargin<2||isempty(a); a=[6 1]; end
    
% Create initial register
register = ones(1,n);

% Generate mls
c = zeros(2^n-1,1);
for i = 1:2^n-1
    c(i) = mod(sum(register(a)),2);
    register = [c(i) register(1:end-1)];
end