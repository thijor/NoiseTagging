function [z] = jt_preproc_jf(z,cfg)
%[z] = jt_preproc_jf(z,cfg)
% Preprocess data by performing: outlier removal on trials, linear detrend, 
% CAR, outlier removal on channels, SSI and spectral filter. All configured
% in the z-structure of tje jf_bci toolbox.
%
% INPUT
%   z    = [struct] z-structure of the jf_bci toolbox
%   cfg  = [struct] configuration structure:
%       .fs       = [int] sample frequency (256)
%       .bands    = {n 2} cell of pass bands ({[5 48],[52 120]})
%       .outthres = [flt] threshold for both outlier removals (Inf)
%       .capfile  = [str] electrode cap file (cap64.txt)
%
% OUTPUT
%   z = [struct] preprocessed z-structure

if nargin<2||isempty(cfg); cfg=[]; end
fs          = jt_parse_cfg(cfg,'fs',256);
outthres    = jt_parse_cfg(cfg,'outthres',Inf);
bands       = jt_parse_cfg(cfg,'bands',{{[5 48],[52 120]}});
capfile     = jt_parse_cfg(cfg,'capfile','cap64.txt');

% Remove bad epochs
z = jf_rmOutliers(z,'dim','epoch','thresh',outthres);

% Linear detrending
z = jf_detrend(z,'order',1,'dim','time');

% Rereferencing using Common Average Referencing
z = jf_reref(z,'dim','ch');

% Remove bad channels and rebuild them with Spherical Spline Interpolation
z = jf_rmOutliers(z,'dim','ch','thresh',outthres);
z = jf_spatdownsample(z,'capFile',capfile,'method','sphericalSplineInterpolate');

% Filter spectrally
z = jf_fftfilter(z,'fs',fs,'bands',bands,'verb',-1);