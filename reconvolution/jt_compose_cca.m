function [T] = jt_compose_cca(M,R)
%[T] = jt_compose_cca(M,R)
%
% INPUT
%   M = [e m n] structure matrices of events by samples by classes
%   R = [e 1]   transient responses samples
%       [e n]   transient response for each class
%
% OUTPUT
%   T = [m n] predicted responses of samples by classes

if size(R,2)==1
    T = tprod(M,[-1 1 2],R,-1);
else
    T = tprod(M,[-1 1 2],R,[-1 2]);
end