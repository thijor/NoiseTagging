function [message] = jt_code2midi(bitarray,channel,noteon)
%[message] = jt_code2midi(bitarray,channel,noteon)
%Converts a sequence of light switches to midi input. Light 1 is on bit 1,
%light 2 on bit 2, etc.
%
% INPUT
%   bitarray = [m n] m samples of n variables (1=on, 0=off)
%   channel  = [int] the midi channel
%   noteon   = [int] the midi noteon constant
%
% OUTPUT
%   message = [m 3] m midi messages containing 3 bytes

% Check input
[m,n] = size(bitarray);
if     n>14;  error('Too many bits!');
elseif n<=7;  bits1=1:n;  bits2=[];   b1=n-1;           b2=0;
elseif n>7;   bits1=1:7;  bits2=8:n;  b1=bits1(end)-1;  b2=bits2(end)-8;
end

% Compute bytes
byte0 = repmat(noteon+channel,[m 1]);
byte1 = sum(bitarray(:,bits1)*2.^(0:b1)',2);
byte2 = sum(bitarray(:,bits2)*2.^(0:b2)',2)+2; % Needs to be nonzero always

% Message
message = [byte0 byte1 byte2];