function jt_testMidiTable(example,cfg)
%jt_testMidiTable(example,cfg)
%Test sending a sequence of multiple midi messages via midi tables.
%
% INPUT
%   example = [int] which example midi table to play:
%   cfg = [struct] configuration structure
%       .port  = [str] midi sport port ('iRig MIDI 2')
%       .name  = [str] midi thread name ('midi')
%       .n     = [int] number of lights (6)
%       .bps   = [int] bits per second (160)
%       .time  = [flt] duration in seconds (60)

if nargin<1||isempty(example); example=1; end
if nargin<2||isempty(cfg); cfg=[]; end
port    = jt_parse_cfg(cfg,'port','iRig MIDI 2');
name    = jt_parse_cfg(cfg,'name','midi');
n       = jt_parse_cfg(cfg,'n',6);
bps     = jt_parse_cfg(cfg,'bps',160);
time    = jt_parse_cfg(cfg,'time',60);

% Generate codes
switch example
    case 1 % half-bps frequency for each light
        codes = repmat([ones(1,n);zeros(1,n)],[bps*time/2 1]);
    case 2 % 1:n hertz for individual lights
        codes = jt_make_frequency_code(1:n,bps,time);
    case 3 % modulated gold code for each light
        codes = jt_make_mgold_code;
        codes = repmat(codes,[ceil(bps*time/size(codes,1)) 1]);
        codes = codes(1:bps*time,1:n);
    otherwise
        error('Unknown example %d',example)
end

% Genarate midi and time tables
cfg = struct('bps',bps,'time',time,'end','off');
[miditable,timetable] = jt_mkMidiTable(codes,cfg);

% Build midi structure
midi = struct('name',name,'msg',miditable,'timing',timetable);

% Setup midi connection
jt_initMidiSender(port);

% Play the sequence
jt_startMidiTable(midi);

% Stop the sequence
% jt_stopMidiTable('midi');