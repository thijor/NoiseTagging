function [flag] = jt_isprefpair(m,v,w,verb)
%[flag] = jt_isprefpair(m,v,w,verb)
%Checks whether or not the inputted variables form a preferred pair of
%m-sequences. 
%
% The requirements to be a preferred pair are:
% A: find ks and qs for which holds:
%  1. mod(m,2)=1 or 
%     mod(m,4)=2
%  2. integer k and odd integer q: 
%            q=2^(k)+1     or 
%            q=2^(2k)-2k+1
%  3. when mod(m,2)=1 then gcd(m,k)=1 or
%     when mod(m,4)=2 then gcd(m,k)=2
% B: try the ks and qs
%  1. Decimation of v with q should yield (a shifted version of) w
%
% INPUT
%   m = [int]     register length
%   v = [1 p]     Feedback Tap Positions 1
%       [2^m-1 1] M-sequence 1
%   w = [1 q]     Feedback Tap Positions 2
%       [2^m-1 1] M-sequence 2
%   
% OPTIONS
%   verb = [int] verbosity level (0)
%
% OUTPUT
%   flag = [int] 1 if preferred pair, otherwise 0

if nargin<4; verb=0; end
if length(v)~=2^m-1; v=jt_make_mls_code(m,v); end
if length(w)~=2^m-1; w=jt_make_mls_code(m,w); end

% Parameters
kmax = 50;
qmax = 50;

% Variables
ks = 1:1:kmax; 
qs = 1:2:qmax; 

% Find q and k
K = [];
Q = [];
for q=qs
    for k=ks
        if (mod(m,2) == 1 && (q==2^k+1 || q==2^(2*k)-2^k+1) && gcd(m,k)==1) || ...
           (mod(m,4) == 2 && (q==2^k+1 || q==2^(2*k)-2^k+1) && gcd(m,k)==2)    
            K=cat(2,K,k);
            Q=cat(2,Q,q);
        end
    end
end

if verb>0; fprintf('Found %d different combinations of q and k.\n',numel(Q)); end

% If values found, check decimation
if ~isempty(Q) 
    for i = 1:numel(Q)
        dseq = decimate(v,Q(i));
        if any(jt_cosine(w,dseq,'shift')==1) %dseq could be a shifted version
            if verb>0; fprintf('Conditions hold for k=%d and q=%d.\n',K(i),Q(i)); end
            flag = 1;
            return
        end
    end
end

% No values found, or none do apply
if verb>0; fprintf('Conditions do not hold.\n'); end
flag = 0;
return

%--------------------------------------------------------------------------
    function dseq = decimate(seq,q)
    repseq = repmat(seq,q,1);
    dseq   = repseq(q:q:end);
    
%--------------------------------------------------------------------------
    function testcase()
    jt_isprefpair(6,[6 1],[6 5 2 1],1); %true
    jt_isprefpair(6,[6 2],[6 5 2 1],1); %false
