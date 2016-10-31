function [classifier] = jt_tmc_train(data,cfg)
%[classifier] = jt_tmc_train(data,cfg)
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m k]  data of channels by samples by trials
%       .y   = [k 1]    labels: one by trials
%       .V   = [s p]    one period of trained sequences: samples by variables
%       .U   = [s q]    one period of test sequences: samples by variables
%   cfg = [struct] configuration structure
%         [struct] classifier with cfg and empty fields at retrainable properties
%
%   General:
%       .user           = [str] name of current user, only used for plotting ('user')
%       .verbosity      = [int] verbosity level: 0=off, 1=classifier, 2=classifier with cheaty accuracy, 3=classifier with cross-validated accuracy (1)
%       .fs             = [int] sample frequency (256)
%       .capfile        = [str] file name of electrode positions ('nt_cap64.loc')
%
%   Classification:
%       .nclasses       = [int] number of classes (2)
%       .method         = [str] classification method: fix=fixed-length trials, fwd=forward-stopping, bwd=backward-stopping ('fix')
%       .supervised     = [str] whether or not supervised ('yes')
%       .synchronous    = [str] whether or not synchronous ('yes')
%       .runcorrelation = [str] whether or not to use running correlations ('no')
%
%   Reconvolution
%       .cca            = [str] CCA method: qr, svd, cov, eig ('cov')
%       .L              = [1 e] length of transient responses in seconds (0.2)
%       .delay          = [1 e] positive delay of each event start (0)
%       .event          = [str] event type for decomposition: on, off, onoff, duration, ... ('duration')
%       .component      = [int] component CCA method to use (1)
%       .lx             = [int] regularization for Wx between 0 (unreliable) and 1 (reliable) (1)
%                       = [1 c] penalties for each c
%                       = [str] penalty type for Wx, i.e. filter
%       .ly             = [int] regularization for Wy between 0 (unreliable) and 1 (reliable) (1)
%                       = [1 l] penalties for each l
%                       = [str] penalty type for Wy, i.e. transients
%       .lxamp          = [flt] amplifier for lx regularization penalties, i.e., maximum penalty (0.1)
%       .lyamp          = [flt] amplifier for ly regularization penalties, i.e., maximum penalty (0.01)
%       .lyperc         = [flt] relative parts of the taper that is regularized (.2)
%       .modelonset     = [str] whether or not to model the onset, uses L(end) as length ('no')
%
%   Optimal Subset Selection:
%       .subsetV        = [1 n] training subset (1:nclasses)
%       .subsetU        = [1 n] testing subset
%                       = [str] default options or optimization ('no')
%
%   Optimal Layout Selection
%       .layoutV        = [1 n] training layout (1:nclasses)
%       .layoutU        = [1 n] testing layout
%                       = [str] default options or optimization ('no')
%       .neighbours     = [x 2] neighbour pairs ([])
%
%   Dynamic Stopping:
%       .stopping       = [str] stopping method: margin, beta ('beta')
%       .segmenttime    = [flt] data segment length in seconds (.1)
%       .maxsegments    = [int] maximum number of segments (10)
%       .forcestop      = [str] whether or not to force stop at maximum trial length ('yes')
%       .accuracy       = [flt] targeted stopping accuracy (.95)
%       .bound          = [str] bound for beta model ('ML')
%
%   Asynchronous
%       .shifttime      = [flt] step size for shifting templates in seconds (1/30)
%       .shifttimemax   = [flt] maximum shift step in seconds (1)
%
%   Transfer-learning
%       .transfermodel  = [str] which transfer model to use: train, transfer, transfertrain, no ('no')
%       .transferfile   = [str] file of the transfer model ('nt_model_chn64_ev144')
%       .transfercount  = [int] number of samples/weight of the model (0)
%
%   Unsupervised
%       .covfilter      = [int] amount of lookback in history (Inf)
%       .preinvert      = [str] whether or not to pre-invert covariance of structure matrices ('no')
%       .frstminsegment = [flt] minimum number of segments needed for first trial (.maxsegments)
%       .frstaccuracy   = [flt] targeted accuracy for first trial (.accuracy)
%
% OUTPUT
%   classifier = [struct] classifier structure:
%       .cfg        = [struct] configuration
%       .stim       = [struct] stimuli structure matrices
%           .Mvs = [l s n] structure matrices for V, period==1, subset and layout are applied
%           .Mvw = [l s n] structure matrices for V, period>1, subset and layout are applied
%           .Mus = [l s n] structure matrices for U, period==1, subset and layout are applied
%           .Muw = [l s n] structure matrices for U, period>1, subset and layout are applied
%           .iCm = [l l]   inverted covariance matrix
%       .transients = [l 1]    transient response(s)
%       .filter     = [c 1]    spatial filter
%       .covmodel   = [struct] covariance model
%           .count = [int] counter of data in model
%           .avg   = [N-D] running average
%           .cov   = [N-D] running covariance
%       .templates  = [struct] templates
%           .Tvs = [s n] templates for V, period==1, subset and layout are applied
%           .Tvw = [s n] templates for V, period>1, subset and layout are applied
%           .Tus = [s n] templates for U, period==1, subset and layout are applied
%           .Tuw = [s n] templates for U, period>1, subset and layout are applied
%       .subset     = [struct] testing subset
%           .V = [1 n] training subset for V
%           .U = [1 n] testing subset for V
%       .layout     = [struct] testing layout
%           .V = [1 n] training layout for V
%           .U = [1 n] testing layout for V
%       .margins    = [1 z]    threshold margins
%       .accuracy   = [struct] accuracy estimation
%           .p = [flt] estimate of accuracy
%           .t = [flt] estimate of trial length, i.e., forward stop
%           .d = [flt] estimate of data length, i.e., backward stop
%       .view       = [hdl]    figure handle to classifier figure

