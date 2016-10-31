function jt_initMidiSender(port)
%jt_initMidiSender(port)
%Initializes midi sender object
% 
% INPUT
%   port = [str] midi port ('iRig MIDI 2')

if nargin<1||isempty(port); port='iRig MIDI 2'; end

% Add paths
% if isempty(which('BrainMidi.jar'))
addpath(genpath(fullfile('~','bci_code','toolboxes','brainstream','resources','midi')));
addpath(genpath(fullfile('~','bci_code','toolboxes','brainstream','core','file_path_management')));
addjavaclasspath(which('BrainMidi.jar'));
addpath(genpath(fullfile('~','bci_code','toolboxes','brainstream','plugins','MMM','BrainMidi')));
% end

% Connect device
ret = sndMidiSequence(MidiSender(port));

% Report if initialization failed
if ~ret
    error('Could not initalize midi object.');
end