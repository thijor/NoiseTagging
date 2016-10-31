function [codes,count] = jt_make_pulse_code(n,m,k,d)
%[codes] = jt_make_pulse_code(n,m,k,d)
%
% INPUT
%   n = [int] number of pulse codes (1)
%   m = [int] length of pulse codes in bits (100)
%   k = [int] number of individual pulses (5)
%   d = [int] length of one pulse in bits (2)
% OUTPUT
%   codes = [m n] the pulse codes
%   count = [1 n] number of pulse per code

if nargin<1||isempty(n); n=1;   end
if nargin<2||isempty(m); m=100; end
if nargin<3||isempty(k); k=5;   end
if nargin<4||isempty(d); d=2;   end

distance = floor(m/k);
codes = false(m,n);
count = zeros(1,n);
for i = 1:n
    
    % Determine pulses (at least one)
    pulses = false(1,k);
    while ~any(pulses)
        pulses = rand(1,k)>.5;
    end
    count(i) = sum(pulses);
    
    % Determine indices
    indices = ones(1,count(i))*floor(distance/2) + (find(pulses)-1)*distance + floor(distance/3*(rand(1,count(i))));
    
    % Fill in indices
    for s = 0:d-1
        codes(indices+s,i) = true;
    end
    
end