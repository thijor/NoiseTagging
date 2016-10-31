function [  ] = nt_transfer_illustrate( timepoints, subject, outdir )
%NT_TRANSFER_ILLUSTRATE Summary of this function goes here
%   Detailed explanation goes here

addpath ~/Documents/MATLAB/altmany-export_fig-4c015d5/

if nargin < 3
    outdir = '~/output/zt_illustrate/good/';
end

%% Parameters
fs  = 360;          % Sample frequency
L   = .2;   % Transient length

nchn = 64;
nsmp = 1512;
ntrl = 36; 
nev = 144;

% Regularization param
cfg = struct(...
    'verbosity',2,'nclasses',1,'fs',fs,'method','zero',...
    'cca','cov','L',[L L],'event','duration','modelonset','no','component',1,'lx',.9,'ly','tukey',...
    'lcs','no','lcl','no','covfilter', inf,'marginmethod', 'betadist2',...
    'model','normal','segmentlength',4.2,'maxsegments', 1, 'alpha',.1,'accuracy',0.95,'forcestop','yes');

%% Data
experiment  = 'v3';
datafile    = '_raw';
D = get_exp_info(experiment);
prpcfg = struct('verb',0,'fs',fs,'reref','CAR','bands',{{[2 55]}},...
    'fronttime',2,'chnthres','no','trlthres','no');

%% Get data
fprintf('Subject %s\n', subject);

% Load data
load(fullfile(D.root,D.experiment,[subject datafile]));

% Preprocess data
if strcmpi(datafile,'_raw')
    tstdata = jt_preproc_basic(tstdata,prpcfg);
end
X = tstdata;

cfg.L = floor(cfg.L * cfg.fs);
% tstlabels = mod(tstlabels, 36) + 1;
M = jt_structure_matrix(tstcodes(:, tstlabels), cfg);


%% Apply CCA

for timepoint = timepoints
    ntrl = floor(timepoint / 4.2);
    
    [Wy, Wx] = jt_decompose_cca(X(:, :, 1:ntrl), M(:, :, 1:ntrl), cfg);

    figure('Visible', 'off'); cla; 
    jt_topoplot(Wx, struct('electrodes', 'numbers'));
    export_fig(sprintf('%s/reconvolution_filter_trl%.3d', outdir, ntrl), '-png', '-transparent', '-m5');
    
    figure('Visible', 'off'); cla; 
    plot(repmat((1:72) / fs, 2, 1)', reshape(Wy, [], numel(cfg.L)), 'LineWidth', 5);
    set(gca, 'YTick', []);
    set(gca, 'XTick', []);
%     xlabel('Time (sec)');
    export_fig(sprintf('%s/reconvolution_transient_trl%.3d', outdir, ntrl), '-png', '-transparent', '-m5');
    
    figure('Visible', 'off'); cla; hold on;
    start = 361;
    last = 720;
    trli = 2;
    Xc = tprod(Wx, -1, X, [-1, 1, 2]);
    Mc = tprod(Wy, -1, M, [-1, 1, 2]);
    plot((start:last) / fs, zscore(Xc(start:last, trli)), 'k', 'LineWidth', 5);
    plot((start:last) / fs, zscore(Mc(start:last, trli)), 'c', 'LineWidth', 5);
    set(gca, 'YTick', []);
    set(gca, 'XTick', []);
%     legend('Actual', 'Predicted');
    export_fig(sprintf('%s/reconvolution_predicted_trl%.3d', outdir, ntrl), '-png', '-transparent', '-m5');
    mean(diag(jt_correlation(Xc, Mc)))
    
end


end

