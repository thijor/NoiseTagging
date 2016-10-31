function [midiTable,timeTable] = jt_mkMidiTable(var,cfg)
%[midiTable,timeTable] = jt_mkMidiTable(var,cfg)
%Generates midi and time table for a specified setting
%
% INPUT
%   var = [m n]    matrix of n variables of m samples
%   cfg = [struct] configuration structure
%       .channel  = [int] channel for midi (0)
%       .noteon   = [int] noteon for midi  (144)
%       .keys     = [1 n] midi keys        (61:68) 
%       .bps      = [int] bits per second  (120)
%       .time     = [flt] total time (sec) (m/bps)
%       .velon    = [int] on velocity      (127)
%       .veloff   = [int] off velocity     (0) 
%       .mode     = [str] pc|noo           ('pc')
%       .endstate = [str] on|off|not       ('on')
%
% OUTPUT
%   midiTable = [q 3] q midi messages of following format:
%                       [channel, key, velocity] if note-on note-off
%                       [channel, byte1, byte2]  if program change
%   timeTable = [q 1] q timings for each midi message in milliseconds.

% Defaults
channel     = jt_parse_cfg(cfg,'channel',0);        % channel for midi
noteon      = jt_parse_cfg(cfg,'noteon',144);       % noteon constant for idi
keys        = jt_parse_cfg(cfg,'keys',61:68);       % keys for midi
bps         = jt_parse_cfg(cfg,'bps',120);          % bits per minute
time        = jt_parse_cfg(cfg,'time',[]);          % time in total for midi table
velon       = jt_parse_cfg(cfg,'velon',127);        % velocity on
veloff      = jt_parse_cfg(cfg,'veloff',0);         % velocity off
mode        = jt_parse_cfg(cfg,'mode','pc');        % mode: Program Change or Note On-Off
endstate    = jt_parse_cfg(cfg,'endstate','on');    % end state: on or off or not

% Convert to matrix if needed
if iscell(var)
    var = jt_cell2mat(var); 
end
[numbits,numvar] = size(var);

% Repeat codebook to fit time entirely
if ~isempty(time)
    var = repmat(var,[ceil(time*bps/numbits) 1]);
    var = var(1:ceil(time*bps),:);
end

% Add end state at back
switch endstate
    case 'on'
        var = [var;ones(1,numvar)];
    case 'off'
        var = [var;zeros(1,numvar)];  
    case 'not'
    otherwise
        error('Not supported end state')
end

% Determine onsets and offsets
shiftvar = circshift(var,[1 0]);
onsets   =  var & ~shiftvar; 
offsets  = ~var &  shiftvar; 

% Generate tables
switch mode
    case 'noo' %note on-off
        
        % Find events
        [on ,con]  = find(onsets);
        [off,coff] = find(offsets);
        
        % Count events
        non  = numel(on);
        noff = numel(off);
        n = non + noff;
        
        % Make tables
        table = sortrows([repmat(channel+noteon, [n 1]),...
            keys([con; coff])',...
            [repmat(velon, [non  1]);...
             repmat(veloff,[noff 1])],...
            [on; off]./bps],4);
        midiTable = table(:,1:3);
        timeTable = table(:,4);  
        
    case 'pc' %program change
        
        % Find events
        switches = any(onsets|offsets,2);
        
        % Make tables
        midiTable = jt_code2midi(var(switches,:),channel,noteon);
        timeTable = (find(switches)-1)/bps;         
        
    otherwise
        error('Mode not supported!')
end

% Ensure timetable is in milliseconds
timeTable = timeTable*1000;