function [labels,results,classifier] = jt_tmc_apply(classifier,X)
%[labels,results,classifier] = jt_tmc_apply(classifier,X)
%Apply the classifier to single-trial or multi-trial data.
%
% INPUT
%   classifier = [struct] classifier structure
%   X          = [c m k]  data of channels by samples by trials
%
% OUTPUT  
%   labels  = [k 1]    the predicted labels, NaN if below threshold
%   results = [struct] addition results of the classifier
%       .r   = [n k] similarity matrix of all n templates by k trials
%       .t   = [1 k] segment at which maximum was found in seconds
%       .d   = [1 k] segments used for classification in seconds
%       .v   = [1 k] similarity margin (1st-2nd) of segment at which maximum was found
%       .rho = [1 n] canonical correlations for all (unsupervised) models
%   classifier = [struct] updated classifier

% Classify
if size(X,3)==1
    [labels,results,classifier] = jt_tmc_apply_single(classifier,X);
else
    [labels,results,classifier] = jt_tmc_apply_multi(classifier,X);
end
   
% Post process results
labels = labels(:);
results.t = results.t.*classifier.cfg.segmenttime;
results.d = results.d.*classifier.cfg.segmenttime;

%--------------------------------------------------------------------------
% Match templates with single trials
function [label,result,classifier] = jt_tmc_apply_single(classifier,X)
    result = struct('r',0,'t',0,'d',0,'v',0,'rho',[]);
    
    if ~classifier.cfg.supervised && (isempty(classifier.covmodel) || classifier.covmodel.count<classifier.cfg.frstminsegment*classifier.cfg.segmenttime*classifier.cfg.fs)
        firsttrial = true;
    else
        firsttrial = false;
    end
    
    % Unsupervised: update classifier
    if ~classifier.cfg.supervised
        [classifier,result.rho] = pm_zt_update(X,classifier);
    end
    
    % Initialize variables
    s   = size(classifier.templates.Tus,1);
    ds  = floor(classifier.cfg.segmenttime*classifier.cfg.fs);
    m   = size(X,2);
    t   = floor(m/ds);
    
    % Compute correlations
    if classifier.cfg.runcorrelation
        % Extract new data
        idx = (t-1)*ds+1:t*ds;
        X = reshape(tprod(X(:,idx,:),[-1 1 2],classifier.filter,[-1 3],'n'),numel(idx),[]);
        T = cat(1,...
            classifier.templates.Tus(idx(idx<=s),:),...
            classifier.templates.Tuw(mod(idx(idx>s)-1,s)+1,:));

        % Update correlation state 
        if t<=1; classifier.state = []; end
        [r,classifier.state] = jt_correlation(T,X,classifier.state,classifier.cfg.maxsegments);
        if strcmpi(classifier.cfg.method,'bwd')
            r = r(:,:,1:t);
        else
            r = r(:,:,t);
        end
    else
        % Extract data
        X = reshape(tprod(X,[-1 1 2],classifier.filter,[-1 3],'n'),m,[]);
        T = cat(1,...
            classifier.templates.Tus,...
            repmat(classifier.templates.Tuw,[ceil(m/s)-1 1]));
        T = T(1:m,:);
        
        % Compute correlation 
        if strcmpi(classifier.cfg.method,'bwd')
            r = (jt_correlation_loop(T,X,'bwd',ds,t));
        else
            r = jt_correlation(T,X);
        end
    end
    
    % Unsupervised: select auto-models
    if ~classifier.cfg.supervised
        r = diag(r);
    end
    
    % Initialize stopping cfg
    cfg = [];
    cfg.method      = classifier.cfg.stopping;
    cfg.margins     = classifier.margins;
    cfg.bound       = classifier.cfg.bound;
    cfg.maxsegments = classifier.cfg.maxsegments;
	cfg.accuracy    = classifier.cfg.accuracy;
    % Set accuracy for unsupervised first trial
    if ~classifier.cfg.supervised && firsttrial
        cfg.accuracy = classifier.cfg.frstaccuracy;
    end
    
    % Classify
    switch classifier.cfg.method
        case 'fix'
            [val,idx] = sort(r,1,'descend');
            if t>=classifier.cfg.maxsegments 
                label = idx(1);
            else
                label = NaN;
            end
            ret.t = t;
            ret.v = val(1)-val(2);
        case 'fwd'
            cfg.t = t;
            [label,ret] = jt_tmc_certainty(r,cfg);
        case 'bwd'
            cfg.t = 1:t;
            [label,ret] = jt_tmc_certainty(r,cfg);
    end
    result.r = r;
    result.t = t;
    result.d = ret.t;
    result.v = ret.v;
    
    % Check minimum time for unsupervised first trial
    if ~classifier.cfg.supervised && ~isnan(label) && firsttrial && t<classifier.cfg.frstminsegment
        label = NaN;
    end

    % If maximum length reached and not classified
    if t>=classifier.cfg.maxsegments && isnan(label)
        [val,idx] = sort(r(:,:,end),1,'descend');
        result.r = r(:,:,end);
        result.t = t;
        result.d = t;
        result.v = val(1)-val(2);
        label = idx(1);
        if ~classifier.cfg.forcestop
            label = -label;
        end
    end

    % If unsupervised and classified update model
    if ~classifier.cfg.supervised && ~isnan(label) && ~(label<1)
        classifier = pm_zt_choose(label,classifier);
    end

