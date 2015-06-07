function [T] = jt_compose(M,R)
%[T] = jt_compose(M,R)
%Composes responses (T) by superposing transient responses (R) according to
%specific structures of events described in the structure matrix (M).
%
% INPUT
%   M = [m sum(L) n] structure matrix of [samples events instances]
%   R = [c sum(L)]   transient responses of [channels events]
%
% OUTPUT
%   T = [c m n] n predicted responses of [channels samples instances]

% Variables
[m,L,n] = size(M);
c = size(R,1);

% Reshape structures and responses
M = reshape(permute(M,[1 3 2]), [m*n,L]);

% Compose responses
T = reshape(R*M', [c m n]);
