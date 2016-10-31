function var = jt_scale(var, lim)
%var = jt_scale(var, lim)
%Scales variables to a certain limit
%
% INPUT
%   var = [m n] the to be scaled variable
%   lim = [1 2] min and max of the limit
%
% OUTPUT
%   var = [m n] the scaled variable

var = (lim(2)-lim(1))*(var-min(var(:))) / ...
    (max(var(:))-min(var(:)))+lim(1);