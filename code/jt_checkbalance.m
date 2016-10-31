function [flags,balance] = jt_checkbalance(var,dif)
%[flags,balance] = jt_checkbalance(var,dif)
%Determines the number of ones and zeros in a variable and checks if these 
%differ. Balanced means equal number of ones and zeros.
%
% INPUT
%   var = [m n] matrix of n variables of m samples 
%   dif = [int] difference between zeros and ones that is allowed (0)
% 
% OUTPUT:
%   flags   = [1 n] 1 if balanced, 0 if not
%   balance = [2 n] amount of both ons and offs for all n variables

if nargin<2; dif=0; end

% Input has to be binary
var = jt_x2bin(var);

% Compute balance
balance = [sum(var,1); sum(~var,1)];

% Check balance
flags = abs(balance(1,:)-balance(2,:))<=dif;