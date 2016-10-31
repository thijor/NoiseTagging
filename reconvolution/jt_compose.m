function [T] = jt_compose(M,R)
%[T] = jt_compose(M,R)
%
% INPUT
%   M = [e m n] structure matrices of events by samples by classes
%   R = [c e]   transient responses of channels by samples
%
% OUTPUT
%   T = [c m n] predicted responses of channels by samples by classes

c = size(R,1);
[~,m,n] = size(M);

% Compose responses
T = reshape(R*M(:,:), [c m n]);
