function jt_set_paths()
%jt_set_paths(cfg)

% Root
if ispc; root = 'G:';
elseif ismac || strcmp(computer(), 'GLNXA64'); root = '~';
else error('Unknown OS!')
end
toolboxes     = fullfile(root,'bci_code','toolboxes');
noise_tagging = fullfile(root,'bci_code','own_experiments','visual','noise_tagging');

% Add toolboxes
addpath(genpath(fullfile(noise_tagging,'jt_box')));        % noise-tagging
addpath(genpath(fullfile(toolboxes,'numerical_tools')));   % math: tprod, repop
addpath(genpath(fullfile(toolboxes,'plotting')));          % plotting: ikelvin
addpath(genpath(fullfile(toolboxes,'signal_processing'))); % signal proc: detrend
addpath(genpath(fullfile(toolboxes,'utilities')));         % signal proc: detrend

% Add BrainStream
addpath(fullfile(toolboxes,'brainstream'));                 % roots
addpath(fullfile(toolboxes,'brainstream','core'));          % roots
bs_addpath;