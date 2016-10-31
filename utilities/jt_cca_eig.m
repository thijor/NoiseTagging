function [Wx,Wy,r,Ax,Ay] = jt_cca_eig(X,Y,lx,ly,k,iCxx,iCyy)
%[Wx,Wy,r,Ax,Ay] = jt_cca_eig(X,Y,lx,ly,k,iCxx,iCyy)
%
% INPUT
%   X      = [m p] p variables of m samples
%          = [p q] covariance matrix of X and Y, given Y=[];
%   Y      = [m q] q variables of m samples
%   lx     = [flt] regularization X, range [0 1], 0 to suppress (1)
%            [p 1] regularization defined for each sample of X
%   ly     = [flt] regularization Y, range [0 1], 0 to suppress (1)
%            [q 1] regularization defined for each sample of Y
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

if nargin<3||isempty(lx); lx=1; end; lx=lx(:);
if nargin<4||isempty(ly); ly=1; end; ly=ly(:);
if nargin<5||isempty(k); k='all'; end
if nargin<6; iCxx=[]; end
if nargin<7; iCyy=[]; end

% Covariances
if isempty(Y)
    C = X;
else
    X = bsxfun(@minus,X,mean(X,1));
    Y = bsxfun(@minus,Y,mean(Y,1));
    C = cov([X Y]);
end
p = numel(lx);
Cxx = C(1:p,1:p) + diag(lx);
Cxy = C(1:p,p+1:end);
Cyx = C(p+1:end,1:p);
Cyy = C(p+1:end,p+1:end) + diag(ly);

% Inversion
if isempty(iCxx)
    iCxx = real(Cxx^(-1/2));
end
if isempty(iCyy)
    iCyy = real(Cyy^(-1/2));
end

% Eigenvalue decomposition
[Wx,R] = eig(iCxx*Cxy*iCyy*Cyx);
r = sqrt(diag(R));
Wy = iCyy*Cyx*Wx;

if ~strcmp(k,'all')
    Wx = Wx(:,k);
    Wy = Wy(:,k);
    r = r(k);
end

% Activation patterns
if nargin>3
    Ax = Cxx*Wx;
    Ay = Cyy*Wy;
end