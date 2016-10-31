function [ sequence ] = pm_label2sequence( cfg, label )
%[ sequence ] = pm_label2sequence( cfg, label )
%Transforms a keyboard label to a midi note
%
% INPUT
%   cfg         = [struct] keyboard configuration, see stim_keyboard()
%   label       = [int] key on the keyboard that is played
% 
% OUTPUT
%   sequence    = [n 3] sequence of midi notes

note = label - 1 + 60 + cfg.keysoffset;
sequence = zeros(numel(note), 3);
sequence(:, 1) = 144;
sequence(:, 2) = note(:);
sequence(:, 3) = 127;

end

