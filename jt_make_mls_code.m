function [codes] = jt_make_mls_code(m, fbtp)
%[codes] = jt_make_mls_code(m, fbtp)
%Generates Maximum Length Sequences.
% 
% INPUT
%   m    = [int]  register length
%   fbtp = [cell] cell containing n feedback tap position arrays
% 
% OUTPUT
%   codes = [2^m-1 n] n maximum length sequences of 2^m-1 bits

% Check input
if m<2; error('Invalid register length.'); end
if ~iscell(fbtp); fbtp={fbtp}; end
if any(cellfun(@max,fbtp)~=m); error('Invalid feedback taps.'); end
if any(cellfun(@min,fbtp)<1); error('Invalid feedback taps.'); end

% Generate mls
numcodes = numel(fbtp);
codes = zeros(2^m-1, numcodes);
for j = 1:numcodes
    
    % Create initial register (may never be empty/all-zero)
    register = ones(m,1);

    % Generate codes by modulo-2-addition
    for i = 1:2^m-1
        codes(i,j) = mod(sum(register(fbtp{j})), 2);
        register = [codes(i,j); register(1:end-1)];
    end
    
end
