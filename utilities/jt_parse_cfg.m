function [val,cfg] = jt_parse_cfg(cfg,key,def)
%[cfg,set] = jt_parse_cfg(cfg,set)
%Overwrites a default configuration structure with new settings.
%
% INPUT 
%   cfg = [struct] configuration
%   key = [str]    requested key
%   def = [ ? ]    default belonging to the key
%
% OUTPUT
%   val = [ ? ]    value belonging to the requested key
%   cfg = [struct] updated conficuration

% Defaults
if nargin<1||isempty(cfg); cfg=struct(); end
if nargin<2||isempty(key); return; end
if nargin<3||isempty(def); def=[]; end

% Search requested value
if isstruct(cfg) && isfield(cfg,key) && ~isempty(cfg.(key))
    val = cfg.(key);
else
    val = def;
end

% Add requested value
cfg.(key) = val;