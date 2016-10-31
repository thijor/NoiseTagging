addpath('~/bci_code/own_experiments/visual/noise_tagging/jt_box/');
jt_set_paths;
addpath('~/bci_code/toolboxes/brainstream/plugins/MMM/buttonbox/');

% Initialize
jt_initMidiSender;

% Cans individually
flag = true;
while flag
    
    can = input('Which can to blow off? (-1 to stop) ');
    
    if can>=0
        blow_can_midi(can);  
    else
        flag = false;
    end
    
end