function [last_xs, last_ys, xs_, ys_] = nt_transfered_bits_plot(trialtimes, correct, plot_cfg, offset_x, offset_y)

if nargin < 3
    plot_cfg = []
end
if nargin < 4
    offset_x = 0;
end
if nargin < 5
    offset_y = 0;
end

correct = +correct;
correct(correct == 0) = -1;
% ys = horzcat(0, cumsum(correct));
% xs = horzcat(0, cumsum(trialtimes));
ys = cumsum(correct);
xs = cumsum(trialtimes);

samples = 100;
xs_ = linspace(min(xs), max(xs), samples);
ys_ = interp1(xs, ys, xs_, 'previous') + offset_y;
xs_ = xs_ + offset_x;

plot(xs_, ys_, plot_cfg);

last_xs = xs(end);
last_ys = ys(end);