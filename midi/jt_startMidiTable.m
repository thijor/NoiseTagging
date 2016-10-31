function jt_startMidiTable(midi,markers)
%jt_startMidiTable(midi,markers)
%Plays a table, i.e. sends midi messages
%
% INPUT
%   midi.name          = [str] midi thread name
%   midi.msg           = [n 3] n midi message of 3 bytes
%   midi.timing        = [n 1] n midi timings
%
%   markers.names      = [m 1] m marker names
%   markers.timing     = [m 1] m marker timings
%   markers.datasource = [str] datasource of markers e.g. 'eeg'

if nargin<2; markers=[]; end

% Send message
if ~isempty(markers)
    ret = sndMidiMarkerSequence(midi,markers);
else
    ret = sndMidiSequence(midi,'start');
end

% Report if failed
if ~ret
    error('Failed sending midi.'); 
end