function [R] = jt_fit_transient_erp(R,L,cfg)
%[R] = jt_fit_transient_erp(E,L,cfg)
%Fits a model to a transient ERP.
%
% INPUT
%   R = [c sum(L)] transient responses of [channels events]
%   L = [1 e]      length of each event
%   cfg = [struct] configuration structure containing:
%       .A  = [flt] mean amplitude (1)
%       .fc = [int] carrier frequency (14)
%       .pc = [flt] carrier phase (0)
%       .fm = [int] modulator frequency (5)
%       .pm = [flt] modulator phase (-.25)
% OUTPUT
%   E = [c s e] matrix of c channels, s samples and e fitted ERPs

% Defaults
R = double(R);
if nargin<2||isempty(cfg); cfg=[]; end
A   = jt_parse_cfg(cfg,'A',1);      % Mean amplitude
fc  = jt_parse_cfg(cfg,'fc',14);    % Carrier frequency
pc  = jt_parse_cfg(cfg,'pc',0);     % Carrier phase
fm  = jt_parse_cfg(cfg,'fm',5);     % Modulator frequency
pm  = jt_parse_cfg(cfg,'pm',-.25);  % Modulator phase
defaults = [A fc pc fm pm];

% Fit 
for i = 1:numel(L)
    taxis = double(0:L(i)-1);
    for j = 1:size(R,1)
        B = nlinfit(taxis,R(j,:,i),...
            @terp_model,defaults,statset('FunValCheck','off'));
        R(j,:,i) = terp_model(B,taxis);
    end
end

%--------------------------------------------------------------------------
function y = terp_model(B,x)
% Pulse response model
y = B(1) * carrier(x,B(2),B(3)) .* modulator(x,B(4),B(5));

%--------------------------------------------------------------------------
function y = carrier(x,f,p)
% Carrier model
y = sin(2.*pi.*(x.*f+p));

%--------------------------------------------------------------------------
function y = modulator(x,f,p)
% Modulator model
y = 1+sin(2.*pi.*(x.*f+p));