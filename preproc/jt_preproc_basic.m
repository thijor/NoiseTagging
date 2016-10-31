function [X,ret] = jt_preproc_basic(X,cfg)
%[X,ret] = jt_preproc_basic(X,cfg)
%Preprocess data by performing: linear detrend, re-referencing, 
%spectral filter and removal of baseline data.
%
% INPUT
%   X   = [c t n]  data matrix of channels by time by trials
%   cfg = [struct] configuration structure:
%       .verb      = [int] verbosity level (0)
%       .fs        = [int] sample frequency (256)
%       .chnthres  = [flt] threshold for channel outlier removal ('no')
%       .trlthres  = [flt] threshold for trial outlier removal ('no')
%       .reref     = [str] re-reference procedure ('car')
%       .bands     = {n 2} cell of pass bands ({[5 48],[52 120]})
%       .fronttime = [flt] time in front of data to remove (0)
%
% OUTPUT
%   X   = [c t n]  preprocessed data matrix of channels by time by trials
%   ret = [struct] summary of pre-processing
%       .rmvchn = [1 c] 1 if channel outlier, 0 otherwise.
%       .rmvtrl = [1 n] 1 if trial outlier, 0 otherwise.

if isempty(X); ret = []; return; end
if nargin<2||isempty(cfg); cfg=[]; end
verb        = jt_parse_cfg(cfg,'verb',0);
fs          = jt_parse_cfg(cfg,'fs',256);
chnthres    = jt_parse_cfg(cfg,'chnthres','no');
trlthres    = jt_parse_cfg(cfg,'trlthres','no');
reref       = jt_parse_cfg(cfg,'reref','car');
bands       = jt_parse_cfg(cfg,'bands',{{[5 48],[52 120]}});
fronttime   = jt_parse_cfg(cfg,'fronttime',0);
[nchannels,nsamples,ntrials] = size(X);

% Remove outliers in channels 
if ~strcmpi(chnthres,'no') && nchannels>1 && ~isinf(chnthres)
    ret.rmvchn = idOutliers(X,1,chnthres);
    ret.rmvchn = squeeze(ret.rmvchn);
    X(ret.rmvchn,:,:) = [];
    if verb>0; fprintf('Removed %d channels.\n',sum(ret.rmvchn)); end
else
    ret.rmvchn = false(1,nchannels);
end

% Remove outliers in trials 
if ~strcmpi(trlthres,'no') && ntrials>1 && ~isinf(trlthres)
    ret.rmvtrl = idOutliers(X,3,trlthres);
    ret.rmvtrl = squeeze(ret.rmvtrl);
    X(:,:,ret.rmvtrl) = [];
    if verb>0; fprintf('Removed %d trials.\n',sum(ret.rmvtrl)); end
else
    ret.rmvtrl = false(1,ntrials);
end

% Linear detrend
X = detrend(X,2,1);

% CAR rereference
switch lower(reref)
    case 'nt8ch'
        X = repop(X,'-',mean(X([1 2 8],:,:)));
    case 'car'
        X = repop(X,'-',mean(X));
    case 'epoc'
        X = repop(X,'-',mean(X(7:8,:,:)));
    case 'oz'
        X = repop(X,'-',X(29,:,:));
    case 'ton'
        X = repop(X,'-',X(end,:,:));
    case 'no'
    otherwise
        error('Unknown reref method: %s',reref)
end

% Spectral filter
if ~strcmp(bands,'no')
    X = fftfilter(X,...
        mkFilter(floor(nsamples/2),bands,fs/nsamples),...
        nsamples,2,1,[],0,[],-1);
end

% Remove baseline data
if fronttime>0
    X = X(:,fronttime*fs+1:end,:);
    if verb>0; fprintf('Removed %d seconds of baseline.\n',fronttime); end
end