function [f,A] = jt_spectrum(y,fs,cfg)
%[f,A] = jt_spectrum(y,fs,cfg)
%Computes the spectrum of a given signal.
%
% INPUT
%   y   = [m n]    n variables of m samples
%   fs  = [int]    sample frequency
%   cfg = [struct] configuration structure
%       .method  = [str] pg|psd (pg)
%       .padding = [str] on|off (off)
%       .nyquist = [str] on|off (off)
%
% OUTPUT
%   f = [1 p] frequency series of p samples
%   A = [n p] amplitudes per p frequency of n variables

% Set user specifications and defaults
if nargin<3||isempty(cfg); cfg=[]; end
method      = jt_parse_cfg(cfg,'method','pg');
padding     = jt_parse_cfg(cfg,'padding','off');
nyquist     = jt_parse_cfg(cfg,'nyquist','off');
N = size(y,1);

% Zero padding
if strcmpi(padding,'on')
    y = cat(1,y,zeros(10*size(y,1),size(y,2)));
    N = size(y,1);
end

% Fourier 
f = fs/N*(0:N-1);
Y = fft(y',[],2);

% Compute amplitudes
switch lower(method)
    case 'pg' ; A = abs(Y)/N;
    case 'psd'; A = (abs(Y)/N).^2;
    otherwise ; error('Unknown method: %s',method)
end
A(:,2:end-1) = 2*A(:,2:end-1);

% Adjust to Nyquist frequency
if strcmpi(nyquist,'on')
    N = floor(N/2);
    A = A(:,1:N);
    f = f(1:N);
end