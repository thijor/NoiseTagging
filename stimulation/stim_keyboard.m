function [Nmissed, vimgs] = stim_keyboard(info,code,marker,target,save2mp4,cfg)
%[Nmissed, vimgs] = ms_speller(info,symbols,code,marker,target,edge_colors,save2mp4)
%
% INPUT
%   info     = [struct]
%       .top        = [str] text displayed at top, right-alligned
%       .bottom     = [str] text displayed at bottom, center-alligned
%   code        = [n^2 t]   which characters should be flashed each timepoint (1=character white & background black)
%   marker      = [struct]  .name   [string] marker name
%                           .source [string] source name
%   target      = [struct]  .index [int]   character index in symbols
%                           .color [r g b] rgb color
%   save2mp4    = [struct]  .filename [string] name of mp4-file, you must include
%                                              path information. The name
%                                              is padded with a timestamp: DDhhmmss
%                           .framerate         video framerate (default=60Hz)
%                           .format            video format
%                           .resolution.x      frame resolution width
%                           .resolution.y      frame resolution hight
%
% OUTPUT
%   Nmissed = [int] number of frames missed
%   vimgs   = {1 t} cell array containing all frames as images
%
% Note:  1) only specifying info as string, will put text in middle of screen.
%        2) only specifying info as integer, test examples are displayed.
%        3) specifing symbols not or empty, symbols are displayed once.

persistent w;
persistent clean;

if nargin==1 && isnumeric(info)
    [Nmissed, vimgs] = testit(info);
    return;
end

if nargin<1;    info        = [];	end
if nargin<2;    code        = [];	end
if nargin<3;    marker      = [];	end
if nargin<4;    target      = [];	end
if nargin<5;    save2mp4    = [];	end
if nargin<6;    cfg         = [];	end

bg_color        = jt_parse_cfg(cfg, 'color_background', 128);
layout          = jt_parse_cfg(cfg, 'layout', [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1]);
offset          = jt_parse_cfg(cfg, 'keysoffset', 0);
cfg.nkeys       = jt_parse_cfg(cfg, 'nkeys', 12);
cfg.use_back    = jt_parse_cfg(cfg, 'use_back', false);
cfg.use_pause   = jt_parse_cfg(cfg, 'use_pause', false);
cfg.use_play    = jt_parse_cfg(cfg, 'use_play', false);
vimgs           = [];
verb            = 0;
non_keys        = cfg.use_back + cfg.use_pause + cfg.use_play;

%% Defaults

if ~isempty(save2mp4)
    if ~isfield(save2mp4,'filename')
        error('No filename specified for saving the video frames');
    end
    % check defaults required
    if ~isfield(save2mp4,'resolution')
        save2mp4.resolution.x = 1024;
        save2mp4.resolution.y = 768;
    end
    if ~isfield(save2mp4,'framerate')
        save2mp4.framerate = 60;
    end
    if ~isfield(save2mp4,'format')
        save2mp4.format = 'MPEG-4';
    end
end

