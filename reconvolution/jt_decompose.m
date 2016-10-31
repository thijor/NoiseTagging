function [R] = jt_decompose(X,M)
%[R] = jt_decompose(X,M)
%
% INPUT
%   X = [c m n]  data matrix of channels by samples by trials
%   M = [e m n]  structure matrices of events by samples by trials
%
% OUTPUT
%   R = [c e] concattenated transient responses of channels by e=sum(L) samples

% Decompose
R = X(:,:)/M(:,:);