function [margins] = jt_learn_margins(X,y,T,cfg)
%[margins] = jt_learn_margins(X,y,T,cfg)
%Learn stopping margins for dynamic stopping.
%
% INPUT
%   X   = [m k]    data of samples by trials
%   y   = [k 1]    labels for each trial
%   T   = [m q]    templates of samples by classes
%   cfg = [struct] configuration structure
%       .method         = [str] method for timing/segmentation ('fix')
%       .model          = [str] model for learning margins ('normal')
%       .segmentlength  = [int] segment length samples (100)
%       .alpha          = [flt] probability of Type I error, 1-alpha is the confidence level (.05)
%       .accuracy       = [flt] targeted classification rate (.99)
%       .marginmin      = [flt] minimum of margins (0.01)
%       .marginmax      = [flt] maximum of margins (0.99)
%       .marginstep     = [flt] stepsize of margins (0.02)
%       .smooth         = [str] whether or not to smoot margins ('yes')
%
% OUTPUT
%   margins = [1 n] margin tresholds of segment (rows) by segment-length (columns)

% Defaults
if size(T,2)<2; error('Stopping cannot be trained on one-class data.'); end
if size(T,1)~=size(X,1); error('X and T have different number of samples'); end
if nargin<4||isempty(cfg); cfg=[]; end
method          = jt_parse_cfg(cfg,'method','fix');         % model timing to use
model           = jt_parse_cfg(cfg,'model','normal');       % model to use to
segmentlength   = jt_parse_cfg(cfg,'segmentlength',100);    % length of segment in samples
alpha           = jt_parse_cfg(cfg,'alpha',.05);            % probability of Type I error, 1-alpha is the confidence level
accuracy        = jt_parse_cfg(cfg,'accuracy',.99);         % targeted accuracy
marginmin       = jt_parse_cfg(cfg,'marginmin',0.01);       % min corelation for margin
marginmax       = jt_parse_cfg(cfg,'marginmax',0.99);       % max corelation for margin
marginstep      = jt_parse_cfg(cfg,'marginstep',0.05);      % correlation values to increase margin with
smooth          = jt_parse_cfg(cfg,'smooth','yes');         % whether or not to smoot margins

% Variables
[nsamples,ntrials] = size(X);
nclasses  = size(T,2);
nsegments = floor(nsamples/segmentlength);
margins   = nan(1,nsegments);

% For all segments, find correlation differences and correctness
if strcmpi(method,'fix')
    margins(1:end) = 1;
    return;
else
    similarity = jt_correlation_loop(T,X,'fwdbwd',segmentlength,nsegments);
    similarity = reshape(max(reshape(similarity,nclasses,[],ntrials,nsegments,nsegments),[],2),[nclasses ntrials nsegments nsegments]);
    [val,idx] = sort(similarity,1,'descend');
    D = squeeze(val(1,:,:,:)-val(2,:,:,:));
    C = squeeze(idx(1,:,:,:))==repmat(y(:),[1 nsegments nsegments]);
end
        
% Initialize variables
marginaxis = marginmin:marginstep:marginmax;
if strcmpi(model,'binom')
    z = norminv(1-alpha);
end

% Over segment length
for i = 1:nsegments 
    
    % Take all segments with equal length
    d = D(:,:,i); 
    d = d(:);
    c = C(:,:,i); 
    c = c(:);
    
    % Remove nans (upper diagonal)
    nanidx = isnan(d);
    d(nanidx) = [];
    c(nanidx) = [];

    % Compute histograms
    wronghist = hist(d(logical(~c)),marginaxis); 
    righthist = hist(d(logical( c)),marginaxis); 

    % Learn margin
    switch model

        case 'normal'
            % Reverse cummulative: how many will stop when margin > x
            wronghist = cumsum(wronghist(end:-1:1));
            wronghist = wronghist(end:-1:1);
            righthist = cumsum(righthist(end:-1:1));
            righthist = righthist(end:-1:1);

            % Compute performance
            perfs = righthist./(wronghist+righthist);

            % Find margin that makes global performance above targeted accuracy
            tresholdi = find(perfs>=accuracy,1);

        case 'binom'
            % Cummulative
            wronghist = cumsum(wronghist);
            righthist = cumsum(righthist);
            N = righthist+wronghist;

            % Compute proportions
            P = righthist./N;

            % Compute bounds of the binomial confidence interval (Wilson score interval)
            cilb = max(0,(2.*N.*P + z^2 - (z .* sqrt(z^2 - 1./N + 4*N.*P.*(1-P) + (4*P-2)) + 1) ) ./ (2*(N + z^2)));
            ciub = max(0,(2.*N.*P + z^2 + (z .* sqrt(z^2 - 1./N + 4*N.*P.*(1-P) + (4*P-2)) + 1) ) ./ (2*(N + z^2)));

            % Find margin that makes global performance above targeted accuracy
            tresholdi = find(ciub>=accuracy,1);

        otherwise
            error('Unknown model: %d.',model);
    end

    % Update thresholds and stopped trials
    if isempty(tresholdi) % No stoppers
        margins(i) = 1;
    else % Stoppers
        margins(i) = marginaxis(tresholdi);
    end
end

% Smooth margins
if strcmp(smooth,'yes')
    mrg = 0;
    for i = nsegments:-1:1
        if margins(i) <= mrg
            margins(i) = mrg;
        else
            mrg = margins(i);
        end
    end
end

%--------------------------------------------------------------------------
    function [margins] = jt_tmc_fit_margins(margins)
        n = numel(margins);
        xaxis = double(5/n:5/n:5);

        % Fit margin function
        B = nlinfit(xaxis',double(margins),@marginfunction,[1 1],statset('FunValCheck','off'));

        % Estimate margin function
        margins = marginfunction(B,xaxis);

%--------------------------------------------------------------------------
    function y = marginfunction(B,x)
        y = (B(1)^2-1) + B(1)^2 ./ exp(B(2) .* x);