if isempty(code);           code = round(rand(6, 1)); end
if numel(code) == 1
    nkeys = code - non_keys;
    nflashes = 1;
    layout = definite_layout(layout, nkeys, offset);
    code = [layout'; ones(non_keys, 1)];
else
    [nkeys, nflashes]   = size(code);
    nkeys = nkeys - non_keys;
    layout = definite_layout(layout, nkeys, offset);
end

% Make sure codes are logicals
code = logical(code);

% Defaults info
if isempty(info);               info = struct('top','','bottom','');
elseif ischar(info);            info = struct('top','','bottom',info);
else
    if ~isfield(info,'top');    info.top        = ''; end
    if ~isfield(info,'bottom'); info.bottom     = ''; end
end

% make sure everything gets cleaned up well
if ~isa(clean,'onCleanup')
    clean = onCleanup(@()cleanup()); % executes at cleanup of local variable clean
end

% Always add path
add_ptb()
% check if we need to initialize Psychtoolbox
if isempty(w) || ~Screen(w.ptr, 'WindowKind')
    w = [];
    w = init_ptb(save2mp4);
end
Screen('BlendFunction',w.ptr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%% Define texels

% id of texels in code pattern
[white_idx, black_idx, back_id, pause_id, play_id] = cfg2flashidx(cfg, layout);

% piano key texels
[w.content.flash_white, w.content.flash_black, w.content.nonflash_white, ...
    w.content.nonflash_black, w.content.black_edges] ...
    = define_key_texels(layout, offset, cfg);

% playback key texels
[play, pause, back] = define_playback_texels();
w.content.flash_play = play.flash;
w.content.nonflash_play = play.nonflash;
w.content.flash_pause = pause.flash;
w.content.nonflash_pause = pause.nonflash;
w.content.flash_back = back.flash;
w.content.nonflash_back = back.nonflash;

% info text texels (top/bottom row)
w.content.topinfo           = define_info_texels(info.top,[0 0 1 0.1], bg_color);
w.content.bottominfo        = define_info_texels(info.bottom,[0 0.9 1 1], bg_color);

% combine all texels
% Note: edges must be installed before (r)symbols, therefore set installation order manually!
content_names = {'bottominfo','topinfo', 'flash_white', ...
    'nonflash_white', 'black_edges', 'flash_black', 'nonflash_black', ...
	'nonflash_play', 'flash_play', 'nonflash_back', 'flash_back', ...
    'flash_pause', 'nonflash_pause'
    };
c = w.content;
for n = 1 : numel(content_names)
    fld = content_names{n};
    % preload all textures
    [resident,~] = Screen('PreloadTextures', w.ptr, c.(fld).texels);
    if ~resident; error('Failed preloading textures'); end
    if ~isempty(info) && any(strcmp(fld,{'info1','info2'}))
        draw_texture(w.ptr,c.(fld).texels, 0, 0, 1, [], ...
            double(c.(fld).srcRects), double(c.(fld).dstRects), [], ...
            [], [], c.(fld).color);
    end
end

% set background to grey
Screen('FillRect',w.ptr,bg_color);

%% Loop
% Bump priority for speed (I think it's useless om a mac)
Priority(MaxPriority(w.ptr));

% call once to load all functions into memory
% draw_texture(); % clear persistent variable Nmissed in draw_texture function
VBLTimestamp=0;

for n = 1 : nflashes
    if n==nflashes, verb=1; end
    c = w.content; % reload and reset content
    
    % current stimulus pattern/code
    curstims = code(:,n);
    
    % which symbols are displayed (on or off)
    c.flash_white.stim      = curstims(white_idx);
    c.flash_black.stim      = curstims(black_idx);
    c.nonflash_white.stim   = ~curstims(white_idx);
    c.nonflash_black.stim   = ~curstims(black_idx);
    c.black_edges.stim      = true(1, numel(black_idx));
    c.flash_play.stim       = curstims(play_id) .* cfg.use_play;
    c.nonflash_play.stim    = ~curstims(play_id) .* cfg.use_play;
    c.flash_back.stim       = curstims(back_id) .* cfg.use_back;
    c.nonflash_back.stim    = ~curstims(back_id) .* cfg.use_back;
    c.flash_pause.stim      = curstims(pause_id) .* cfg.use_pause;
    c.nonflash_pause.stim   = ~curstims(pause_id) .* cfg.use_pause;
    
    % if target should be primed, set corresponding color
    if ~isempty(target)
        if sum(white_idx == target.index)
            white_target = find(white_idx == target.index);
            c.flash_white.color(:,white_target)     = target.color;
            c.nonflash_white.color(:,white_target)  = target.color;
        elseif sum(black_idx == target.index)
            black_target = find(black_idx == target.index);
            c.flash_black.color(:,black_target)     = target.color;
            c.nonflash_black.color(:,black_target)  = target.color;
        elseif back_id == target.index
            c.flash_back.color(:, 1)                = target.color;
            c.nonflash_back.color(:, 1)             = target.color;
        elseif pause_id == target.index
            c.flash_pause.color(:, 1)               = target.color;
            c.nonflash_pause.color(:, 1)            = target.color;
        elseif play_id == target.index
            c.flash_play.color(:, 1)                = target.color;
            c.nonflash_play.color(:, 1)             = target.color;
        end
    end
    
    %% Marker
    mrk = [];
    if n==1
        draw_texture(); % Clear Nmissed, reset time
        % Marker at first stimulus
        if numel(marker)<=1; mrk = marker;
        else mrk = marker(1); end
        % Marker at last stimulus
    elseif n==nflashes && numel(marker)==2
        mrk = marker(2);
    end
    
    %% Draw
    
    % Merge contents of actually presented texels
    alltexels   = [];
    alldstRects = [];
    allcolors   = [];
    for k = 1:numel(content_names)
        fld = content_names{k};
        idx = find(c.(fld).stim);
        if ~isempty(idx)
            alltexels   = cat(2,alltexels  ,c.(fld).texels(idx));
            alldstRects = cat(2,alldstRects,c.(fld).dstRects(:,idx));
            allcolors   = cat(2,allcolors  ,c.(fld).color(:,idx));
        end
    end

    % Present textures
    [VBLTimestamp, Nmissed] = draw_texture(w.ptr,alltexels,...
        verb,VBLTimestamp,w.monitorFlipInterval,mrk, ...
        [],double( alldstRects),[],[],[],allcolors);
    
    %% Save
    if ~isempty(save2mp4)
        % collect video frames
        img = Screen('GetImage',w.ptr);
        if ~iscell(img); vimgs{end+1} = img; end
    end
    
    %% BrainStream stop
    try
        % check if BrainStream sends an early-stopping command (takes less than 1.5 ms)
        % check for new information in a non-blocking call to the socket
        uservars = bs_recv_user_brainstream([],'stim',0,0);
        while ~isempty(uservars)
            fprintf('color feedback received\n');
            % received 'stop' or empty (by BS) will exit the loop
            if isempty(uservars{1}) || isequal(uservars{1},'stop')
                % set priority back to normal
                Priority(0);
                % write frames to mp4-file if necessary
                write2mp4(vimgs,save2mp4);
                return;
            end
            if isnumeric(uservars{1}) && isequal(size(uservars{1}),[3, numel(w.content.edges.texels)])
                % assume edge feedback color values received (matrix [3 x num_symbols])
                edges = uservars{1};
            else
                % if it doesn't work check incoming result
                %keyboard;
            end
            uservars = {uservars{2:end}}; % assures empty uservars={} instead of []
        end
    catch
        % make sure it will never break
    end
    
end

%% Output
% write frames to mp4-file
write2mp4(vimgs,save2mp4);

% set priority back to normal
Priority(0);

%% define_symbols_texels()
    function [flash_white, flash_black, nonflash_white, nonflash_black, black_edges] ...
            = define_key_texels(layout, offset, cfg)
        scale           = jt_parse_cfg(cfg, 'scale', 1.0);
        white_flash     = jt_parse_cfg(cfg, 'white_flash_color', [255, 255, 255]);
        white_nonflash  = jt_parse_cfg(cfg, 'white_nonflash_color', [0, 0, 0]);
        white_width     = jt_parse_cfg(cfg, 'white_width', 2/7);
        white_height    = jt_parse_cfg(cfg, 'white_height', 1);
        black_flash     = jt_parse_cfg(cfg, 'black_flash_color', [255, 255, 255]);
        black_nonflash  = jt_parse_cfg(cfg, 'black_nonflash_color', [0, 0, 0]);
        black_width     = jt_parse_cfg(cfg, 'black_width', 1/7);
        black_height    = jt_parse_cfg(cfg, 'black_height', 4/7);
        space           = jt_parse_cfg(cfg, 'space', 0.01);
        
        % Number of keys
        nwhite = sum(layout);
        nblack = sum(~layout);
        % Lengths piano keys
        L=[white_height black_height];
        W=[white_width black_width];
        % Relative to screen size
        W = ceil(w.height/2 * scale * W);
        L = ceil(w.height/2 * scale * L);
        space = ceil(w.height / 2 * scale * space);
        % Define keys
        wk = {255*ones(L(1), W(1), 3, 'uint8')}; % white key
        bk = {255*ones(L(2), W(2), 3, 'uint8')}; % black key
        bk_edge = {255*ones(L(2) + space, W(2) + space, 3, 'uint8')};
        % Black and white keys order
        white_keys = repmat(wk, nwhite, 1);
        black_keys = repmat(bk, nblack, 1);
        black_edge = repmat(bk_edge, nblack, 1);
        white_colors = struct('flash', repmat(white_flash, nwhite, 1), ...
            'nonflash', repmat(white_nonflash, nwhite, 1));
        black_colors = struct('flash', repmat(black_flash, nblack, 1), ...
            'nonflash', repmat(black_nonflash, nblack, 1));
        edges_colors = repmat(bg_color, nblack, 1);
        
        % Locations
        white_idx = find(layout);
        black_idx = find(~layout);
        nwkeys = numel(white_idx);
        startxpos = floor((w.width - (W(1)+space)*nwkeys - space) / 2);
        startypos = floor(w.height * 0.1);
        bloc = arrayfun(@(x) sum(layout(1:x)),black_idx);
        white_xpos = startxpos + (0:numel(white_idx)-1) * (W(1)+space);
        black_xpos = startxpos + bloc * (W(1)+space) - 0.5*W(2) -0.5*space;
        white_width = ones(1, numel(white_idx)) * W(1);
        black_width = ones(1, numel(black_idx)) * W(2);
        white_height = ones(1, numel(white_idx)) * L(1);
        black_height = ones(1, numel(black_idx)) * L(2);
        white_ypos = startypos + zeros(numel(white_xpos), 1);
        black_ypos = startypos + zeros(numel(black_xpos), 1);
        width_octave = 7 * (W(1) + space);
        black_shift = ([1, 3, 6, 8, 10] / 12) - (([1, 2, 4, 5, 6] / 7) - (0.5 * W(2) / width_octave));
        black_shift = black_shift * width_octave;
        offset = mod(offset, nkeys);
        if offset > 5; black_offset = offset-1; else black_offset = offset; end
        black_offset = floor(black_offset / 2);
        black_shift = definite_layout(black_shift, nblack, black_offset);
        black_xpos = black_xpos + black_shift;
        
        white_dstRects = zeros(4,numel(white_xpos));
        for i = 1 : numel(white_xpos)
            % Left/Top/Right/Bottom is column info of Rects
            x = white_xpos(i);
            y = white_ypos(i);
            white_dstRects(:, i) = [x y x+white_width(i) y+white_height(i)];
        end
        black_dstRects = zeros(4,numel(black_xpos));
        for i = 1 : numel(black_xpos)
            % Left/Top/Right/Bottom is column info of Rects
            x = black_xpos(i);
            y = black_ypos(i);
            black_dstRects(:, i) = [x y x+black_width(i) y+black_height(i)];
        end
        edges_dstRects = zeros(4,numel(black_xpos));
        for i = 1 : numel(black_xpos)
            % Left/Top/Right/Bottom is column info of Rects
            x = black_xpos(i) - space;
            y = black_ypos(i) - space;
            ww = 2*space + black_width(i);
            hh = 2*space + black_height(i);
            edges_dstRects(:, i) = [x y x+ww y+hh];
        end
        
        % build combined texels
        [texels,~,~] = mkTextureGrid(w.ptr,white_keys);
        flash_white.texels     = texels;
        flash_white.dstRects   = white_dstRects;
        flash_white.color      = white_colors.flash';
        
        % build combined texels
        [texels,~,~] = mkTextureGrid(w.ptr,black_keys);
        flash_black.texels     = texels;
        flash_black.dstRects   = black_dstRects;
        flash_black.color      = black_colors.flash';
        
        [texels,~,~] = mkTextureGrid(w.ptr,black_edge);
        black_edges.texels     = texels;
        black_edges.dstRects   = edges_dstRects;
        black_edges.color      = edges_colors';
        
        % build combined texels
        nonflash_white          = flash_white;
        nonflash_white.color    = white_colors.nonflash';
        nonflash_black          = flash_black;
        nonflash_black.color    = black_colors.nonflash';
    end

%% define_info_texels
    function c_info = define_info_texels(info,vp,bg_color)
        if ~isempty(info)
            if isempty(code)
                vp = [0 0 1 1]; % overwrite vp to put text in middle of screen
            end
            [texels,~,dstRects] = ...
                mkTextureGrid(w.ptr, info, 'bgCol',bg_color,'viewPort',vp,'TextSize',40);
            c_info.texels    = texels;
            c_info.dstRects  = dstRects;
            c_info.color     = ones(3,1).*255;
            c_info.stim      = true;
        else
            c_info.texels    = [];
            c_info.dstRects  = [];
            c_info.color     = [];
            c_info.stim      = [];
        end
    end

%% define_playback_texels
    function [play, pause, back] = define_playback_texels()
        width = 100;
        height = 100;
        y_pos = w.height * 0.9 - height;
        color = [255 255 255];
        % Play
        play_x = [0 width 0];
        play_y = [0 height/2 height];
        play_image = poly2mask(play_x, play_y, width, height);
        play_xpos = w.width * 4/5 - width/2;
        play.flash      = define_texel(play_image, play_xpos, y_pos, width, height, color);
        play.nonflash   = define_texel(play_image, play_xpos, y_pos, width, height, 255-color);
        % Pause
        pause_x = [0 width/3 width/3 0];
        pause_y = [0, 0, height, height];
        pause_image = poly2mask(pause_x, pause_y, width, height);
        pause_image = pause_image + fliplr(pause_image);
        pause_xpos = w.width / 2 - width / 2;
        pause.flash     = define_texel(pause_image, pause_xpos, y_pos, width, height, color);
        pause.nonflash  = define_texel(pause_image, pause_xpos, y_pos, width, height, 255-color);
        % Back
        back_x = [width/2 width/2 0 width/2 width/2 width width width/2];
        back_y = [height/2 0 height/2 height height/2 0 height height/2];
        back_image = poly2mask(back_x, back_y, width, height);
        back_xpos = w.width / 5 - width / 2;
        back.flash     = define_texel(back_image, back_xpos, y_pos, width, height, color);
        back.nonflash  = define_texel(back_image, back_xpos, y_pos, width, height, 255-color);
    end

%% Repeat layout
    function layout = definite_layout(layout, nkeys, offset)
        layout = repmat(layout, 1, ceil(nkeys / numel(layout)));
        shift = mod(offset, nkeys);
        layout = [layout(shift+1:end), layout(1:shift)];
        layout = layout(1:nkeys);
    end

%% define_texel
    function texel = define_texel(img, x_pos, y_pos, width, height, color)
%         viewPort        = [0 0.075 1 0.925];
%         [texels,~,~]    = mkTextureGrid(w.ptr,image,'viewPort',viewPort);
        image(:, :, 1) = img * 255;
        image(:, :, 2) = img * 255;
        texels = Screen('MakeTexture', w.ptr, uint8(image));
        texel.texels    = texels;
        texel.dstRects  = [x_pos y_pos x_pos+width y_pos+width]';
        texel.color     = color';
    end

%% cleanup
    function cleanup()
        % close screen and its texels
        try
            sca();
        catch
        end
        
        % make sure next call reinitializes ptb window
        w = [];
        
        % set priority back to normal
        Priority(0);
    end

%% Tests
    function [Nmissed, vimgs]= testit(example)
        
        info            = [];
        code            = [];
        marker          = [];
        target          = [];
        save2mp4        = [];
        
        % Piano config
        cfg.scale                   = 1.0;
        cfg.white_flash_color       = [255, 255, 255];
        cfg.white_nonflash_color    = [32, 32, 32];
        cfg.black_flash_color       = [223, 223, 223];
        cfg.black_nonflash_color    = [0, 0, 0];
        cfg.color_background        = [41, 20, 0];
        cfg.black_width             = 0.2;
        cfg.black_height            = 0.6;
        cfg.white_width             = 0.3;
        cfg.white_height            = 1;
        cfg.space                   = 0.02;
        cfg.keysoffset              = 0; % 0 = starting with C
        cfg.layout                  = [];
        cfg.use_back                = false;
        cfg.use_pause               = true;
        cfg.use_play                = false;
        cfg.nkeys                   = 12;
        
        % Parameters
        nflashes = 50;
        non_keys = cfg.use_back + cfg.use_pause + cfg.use_play;
        num_codes = cfg.nkeys + non_keys;
        
        switch example
            case 0
                info.top = 'Information at top';
                info.bottom = 'Information at bottom';
                code = num_codes;
            case 1
                %continuous swapping halve character set
                code = true(num_codes,nflashes);
                code(1:2:end,1:2:end)=false;
                code(2:2:end,2:2:end)=false;
                
            case 2
                %or changing a character one by one
                code = true(num_codes, nflashes);
                for i=1:size(code,2),code(mod(i-1,num_codes)+1,i)=false;end
            case 3
                code = round(rand(num_codes,nflashes));
            case 4
                info = [];         % no text displayed
            case 5
                code = true(num_codes, nflashes);
            case 6
                info.top = 'info at top line';
                info.bottom = '';   % top line
            case 7
                info.top = '';
                info.bottom = 'info at bottom line'; % bottom line
            case 8
                info.top = 'info at top line';
                info.bottom = 'info at bottom line';
            case 9
                % for testing early stopping
                %continuous swapping halve character set
                code = true(num_codes,10*60); % 10 or 5 sec dependent of refresh rate
                code(1:2:end,1:2:end)=false;
                code(2:2:end,2:2:end)=false;
                marker = struct('name','pretrial','source','eeg');
            case 10
                % display speller set with random edge colors
                code = false(num_codes, nflashes);
            case 11
                code = rand(num_codes, nflashes)>0.5;
                save2mp4 = struct('filename','~/Desktop/test_noisetagging_video');
            case 12
                load('mgold_61_6521.mat');
                code = repmat(codes(:,1:13),[4 1])';
            case 13
                code = false(num_codes, nflashes);
                code(5, :) = true;
            otherwise
                % just display speller set with first one highlighted as target
                code = num_codes;
                target.index = 1;
                target.color = 255*[0 0.5 0];
        end
        
        [Nmissed,vimgs] = stim_keyboard(info,code,marker,target,save2mp4,cfg);
        
    end

end