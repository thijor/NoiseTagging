function [var] = jt_modulate_code(var,cfg)
%[var] = jt_modulatecode(var)
%Modulates codes according to a certain process.
%
% INPUT
%   var = [m n]    m samples and n variables
%   cfg = [struct] configuration structure
%       .method = [str] modulation method: psk|run1
%
% OUTPUT
%   var = [k n] the modulated codes

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
method = jt_parse_cfg(cfg,'method','psk');

% Make sure input is binary
var = jt_x2bin(var);

switch lower(method)
    
    case {'psk','psk2'}

        % Upsample var
        var = jt_upsample(var,2);

        % Generate bitclock
        clock = zeros(size(var));
        clock(1:2:end,:) = 1;

        % Modulate var
        var = xor(var, clock);
        
    case 'psk3'
        % Upsample var
        var = jt_upsample(var,3);
        
        % Generate bitclock
        clock = zeros(size(var));
        clock(1:3:end,:) = 1;

        % Modulate var
        var = xor(var, clock);
        
    case 'run1'
        
        % Shift var
        shiftvar = circshift(var, [1 0]);
        shiftvar(1,:) = 0;

        % Compute contrast
        longs = var & shiftvar;
        
        % Make runs zeros
        var(longs) = 0;
        
        
    otherwise
        error('Unknown method: %s.',method)

end
