function v = jt_x2bin(v)
%v = jt_x2bin(v)
%Converts a two-valued input to zeros and ones.
%
% INPUT
%   v = [N-D] two-valued variable
%
% OUTPUT
%   v = [N-D] binary variable

uniques = unique(v(:));
if numel(uniques) ~= 2
    error('No binary input.')
else
    v(v==uniques(1)) = 0;
    v(v==uniques(2)) = 1;
end