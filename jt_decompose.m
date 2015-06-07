function [R] = jt_decompose(M,T)
%[R] = jt_decompose(M,T)
%Decomposes responses (T) according to a structure matrix (M) to obtain
%transient responses (R) to each individual event in the structure matrix.
%
% INPUT
%   M = [m sum(L) n] structure matrix of [samples events instances]
%   T = [c m n]      responses of [channels samples instances]
%
% OUTPUT
%   R = [c sum(L)] transient responses of [channels events]

% Variables
[m,L,n] = size(M);
c = size(T,1);

% Reshape structures and responses
M = reshape(permute(M,[1 3 2]),[m*n L]);
T = reshape(T,[c m*n]);

% Extract responses
R = T/M';
