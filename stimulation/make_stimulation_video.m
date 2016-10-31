function make_stimulation_video(cfg)
%make_stimulation_video(varargin)
%Generates a video of stimulation bit-sequences. The video is saved at the
%specified path with a specified filename, including the type of
%stimulation and atime stamp.
%
% INPUT
%   cfg = [struct] configuration structure
%       .type        = [str] stimulation type: rc|ft|nt|nttrain|nttest (nt)
%       .filename    = [str] file name (stimvid)
%       .filepath    = [str] file path (~/Desktop/)
%       .fileformat  = [str] file format (Motion JPEG AVI)
%       .framerate   = [int] frame rate in hz (60)
%       .resolution  = [1 2] resolution of the video ([1024 768])
%
% NOTES
%   - For different file formats, see the help of VidoeWriter
%   - If precisly one code repetition, make sure duration is set correctly

% Defaults
if nargin<1||isempty(cfg); cfg=[]; end
defaults = struct( ...
    'type'        , 'nt',...
    'filename'    , 'stimvid',...
    'filepath'    , '~/Desktop',...
    'fileformat'  , 'MPEG-4',... %'Motion JPEG AVI'
    'framerate'   , 60,...
    'resolution'  , [1024 768]);
cfg = parseOpts(defaults,cfg);

% Variables
symbols = {...
    'A','B','C','D','E','F'; ...
    'G','H','I','J','K','L'; ...
    'M','N','O','P','Q','R'; ...
    'S','T','U','V','W','X'; ...
    'Y','Z','@','$','%','&'; ...
    '#','<','-','!','?','.';};
duration = 2.10;
nsymbols = numel(symbols);
nsamples = duration*cfg.framerate;
repfn = @(c,m) repmat(c,[ceil(m/size(c,1)) 1]);
cutfn = @(c,m) c(1:m,:);

% Build stimulation bit-sequence
switch lower(cfg.type)
    case 'rc'
        codes = false(12,nsymbols);
        for i = 1:6; codes(i,(i-1)*6+1:i*6)=true; end
        for i = 1:6; codes(i+6,i:6:end)=true; end
        codes = cutfn(repfn(jt_upsample(codes(randperm(12),:),8,2),nsamples),nsamples);
        code.symbols = ~logical(codes)';
        cfg.filename = [cfg.filename '_' cfg.type];
    case 'ft'
        codes = arrayfun(@(x)cutfn(repfn(x{:},nsamples),nsamples),...
            jt_make_code('freq','maxlen',nsymbols+1,'format','cell'),...
            'uniformoutput',false);
        code.symbols = ~logical(jt_cell2mat(codes))';
        cfg.filename = [cfg.filename '_' cfg.type];
    case 'nt'
        codes = cutfn(repfn(jt_make_code('mgold'),nsamples),nsamples);
        code.symbols = ~logical(codes(:,1:nsymbols))';
        cfg.filename = [cfg.filename '_' cfg.type];
    case 'nttrain'
        codes = [];
        load('mgold_61_6521.mat');
        code.symbols = ~logical(repmat(codes(:,1:36)',[1 4]));
        code.framerate = false(1,size(code.symbols,2));
        code.framerate(1:2:end) = true;
        code.sync = [true false(1,size(code.symbols,2)-1)];
        cfg.filename = [cfg.filename '_' cfg.type];
    case 'nttest'
        codes = [];
        load('mgold_65_6532.mat');
        code.symbols = ~logical(repmat(codes(:,1:36)',[1 4]));
        code.framerate = false(1,size(code.symbols,2));
        code.framerate(1:2:end) = true;
        code.sync = [true false(1,size(code.symbols,2)-1)];
        cfg.filename = [cfg.filename '_' cfg.type];
    otherwise
        error('Unknown type: %s.',type)
end

% Build save struct
save2mp4.filename = fullfile(cfg.filepath,cfg.filename);
save2mp4.framerate = cfg.framerate;
save2mp4.resulution.x = cfg.resolution(1);
save2mp4.resulution.y = cfg.resolution(2);
save2mp4.format = cfg.fileformat;

% Start speller and record
ms_speller([],symbols,code,[],[],[],save2mp4);

% Clear psychtoolbox screen
clear Screen;