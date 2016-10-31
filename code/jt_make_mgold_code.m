function [w] = jt_make_mgold_code(m,a,b)
%[w] = jt_make_mgold_code(m,a,b)
%Generates modulated gold codes. 
%
% INPUT
%   m = [int] register length (6)
%   a = [1 p] array of p feedback tab points ([6 1])
%   b = [1 q] array of q feedback tab points ([6 5 2 1])
% 
% OUTPUT
%   w = [2*2^m-1 2^m+1] bits by codes

% Check input
if nargin<1||isempty(m); m=6; end
if nargin<2||isempty(a); a=[6 1]; end
if nargin<3||isempty(b); b=[6 5 2 1]; end

% Generate gold codes
w = jt_make_gold_code(m,a,b);

% Modulate gold codes
w = jt_modulate_code(w,'psk2');