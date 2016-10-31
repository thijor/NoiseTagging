function [ white_idx, black_idx, back_id, pause_id, play_id ] = cfg2flashidx( cfg, layout )
%[ white_idx, black_idx, back_id, pause_id, play_id ] = cfg2flashidx( cfg, layout )
%Translates keyboard configuration to indexes of white and black keys and
%the id's of the back, pause and play button.
% 
% INPUT
%   cfg         = [struct] keyboard configuration, see stim_keyboard()
%   layout      = [n 1] layout of keyboard with n keys, 1=white, 0=black
%
% OUTPUT
%   white_idx   = [w 1] indexes of w white keys
%   black_idx   = [b 1] indexes of b black keys. Note w + b = numel(layout)
%   back_id     = [int] index of the back button
%               = [] No back button
%   pause_id    = [int] index of the pause button
%               = [] No pause button
%   play_id     = [int] index of the play button
%               = [] No play button

back = cfg.use_back;
pause = cfg.use_pause;
play = cfg.use_play;
nkeys = cfg.nkeys;

white_idx = find(layout);
black_idx = find(~layout);

if back;    back_id     = nkeys + back;                 else back_id    = []; end
if pause;   pause_id    = nkeys + back + pause;         else pause_id   = []; end
if play;    play_id     = nkeys + back + pause + play;  else play_id    = []; end;

end

