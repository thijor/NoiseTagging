function [ bad_channel ] = pm_bcd_apply( X, model, fs )
%model = pm_bcd_apply(X)
%Detect bad channels using a model trained on good data
%
% INPUT
%   X               = [c m k] Data of channels by samples by trials
%   fs              = [double] Sampling frequence
%   model           = [struct] Distribution parameters for voltage, 50hz and max derivative
% 
% OUTPUT
%   bad_channel     = [c 1] Probability for each channel to be good (1=good, 0=bad)


ntrials     = size(X, 3);

res = cell(ntrials, 4);
for i = 1:ntrials
    res(i, :) = core_bcd(X(:, :, i), fs, [2, 1]);
end
feat = reshape(cell2mat(res(:, 1:3)), [], 3);

[K1, K2, K3] = pm_bcd_basis(feat, model);

bad_channel = glmval(model.B, [K1, K2, K3], 'logit', 'constant', 'off', 'offset', model.intercept);

end

