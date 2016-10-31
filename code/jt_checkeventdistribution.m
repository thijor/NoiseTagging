function [lengths,distributions] = jt_checkeventdistribution(var)
%[lengths,distributions] = jt_checkeventdistribution(var)
%Determines the distribution of events
% 
% INPUT
%   var = [m n] matrix of n variables of m samples
%       = {1 n} cell of n variables of arbitrary length
%
% OUTPUT
%   lengths 
%   distributions
    
if iscell(var)
    n = numel(var);
else
    [m,n] = size(var);
end

% Check distributions
lengths = [];
distributions = zeros(0,n);
for i = 1:n
    
    if iscell(var)
        v = var{i};
        m = length(v);
    else
        v = var(:,i);
    end
    
    % Find lengths of events
    eventlengths = diff([find(v); m+1]);
    
    % Extract lengths distribution
    ilengths = unique(eventlengths);
    if numel(ilengths)==1
        idistributions = numel(eventlengths);
    else
        idistributions = hist(eventlengths,ilengths)';
    end
    
    % Save distribution
    [in,idx] = ismember(ilengths,lengths);
    if any(in)
        idx = idx(idx~=0);
        distributions(idx,i) = idistributions(in);
    end
    if any(~in)
        nout = sum(~in);
        lengths = cat(1,lengths,ilengths(~in));
        [lengths,idx] = sort(lengths);
        distributions = cat(1,distributions,zeros(nout,n));
        distributions(end-nout+1:end,i) = idistributions(~in); 
        distributions = distributions(idx,:);
    end
    
end