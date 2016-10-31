function [ ps, beta, cmaxsamples ] = pm_max_corr( cs, ndraws, estimate, alpha )
% [ps, beta] = pm_max_corr(cs, n, samples, estimate)
% Estimates the probability that the maximum correlation is larger than all
% the others. Takes absolute value of correlation and fits a beta
% distribution over the non-maximum correlations. Takes n samples of n
% draws and checks wheter the maximum correlation is higher than the sample
% maximum. 
% 
% INPUT
%   cs              = [n 1] array of correlations
%   ndraws          = [int] number of draws per sample (n)
%   estimate        = ['LB'|'ML'|'UB'] Wheter to use the lower bound,
%                       maximum likelihood or upper bound of the
%                       betadistribution estimation ('ML')
%                   = [flt] weighting between lower and upperbound. bound =
%                   LB * (1-estimate) + UB * estimate;

if nargin < 2 || isempty(ndraws)
    ndraws = numel(cs);
end
if nargin < 3 || isempty(estimate)
    estimate = 'ML';
end
if nargin < 4 || isempty(alpha)
    alpha = 0.05;
end

if isnumeric(estimate) && (estimate < 0 || estimate > 1)
    error('Lower-upper bound weighting should be between zero and one');
end

if min(cs) < -1 || max(cs) > 1;
    error('Correlations should be betweeen minus one and one');
end

% cs = abs(cs);
cs = (cs + 1) / 2;
% cs = min(max(cs, 0), 1);

[~, cmaxi] = max(cs);
nonmax = cs([1:cmaxi-1, cmaxi+1:numel(cs)]);
if numel(unique(nonmax)) > 1
    [beta_ml, beta_b] = betafit(nonmax, alpha);
    beta = get_beta_dist(beta_b(1, :), beta_ml, beta_b(2, :), estimate);
    ps = betacdf(cs, beta(1), beta(2)) .^ ndraws; % Probability: max(Beta(a, b)) < cs
else
    ps = zeros(size(cs));
    beta = [];
    cmaxsamples = [];
end

function beta = get_beta_dist(lb, ml, ub, estimate)
if ischar(estimate)
    switch estimate
        case 'LB'
            beta = lb;
        case 'ML'
            beta = ml;
        case 'UB'
            beta = ub;
        otherwise
            error('Estimate should be one of LB, ML, UB or float');
    end
else
    beta = lb * (1-estimate) + ub * estimate;
end

