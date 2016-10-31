function c = jt_correlation_loop(v,w,a,m,n)
%c = jt_correlation_loop(v,w,method,m,n)
%
% INPUT
%   v = [s p] p variables of s samples
%   w = [s q] q variables of s samples
%   a = [str] correlation action: fix|fwd|bwd|fwdbwd|shift (fix)
%   m = [int] segment length (1)
%   n = [int] number of segments (s/m)
%
% OUTPUT
%   c = [N-D] correlation values:
%           fix:   [p q] = [v w]
%           fwd:   [p q n] = [v w f]
%           bwd:   [p q n] = [v w b]
%           fwdbwd:[p q n n] = [v w b f]
%           shift: [p q n] = [v w s]

s = size(v,1);
p = size(v,2);
q = size(w,2);
if nargin<3||isempty(a); a = 'fix'; end
if nargin<4||isempty(m); m = 1; end
if nargin<5||isempty(n); n = floor(s/m); end

switch a
    
    case 'fix'
        c = jt_correlation(v,w);
    
    case 'fwd'
        c = zeros(p,q,n);
        state = [];
        for f = 1:n
            idx = (f-1)*m+1:f*m;
            [corrs,state] = jt_correlation(v(idx,:),w(idx,:),state,n);
            c(:,:,f) = corrs(:,:,f);
        end
        
    case 'bwd'
        state = [];
        for f = 1:n
            idx = (f-1)*m+1:f*m;
            [corrs,state] = jt_correlation(v(idx,:),w(idx,:),state,n);
        end
        c = corrs;
        
    case 'fwdbwd'
        c = zeros(p,q,n,n);
        state = [];
        for f = 1:n
            idx = (f-1)*m+1:f*m;
            [c(:,:,:,f),state] = jt_correlation(v(idx,:),w(idx,:),state,n);
        end
        
    case 'shift'
        c = zeros(p,q,n);
        for s = 1:n
            w = circshift(w,m);
            c(:,:,s) = jt_correlation(v,w);
        end
        
end