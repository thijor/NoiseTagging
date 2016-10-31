function [Wx,Wy,r,Ax,Ay] = jt_cca_svd(X,Y,k)
%[Wx,Wy,r,Ax,Ay] = jt_cca_svd(X,Y,k)
%
% INPUT
%   X      = [m p] p variables of m samples
%   Y      = [m q] q variables of m samples
%   k      = [int] number of component ('all')
%          = [1 n] indexes of components
%          = [str] 'all' components
%
% OUTPUT
%   Wx = [p k] k components with coefficients for X
%   Wy = [q k] k components with coefficients for Y
%   r  = [k 1] k canonical correlations between XWx and YWy
%   Ax = [p k] k components with activation patterns for X
%   Ay = [q k] k components with activation patterns for Y    

if nargin<3||isempty(k); k='all'; end

% Zero mean
X = bsxfun(@minus,X,mean(X,1));
Y = bsxfun(@minus,Y,mean(Y,1));

% SVD X and Y
[Ux,Sx,Vx] = svd(X,0);
[Uy,Sy,Vy] = svd(Y,0);

% SVD Ux'Uy
[U,S,V] = svd(Ux'*Uy,0);
r = diag(S);

% Coefficients
Wx = Vx/Sx*U;
Wy = Vy/Sy*V;

% Activation patterns
Ax = pinv(Wx)';
Ay = pinv(Wy)';
    
% Select component(s)
if ~strcmp(k,'all')
    Wx = Wx(:,k);
    Wy = Wy(:,k);
    r = r(k);
    Ax = Ax(:,k);
    Ay = Ay(:,k);
end