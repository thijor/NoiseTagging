function [ p ] = pm_beta_largest( alphas, betas )
% [ p ] = pm_beta_largest( alphas, betas )
% Probability for each of the beta distribution that it is the largest.
% Effectively compares each distribution to the largest other distribution.
% 
% INPUT
%   alphas      = [n 1] alpha parameters for beta distribution
%   betas       = [n 1] beta parameters for beta distribution
% 
% OUTPUT
%   p           = [n 1] probability for each distribution that it is the
%                   largest

[~, p_larger]                           = pm_beta_order(alphas, betas);
p_larger(1:size(p_larger, 1)+1:end)     = 1;
p                                       = min(p_larger, [], 2);

end

