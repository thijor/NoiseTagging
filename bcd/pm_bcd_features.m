function [ feat ] = pm_bcd_features( X, fs )
%PM_BCD_FEATURES Summary of this function goes here
%   Detailed explanation goes here

ntrl     = size(X, 3);

res = cell(ntrl, 4);
for i = 1:ntrl
    res(i,:) = core_bcd(X(:, :, i), fs, [2, 1]);
end
feat = reshape(cell2mat(res(:, 1:3)), [], 3);

end

