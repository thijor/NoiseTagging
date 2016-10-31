function [lambda] = pm_regularization(lambda,N,intercept,maximum,alpha)
%[lambda] = pm_regularization(lambda,L,intercept,maximum,alpha)
%
% INPUT
%   lambda      = [flt] between 0 and 1 meaning heavy and no regularization
%               = [str] taper function, see jt_make_taper
%   N           = [n 1] size of the to-be regularized covariances, possible modelonset is last one.
%   intercept   = [int] adds zero regularization (useful for an intercept)
%   maximum     = [flt] maximum regularization on the covariance
%   alpha       = [int] relative parts of the taper that is regularized

if nargin<3||isempty(intercept); intercept = 0; end
if nargin<4||isempty(maximum); maximum = 1; end
if nargin<5||isempty(alpha); alpha = .2; end

% Design taper for regularization
if ischar(lambda)
    if intercept
        lambda = cat(1,jt_make_taper(lambda,N(1:end-1),1,alpha),ones(N(end),1)); 
    else
        lambda = jt_make_taper(lambda,N,maximum,alpha); 
    end
else
    if numel(lambda)==1
        lambda = maximum*repmat(lambda, sum(N), 1);
    end
end

% Revert order (i.e., 1 confidence means no (i.e., low) penalty and vice versa)
lambda = max(min((maximum-lambda),maximum),0);