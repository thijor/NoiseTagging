function jt_stopMidiTable(name)
%jt_stopMidiTable(threadname)
%Stops a table, i.e. cancels ongoing midi messages
%
% INPUT
%   name = [str] midi thread name ('midi')

if nargin<1; name='midi'; end

% Check if still running
if ~sndMidiSequence(struct('name',name),'isbusy');
    return;
end

% Send stop message
ret = sndMidiSequence(struct('name',name),'stop');
pause(0.1);

% Report if failed
if ~ret
    error('Failed sending midi.'); 
end