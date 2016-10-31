function [ order, p ] = pm_beta_order( alphas, betas )
% [ order, p ] = pm_beta_order( alphas, betas )
% Pair wise probability that a Beta distribution is larger
% 
% INPUT
%   alphas      = [n 1] alpha parameters for beta distribution
%   betas       = [n 1] beta parameters for beta distribution
% 
% OUTPUT
%   order       = [n 1] indexes of the highest to lowest distributions
%   p           = [n n] probabilities p(i, j) that Beta(alphas(i),
%                   betas(i)) is larger than Beta(alphas(j), betas(j))

p = zeros(numel(alphas));
for i = 1:numel(alphas)
    for j = i+1:numel(alphas)
        p(i, j) = pm_beta_larger(alphas(i), betas(i), alphas(j), betas(j));
    end
end
p = p + (1 - p') .* (p' > 0);
p = p + diag(ones(numel(alphas), 1) * 0.5);

[~, order] = sort(alphas ./ betas, 'descend');

end

