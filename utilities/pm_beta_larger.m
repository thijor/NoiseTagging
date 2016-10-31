function [ p ] = pm_beta_larger( a1, b1, a2, b2 )
% [p] = pm_beta_larger(a1, b1, a2, b2)
% Probability that Beta(a1, b1) is larger than Beta(a2, b2)
% Also see: http://www.evanmiller.org/bayesian-ab-testing.html
% 
% INPUT
%   a1          = [num] alpha of first distribution
%   b1          = [num] beta of first distribution
%   a2          = [num] alpha of second distribution
%   a2          = [num] beta of second distrubition

ii = 0:a1-1;
p = sum(exp(betaln(a2 + ii, b2 + b1) - ...
        log(b1 + ii) - betaln(1 + ii, b1) - betaln(a2, b2))); 
end