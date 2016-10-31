function jt_lcs_plot(subset,xcors)
%jt_lcs_plot(subset,xcors)
%
% INPUT
%   subset = [n 1] subset 
%   xcors  = [n n] cross-correlations of all variables

n = numel(subset);

% Plot correlations
imshow(xcors,'InitialMagnification','fit','DisplayRange',[-1 1]);
colorbar;
drawnow;

% Put cell numbers in grid
for x = 1:n
    text(x,1,num2str(subset(x)));
end
for y = 2:n
    text(1,y,num2str(subset(y)));
end