function [flag,vals] = jt_checkxcor(n,v,w)
%[flag,vals] = jt_checkxcor(m,v,w)
%Checks whether the cross-correlation of a variable is three valued.
%
% INPUT
%   n = [int] register length
%   v = [m p] p variables of m samples
%   w = [m q] q variables of m samples
%
% OUTPUT
%   flag = [int]  1 if 3-valued, otherwise 0
%   vals = [flt] unique cross-correlation values  

% Convert variables
v = jt_bin2pol(v);
w = jt_bin2pol(w);

% Compute unique correlation values
correlations = single(jt_cosine(v,w,'shift'));
vals = unique(correlations);

% Should be three-valued excluding the zero-lag auto-correlation
if numel(vals)~=4
    flag = 0; 
    return; 
end

% Check 3-valued cross-correlation (and auto-correlation)
if mod(n,2)==0 && all(vals == ...
                   [-(2^((n+2)/2)+1)/(2^n-1);...
                   -1/(2^n-1);...
                   (2^((n+2)/2)-1)/(2^n-1);...
                   1]) ...
               || ...
   mod(n,2)==1 && all(vals == ...
                   [-(2^((n+1)/2)+1)/(2^n-1);...
                   -1/(2^n-1);...
                   (2^((n+1)/2)-1)/(2^n-1);...
                   1])
    flag = 1;
else
    flag = 0;
end