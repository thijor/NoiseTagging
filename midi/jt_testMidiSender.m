function jt_testMidiSender(port)
%jt_testMidiSender(port)
%Independent function to test Midi setup. This function allows turning on
%and off individual and grouped lights.
%
% INPUT
%   port = [str] midi port ('iRig MIDI 2')

if nargin<1 || isempty(port); port='iRig MIDI 2'; end

% Setup device
addpath(genpath(fullfile('~','bci_code','toolboxes','brainstream','resources','midi')));
javaaddpath(which('BrainMidi.jar'));
sender = MidiSender(port);

% Setup variables
channel = 0;
noteon  = 144;
nlights = input('How many lights are there? ');

% Turn off all lights
sender.sendJavaMidi(jt_code2midi(zeros(1,nlights),channel,noteon)) 

% Lights individually
flag = true;
while flag
    
    light = input('Which light to put on? (-1 to stop) ');
    
    if light>=0
        code = zeros(1, nlights);
        if light>0; code(light)=1; end;
        sender.sendJavaMidi(jt_code2midi(code,channel,noteon))   
    else
        flag = false;
    end
    
end

% Lights grouped
table = fullfact(repmat(2, [1 nlights]))-1;
flag = true;
while flag
    
    group = input('Give number corresponding to lights on: (-1 to stop) ');
    
    if group>=0
        sender.sendJavaMidi(jt_code2midi(table(group+1,:),channel,noteon))
    else
        flag = false;
    end
    
end

% Turn off all lights
sender.sendJavaMidi(jt_code2midi(zeros(1,nlights),channel,noteon))