function [R,W] = pm_decompose_ls(X,M,classifier,cfg)
%[R,W] = jt_decompose_cca(X,M,cfg)
%
% INPUT
%   X = [c m n]  data matrix of channels by samples by trials
%   M = [e m n]  structure matrices of events by samples by trials
%
%   classifier = [struct] classifier structure
%
%   cfg = [struct] configuration structure:
%       .L          = [1 r] length of transient responses in samples (100)
%       .lx         = [flt] regularization on data.X (1)
%                     [1 c] regularization on data.X for each sample
%                     [str] regularization on data.X with taper
%       .ly         = [flt] regularization on Y (1)
%                     [1 L] regularization on Y for each sample
%                     [str] regularization on data.X with taper
%       .lxamp      = [flt] amplifier for lx regularization penalties, i.e., maximum penalty (1)
%       .lyamp      = [flt] amplifier for ly regularization penalties, i.e., maximum penalty (1)
%       .lyperc     = [flt] relative parts of the taper that is regularized (.2)
%       .modelonset = [str] whether or not to model the onset, uses L(end) as length (false)
%
% OUTPUT
%   R = [e 1] concattenated transient responses of e=sum(L) samples
%   W = [c 1] spatial filter to be applied to data [channels components]

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
L           = jt_parse_cfg(cfg,'L',100);
modelonset  = jt_parse_cfg(cfg,'modelonset',false);
lx          = jt_parse_cfg(cfg,'lx',1);
ly          = jt_parse_cfg(cfg,'ly',1);
lxamp       = jt_parse_cfg(cfg,'lxamp',1);
lyamp       = jt_parse_cfg(cfg,'lyamp',1);
lyperc      = jt_parse_cfg(cfg,'lyperc',.2);
[c,m,k] = size(X);
e = size(M,1);
if isscalar(L) && L~=e; L= L*ones(1,e/L); end

% Reshape
X = reshape(X,[c m*k])';
M = reshape(M,[e m*k])';

% Design taper for regularization
lx = pm_regularization(lx,c,false,lxamp);
ly = pm_regularization(ly,L,modelonset,lyamp,lyperc);

% Decompose
if ~jt_exists_in(classifier,'filter') && jt_exists_in(classifier,'transients')
    R = classifier.transients;
    W = pm_ridge(X, M*R, lx);
elseif jt_exists_in(classifier,'filter') && ~jt_exists_in(classifier,'transients')
    W = classifier.filter;
    R = pm_ridge(M, X*W, ly);
else
    error('For decomposition with ordinary least squares (OLS) either the filter or transients should already be set');
end