% Configuration
if nargin<2||isempty(cfg); cfg=[]; end
if jt_exists_in(data,'y'); data.y=data.y(:); end
classifier = jt_tmc_defaults(cfg);

% Structure matrices
if ~jt_exists_in(classifier,'stim') || ~jt_exists_in(classifier.stim,{'Mvs','Mvw','Mus','Muw'})
    classifier = jt_tmc_stimuli(classifier,data);
end

% Apply training subset and layout
classifier.subset.V = classifier.cfg.subsetV;
classifier.layout.V = classifier.cfg.layoutV;
classifier.stim.Mvs = classifier.stim.Mvs(:,:,classifier.subset.V(classifier.layout.V));
classifier.stim.Mvw = classifier.stim.Mvw(:,:,classifier.subset.V(classifier.layout.V));

% Deconvolution
if ~jt_exists_in(classifier,{'transients','filter'})
    classifier = jt_tmc_deconvolution(classifier,data);
end

% Convolution
if ~jt_exists_in(classifier,'templates') || ~jt_exists_in(classifier.templates,{'Tvs','Tvw','Tus','Tuw'})
    classifier = jt_tmc_convolution(classifier);
end

% Optimal subset
if ~jt_exists_in(classifier.subset,'U')
    classifier = jt_tmc_subset(classifier);
end

% Optimal layout
if ~jt_exists_in(classifier.layout,'U')
    classifier = jt_tmc_layout(classifier);
end

% Asynchronous
if ~classifier.cfg.synchronous
    classifier = jt_tmc_asynchronous(classifier);
end

% Margins
if ~jt_exists_in(classifier,'margins')
    classifier = jt_tmc_margins(classifier,data);
end

% Accuracy
if ~jt_exists_in(classifier,'accuracy')
    classifier = jt_tmc_accuracy(classifier,data);
end

% View classifier
if classifier.cfg.verbosity>0
    classifier = jt_tmc_view(classifier);
