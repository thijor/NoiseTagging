function [c,i] = jt_make_kasami_code(n,a,b)
%[c] = jt_make_kasami_code(m,a,b)
%Generates kasami codes.
% 
% INPUT
%   m = [int] register length (6)
%   a = [1 p] array of p feedback tab points ([6 1])
%   b = [1 q] array of q feedback tab points ([6 5 2 1])
% 
% OUTPUT
%   c = [2^m-1 (2^m+1)*2^(m/2)] bits by codes

% Check input
if nargin<1||isempty(n); n=6; end
if nargin<2||isempty(a); a=[6 1]; end
if nargin<3||isempty(b); b=[6 5 2 1]; end

% Check if preferred pair
if ~jt_isprefpair(n,a,b); 
    error('Invalid input: no preferred pair.'); 
end

% Generate two mls
u = jt_make_mls_code(n,a);
v = jt_make_mls_code(n,b);

% Decimate u
w = u(2^(n/2)+1:2^(n/2)+1:end);
w = repmat(w,[size(u,1)/size(w,1) 1]);

% Generate kasami codes
i = struct('large',[],'smallu',[],'smallv',[],'gold',[],'u',[],'v',[]);
c = zeros(2^n-1,2^n-1*(2^(n/2)-1));
for k = 0:2^n
    for m = 0:2^(n/2)-1
        index = k*2^(n/2)+m+1;
        
        % Save subset indices
        if     k<=2^n-2 && m<=2^(n/2)-2
            c(:,index) = mod(u+circshift(v,[k 0])+circshift(w,[m 0]),2);
            i.large  = cat(1,i.large ,index);
        elseif k==2^n-1 && m<=2^(n/2)-2
            c(:,index) = mod(u+circshift(w,[m 0]),2);
            i.smallu = cat(1,i.smallu,index);
        elseif k==2^n   && m<=2^(n/2)-2
            c(:,index) = mod(v+circshift(w,[m 0]),2);
            i.smallv = cat(1,i.smallv,index);
        elseif k<=2^n-2 && m==2^(n/2)-1
            c(:,index) = mod(u+circshift(v,[k 0]),2);
            i.gold   = cat(1,i.gold  ,index);
        elseif k==2^n-1 && m==2^(n/2)-1
            c(:,index) = v;
            i.v      = cat(1,i.v     ,index);
        elseif k==2^n   && m==2^(n/2)-1
            c(:,index) = u;
            i.u      = cat(1,i.u     ,index);
        else
            error('Indexes invalid: %d, %d.\n',i,m);
        end
    end
end

function testcase()
    % Parameters
    n = 6;          % length shift register
    a = [6 1];      % feedback tap positions 1
    b = [6 5 2 1];  % feedback tap positions 2

    % Generate kasami codes
    [kasami,index] = jt_make_kasami_code(n,a,b);

    % Select codes
    mls    = kasami(:,index.u);
    gold   = kasami(:,index.gold(1));
    kasami = kasami(:,index.smallu(1));

    % Compare generation
    q = 2^(n/2)+1;
    u = jt_make_mls_code(n,a);
    v = jt_make_mls_code(n,b);
    w = repmat(u(q:q:end),[q 1]);
    g = mod(u+v,2);
    k = mod(u+w,2);
    
    % Check
    disp([all(mls==u) all(gold==g) all(kasami==k)])