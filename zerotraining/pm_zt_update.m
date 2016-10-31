function [classifier,rho] = pm_zt_update(X,classifier)
%[classifier] = pm_zt_update(X,classifier,stoplearning,maxsamples)
% Updates the classifier covariance model and templates with new data. 
% 
% INPUT
%   X          = [c m]    data of channels by samples
%   classifier = [struct] classifier
%
% OUTPUT
%   classifier = [struct] updated classifier

% Find samples of last segment
ds = floor(classifier.cfg.segmenttime*classifier.cfg.fs); 
t  = floor(size(X,2)/ds);
idx = (t-1)*ds+1:t*ds;

% Extract data
X = X(:,idx);

% Extract structure matrix
s = size(classifier.stim.Mus,2);
M = cat(2,...
    classifier.stim.Mus(:,idx(idx<=s),:),...
    classifier.stim.Muw(:,mod(idx(idx>s)-1,s)+1,:));

% Update model
cfg = [];
cfg.L           = floor(classifier.cfg.fs.*classifier.cfg.L);
cfg.modelonset  = classifier.cfg.modelonset;
cfg.component   = classifier.cfg.component;
cfg.lx          = classifier.cfg.lx;
cfg.ly          = classifier.cfg.ly;
cfg.covfilter   = classifier.cfg.covfilter;
[classifier.covmodel,classifier.filter,classifier.transients,rho] = pm_recompose_cca(X,M,classifier.covmodel,cfg,classifier.stim.iMu);

% Update templates
classifier.templates.Tus = jt_compose_cca(classifier.stim.Mus,classifier.transients);
classifier.templates.Tuw = jt_compose_cca(classifier.stim.Muw,classifier.transients);