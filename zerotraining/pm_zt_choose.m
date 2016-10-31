function [classifier] = pm_zt_choose(label,classifier)
%[classifier] = pm_zt_choose(label,classifier)
% Update classifier covariance model for the given label. If the label is
% nan (no classification) nothing happens. 

% INPUT
%   label       = [int] the label for the classified trial
%               = [nan] the trial is not classified
%   classifier  = [struct] classifier
% 
% OUTPUT
%   classifier  = [struct] updated classifier

if ~isnan(label) && numel(size(classifier.covmodel.cov)) > 2
    classifier.covmodel.avg = classifier.covmodel.avg(:,label);
    classifier.covmodel.cov = classifier.covmodel.cov(:,:,label);
    classifier.filter       = classifier.filter(:,label);
    classifier.transients   = classifier.transients(:,label);
end