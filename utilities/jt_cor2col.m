function [colors] = jt_cor2col(correlations,threshold,doplot)
%[scaled,colors] = jt_cor2col(correlations,threshold)
%
%
% INPUT
%   correlations = [n 1] correlations between m templates and single trial
%   threshold    = [1 1] threshold value
% 
% OPTIONS
%   doplot = [int] 1 if plot, 0 otherwise (0)
%
% OUTPUT
%   colors = [n 3] colors defining the degree of certainty according to a 
%                  colormap: red (uncertain) > grey > green (certain)

if nargin<3||isempty(doplot); doplot=0; end
correlations = correlations(:);

% Scale correlations to colors
data = sort(correlations,1,'descend');
maxdata = data(1);
snddata = data(2);
mindata = data(end);
margedata = maxdata-snddata;
rangedata = maxdata-mindata;
closedata = max(0,min(1,margedata./threshold));
normed = (correlations-mindata)./rangedata;
scaled = .5+closedata.*(normed-.5);

% Generate colormap
ncolors = 64;
cmap = zeros(ncolors,3);
cmap(:,2) = (0:ncolors-1)/(ncolors-1);
cmap(:,1) = (ncolors-1:-1:0)/(ncolors-1);
cmap(1:ncolors/2,3) = cmap(1:ncolors/2,2);
cmap(ncolors/2+1:ncolors,3) = cmap(ncolors/2+1:ncolors,1);

% Convert scaled marges to colors
colors = cmap(floor(scaled*(ncolors-1))+1,:)*255;

% Plot image
if doplot
    figure;
    image(round(scaled*ncolors));
    colormap(cmap);
end
