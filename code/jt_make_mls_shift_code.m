function [codes] = jt_make_mls_shift_code(m,fbtp,border)
%[codes] = jt_make_mls_shift_code(m,fbtp,border)
%Generates shifted Maximum Length Sequences.
% 
% INPUT
%   m      = [int] register length (6)
%   fbtp   = [1 p] array of p feedback tab points ([6 1])
%   border = [int] whether or not to put border aroundd (0)
% 
% OUTPUT
%   codes = [2^m-1 n] n maximum length sequences of 2^m-1 bits

% Check input
if nargin<1||isempty(m); m=6; end
if nargin<2||isempty(fbtp); fbtp=[6 1]; end
if nargin<3||isempty(border); border=0; end

% Generate mls
code = jt_make_mls_code(m, fbtp);

% Generate all shifts
m = size(code,1);
codes = zeros(m,m);
codes(:,1) = code;
for i = 2:m
    codes(:,i) = circshift(code,i-1);
end

% Apply layout
layout = jt_lcl_shiftmls(codes,border,0);

% Arrange codes
codes = codes(:,layout);