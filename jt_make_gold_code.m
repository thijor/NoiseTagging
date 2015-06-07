function [codes] = jt_make_gold_code(m, fbtp1, fbtp2)
%[codes] = jt_make_gold_code(m, fbtp1, fbtp2)
%Generates Gold Codes.
% 
% INPUT
%   m     = [int] register length 
%   fbtp1 = [1 p] array of p feedback tab points
%   fbtp2 = [1 k] array of k feedback tab points
% 
% OUTPUT
%   codes = [2^m-1 2^m+1] 2^m+1 codes of 2^m-1 bits

% Determine number of possible codes
numcodes = 2^m+1;

% Check input
if m<1; error('Invalid input: m.'); end
if isempty(fbtp1)||min(fbtp1)<1||max(fbtp1)>m; error('Invalid input: fbtp1.'); end
if isempty(fbtp2)||min(fbtp2)<1||max(fbtp2)>m; error('Invalid input: fbtp2.'); end
if ~jt_isprefpair(m,fbtp1,fbtp2); error('Invalid input: no preferred pair.'); end

% Generate two mls sequences
mls1 = jt_make_mls_code(m, fbtp1);
mls2 = jt_make_mls_code(m, fbtp2);

% Generate gold codes
codes = zeros(2^m-1, numcodes); 
for i = 1:min(2^m-1, numcodes-2)
    codes(:,i) = mod(mls1+mls2, 2);
    mls1 = circshift(mls1, [1 0]);
end

% Put both m-sequences with the codes
codes(:,end-1) = mls1;
codes(:,end)   = mls2;
