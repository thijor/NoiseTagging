function jt_topoplot(w,cfg)
%jt_topoplot(w,cfg)
%Plot topo
%
% INPUT
%   w   = [n 1]    the weights
%   cfg = [struct] configuration structure
%       .capfile    = [str] cap file (cap64.loc)
%       .electrodes = [str] how to depict the electrode (on)
%       .style      = [str] how to depict the head (map)
%       .headcolor  = [str] color of the head ('k')
%       .markersize = [str] marker size ([]) ([] is the default and  
%                     dependent on the number of channels plotted)

% Defaults
if nargin<2||isempty(cfg); cfg=[]; end
capfile     = jt_parse_cfg(cfg,'capfile','nt_cap64.loc');
electrodes  = jt_parse_cfg(cfg,'electrodes','on');
style       = jt_parse_cfg(cfg,'style','map');
headcolor   = jt_parse_cfg(cfg,'headcolor','k');
markersize  = jt_parse_cfg(cfg,'markersize',[]);

% Check extension
[~,file,ext] = fileparts(capfile);
if ~strcmpi(ext,'loc')
    capfile = [file '.loc'];
end

% Check cap existance
if ~exist(capfile,'file')
    error('Capfile not found on the path: %s.',capfile);
end

% Plot
topoplot(w,capfile,...
    'electrodes',electrodes,'style',style,'verbose','off',...
    'colormap',ikelvin,'hcolor',headcolor,'emarker',{'.','k',markersize,1});