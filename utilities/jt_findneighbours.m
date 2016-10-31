function nb = jt_findneighbours(lay)
%nb = jt_findneighbours(v)
%Finds all neighbouring pairs in v (up, down, left, right, left-diagonal,
%right-diagonal).
%
% INPUT
%   lay = [n m] layout
%  
% OUTPUT
%   nb = [k 2] neighbouring pairs

[n,m] = size(lay);
p = (n+2)*(m+2);

% Put wrapper around
lay = cat(1,nan(1,m),lay,nan(1,m));
lay = cat(2,nan(n+2,1),lay,nan(n+2,1));

% Find all neighbours
w = [reshape(circshift(lay,[ 0,-1]),[p,1]), ... % right
     reshape(circshift(lay,[-1, 0]),[p,1]), ... % below
     reshape(circshift(lay,[-1,-1]),[p,1]), ... % below right
     reshape(circshift(lay,[-1, 1]),[p,1])];    % below left
q = size(w,2);
         
% Find neigboring pairs
nb = [reshape(repmat(lay(:),[1 q])',[p*q 1]),...
              reshape(w',[p*q 1])];
         
% Remove wrapper
nb = nb(all(~isnan(nb),2),:);

% Sort neighbours
nb = sortrows(nb);