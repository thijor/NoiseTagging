function [codes] = jt_make_mgold_code(m, fbtp1, fbtp2)
%[codes] = jt_make_mgold_code(m, fbtp1, fbtp2)
%Generates modulated Gold Codes. 
%
% INPUT
%   m     = [int] register length 
%   fbtp1 = [1 m] array of m feedback tab points
%   fbtp2 = [1 k] array of k feedback tab points
% 
% OUTPUT
%   codes = [2*2^m-1 2^m+1] 2^m+1 codes of 2*2^m-1 bits

% Check input
if m<1; error('Invalid input: m.'); end
if isempty(fbtp1)||min(fbtp1)<1||max(fbtp1)>m; error('Invalid input: fbtp1.'); end
if isempty(fbtp2)||min(fbtp2)<1||max(fbtp2)>m; error('Invalid input: fbtp2.'); end
if ~jt_isprefpair(m,fbtp1,fbtp2); error('Invalid input: no preferred pair.'); end

% Generate Gold codes
gold = jt_make_gold_code(m, fbtp1, fbtp2);

% Modulate codes
codes = jt_modulate_code(gold);