end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_defaults(cfg)

    % Initialize classifier
    if isfield(cfg,'cfg') 
        classifier = cfg;
    else
        classifier = [];
        classifier.cfg = cfg;
    end

    % General
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'user','user');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'verbosity',1);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'fs',256);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'capfile','nt_cap64.loc');

    % Classification
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'nclasses',2);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'method','fix');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'supervised','yes');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'synchronous','yes');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'runcorrelation','no');

    % Reconvolution
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'cca','cov');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'L',0.2);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'delay',0);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'event','duration');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'component',1);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'lx',1);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'ly',1);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'lxamp',0.1);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'lyamp',0.01);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'lyperc',.2);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'modelonset','no');

    % Subset
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'subsetV',1:classifier.cfg.nclasses);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'subsetU','no');

    % Layout
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'layoutV',1:classifier.cfg.nclasses);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'layoutU','no');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'neighbours',[]);

    % Dynamic Stopping
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'stopping','beta');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'segmenttime',.1);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'maxsegments',10);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'forcestop','yes');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'accuracy',.95);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'bound','ML');

    % Asynchronous
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'shifttime',1/30);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'shifttimemax',1);

    % Transfer-learning
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'transfermodel','no');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'transferfile','nt_model_chn64_ev144');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'transfercount',0);

    % Unsupervised
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'covfilter',Inf);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'preinvert','no');
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'frstaccuracy',classifier.cfg.accuracy);
    [~,classifier.cfg] = jt_parse_cfg(classifier.cfg,'frstminsegment',classifier.cfg.maxsegments);

    % Parse some
    classifier.cfg.supervised       = strcmpi(classifier.cfg.supervised    ,'yes');
    classifier.cfg.synchronous      = strcmpi(classifier.cfg.synchronous   ,'yes');
    classifier.cfg.modelonset       = strcmpi(classifier.cfg.modelonset    ,'yes');
    classifier.cfg.forcestop        = strcmpi(classifier.cfg.forcestop     ,'yes');
    classifier.cfg.preinvert        = strcmpi(classifier.cfg.preinvert     ,'yes');
    classifier.cfg.runcorrelation   = strcmpi(classifier.cfg.runcorrelation,'yes');
    
