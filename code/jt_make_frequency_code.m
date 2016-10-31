function [codes] = jt_make_frequency_code(f,fs,d)
%[codes] = jt_make_frequency_code(f,fs,d)
%Generate frequency tags.
% 
% INPUT
%   f  = [1 n] frequencies of the codes
%   fs = [int] sample frequency
%   d  = [flt] duration of frequency tags in seconds
% 
% OUTPUT
%   codes = [fs*d n] the frequency tags

n = numel(f);
s = fs*d;
codes = zeros(s,n);
for i = 1:n
    di = floor(fs/f(i));
    ft = repmat([1;zeros(di-1,1)],[ceil(s/di) 1]);
    codes(:,i) = ft(1:s);
end