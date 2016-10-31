function [c] = jt_euclidean(v,w,a,l)
%[c] = jt_euclidean(v,w,action)
%(Cross-)Euclidean similarity
%
% INPUT
%   v = [m p] matrix of p variables of m samples
%   w = [m q] matrix of q variables of m samples
%
% OPTIONS
%   a = [str] lock|shift|sgmfwd|sgmbck|sgmfwdbck (lock)
%   l = [int] length of segment (100)
%
% OUTPUT
%   c = [p q]     lock Euclidean similarity
%       [p q m]   shift Euclidean similarity
%       [p q l]   sgmfwd Euclidean similarity
%       [p q l]   sgmbck Euclidean similarity
%       [p q l l] sgmfwdbck Euclidean similarity

% Defaults
if nargin<2||isempty(w); w = v; end
if nargin<3||isempty(a); a='lock'; end
if nargin<4||isempty(l); l = 100; end

% Variables
[m,p] = size(v);
[m2,q] = size(w);
if m~=m2; error('Inconsistent sizes: v=%d, w=%d.',m,m2); end

% Perform action
switch lower(a)
    
    case 'lock'
        c = euclidean(v,w);
        
    case 'shift'
        c = nan(p,q,m);
        for i = 1:m
            c(:,:,i) = euclidean(v,circshift(w,[i-1 0]));
        end
        
    case 'sgmfwd'
        n = floor(m/l);
        c = nan(p,q,n);
        for i = 1:n
            idx = 1:i*l;
            c(:,:,i) = euclidean(v(idx,:),w(idx,:));
        end
        
    case 'sgmbck'
        n = floor(m/l);
        c = nan(p,q,n,n);
        for i = n:-1:1
            idx = 1+(i-1)*l:i*l;
            c(:,:,i) = euclidean(v(idx,:),w(idx,:));
        end
        
    case 'sgmfwdbck'
        n = floor(m/l);
        c = nan(p,q,n,n);
        for i = 1:n
            for j = 1:i
                idx = 1+(i-j)*l:i*l;
                c(:,:,i,j) = euclidean(v(idx,:),w(idx,:));
            end
        end
        
    otherwise
        error('Unknown action: %s',a)
        
end

c = 1 - c;

%-----------------------------------------------------
function [c] = euclidean(v,w)
    p = size(v,2);
    q = size(w,2);
    c = zeros(p,q);
    for i = 1:p
        for j = 1:q
            c(i,j) = sum((v(:,i)-w(:,j)).^(2),1).^(1/2);
        end
    end
    c = c./sqrt(size(v,1));