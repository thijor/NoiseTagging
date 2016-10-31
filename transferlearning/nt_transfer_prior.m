function nt_transfer_prior(channels)
addpath(fullfile('~','bci_code','own_experiments','visual','noise_tagging','matrixspeller','analysis','matrixspeller'));
if nargin<1; channels='all'; end
if isnumeric(channels); nchn=numel(channels); else nchn=64; channels=1:nchn; end

%% Parameters    

% Preprocessing
prpcfg = struct(...
    'verb',0,'fs',360,'reref','car','bands',{{[2 48]}},'fronttime',2,'chnthres','no','trlthres','no');

% Classifier configuration
fs = 360;
cfg = struct(...
    'nclasses',36,'cca','cov','L',[.2 .2],'delay',0,'event','duration',...
    'modelonset','no','component',1,'lx',.9,'ly','tukey','covfilter',inf);
cfg.L = floor(cfg.L*fs);
nev = sum(cfg.L);

% Data
experiment  = 'v3';
datafile    = '_raw';

%% Analyse

% Data
D = get_exp_info(experiment);
nsubjects = numel(D.subjects);

% Initialize covariance model
covs = zeros(nchn+nev, nchn+nev, nsubjects);
avgs = zeros(nchn+nev, nsubjects);
counts = zeros(1, nsubjects);

% Analyse
for i = 1:nsubjects
    fprintf('Subject %d\n', i);
    
    % Load data
    load(fullfile(D.repo,[D.subjects{i} datafile]));
    
    % Preprocess data
    if strcmpi(datafile,'_raw')
        trndata = jt_preproc_basic(trndata,prpcfg);
    end
    trndata = trndata(channels,:,:);
    X = reshape(trndata,nchn,[]);
    
    % Compute structure matrices
    M = jt_structure_matrix(trncodes(:,trnlabels),cfg);
    M = reshape(M,nev,[]);

    % Compute model
    model = pm_recompose_cca(X,M,[],cfg);
    covs(:,:,i) = model.cov;
    avgs(:,i)   = model.avg;
    counts(:,i) = model.count;
    
end

% Grand average
cov   = sum(covs,3) ./ size(covs,3);
avg   = sum(avgs,2) ./ size(avgs,2);
count = sum(counts) ./ numel(counts);
model = struct('n',cfg.nclasses,'c',nchn,'e',nev,'cov',cov,'avg',avg,'count',count);

% Show data
[~,Wx,Wy] = pm_recompose_cca([],[],model,cfg);
figure; 
subplot(2,1,1); jt_topoplot(Wx(:,1));
subplot(2,1,2); plot(Wy(:,1));

% Save model
fname = sprintf('~/bci_code/own_experiments/visual/noise_tagging/jt_box/transferlearning/example/nt_model_chn%d_ev%d',nchn,nev);
save(fname,'model');
