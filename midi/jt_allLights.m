function jt_allLights(state,n,name,channel,noteon)
%jt_allLights(state,n,threadname,channel,noteon)
%Put all light on or off.
%
% INPUT
%   state      = [str] on|off ('on')
%   n          = [int] number of lights (6)
%   threadname = [str] midi threadname ('midi')
%   channel    = [int] midi channel (0)
%   noteon     = [int] midi noteon constant (144)

% Defaults
if nargin<1||isempty(state); state='on'; end
if nargin<2||isempty(n); n=6; end
if nargin<3||isempty(name); name='midi'; end
if nargin<4||isempty(channel); channel=0; end
if nargin<5||isempty(noteon); noteon=144; end

% Prepare sequence
if strcmpi(state,'on') 
    message = jt_code2midi(ones(1,n),channel,noteon);
else
    message = jt_code2midi(zeros(1,n),channel,noteon);
end

% Send midi message
jt_startMidiTable(struct('name',name,'msg',message,'timing',0));