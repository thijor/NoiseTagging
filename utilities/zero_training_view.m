function zero_training_view( data, cfg )
%[ figs ] = zero_training_view(data, cfg)
% Shows results of zero training
% 
% INPUT
%   data = [struct]
%       .response               [n m] n responses of m length
%       .spatial                [n m] n responses of m length
%       .act_res                [n m] n activation responses of m length
%       .act_sp                 [n m] n spatial activation of m length
%       .comp_data              [n m] n filtered component activation of m length
%       .comp_pred              [n m] n predicted component activation of m length
%       .code_perf              [n m] n performances for m codes
%       .ranking                [n m] n good label rankings on m trials
%       .accuracy               [n m] accuracies of n measures on m subjects
%       .cov                    [k l] covariance matrix

%   cfg = [struct]
%       .figure_num         [int] (1) figure number
%       .seperate_plots     [bool] (false) plot in different windows
%       .plot_response      [bool] (true) plot responses if data available
%       .plot_spatial       [bool] (true) plot second responses if available
%       .plot_act_sp        [bool] (true) plot spatial activation if available 
%       .plot_act_res       [bool] (true) plot response activation if available 
%       .plot_data          [bool] (true) plot component activation if available 
%       .plot_code_perf     [bool] (true) plot code performance if available
%       .plot_ranking       [bool] (true) plot good label rankings if available
%       .plot_accuracy      [bool] (true) plot accuracies if available
%       .plot_cov           [bool] (true) plot covariance matrix
%       .capfile            [str] ([]) capfile for spatial plot
%       .title              [str] ('') Super title when using subplots
%       .fs                 [int] (1) Sampling frequency
%       .L                  [n 1] ([]) Length of the responses

if nargin < 2
    cfg = struct();
end

plot_response   = jt_parse_cfg(cfg, 'plot_response', true);
plot_spatial    = jt_parse_cfg(cfg, 'plot_spatial', true);
plot_act_res    = jt_parse_cfg(cfg, 'plot_act_res', true);
plot_act_sp     = jt_parse_cfg(cfg, 'plot_act_sp', true);
plot_data       = jt_parse_cfg(cfg, 'plot_data', true);
plot_code_perf  = jt_parse_cfg(cfg, 'plot_code_perf', true);
plot_ranking    = jt_parse_cfg(cfg, 'plot_ranking', true);
plot_accuracy   = jt_parse_cfg(cfg, 'plot_accuracy', true);
plot_cov        = jt_parse_cfg(cfg, 'plot_cov', true);

seperate_plots  = jt_parse_cfg(cfg, 'seperate_plots', false);
figure_num      = jt_parse_cfg(cfg, 'figure_num', 1);
capfile         = jt_parse_cfg(cfg, 'capfile', []);
tit             = jt_parse_cfg(cfg, 'title', []);
fs              = jt_parse_cfg(cfg, 'fs', 1);
L               = jt_parse_cfg(cfg, 'L', []);

figure(figure_num);

plot_num = plot_response + plot_spatial + plot_act_res + plot_act_sp ...
    + plot_data + plot_code_perf + plot_ranking + plot_accuracy;
plot_count = 0;
if seperate_plots
    plot_count = figure_num;
end

times = (1:L(1))' / fs;

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_response);
if plot_response && isfield(data, 'response')
    data.response = reshape(data.response, L(1), []);
    plot(repmat(times, 1, size(data.response, 2)), data.response); 
    title('Response');
    xlabel('Time');
    ylabel('mV');
    ylim([-2.5 2.5]);
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_spatial);
if plot_spatial && isfield(data, 'spatial')
    jt_topoplot(data.spatial, struct('capfile', capfile));
    title('Spatial filter');
    xlabel('Channel');
    ylabel('Coefficient');
    ylim([-0.5 0.5])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_act_res);
if plot_act_res && isfield(data, 'act_res')
    plot(repmat(times, 1, size(data.act_res, 2)), data.act_res);
    title('Response activation');
    xlabel('Time');
    ylabel('?');
%     ylim([0.5 0.5])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_act_sp);
if plot_act_sp && isfield(data, 'act_sp')
%     plot(data.act_sp);
    jt_topoplot(data.act_sp, struct('capfile', capfile))
    title('Spatial activation');
    xlabel('Channel');
    ylabel('?');
%     ylim([0.5 0.5])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_data);
if plot_data && (isfield(data, 'comp_data') || isfield(data, 'comp_pred'))
    hold on
    legend_label = {};
    if isfield(data, 'comp_data')
        plot(data.comp_data);
        legend_label = {'Filtered component'};
    end
    if isfield(data, 'comp_pred')
        plot(data.comp_pred);
        legend_label = {legend_label{:}, 'Predicted component'};
    end
    hold off
    legend(legend_label);
    title('Component space');
    xlabel('Sample');
    ylabel('?');
%     ylim([0.5 0.5])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_code_perf);
if plot_code_perf && isfield(data, 'code_perf')
    scatter(mod((1:numel(data.code_perf))-1, size(data.code_perf, 1))+1, reshape(data.code_perf, 1, [])); 
    title('Code performance');
    xlabel('Code');
    ylabel('Performance');
    legend(cellstr(num2str((1:size(data.code_perf, 2))')))
    ylim([-1 1])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_ranking);
if plot_ranking && isfield(data, 'ranking')
    cla;
    hold on
    for row = data.ranking
        scatter(1:numel(row), row);
    end
    hold off
    title('Measure ranking');
    xlabel('Trial');
    ylabel('Rank');
    legend(cellstr(num2str((1:size(data.ranking, 2))')))
    ylim([0 36])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_accuracy);
if plot_accuracy && isfield(data, 'accuracy')
    cla;
    hold on
    for row = data.accuracy
        scatter(1:numel(row), row);
    end
    hold off
    title('Measure accuracy');
    xlabel('Subject');
    ylabel('Accuracy');
    legend(cellstr(num2str((1:size(data.accuracy, 2))')))
    ylim([0 1])
end

plot_count = new_window(seperate_plots, plot_count, plot_num, plot_cov);
if plot_cov && isfield(data, 'cov')
    cla; 
    if size(data.cov, 1) < size(data.cov, 2)
        data.cov = data.cov';
    end
    imagesc(data.cov);
    colorbar();
end

if numel(tit) > 0
    suptitle(tit)
end

drawnow

end

function plot_count = new_window(seperate_plots, plot_count, plot_num, plot_bool)

if plot_bool
    if seperate_plots
        figure(plot_count+1)
    else
        width   = ceil(sqrt(double(plot_num)));
        if width*(width-1) >= plot_num; height = width-1; else height = width; end
        subplot(height, width, plot_count+1);
    end

    plot_count = plot_count + 1;
end

end