%--------------------------------------------------------------------------
% Match templates with multiple trials
function [labels,results,classifier] = jt_tmc_apply_multi(classifier,X)
    results = struct('r',0,'t',0,'d',0,'v',0);
    
    [s,n]   = size(classifier.templates.Tus);
    [~,m,k] = size(X);
    ds      = floor(classifier.cfg.segmenttime*classifier.cfg.fs);
    t       = floor(m/ds);

    % Extract data
    T = cat(1,...
        classifier.templates.Tus,...
        repmat(classifier.templates.Tuw,[ceil(m/s)-1 1]));
    T = T(1:m,:);
    X = tprod(X,[-1 1 2],classifier.filter,-1);

    switch classifier.cfg.method
        case 'fix'
            r = jt_correlation_loop(T,X,'fix',ds,t);
            r = reshape(max(reshape(r,n,[],k),[],2),[n k]);
            [val,idx] = sort(r,1,'descend');
            labels = idx(1,:);
            results.r = r;
            results.t = ones(1,k)*t;
            results.d = ones(1,k)*t;
            results.v = val(1,:)-val(2,:);
        case 'fwd'
            r = jt_correlation_loop(T,X,'fwd',ds,t);
            r = reshape(max(reshape(r,n,[],k,t),[],2),[n k t]);
            [val,idx] = sort(r,1,'descend');
            margins = reshape(val(1,:,:)-val(2,:,:),[k t]);
            stopped = margins>=repmat(classifier.margins,[k 1]);
            if classifier.cfg.forcestop
                stopped(:,end) = 1;
            end
            [~,fwdidx] = max(stopped,[],2);
            bestidx   = sub2ind([n k t],  ones(k,1),(1:k)',fwdidx(:));
            secondidx = sub2ind([n k t],2*ones(k,1),(1:k)',fwdidx(:));
            labels = idx(bestidx);
            results.r = NaN;
            results.t = fwdidx;
            results.d = fwdidx;
            results.v = val(bestidx)-val(secondidx);
        case 'bwd'
            r = jt_correlation_loop(T,X,'fwdbwd',ds,t);
            r = permute(r,[1 2 4 3]);
            r = reshape(max(reshape(r,n,[],k,t,t),[],2),[n k t t]);
            [val,idx] = sort(r,1,'descend');
            margins = reshape(val(1,:,:,:)-val(2,:,:,:),[k t t]);
            stopped = margins>=permute(repmat(classifier.margins,[t 1 k]),[3 1 2]);
            if classifier.cfg.forcestop
                stopped(:,end,end) = 1;
            end
            [~,stopidx] = max(reshape(stopped,[k t*t]),[],2);
            [fwdidx,bwdidx] = ind2sub([t t],stopidx);
            bestidx   = sub2ind([n k t t],  ones(k,1),(1:k)',fwdidx,bwdidx);
            secondidx = sub2ind([n k t t],2*ones(k,1),(1:k)',fwdidx,bwdidx);
            labels = idx(bestidx);
            results.r = NaN;
            results.t = fwdidx;
            results.d = bwdidx;
            results.v = val(bestidx)-val(secondidx);
        otherwise
            error('Unknown method: %s.',classifier.cfg.method)
    end
    
%--------------------------------------------------------------------------
function [y,ret] = jt_tmc_certainty(similarity,cfg)
    %[y,ret] = jt_tmc_certainty(similarity,cfg)
    %
    % INPUT
    %   similarity       = [n k]    similarities of n classes by k steps
    %   cfg              = [struct] configuration
    %       .method      = [str] certainty method ('margin')
    %       .t           = [int] current segment (1)
    %       .accuracy    = [flt] targeted accuracy (.95)
    %       .maxsegments = [int] maximum number of segments (1)
    %       .bound       = [str] LowerBound, MaximumLikelihood or UpperBound ('ML')
    %       .margins     = [m 1] margin for m segments, used with margin method ([])
    %
    % OUTPUT
    %   y   = [int]    selected label, NaN none selected
    %   ret = [struct] results structure
    %       .t  [int] best segment, last if none selected
    %       .v  [flt] certainty of best class
    %       .vs [flt] certainty of all classes

    t = cfg.t;
    n = numel(t);
    y = NaN;
    ret = struct('t',[],'v',[],'vs',[]);
    switch cfg.method

        % use pre-learned margins as thresholds for confidence of maximum
        case 'margin'

            % Sort values
            [val,idx] = sort(similarity,1,'descend');

            % Difference best and second best
            v = val(1,:) - val(2,:);
            vs = bsxfun(@minus,val,val(2,:));
            vs = vs(idx);

            % Check if margins reached
            stopped = v >= cfg.margins(t);

            % Select stopped segment
            if any(stopped)
                i   = find(stopped,1);
                y   = idx(1,i);
                ret.t  = t(i);
                ret.v  = v(i);
                ret.vs = vs(:,i);
            else
                ret.t  = t(end);
                ret.v  = v(end);
                ret.vs = vs(:,end);
            end

        % Use a beta model to determine confidence of maximum
        case 'beta'

            for i = 1:n
                % Compute probability that max correlation is higher than others
                ret.vs = pm_max_corr(similarity(:,i),[],cfg.bound);
                ret.v  = max(ret.vs);
                ret.t  = t(i);

                % Stop if probability is large
                if ret.v > cfg.accuracy ^ (1/cfg.maxsegments)
                    [~,y] = max(similarity(:,i));
                    break;
                end
            end

        case 'beta_margin'

            cs = (similarity + 1) / 2;
            [~, cmaxi] = max(cs);
            nonmax = cs([1:cmaxi-1, cmaxi+1:numel(cs)]);
            beta = betafit(nonmax);
            xs = 0:0.01:1;
            cdf = arrayfun(@(x) nt_beta_diff(beta(1), beta(2), numel(cs), x), xs);
            cdf = cdf ./ sum(cdf);
            ret.v = sum(cdf(xs < cs(cmaxi) - max(nonmax)));
            if ret.v>cfg.accuracy
                [~,y] = max(similarity);
            end
            ret.vs = [];

        otherwise
            error('Unknown method: %s.',cfg.method);

    end

%--------------------------------------------------------------------------
function [p] = nt_beta_diff(a,b,n,z)
    stepsize    = 0.0001;
    norm        = n .* (n - 1) * beta(a, b).^(-2);
    xs = 0:stepsize:1-z; %linspace(0, 1-z, 1000);
    integral = betacdf(xs, a, b) .^ (n - 2) ...
        .* xs .^ (a-1) ...
        .* (1-xs) .^ (b-1) ...
        .* (xs+z) .^ (a-1) ...
        .* (1-xs-z) .^ (b-1);
    p = norm .* sum(integral) * stepsize;