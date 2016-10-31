function [Wx,Wy,r,Ax,Ay] = jt_cca(X,Y,lx,ly,k,method)
%[Wx,Wy,r,Ax,Ay] = jt_cca(X,Y,lx,ly,k,method)
%
% INPUT
%   X      = [m p] p variables of m samples
%   Y      = [m q] q variables of m samples
%   lx     = [flt] regularization X, range [0 1], 0 to suppress (1)
%            [p 1] regularization defined for each sample of X
%   ly     = [flt] regularization Y, range [0 1], 0 to suppress (1)
%            [q 1] regularization defined for each sample of Y
%   k      = [int] number of component ('all')
%          = [1 n] indexes of components
%          = [str] 'all' components
%   method = [str] method to use for CCA: qr|svd|cov|eig ('qr')
%
% OUTPUT
%   Wx = [p k] k components with coefficients for X
%   Wy = [q k] k components with coefficients for Y
%   r  = [k 1] k canonical correlations between XWx and YWy
%   Ax = [p k] k components with activation patterns for X
%   Ay = [q k] k components with activation patterns for Y    

if nargin<3||isempty(lx); lx=zeros(size(X,2),1); end; lx=lx(:);
if nargin<4||isempty(ly); ly=zeros(size(Y,2),1); end; ly=ly(:);
if nargin<5||isempty(method); method='qr'; end
if nargin<6||isempty(k); k='all'; end

% Do CCA
switch method
    case 'qr'
        [Wx,Wy,r,Ax,Ay] = jt_cca_qr (X,Y,lx,ly,k);
    case 'svd'
        [Wx,Wy,r,Ax,Ay] = jt_cca_svd(X,Y,k);
    case 'cov'
        [Wx,Wy,r,Ax,Ay] = jt_cca_cov(X,Y,lx,ly,k);
    case 'eig'
        [Wx,Wy,r,Ax,Ay] = jt_cca_eig(X,Y,lx,ly,k);
    otherwise
        error('Unknown method: %s.',method);
end