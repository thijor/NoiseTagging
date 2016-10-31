function [ boundary ] = nt_beta_boundary( similarities, accuracy, nseg )
%NT_BETA_BOUNDARY Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3
    nseg = 1;
end

boundary = zeros(1, size(similarities, 2));
for i = 1:size(similarities, 2)
    seg_similarities = similarities(:, i);
    nclasses = numel(seg_similarities);
    [~, maxi] = max(seg_similarities); 
    seg_similarities(maxi) = [];
    betas = betafit((seg_similarities + 1)/2); 
    boundary(i) = betainv(accuracy^(1/(nseg*nclasses)), betas(1), betas(2));
    boundary(i) = (boundary(i) * 2) - 1;
end

end

