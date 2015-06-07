function [T,R,ret] = jt_reconvolution(X,y,V,U,cfg)
%[T,R,ret] = jt_reconvolution(X,y,V,U,cfg)
%Apply reconvolution to responses (X) to specific sequences (V) labeled 
%accordingly (y), in order to predict responses (T) to other sequences (U). 
%This is achieved by decomposing X according to V into transient responses 
%(R) that can be used to predict responses (T) by superposition of R
%according to U.
%Each transient response Ri...Rn has a specific component length Li...Ln.
%
% INPUT
%   X   = [c m k]  data of [channels samples trials]
%   y   = [1 k]    labels for each trials
%   V   = [m p]    trained sequences of [samples sequences]
%   U   = [m q]    predict sequences of [samples sequences] 
%   cfg = [struct] configuration structure
%       .L     = [1 e] length of transient responses in seconds (100)
%       .event = [str] type of decomposition event:
%                       duration|on|off|onoff|switch|seq (duration)
%
% OUTPUT
%   T   = [c m q]    predicted responses of [channels samples sequences]
%   R   = [c sum(L)] transient responses of [channels events]
%   ret = [1 e]      events

% Defaults
if nargin<5||isempty(cfg); cfg=[]; end
L       = jt_parse_cfg(cfg,'L',100);
event   = jt_parse_cfg(cfg,'event','duration');

% Variables
[~,sx,k] = size(X);
[sv,p] = size(V);
su = size(U,1);

% Check input
if sx~=sv||sv~=su; error('Error: Inconsistent sample sizes: X=%d, V=%d, U=%d.',sx,sv,su); end
if any(y<1)||any(y>p)||numel(y)~=k; error('Error: Invalid y.'); end

% Derive events
[E,ret] = jt_event_matrix([V,U],event);
Ev = E(:,:,1:p);
Eu = E(:,:,p+1:end);

% Construct structure matrices
Mv = jt_structure_matrix(Ev,L);
Mu = jt_structure_matrix(Eu,L);

% Decompose transient responses
R = jt_decompose(Mv(:,:,y),X);

% Predict responses
T = jt_compose(Mu,R); 
