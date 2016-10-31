function [layout,value] = jt_lcl_incremental(v,nb,a,d,N,M)
%[layout,value] = jt_lcl_incremental(v,nb,a,d,N,M)
%
% INPUT
%   v  = [m p] p variables of s samples
%   nb = [k 2] k neighbour pairs
%   a  = [str] synchronous correlations ('yes')
%   d  = [int] length of segment (1)
%   N  = [int] maximum number of initial layouts (50)
%   M  = [int] maximum number of optimizations (50)
%
% OUTPUT
%   layout = [1 n] optimized layout
%   value  = [flt] max correlation in layout

n = size(v,2);
if nargin<2||isempty(nb); layout=1:n; return; end
if nargin<3||isempty(a); a='yes'; end
if nargin<4||isempty(d); d=1; end
if nargin<5||isempty(N); N=50; end
if nargin<6||isempty(M); M=50; end

% Compute correlation
if strcmp(a,'yes')
    c = jt_correlation(v,v);
else
    c = jt_correlation_loop(v,v,'shift',d);
    while length(size(c))>2
        c = squeeze(max(c,[],3));
    end
end

layout = 1:n;
value  = Inf;
for i = 1:N

    % Generate initial random layout
    lay = randperm(n);

    % Start optimizing
   for j = 1:M
        
        % Find worst neighbours
        [~,idx] = findworst(c,nb,lay);
        worst = nb(idx,:);
        
        % Find all possible swaps
        others = find(~ismember(1:n,worst))';
        swaps = [repmat(worst(1),n-2,1) others; ...
                 repmat(worst(2),n-2,1) others];

        % Try all possible swaps
        nswaps = size(swaps,1);
        vals = zeros(1,nswaps);
        for l = 1:nswaps
            vals(l) = findworst(c,nb,swap(lay,swaps(l,:)));
        end

        % Perform best swap
        [val,idx] = min(vals);
        lay = swap(lay,swaps(idx,:));
        
        % Stop if no improvement
        if val >= value
            break;
        end

    end

    % Assign results
    if val <= value
        layout = lay;
        value  = val;
    end
end
         
%--------------------------------------------------------------------------
    function [lay] = swap(lay,pair)
    lay(lay==pair(1)) = NaN;
    lay(lay==pair(2)) = pair(1);
    lay(isnan(lay)) = pair(2);
    
%--------------------------------------------------------------------------
    function [val,idx] = findworst(c,nb,lay)
    [val,idx] = max(c(sub2ind(size(c),lay(nb(:,1)),lay(nb(:,2)))));