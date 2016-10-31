function [c] = jt_cosine(v,w,action)
%[c] = jt_correlate(v,w,action)
%(Cross-)Cosine similarity
%
% INPUT
%   v = [m p] matrix of p variables of m samples
%   w = [m q] matrix of q variables of m samples
%
% OPTIONS
%   action = [string] lock|sync|stop|shift|async (lock)
%
% OUTPUT
%   c = [p*q p*q]   all cross-correlations locked/sync/stop
%       [p*q p*q m] all cross-correlations shift/async

% Defaults
if nargin<3||isempty(action); action='lock'; end

% Make sure it is double
v = double(v);
w = double(w);

% Perform action
switch lower(action)
    case {'lock','sync','stop'}
        c = lock_cosine(v,w);
    case {'shift','async'}
        c = shift_cosine(v,w);
    otherwise
        error('Unknown action: %s',action)
end

%-----------------------------------------------------
function [c] = lock_cosine(v,w)
    c = v'*w ./ sqrt(sum(v.^2)'*sum(w.^2));
end

%-----------------------------------------------------
function [c] = shift_cosine(v,w)
    c = zeros(size(v,2),size(w,2),size(v,1));
    for i = 1:size(w,1)
        c(:,:,i) = lock_cosine(v, circshift(w, [i-1 0]));
    end
end

end