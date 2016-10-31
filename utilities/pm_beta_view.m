function pm_beta_view( alphas, betas, fig, normalize, plot_properties )
% pm_beta_view( alphas, betas )
% Displays the beta distribution
% 
% INPUT
%   alphas      = [n 1] alpha parameters for beta distribution
%   betas       = [n 1] beta parameters for beta distribution
%   fig         = [int] figure number (8494)

if nargin < 3
    fig = 8494;
end
if nargin < 4
    normalize = false;
end
if nargin < 5
    plot_properties = {};
end

figure(fig)
cla;

xs = 0:0.001:1;
hold on;
for i = 1:numel(alphas)
    pdf = betapdf(xs, alphas(i), betas(i));
    if normalize
        pdf = pdf ./ max(pdf);
    end
    plot(xs, pdf, plot_properties{:});
end
hold off;

end

