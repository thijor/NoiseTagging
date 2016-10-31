function [ ] = nt_plot_similarities( similarities, label, times, boundary )
%NT_PLOT_SIMILARITIES Summary of this function goes here
%   Detailed explanation goes here

if nargin < 4
    boundary = [];
end

sim_times = repmat(times(1:size(similarities, 2)), size(similarities, 1), 1);

hold on;
plot(sim_times', similarities', 'Color', [.5 .5 .5]);
plot(sim_times(1, :), similarities(label, :), 'Color', 'g');

text = {'other', 'correct'};
if numel(boundary) > 0
    plot(sim_times(1, :), boundary, 'Color', 'b');
    text = {text{:}, 'decision boundary'};
end
hold off;

legend(text{:});

ylim([-1 1]);
xlim([0 max(times)]);

xlabel('Time (sec)');
ylabel('Correlation');

end

