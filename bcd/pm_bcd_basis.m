function [ K_dc, K_fiftyhz, K_maxderiv ] = pm_bcd_basis( feat, model )
%[K_dc, K_fiftyhz, K_maxderiv] = pm_bcd_basis(feat, model)
%Probabilities for offset (dc), fifty hz and maximum derivative to be in a
%normal range. 
% 
% INPUT
%   feat        = [c 3] channels by [dc, fiftyhz, maxderiv] feature matrix
%   model       = [struct] normal values for dc, fiftyhz and maxderiv. See
%                   pm_bcd_train
%
% OUTPUT
%   K_dc        = [double] probability that the offset is normal
%   K_fiftyhz   = [2] probabilties that fiftyhz is normal (either around
%                   learned mean or close to zero)
%   K_maxderiv  = [2] probabilities that maxderiv is normal (either around
%                   learned mean or close to zero)

K_dc                = normpdf(feat(:, 1), 0, model.dc.zerostd) ...
    ./ normpdf(0, 0, model.dc.zerostd);
K_fiftyhz(:, 1)     = normpdf(feat(:, 2), model.fiftyhz.mean, model.fiftyhz.std) ...
    ./ normpdf(model.fiftyhz.mean, model.fiftyhz.mean, model.fiftyhz.std);
K_fiftyhz(:, 2)     = normpdf(feat(:, 2), 0, 5) ... % close to zero
    ./ normpdf(0, 0, 5);
K_maxderiv(:, 1)    = normpdf(feat(:, 3), model.maxderiv.mean, model.maxderiv.std) ...
    ./ normpdf(model.maxderiv.mean, model.maxderiv.mean, model.maxderiv.std);
K_maxderiv(:, 2)    = normpdf(feat(:, 3), 0, model.maxderiv.zerostd) ... % close to zero
    ./ normpdf(0, 0, model.maxderiv.zerostd);

end

