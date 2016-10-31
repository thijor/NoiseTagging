function [distance] = jt_checkdistance(var,type)
%[distance] = jt_checkdistance(var,type)
%Determines the distance of variables. 
%
% INPUT
%   var  = [m n] matrix of n variables of m samples 
%   type = [str] hamming|nhamming ('hamming')
%
% OUTPUT:
%   distance = [n n] percentage that differs among variables

if nargin<2||isempty(type); type='hamming'; end;

% Input has to be binary
var = jt_x2bin(var);

switch(lower(type))
    case 'hamming'  %hamming distance
        distance = double( var')*double(~var)+...
                   double(~var')*double( var);
    case 'nhamming' %normalised hamming distance
        distance = (double( var')*double(~var)+...
                    double(~var')*double( var))./size(var,1);
    otherwise
        error('Unknown type, %s', type)
end