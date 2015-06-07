function [layout,xcorr] = jt_lcl_incremental(x,maxiter,maxrand,doplot)
%[layout,xcorr] = jt_lcl_incremental(x,maxiter,maxrand,doplot)
%Optimize layout by starting with a random one, and improving it step by
%step.
%
% INPUT
%   x       = [m n] n variables of m samples
%   maxiter = [int] maximum number of iterations in optimization of one layout (50)
%   maxrand = [int] number of initial random layouts (50)
%   doplot  = [int] 2 if plot each iteration, 1 if first and last, 0 otherwise (0)
%
% OUTPUT
%   layout = [1 n] optimal layout
%   xcorr  = [flt] max pairwise correlation in layout

n = sqrt(size(x,2));
if rem(n,1)~=0; error('Columns in x is not square: [%d %d].',size(x)); end
if nargin<2; maxiter=50; end;
if nargin<3; maxrand=50; end;
if nargin<4; doplot=0; end

% Compute cross correlations
correlations = jt_correlation(x,x,'lock');

% Save best layout
layout = randperm(n^2)';
xcorr = 1;

% Try different initial designs
for k = 1:maxrand

    % Generate initial layout
    tmplayout = randperm(n^2)';
    neighbours = jt_findneighbours(tmplayout);

    % Start optimizing
    flag = 0; 
    iter = 0; 
    while ~flag && iter<=maxiter
        
        iter = iter+1;
        
        % Find worst neighbours
        [tmpxcorr,worstpair] = jt_findworstneighbours(neighbours,correlations);
        swaps = findswaps(tmplayout,worstpair);

        % Try all possible swaps
        values = zeros(1,size(swaps,1));
        for i = 1:size(swaps,1);
            [~,newneighbours] = swap(tmplayout,neighbours,swaps(i,:));
            values(i) = jt_findworstneighbours(newneighbours,correlations);
        end

        % Go on with best swapped layout
        [best,bestswap] = min(values);
        [tmplayout,neighbours] = swap(tmplayout,neighbours,swaps(bestswap,:));
        
        % Check if there was improvement, if not, abort
        if best >= tmpxcorr
            flag = 1;
        end

    end

    % Assign results
    if best < xcorr
        layout = tmplayout;
        xcorr  = best;
    end
    
end

% Reshape layout
layout = reshape(layout,[1 n^2]);

if doplot>0
    figure;
    jt_plotlcl(layout,correlations);
    title('Optimized')
end


%--------------------------------------------------------------------------
    function [layout,neighbours] = swap(layout, neighbours, pair)
    %[layout neighbours] = swap(layout, neighbours, pair)
    %
    % INPUT
    %   layout     = [n n] layout
    %   neighbours = [m 2] all neighbouring pairs
    %   pair       = [2 1] the pair to be swapped
    %
    % OUTPUT
    %   layout     = [n n] updated layout
    %   neighbours = [m 2] updated neighbouring pairs

    layout(layout==pair(1)) = NaN;
    neighbours(neighbours==pair(1)) = NaN;
    
    layout(layout==pair(2)) = pair(1);
    neighbours(neighbours==pair(2)) = pair(1);
    
    layout(isnan(layout)) = pair(2);
    neighbours(isnan(neighbours)) = pair(2);
    
    
%--------------------------------------------------------------------------
    function [swaps] = findswaps(all,pair)
    %[swaps] = findswaps(all,pair)
    %
    % INPUT
    %   all  [n^2 1] entire layout
    %   pair [2 1]   the worst pair
    %
    % OUTPUT
    %   swaps = [n^2-2 1] all possible swaps
    
    m = numel(all);
    swaps = [repmat(pair(1),m-2,1), find(~ismember(all,pair)); ...
             repmat(pair(2),m-2,1), find(~ismember(all,pair))];
