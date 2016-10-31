function add_ptb()
%add_ptb()
%Add PsychToolbox and Stimbox2 to the path if not already on it

if isempty(which('Screen'))
    addpath(genpath(psychtoolbox_root()));
    if ispc
        addpath(fullfile(psychtoolbox_root(),'PsychBasic','MatlabWindowsFilesR2007a'));
    end
end

if isempty(which('mkTextureGrid'))
    addpath(genpath(fullfile(bs_folder('toolbox'),'stimbox2')));
end