function [w] = jt_make_mmls_code(m,a)
%[w] = jt_make_mmls_code(m,a)
%Generates a modulated maximum length sequence.
% 
% INPUT
%   m = [int] register length (6)
%   a = [1 p] array of p feedback tab points ([6 1])
% 
% OUTPUT
%   w = [2*(2^m-1) 1] bits by codes

% Check input
if nargin<1||isempty(m); m=6; end
if nargin<2||isempty(a); a=[6 1]; end

% Generate mls
w = jt_make_mls_code(m,a);

% Modulate mls
w = jt_modulate_code(w,'psk2');