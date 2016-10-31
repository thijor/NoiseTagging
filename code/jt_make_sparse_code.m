function [codes] = jt_make_sparse_code(n,m,s,v,p)
%[codes] = jt_make_sparse_code(n,m,s,v,p)
%Generates sparse codes, i.e. lots of zeros and spaced ones
%
% INPUT
%   n = [int] number of codes
%   m = [int] number of samples
%   s = [1 2] min and max zeros in samples
%   v = [1 n] n lengths of on sequences
%   p = [1 n] n probabilities of each vars
%
% OUTPUT
%   codes = [m n] n sparse codes of m samples

% Defaults
if nargin<1||isempty(n); n=10;      end
if nargin<2||isempty(m); m=1800;    end
if nargin<3||isempty(s); s=[54 90]; end
if nargin<4||isempty(v); v=[1 2];   end
if nargin<5||isempty(p); p=[.5 .5]; end

% Check input
if numel(s)~=2; error('Variable s does not contain 2 variables!'); end
if numel(v)~=numel(p); error('Variables v and p differ in size!'); end
if sum(p)~=1; error('Probabilities in p do not add up to 1!'); end

% Make codes
codes = zeros(m,n);
for i = 1:n
    
    flag = 1;
    j = fix(rand(1)*(s(2)-s(1)))+s(1);
    while flag
        
        % Fill in ones
        k = v(find(cumsum(p)>rand(1),1));
        codes(j:j+k-1,i) = ones(k,1);
        j = j+k;
        
        % Fill in zeros
        j = j + fix(rand(1)*(s(2)-s(1)))+s(1) + 1;
        
        % Check
        if j+s(2) > m
            flag = 0;
        end
        
    end
    
end