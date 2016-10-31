function [results] = jt_reconvolution_cca_cv(X,V,cfg)
%[Tv,Tu,W,R] = jt_reconvolution_cca(data,cfg)
%
% INPUT
%   X   = [c m k]  data of channels by samples by trials
%   V   = [m p]    train sequences of samples by classes
%   cfg = [struct] configuration structure:
%       .cca        = [str] CCA method
%       .event      = [str] type of decomposition event ('duration')
%       .L          = [1 r] length of transient responses in samples (100)
%       .delay      = [int] number of samples delay in signal (0)
%       .component  = [int] CCA component to use (1)
%       .lx         = [flt] regularization on data.X (1)
%                     [1 c] regularization on data.X for each sample
%                     [str] regularization on data.X with taper
%       .ly         = [flt] regularization on Y (1)
%                     [1 L] regularization on Y for each sample
%                     [str] regularization on data.X with taper
%       .modelonset = [str] whether or not to model the onset, uses L(end) as length ('no')
%       .symmetric  = [str] whether or not to model symmetric transients ('no')
%       .wraparound = [str] whether or not to wrap responses around ('no')
%
% OUTPUT
%

% Defauls
nfolds      = jt_parse_cfg(cfg,'nfolds',10);
cca         = jt_parse_cfg(cfg,'cca','qr');
event       = jt_parse_cfg(cfg,'event','duration');
L           = jt_parse_cfg(cfg,'L',100);
delay       = jt_parse_cfg(cfg,'delay',0);
component   = jt_parse_cfg(cfg,'component',1);
lx          = jt_parse_cfg(cfg,'lx',1);
ly          = jt_parse_cfg(cfg,'ly',1);
modelonset  = jt_parse_cfg(cfg,'modelonset','no');
symmetric   = jt_parse_cfg(cfg,'symmetric','no');
wraparound  = jt_parse_cfg(cfg,'wraparound','no');
[c,m,k] = size(X);

% Build structure matrix
cfg = [];
cfg.L           = L;
cfg.delay       = delay;
cfg.event       = event;
cfg.modelonset  = modelonset;
cfg.wraparound  = wraparound;
cfg.symmetric   =symmetric;
M = jt_structure_matrix(V,cfg);
l = size(M,1);

% Cross-validation
cv = cvpartition(k,'k',nfolds);
results = struct();
for i = 1:nfolds
    
    % Select fold
    trnidx = cv.training(i);
    tstidx = cv.test(i);
    ntst = sum(tstidx);
    
    % Compute ERP
    Terp = mean(X(:,:,trnidx),3);
    
    % Estimate; deconvolution
    [Wx,Wy,r,Ax,Ay] = jt_cca(...
        reshape(X(:,:,tstidx)       ,[c m*ntst])',...
        reshape(repmat(M,[1 1 ntst]),[l m*ntst])',...
        pm_regularization(lx,c),...
        pm_regularization(ly,l),...
        cca,'all');
    
    % Generate; convolution
    Tprd = Ax(:,component)*(M'*Wy(:,component))';
    
    % Compute performance
    corr = jt_correlation(Terp',Tprd').^2;
    
    % Save variables
    results(i).Wx = Wx;
    results(i).Wy = Wy;
    results(i).r  = r;
    results(i).Ax = Ax;
    results(i).Ay = Ay;
    results(i).c  = diag(corr);
end