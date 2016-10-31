function jt_lcl_plot(layout,xcors,range)
%jt_lcl_plot(layout,xcors,range)
%
% INPUT
%   layout = [n n]     Layout matrix 
%            [n^2 1]   Layout vector
%   xcors  = [n^2 n^2] cross-correlations of all variables
%   range  = [1 2]     range of colors [low high] 

n = sqrt(numel(layout));
if rem(n,1)~=0; error('Input x is not a square matrix: [%d %d].',size(x)); end
if any(size(layout)==1); layout=reshape(layout,[n n]); end
if nargin<3||isempty(range); range=[0 1]; end

% Generate grid with wrapper around
grid = nan(n*2+3,n*2+3);
grid(3:end-2,3:end-2) = jt_mkgrid(layout,xcors);

% Make small borders
board = cumsum(repmat([1,0,0,1],1,8));
board(end) = [];
grid = grid(board,board);

% Plot correlations
imshow(min(grid,1),'InitialMagnification','fit','DisplayRange',range);

% Put cell numbers in grid
[x,y] = meshgrid(n+(0:n-1)*4,n+(0:n-1)*4);
for i = 1:n^2
    [a,b] = ind2sub([n,n],i);
    text(x(a,b),y(a,b),num2str(layout(i)),'FontSize',7,'HorizontalAlignment','Center');
end

drawnow;