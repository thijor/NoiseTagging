function [subset,layout] = nt_transfer_lcs_lcl(channels)
% Zero-training by applying cca-based reconvolution to single-trials

if nargin<1; channels = 'all'; end

%% Parameters
fs      = 360;
fr      = 120;
if isnumeric(channels); nchn=numel(channels); else nchn=64; end;
nsmp    = 1512;
ntrl    = 36; 
cfg = struct(...
    'verbosity',2,'nclasses',36,'fs',fs,'method','bwd','synchronous','yes',...
    'cca','cov','L',[.2 .2],'delay',0,'event','duration','modelonset','no','component',1,'lx',.9,'ly','tukey',...
    'lcs','yes','lcl','yes','neighbours',jt_findneighbours(reshape((1:36)',[6 6])),...
    'stopping','beta','segmenttime',0.1,'accuracy',.95);

%% Data
experiment  = 'v3';
datafile    = '_raw';
D = get_exp_info(experiment);
nsubjects = 1;%numel(D.subjects);
prpcfg = struct('verb',0,'fs',fs,'reref','car','bands',{{[2 48]}},...
    'fronttime',2,'chnthres','no','trlthres','no');

%% Test codes
in = load('mgold_61_6521.mat');
codes = jt_upsample(in.codes, fs / fr);
codes = repmat(codes,[4 1]);

%% Analyse
Xs = zeros(nchn,nsmp,ntrl,nsubjects);
ys = zeros(ntrl,nsubjects);

for i = 1:nsubjects
    fprintf('Subject %d\n', i);
    
    % Load data
    load(fullfile(D.repo,[D.subjects{i} datafile]));
    
    % Preprocess data
    if strcmpi(datafile,'_raw')
        trndata = jt_preproc_basic(trndata,prpcfg);
    end
    
    % Select channels
    if isnumeric(channels)
        trndata = trndata(channels, :, :);
    end
    
    % Gather data
    % Note: subset and layout of traindata were always 1:36
    Xs(:,:,:,i) = trndata;
    ys(:,i) = trnlabels;
    
end

%% Train on all data from v3
data.X = reshape(Xs,[nchn nsmp ntrl*nsubjects]);
data.V = trncodes;
data.U = codes;
data.y = ys(:);
classifier = jt_tmc_train(data, cfg);

%% Save subset and layout
subset = classifier.subset;
layout = classifier.layout;

fprintf('subset=['); fprintf('%d ',subset); fprintf(']\n');
fprintf('layout=['); fprintf('%d ',layout); fprintf(']\n');

save(fullfile('~','bci_code','own_experiments','visual','noise_tagging','jt_box','transferlearning','example','nt_subset.mat'),...
    'subset');
save(fullfile('~','bci_code','own_experiments','visual','noise_tagging','jt_box','transferlearning','example','nt_layout.mat'),...
    'layout');