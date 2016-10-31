function [codes] = jt_make_musical_code(Fb,Fs,time)
%[codes] = jt_make_musical_code(Fb,Fs,time)
%Generates Musical Codes, being codes that represent one octave.
%
% INPUT
%   Fb   = [flt] base frequency (first tone)
%   Fs   = [flt] sample frequency
%   time = [flt] total playtime, seconds
%
% OUTPUT
%   codes = [Fs*time n] generated codes (one octave)

% Determine number of codes
numcodes = 13; % One octave

% Check input
if Fb<1||Fs<1||time<=0; error('Invalid input: zero/negative input'); end

% Generate music codes
Fi = Fb*2.^(((1:numcodes)-1)/12); % frequencies
t = 0:1/Fs:time-1/Fs;             % time axis
codes = sin(2.*pi.*Fi'*t)'>0;     % sinusoids