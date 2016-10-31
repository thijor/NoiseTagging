function start_capfitting(src)
% start_capfitting(src)
% Start capfitting procedure
%
% INPUT
%   src = [str] source location of data ('buffer://localhost:1973:tmsi_mobita|rjv_basic_preproc_biosemi_active2')

% Default source
if nargin<1||isempty(src)
    src = 'buffer://localhost:1973:tmsi_mobita|rjv_basic_preproc_biosemi_active2';
end

% Add brainstream to path
cd('~/bci_code/toolboxes/brainstream/core/');
bs_addpath;

% Start viewer
start_viewer(src,'eeg','eeglab.blk');