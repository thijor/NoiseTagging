function start_mobita(src,dst)
% start_mobita(src,dst)
% Start TMSi Mobita local buffer from external buffer, with trigger functionality.
%
% INPUT
%   src = [str] source location of data ('buffer://131.174.111.215:1972')
%   dst = [str] destiny location of data ('buffer://localhost:1973')
%
% SETUP
%	?	Mobita with trigger-header, connected to trigger interface
%	?	Trigger interface IN connected to OUT on MidiSport device
%	?	MidiSport device connected to main machine USB.
%	?	Windows machine with both ethernet and wifi
%	?	Buffer_BCI software
%	?	TMSi Fieldtrip Polybench
%	?	Main machine with ethernet
%	?	Matlab
%	?	Brainstream
% STARTUP
%	?	Connect Mobita with header.? Blue light on Mobita should start flashing.
%	?	On Windows machine, setup WiFi connection with mobita. Password is MOBITAxxxxxxx, x-es are last seven numbers of the mobita. ?Windows should say ?Connected?. 
%	?	On Windows machine, double-click downloads/buffer_bci/buffer_bci/dataAcq/startBuffer?. Command window with buffer should appear.
%	?	On Windows machine, start Polybench (TSMi to Fieldtrip). In Polybench, set ?Front-end categ? to ?WiFi front-ends? and check sample frequency. Press ?Start?.? Buffer should start running data, Polybench should show data of first four channels.
%	?	On main machine, start Matlab, run this code. Make sure the src variable is set according to the Windows machine?s IP address (IPv4-address). ?The variable ?dst? specifies the location at which the buffer can be found (e.g., BrainStream project). Matlab should start running data.
% NOTES
%	?	Mobita_0710130019  works with header 0730140005.
%	?	Mobita works with only one trigger input, only at event/marker value 1.
%	?	Trigger pulse can be viewed using quick_buffer_viewer_raw at braintream/resources/start_scripts or StartBufferViewer at buffer_bci/dataAcq.

% Default source
if nargin<1||isempty(src)
    src = 'buffer://169.254.26.40:1972';
end
% Default destiny
if nargin<2||isempty(dst)
    dst = 'buffer://localhost:1973';
end

% Add brainstream to path
cd('~/bci_code/toolboxes/brainstream/core/');
bs_addpath;

% Add trigger options
% trigger = [];
% trigger.fun = 'get_tmsi_mobita_triggers';
% trigger.cfg.channel = 36;

% Start buffer
ft2ft(src,dst);