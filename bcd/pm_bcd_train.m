function [ model ] = pm_bcd_train( X, fs, Y )
%model = pm_bcd_train(X)
%Trains a model on good data for online bad channel detection.
%
% INPUT
%   X       = [c m k]   Data of channels by samples by trials
%   fs      = double    Sampling frequence
%   Y       = [c k]     Default: []. Bad channel label (1=bad, 0=good) for each channel by trial
% 
% OUTPUT
%   model           = [struct]  distribution parameters for voltage, 50hz and max derivative
%       .dc         = [struct]  parameters for voltage
%           .mean               mean voltage
%           .std                standard devation voltage
%           .zerostd            deviation from zero of voltage
%       .fiftyhz    = [struct]  parameters for fiftyhz
%           {.mean, .std, .zerostd}
%       .maxderiv   = [strcut]  parameters for maximum derivative
%           {.mean, .std, .zerostd}

if nargin < 3
    Y = [];
end

Y = logical(Y);

%% Gaussian kernels
feat = pm_bcd_features(X, fs);
model = pm_bcd_distributions(feat, Y);
[K_dc, K_fiftyhz, K_maxdiff] = pm_bcd_basis(feat, model);

%% Regularized linear regression parameters
Y = reshape(Y, [], 1);

lambda = 1e-4;
if numel(Y) > 0
%     [B1, FitInfo1] = lassoglm(K_dc, Y, 'binomial', 'Link', 'logit', 'Lambda', lambda);
%     [B2, FitInfo2] = lassoglm(K_fiftyhz, Y, 'binomial', 'Link', 'logit', 'Lambda', lambda);
%     [B3, FitInfo3] = lassoglm(K_maxderiv, Y, 'binomial', 'Link', 'logit', 'Lambda', lambda);
%     intercept1 = FitInfo1.Intercept;
%     p1 = glmval(B1, K_dc, 'logit', 'constant', 'off', 'offset',  intercept1);
%     intercept2 = FitInfo2.Intercept;
%     p2 = glmval(B2, K_fiftyhz, 'logit', 'constant', 'off', 'offset', intercept2);
%     intercept3 = FitInfo3.Intercept;
%     p3 = glmval(B3, K_maxderiv, 'logit', 'constant', 'off', 'offset', intercept3);
%     [B, FitInfo] = lassoglm([p1 p2 p3], Y, 'binomial', 'Link', 'logit', 'Lambda', lambda);
%     intercept = FitInfo.Intercept;
%     p = glmval(B, [p1 p2 p3], 'logit', 'constant', 'off', 'offset', intercept);
    
    
    [B FitInfo] = lassoglm([K_dc, K_fiftyhz, K_maxdiff], Y, 'binomial', ...
        'Link', 'logit', 'Alpha', 0.5, 'Lambda', lambda);
    intercept   = FitInfo.Intercept;
else
%     B           = [   -4.1284; -3.8544; 6.2025; -3.4175; -0.3050];
%     intercept   = 1.1083;
    B           = [-14.4190; -11.4448; 5.7527; -1.4311; 0];
    intercept   = 8.8339;
end

model.B                  = B;
model.intercept          = intercept;

end

