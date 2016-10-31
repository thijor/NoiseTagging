function B = jt_itr(N,P,T,method)
%itr = jt_itr(N,P,T,method)
%Computes the Information Transfer Rate defined by Wolpaw.
%
% INPUT
%   N = [int] number of classes
%   P = [flt] classification rate
%   T = [flt] duration of one classification in seconds
%
% OPTIONS
%   method = [str] method to compute itr (Wolpaw)
%
% OUTPUT
%   B = [flt] Information Transfer Rate

if nargin<4||isempty(method); method='ritr'; end

% Get rid of ones and zeros
P(P>=1) = 1-eps;
P(P<=0) = eps;

% Compute bits/trial
switch lower(method)
    
    case 'itr'  
        B = wolpaw_itr(N,P); % bits/trial
        
    case 'ritr' 
        B = (60./T).*wolpaw_itr(N,P); %bits/minute
        
    case 'cr'
        B = wolpaw_itr(N,P)./log2(N); %char/trial
        
    case 'cpm'
        B = (60./T).*wolpaw_itr(N,P)./log2(N); %char/min
        
    case 'spm'
        B = (60./T).*max(0,(P-(1-P))); %char/min realistic
        
    case 'spm*'
        B = (60./T).*max(0,(P-(1-P))).*log2(N); %bits/min including N
         
    otherwise
        error('Unknown method: %s',method)
end

% Wolpaw definition of ITR
function B = wolpaw_itr(N,P)
    B = log2(N) + P.*log2(P) + (1-P).*log2((1-P)./(N-1));