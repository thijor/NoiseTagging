function [ inv_cov ] = pm_inv_reg_cov( data, reg )
%PM_INVERSE_REG_COV Summary of this function goes here
%
% INPUT
%   data        = [m n] 
%               = [m n k]
% 
% OUTPUT
%   cov         = [n n]
%               = [n n k]

data = bsxfun(@minus, data, mean(data, 2));

Mcov = tprod(data, [1, -1, 3], data, [2, -1, 3]) ./ (size(data, 2) - 1);
reg = min((1-reg)./(reg+eps), 1e3) + eps;
Mcov = bsxfun(@plus, Mcov, diag(reg));
if numel(size(Mcov)) > 2
    Mcov = mat2cell(Mcov, size(Mcov, 1), size(Mcov, 2), ones(size(Mcov, 3), 1));
else
    Mcov = mat2cell(Mcov, size(Mcov, 1), size(Mcov, 2)); 
end
inv_cov = cellfun(@(x) real(x^(-1/2)), Mcov, 'UniformOutput', false);
inv_cov = cell2mat(inv_cov);

end

