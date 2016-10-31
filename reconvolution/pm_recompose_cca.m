 function [model,Wxs,Wys,r] = pm_recompose_cca(X,M,model,cfg,iCm)
%[model,Wxs,Wys] = pm_recompose_cca(X,M,model,cfg,iCm)
%
% INPUT
%   X     = [c m]    data matrix of channels by samples by trials
%   M     = [e m n]  structure matrices of events by samples by trials
%   model = [struct] filtered covariance model
%       .avg   = [c+e n]     filtered mean of the data and structure matrixes
%       .cov   = [c+e c+e n] filtered sum of covariances (not normalized) of the data and structure matrixes
%       .count = [int]       count of datasamples that contributed to the mean and covsum
%   cfg   = [struct] configuration structure:
%       .L          = [1 r] length of transient responses in samples (100)
%       .cca        = [str] CCA method
%       .component  = [int] CCA component to use (1)
%       .lx         = [flt] regularization on data.X (1)
%                     [1 c] regularization on data.X for each sample
%                     [str] regularization on data.X with taper
%       .ly         = [flt] regularization on Y (1)
%                     [1 e] regularization on Y for each sample
%                     [str] regularization on data.X with taper
%       .lxamp      = [flt] amplifier for lx regularization penalties, i.e., maximum penalty (1)
%       .lyamp      = [flt] amplifier for ly regularization penalties, i.e., maximum penalty (1)
%       .lyperc     = [flt] relative parts of the taper that is regularized
%       .modelonset = [str] whether or not to model the onset, uses L(end) as length (false)
%   iCm   = [e e]   inverse covariance of structure matrixes ([])
%
% OUTPUT
%   model = [struct] updated covariance model
%   Wxs   = [c p]    coefficients for X for each class
%   Wys   = [e p]    coefficients for Y for each class
%   r     = [p 1]    canonical correlations

% Defaults
if nargin<5||isempty(iCm); iCm=[]; end
if isscalar(cfg.L) && cfg.L~=e; cfg.L=repmat(cfg.L,[1 floor(e/cfg.L)]); end
X = permute(X,[2 1]);
M = permute(M,[2 1 3]);

% Initialize model
if isempty(model)
    model.n = size(M,3);
    model.c = size(X,2);
    model.e = size(M,2);
    model.avg = nan(model.c+model.e,model.n);
    model.cov = nan(model.c+model.e,model.c+model.e,model.n);
    model.count = 0;
end

% Regularization parameters
lx = pm_regularization(cfg.lx,model.c,false,cfg.lxamp);
ly = pm_regularization(cfg.ly,cfg.L,cfg.modelonset,cfg.lyamp,cfg.lyperc);

% Create the same model for each class if only one model is given
if size(model.avg,2)==1
    model.avg = repmat(model.avg,[1 model.n]);
end
if size(model.cov,3)==1
    model.cov = repmat(model.cov,[1 1 model.n]);
end

% Compute and invert Cxx only once
if ~isempty(X)
    X = bsxfun(@minus,X,mean(X,1));
    [~,tempcov] = pm_running_cov([X M(:,:,1)],model.avg(:,1)',model.cov(:,:,1),model.count);
else
    tempcov = model.cov(:,:,1);
end
Cxx = tempcov(1:model.c,1:model.c) + diag(lx);
iCx = real(Cxx^(-1/2));

% Results for each code
Wxs = zeros(model.c,model.n);
Wys = zeros(model.e,model.n);
r = zeros(model.n,1);
tmpcount = zeros(1,model.n);
for i = 1:model.n
    
    % Zero mean structure matrixes
    if ~isempty(X)
        m = M(:,:,i);
        m = bsxfun(@minus,m,mean(m,1));
        [model.avg(:,i),model.cov(:,:,i),tmpcount(i)] = pm_running_cov([X m],model.avg(:,i)',model.cov(:,:,i),model.count,cfg.covfilter);
    end
    
    % Decomposition
    [Wxs(:,i),Wys(:,i),r(i)] = jt_cca_cov(model.cov(:,:,i),[],lx,ly,cfg.component,iCx,iCm);
end
model.count = tmpcount(1);