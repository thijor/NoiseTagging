function pm_sendMusicMidi( ms, sequence, timing, endNote, name )
%pm_sendMusicMidi( ms, sequence, timing, endNote, name )
%Send a note or multiple notes to the MidiSender ms with possible endnotes.
%
% INPUT
%   ms          = [MidiSender] see pm_initMusicMidi()
%   sequence    = [n 3] midi messages with channel, pitch and velocity
%   timing      = [n 1] times when to play each note in ms
%   endNote     = [int] If and when to include an end note with zero
%                   velocity (1000 ms)
%   name        = [str] name of the midi thread (random name)

if nargin < 5
    symbols = ['a':'z' 'A':'Z' '0':'9'];
    name = symbols(randi(numel(symbols), 1, 20));
end
if nargin < 4; endNote = 1000; end

if endNote > 0
    sequence = reshape([sequence'; sequence'], [], size(sequence, 1) * 2)';
    sequence(2:2:end, 3) = 0;
    timing = reshape([timing; timing], [], numel(timing) * 2);
    timing(2:2:end) = timing(2:2:end) + endNote;
    [timing, idx] = sort(timing);
    sequence = sequence(idx, :);
end

ms.sendJavaMidiSequence(name, sequence, timing);

end

