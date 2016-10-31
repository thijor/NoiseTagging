function [switches] = jt_checkswitches(var)
%[switches] = jt_checkswitches(var)
%Determines the number of on and off switches in a variable.
% 
% INPUT
%   var = [m n] matrix of n variables of m samples
%
% OUTPUT
%   switches = [2 n] amound of both on and off switches for all variables

% Input has to be binary
var = jt_x2bin(var);

% Shift var
shiftvar = circshift(var, [1 0]);

% Last bit became first bit, redo
shiftvar(1,:) = 0;

% Find switches
switches = [ sum( var & ~shiftvar,1);... % On:  01
             sum(~var &  shiftvar,1)];   % Off: 10