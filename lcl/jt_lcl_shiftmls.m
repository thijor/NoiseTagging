function [layout,xcorr] = jt_lcl_shiftmls(x,border,doplot)
%[layout,xcorr] = jt_lcl_shiftmls(x,border,doplot)
%General layout used for circular-shifted m-sequences, including or
%excluding a border around selectable stimuli.
%
% INPUT
%   x       = [m n] n variables of m samples
%   border  = [int] whether or not to put a border around (0)
%   doplot  = [int] plot cross-correlations (0)
%
% OUTPUT
%   layout = [1 n] layout
%   xcorr  = [flt] max pairwise correlation in layout

if nargin<2; border=0; end
if nargin<3; doplot=0; end

% Compute cross correlations
correlations = jt_correlation(x,x,'fix');

% Set layout
if border
    layout = [  24 25 26 27 28 29 30 31 32  1 ;
                32  1  2  3  4  5  6  7  8  9 ; 
                 8  9 10 11 12 13 14 15 16 17 ;
                16 17 18 19 20 21 22 23 24 25 ;
                24 25 26 27 28 29 30 31 32  1 ;
                32  1  2  3  4  5  6  7  8  9];
else
    layout = [  1  2  3  4  5  6  7  8 ; 
                9 10 11 12 13 14 15 16 ;
               17 18 19 20 21 22 23 24 ;
               25 26 27 28 29 30 31 32 ];
end
layout = layout(:);

% Take correlations
xcorr = correlations;

% Plot
if doplot>0
    figure;
    jt_plotlcl(layout,correlations);
end