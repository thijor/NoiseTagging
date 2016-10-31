function ms = pm_initMidiSender(port)
%jt_initMidiSender(port)
%Initializes midi sender object
% 
% INPUT
%   port = [str] midi port

% Add paths
% addpath(fullfile('~','bci_code','toolboxes','brainstream','resources','midi'));
% path = fullfile('toolboxes','brainstream','resources','midi','BrainMidi.jar');

% also install java path for midi marker
if exist(fullfile(resources_folder,'midi','BrainMidi.jar'),'file')
    % make sure the correct jar-file from resources/midi folder will be installed
    addjavaclasspath(fullfile(resources_folder,'midi','BrainMidi.jar'));
end

% addpath(genpath(fullfile('~','bci_code','toolboxes','brainstream','plugins','MMM','BrainMidi')));

% Connect device
ms = MidiSender(port);

% Report if initialization failed
if ~ms.isOutputEnabled
    error('Could not initalize midi object. Perhaps the port was wrong?');
end