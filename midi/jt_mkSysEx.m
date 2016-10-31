function [mmsg] = jt_mkSysEx(default)
%[mmsg] = jt_mkSysEx(default)
% 
% INPUT
%   default=1: produces default SysEx message for liquid device
%   default=0: produces custom SysEx message for liquid device in order to
%              simultaneously modify first 8 outputs of the device by 
%              sending only one midi tone message (bit-wise interpreted)

% create the default message
if nargin<1; default = 1; end
 
channel = 0;
header  = hex2dec({'F0' '00' '01' '5D' '03' '01'})';
 
% Set outputs needed
data = [];
if ~default
   for bit = 0:7
      data = [data bit bit+4 channel 0];
   end
end
 
% Set other outputs
for bit = 0: 15+default*8
   data = [data bit+(~default)*8 1 channel+(~default) hex2dec('3C')+(~default)*8+bit];
end
 
footer = hex2dec({'F7'});
mmsg   = [header data footer];