function [ x ] = pm_ridge( A, b, gamma )
%[ x ] = pm_ridge(A, b, gamma) 
%Ridge regression
%https://en.wikipedia.org/wiki/Tikhonov_regularization

% Zero mean
A = bsxfun(@minus,A,mean(A,1));
b = bsxfun(@minus,b,mean(b,1));

% Regularisation parameters
g = min((1-gamma)./(gamma+eps), 1e4);
if numel(g) == 1; g = repmat(g, size(A, 2), 1); end
g = diag(g) .* sqrt(size(A, 1));

x = (A' * A + g * g')^-1 * A' * b;

end

