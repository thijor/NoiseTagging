function neighbours = jt_findneighbours(x)
%neighbours = jt_findneighbours(x)
%Finds all neighbouring pairs in x.
%
% INPUT
%   x = [n n]   Input matrix 
%       [n^2 1] Input vector
%  
% OUTPUT
%   neighbours = [p 2] all neighbouring pairs

n = sqrt(numel(x));
if rem(n,1)~=0; error('Input x is not a square matrix: [%d %d].',size(x)); end
if any(size(x)==1); x=reshape(x,[n n]); end

% Put a wrapper around
x = cat(1,zeros(1,n),x,zeros(1,n));
m = n+2;
x = cat(2,zeros(m,1),x,zeros(m,1));

% Find all neighbours
setting = [reshape(circshift(x,[ 1, 0]),[m^2,1]), ... % above
           reshape(circshift(x,[ 0,-1]),[m^2,1]), ... % right
           reshape(circshift(x,[-1, 0]),[m^2,1]), ... % below
           reshape(circshift(x,[ 0, 1]),[m^2,1]), ... % left
           reshape(circshift(x,[ 1,-1]),[m^2,1]), ... % above right
           reshape(circshift(x,[-1,-1]),[m^2,1]), ... % below right
           reshape(circshift(x,[-1, 1]),[m^2,1]), ... % below left
           reshape(circshift(x,[ 1, 1]),[m^2,1]), ... % above left
          ];
nsetting = size(setting,2);
         
% Find neigboring pairs
neighbours = [reshape(reshape(repmat(x(:),[1 nsetting])',...
                        [m^2 nsetting]) ,[m^2*nsetting 1]),...
              reshape(reshape(setting,...
                        [m^2 nsetting])',[m^2*nsetting 1]) ...
             ];
         
% Exclude double listed instances
neighbours = neighbours(neighbours(:,1)>neighbours(:,2),:);

% Remove wrapper
neighbours = neighbours(neighbours(:,1)~=0 & neighbours(:,2)~=0,:);