%--------------------------------------------------------------------------
function [classifier] = jt_tmc_stimuli(classifier,data)

    % Build structure matrices
    [s,p] = size(data.V);
    cfg = [];
    cfg.L           = floor(classifier.cfg.fs*classifier.cfg.L);
    cfg.delay       = floor(classifier.cfg.fs*classifier.cfg.delay);
    cfg.event       = classifier.cfg.event;
    cfg.modelonset  = classifier.cfg.modelonset;
    M = jt_structure_matrix(repmat(cat(2,data.V,data.U),[2 1]),cfg);
    classifier.stim.Mvs = M(:,1:s,1:p);
    classifier.stim.Mvw = M(:,1+s:end,1:p);
    classifier.stim.Mus = M(:,1:s,p+1:end);
    classifier.stim.Muw = M(:,1+s:end,p+1:end);

    % Make sure there is an L for each event
    if numel(classifier.cfg.L)==1
        classifier.cfg.L = repmat(classifier.cfg.L,[1 floor(size(M,1)/(classifier.cfg.L*classifier.cfg.fs))]); 
    end

    % Pre-compute the inverse structure matrix covariance
    if classifier.cfg.preinvert
        ly = pm_regularization(classifier.cfg.ly,floor(classifier.cfg.L*classifier.cfg.fs),classifier.cfg.modelonset,1e3);
        l = sum(classifier.cfg.L*classifier.cfg.fs);
        classifier.stim.iMu = real((cov(reshape(classifier.stim.Muw,l,[])')+diag(ly))^(-1/2));
    else
        classifier.stim.iMu = [];
    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_deconvolution(classifier,data)

    % Initialize
    classifier.transients = [];
    classifier.filter     = [];
    classifier.covmodel   = [];

    % Create full structure matrix 
    m = size(data.X,2);
    s = size(classifier.stim.Mvs,2);
    data.M = cat(2,classifier.stim.Mvs,repmat(classifier.stim.Mvw,[1 ceil(m/s)-1 1]));
    data.M = data.M(:,1:m,data.y);

    % Create configuration
    cfg = classifier.cfg;
    cfg.L = floor(classifier.cfg.fs.*classifier.cfg.L);

    % Supervised
    if classifier.cfg.supervised

        % Train transients only
        if jt_exists_in(classifier,'filter')
            classifier.transients = pm_decompose_ls(data.X,data.M,classifier,cfg);
        % Train filter only
        elseif jt_exists_in(classifier,'transients')
            [~,classifier.filter] = pm_decompose_ls(data.X,data.M,classifier,cfg);
        % Train transients and filter
        else
            [classifier.transients,classifier.filter] = jt_decompose_cca(data.X,data.M,cfg);
        end

    % Unsupervised
    else

        % Use transfer data 
        if any(strcmpi(classifier.cfg.transfermodel,{'transfer','transfertrain'}))
            in = load(classifier.cfg.transferfile);
            in.model.n = 1;
            [classifier.covmodel,classifier.filter,classifier.transients] = pm_recompose_cca([],[],in.model,cfg);
            classifier.covmodel.n = classifier.cfg.nclasses;
            if isnumeric(classifier.cfg.transfercount)
                classifier.covmodel.count = classifier.cfg.transfercount;
            end
        end

        % Use training data
        if any(strcmpi(classifier.cfg.transfermodel,{'train','transfertrain'})) && ~isempty(data.X) && ~isempty(data.y)
            [classifier.covmodel,classifier.filter,classifier.transients] = pm_recompose_cca(reshape(data.X,size(data.X,1),[]),reshape(data.M,size(data.M,1),[]),classifier.covmodel,cfg);
            classifier.covmodel.n = classifier.cfg.nclasses;
        end

    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_convolution(classifier)

    % Initialize
    classifier.templates.Tvs = [];
    classifier.templates.Tvw = [];
    classifier.templates.Tus = [];
    classifier.templates.Tuw = [];

    % Convolution
    if ~isempty(classifier.transients)
        classifier.templates.Tvs = jt_compose_cca(classifier.stim.Mvs,classifier.transients);
        classifier.templates.Tvw = jt_compose_cca(classifier.stim.Mvw,classifier.transients);
        classifier.templates.Tus = jt_compose_cca(classifier.stim.Mus,classifier.transients);
        classifier.templates.Tuw = jt_compose_cca(classifier.stim.Muw,classifier.transients);
    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_subset(classifier)

    % Select subset
    if isnumeric(classifier.cfg.subsetU)
        classifier.subset.U = classifier.cfg.subsetU;
    else
        switch classifier.cfg.subsetU

            case 'no'
                classifier.subset.U = 1:classifier.cfg.nclasses;

            case 'default_36'
                in = load('nt_subset.mat');
                classifier.subset.U = in.subset;

            case 'random'
                classifier.subset.U = randperm(size(classifier.templates.Tus,2),classifier.cfg.nclasses);

            case {'yes','clustering'}
                if strcmpi(classifier.cfg.supervised,'no'); 
                    error('Impossible to train a subset unsupervised!'); 
                end
                templates = cat(1,classifier.templates.Tus,classifier.templates.Tuw);
                classifier.subset.U = jt_lcs_clustering(templates,classifier.cfg.nclasses,classifier.cfg.synchronous,classifier.cfg.fs*classifier.cfg.segmenttime);

            otherwise
                error('jt_tmc_train: unknown lcs method %s.',lcs);
        end
    end

    % Apply subset
    classifier.stim.Mus = classifier.stim.Mus(:,:,classifier.subset.U);
    classifier.stim.Muw = classifier.stim.Muw(:,:,classifier.subset.U);
    if ~isempty(classifier.templates.Tus) && ~isempty(classifier.templates.Tuw)
        classifier.templates.Tus = classifier.templates.Tus(:,classifier.subset.U);
        classifier.templates.Tuw = classifier.templates.Tuw(:,classifier.subset.U);
    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_layout(classifier)

    % Select layout
    if isnumeric(classifier.cfg.layoutU)
        classifier.layout.U = classifier.cfg.layoutU;
    else
        switch classifier.cfg.layoutU

            case 'no'
                classifier.layout.U = 1:classifier.cfg.nclasses;

            case 'default_36'
                in = load('nt_layout.mat');
                classifier.layout.U = in.layout;

            case 'random'
                classifier.layout.U = randperm(size(classifier.templates.Tus,2),classifier.cfg.nclasses);

            case {'yes','incremental'}
                if strcmp(classifier.cfg.supervised,'no'); 
                    error('Impossible to train a layout unsupervised!'); 
                end
                templates = cat(1,classifier.templates.Tus,classifier.templates.Tuw);
                if isnumeric(classifier.cfg.neighbours) && numel(classifier.cfg.neighbours)==2
                    neighbours = jt_findneighbours(reshape((1:classifier.cfg.nclasses)',classifier.cfg.neighbours));
                end
                classifier.layout.U = jt_lcl_incremental(templates,neighbours,classifier.cfg.synchronous,classifier.cfg.fs*classifier.cfg.segmenttime);

            otherwise
                error('jt_tmc_train: unknown lcl method %s.',lcl);
        end
    end

    % Apply layout
    classifier.stim.Mus = classifier.stim.Mus(:,:,classifier.layout.U);
    classifier.stim.Muw = classifier.stim.Muw(:,:,classifier.layout.U);
    if ~isempty(classifier.templates.Tus) && ~isempty(classifier.templates.Tuw)
        classifier.templates.Tus = classifier.templates.Tus(:,classifier.layout.U);
        classifier.templates.Tuw = classifier.templates.Tuw(:,classifier.layout.U);
    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_asynchronous(classifier)

    % Check if templates can be or are already shifted
    if isempty(classifier.templates.Tus) || isempty(classifier.templates.Tuw) || size(classifier.templates.Tus,2)~=classifier.cfg.nclasses
        return;
    end

    % Add shifted templates
    d = classifier.cfg.shifttime*classifier.cfg.fs;
    n = floor(classifier.cfg.shifttimemax*classifier.cfg.fs/d);
    p = size(classifier.templates.Tvs,2);
    q = size(classifier.templates.Tus,2);
    for i = 2:n
        classifier.templates.Tvs = cat(2,classifier.templates.Tvs,circshift(classifier.templates.Tvs(:,end-p+1:end),d));
        classifier.templates.Tvw = cat(2,classifier.templates.Tvw,circshift(classifier.templates.Tvw(:,end-p+1:end),d));
        classifier.templates.Tus = cat(2,classifier.templates.Tus,circshift(classifier.templates.Tus(:,end-q+1:end),d));
        classifier.templates.Tuw = cat(2,classifier.templates.Tuw,circshift(classifier.templates.Tuw(:,end-q+1:end),d));
    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_margins(classifier,data)

    % Initialize
    classifier.margins = [];

    % Margins
    switch classifier.cfg.stopping

        case 'beta'
            classifier.margins = nan(1,classifier.cfg.maxsegments);

        case 'margin'
            if isempty(classifier.templates.Tvs) || isempty(classifier.templates.Tvw) || isempty(data.X) || isempty(data.y)
                error('Margins can only be computed given data and templates.');
            end

            X = tprod(data.X,[-1 1 2],classifier.filter,-1);
            m = size(X,1);
            s = size(classifier.templates.Tvs,1);
            T = cat(1,classifier.templates.Tvs,repmat(classifier.templates.Tvw,[ceil(m/s) 1]));
            T = T(1:m,:);
            cfg = [];
            cfg.nclasses        = classifier.cfg.nclasses;
            cfg.method          = classifier.cfg.method;
            cfg.segmentlength   = classifier.cfg.fs*classifier.cfg.segmenttime;
            cfg.forcestop       = classifier.cfg.forcestop;
            cfg.accuracy        = classifier.cfg.accuracy;
            classifier.margins = jt_learn_margins(X,data.y,T,cfg); 
    end

%--------------------------------------------------------------------------
function [classifier] = jt_tmc_accuracy(classifier,data)

    % Initialize
    classifier.accuracy = [];
    classifier.accuracy.p = [];
    classifier.accuracy.t = [];
    classifier.accuracy.d = [];

    % Check if accuracy can be computed
    if classifier.cfg.verbosity>1 && (~jt_exists_in(classifier.templates,{'Tvs','Tvw'}) || ~jt_exists_in(data,{'X','y'}) )
        warning('Changed verbosity level.');
        classifier.cfg.verbosity = 1;
    end

    % Accuracy
    switch classifier.cfg.verbosity

        case 2
            % Test directly on train data (cheaty)
            tmp = classifier;
            tmp.cfg.supervised = true;
            tmp.cfg.forcestop = true;
            tmp.templates.Tus = classifier.templates.Tvs;
            tmp.templates.Tuw = classifier.templates.Tvw;
            [labels,results] = jt_tmc_apply(tmp,data.X);
            classifier.accuracy.p = mean(labels==data.y);
            classifier.accuracy.t = mean(results.t);
            classifier.accuracy.d = mean(results.d);

        case 3
            % Cross-validation 10-fold
            tmp = classifier.cfg;
            tmp.supervised = true;
            results = jt_tmc_cv(data,tmp,10);
            classifier.accuracy.p = mean(results.p);
            classifier.accuracy.t = mean(results.t);
            classifier.accuracy.d = mean(results.d);
    end