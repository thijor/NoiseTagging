function [results] = jt_tmc_cv(data,cfg,k,cvswitch)
%[results] = jt_tmc_cv(data,cfg,k,cvswitch)
% Cross-validation to validate classification performance.
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m n]  data of channels by samples by trials
%       .y   = [1 k]    labels: one by trials
%       .V   = [m p]    trained sequences: samples by variables
%   cfg      = [struct] configuration structure, see jt_tmc_train
%   k        = [int]    number of folds (10)
%   cvswitch = [str]    switch train and test folds ('no')
%
% OUTPUT
%   results = [struct] results structure
%       .p = [1 k] accuracies for each fold
%       .t = [1 k] trial-lengths for each fold
%       .d = [1 k] data-lenghts for each fold

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
if nargin<3||isempty(k); k=10; end
if nargin<4||isempty(cvswitch); cvswitch='no'; end
cfg.verbosity = 0;
cfg.lcs = 'no';
cfg.lcl = 'no';
docvswitch = strcmpi(cvswitch,'yes');

% Fold data
cv = cvpartition(numel(data.y),'Kfold',k);

% Loop over folds
results.p = zeros(1,k);
results.t = zeros(1,k);
results.d = zeros(1,k);
for i = 1:k

    % Assign folds
    if docvswitch
        trnidx = cv.test(i);
        tstidx = cv.training(i);
    else
        trnidx = cv.training(i);
        tstidx = cv.test(i);
    end

    % Train classifier
    classifier = jt_tmc_train(struct('X',data.X(:,:,trnidx),'y',data.y(trnidx),'V',data.V,'U',data.V),cfg);
    
    % Apply classifier
    [labels,ret] = jt_tmc_apply(classifier,data.X(:,:,tstidx));
    results.p(i) = mean(labels==data.y(tstidx));
    results.t(i) = mean(ret.t);
    results.d(i) = mean(ret.d);
end