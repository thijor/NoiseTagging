function [subset,value] = jt_lcs_clustering(x,n)
%[subset,value] = jt_lcs_clustering(x,n)
%Finds the Least Correlating Subset using a hierarchical clustering.
%
%The variables are first clustered by complete link hierarchical 
%clustering. In this way, similar variables are grouped. then, from each
%cluster, one element is selected as representative, to further minimize 
%correlation with other clusters.
%
% INPUT
%   x = [s m] s samples of m variables
%   n = [int] number of variables in subset
%
% OUTPUT
%   subset = [1 n] ascending indices of the subset in x
%   value  = [flt] correlation value of the subset

numvar = size(x,2);
if n>numvar; error('x does not hold n variables!'); end

% Compute correlations
correlations = jt_correlation(x,x);
correlations = max(correlations,[],3);

% Cluster x
links = linkage(correlations,'single');
%dendrogram(links);
clusters = cluster(links,'maxclust',n)';

% Define the subset
correlations(logical(eye(numvar))) = NaN; %ignore diagonal
nons = zeros(1,numvar);
for icluster = 1:n
    % Define representative
    points = find(clusters==icluster);
    [~, index] = nanmin(nanmax(correlations(points,clusters~=icluster&~nons),[],2));
    % Remember non-representatives        
    nons = nons|ismember(1:size(x,2),points(points~=points(index)));
end
% Find subset
subset = find(~nons);

% Compute output
subset = sort(subset,'ascend');
value = nanmax(nanmax(correlations(subset, subset)));
