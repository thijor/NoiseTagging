function [ model ] = pm_bcd_distributions( feat, Y )
%PM_BCD_DISTRIBUTIONS Summary of this function goes here
%   Detailed explanation goes here

threshold = [1e3 1e4 1e3]; 

good_idx = all(bsxfun(@lt, feat, threshold), 2);

if numel(Y) > 0
    good_idx = and(~reshape(Y, [], 1), good_idx);
end
good_feat = feat(good_idx, :);
m = mean(good_feat);
s = std(good_feat);
s0 = sqrt(mean(good_feat.^2));

model = struct('dc', struct('mean', m(1), 'std', s(1), 'zerostd', s0(1)), ...
    'fiftyhz', struct('mean', m(2), 'std', s(2), 'zerostd', s0(2)), ...
    'maxderiv', struct('mean', m(3), 'std', s(3), 'zerostd', s0(3)));

end

