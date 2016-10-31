function jt_printcounter(i,s,d)
%jt_printcounter(i,s,d)
%Prints the current counter, overwriting previous ones.
%
% INPUT
%   i = [int] counter
%   s = [int] start value (1)
%   d = [int] stepsize (1)

% Defaults
if nargin<2||isempty(s); s=1; end
if nargin<3||isempty(d); d=1; end

% Delete previous eof
if i==s; fprintf('\b'); end

% Delete previous counters
if i>s
    for j=0:log10(i-d)+1
        fprintf('\b');
    end
end

% Print counter
fprintf('%d\n', i); 