function [accuracy] = jt_best_channel(data,cfg)
%[accuracy] = jt_best_channel(data,cfg)
%Cross-validation over channels to estimate a performance for each channel.
%
% INPUT
%   data = [struct] data structure:
%       .X   = [c m k]  data of channels by samples by trials
%       .y   = [1 k]    labels indicating class-index for each trial
%       .V   = [m p]    train sequences of samples by classes
%       .Mv  = [m e p]  structure matrices of V
%   cfg = [struct] configuration structure:
%       .L     = [1 r] length of transient responses in samples (100)
%       .event = [str] type of decomposition event ('duration')
%
% OUTPUT
%   accuracy = [c 1] accuracies for each channel

c = size(data.X,1);

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end

% Pre-compute structure matrices
if ~isfield(data,'Mv')
    Mv = jt_structure_matrix(data.V,cfg);
else
    Mv = data.Mv;
end

% Pre-compute folds
nfolds = 10;
cv = cvpartition(numel(data.y),'Kfold',nfolds);

% Analyse
accuracy = zeros(nfolds,c);
for i = 1:nfolds
    
    % Select data
    trnX = data.X(:,:,cv.training(i));
    tstX = data.X(:,:,cv.test(i));
    trnY = data.y(cv.training(i));
	tstY = data.y(cv.test(i));
    
    % Build templates (note: independent over channels)
    tmp = [];
    tmp.X = trnX;
    tmp.y = trnY;
    tmp.Mv = Mv;
    tmp.Mu = Mv;
	Tv = jt_reconvolution(tmp,cfg);
    
    for j = 1:c
        
        % Correlate channels
        [~,prediction] = max(jt_correlation(squeeze(Tv(j,:,:)),squeeze(tstX(j,:,:))));
        accuracy(i,j) = mean(tstY==prediction');
        
    end
end

% Average over folds
accuracy = mean(accuracy,1);