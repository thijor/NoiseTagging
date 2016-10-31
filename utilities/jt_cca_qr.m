function [Wx,Wy,r,Ax,Ay] = jt_cca_qr(X,Y,lx,ly,k)
%[Wx,Wy,r,Ax,Ay] = jt_cca_qr(X,Y,lx,ly,k)
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

% Zero mean
X = bsxfun(@minus,X,mean(X,1));
Y = bsxfun(@minus,Y,mean(Y,1));

% QR decomposition
[Qx,Rx,Ox] = qr(X,0); % X=QxRx, Qx:[m p], Rx:[p p]
[Qy,Ry,Oy] = qr(Y,0); % Y=QyRy, Qy:[m q], Ry:[q q]

% Ranks
rx = rank(X); % now p=rx
Qx = Qx(:,1:rx);
Rx = Rx(1:rx,1:rx);
ry = rank(Y); % now q=ry
Qy = Qy(:,1:ry); 
Ry = Ry(1:ry,1:ry);
d = min(rx,ry);

% Re-order lambdas
lx = lx(Ox(1:rx));
ly = ly(Oy(1:ry));

% SVD
[U,S,V] = svd(Qx'*Qy,0); % Qx'Qy=USV', U:[p p], S:[p q], V:[q q]
r = diag(S);

% Wx and Wy
m = size(X,1);
Wx = (Rx'*Rx+diag(lx))\Rx'*U(:,1:d)*sqrt(m-1); % Wx=inv(Rx)U, Wx:[p p]
Wy = (Ry'*Ry+diag(ly))\Ry'*V(:,1:d)*sqrt(m-1); % Wy=inv(Ry)V, Wy:[q q]

% Rearrange weights
Wx(Ox,:) = [Wx; zeros(size(X,2)-rx,d)]; % Wx:[p p], p=original p
Wy(Oy,:) = [Wy; zeros(size(Y,2)-ry,d)]; % Wy:[q q], q=original q

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