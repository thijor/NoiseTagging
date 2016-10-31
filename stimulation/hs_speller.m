function [Nmissed,vimgs] = hs_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg)
%[Nmissed,vimgs] = hs_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP)
%
% INPUT
%   info     = [struct]
%       .top        = [str] text displayed at top, right-alligned ('')
%       .bottom     = [str] text displayed at bottom, center-alligned ('')
%       .completion = [str] text displayed top, left-alligned ('')
%   symbols  = {n m} character set (6x6 default)
%   stimuli  = [struct]
%       .symbols   = [nm t] characters by samples: 1 = character white, background black (false(nm,1))
%       .framerate = [1 t]  right-top, framerate; toggle on/off every frame ([])
%       .sync      = [1 t]  left-top, sync-puls; flash at sync moment ([])
%   marker   = [struct] ([])
%       .name   = [str] marker name
%       .source = [str] source name
%       .type   = [str] marker type: hardware|software
%   target   = [struct] ([])
%       .index = [int] target index in symbols
%       .color = [1 3] rgb target color
%   edges    = [3 nm] rgb edge colors ([])
%   save2mp4 = [struct] ([])
%       .filename     = [str] path-name of mp4-file, is padded with a timestamp (DDhhmmss)
%       .framerate    = [int] video framerate (60)
%       .format       = [str] video format
%       .resolution.x = [int] frame resolution width
%       .resolution.y = [int] frame resolution hight
%   LOOP     = [bool]   boolean whether or not to loop (false)
%   cfg      = [struct]
%       .color_symbol     = [3 1]    rgb color value of ones for symbols   ([255;255;255])
%       .color_rsymbol    = [3 1]    rgb color values of zeros for symbols ([  0;  0;  0])
%       .color_background = [3 1]    rgb color values of zeros for symbols ([128;128;128])
%       .function         = [str]    function that returns normalized locations ('jt_arrange_texels_equal')
%       .params           = [struct] structure with parameters for the function
%
% OUTPUT
%   Nmissed = [int] number of frames missed
%   vimgs   = {1 t} cell array containing all frames as images
%
% Note: test examples are displayed if only specifying info as integer.

persistent w;
persistent clean;
vimgs = [];

% If numeric one argument, test examples
if nargin==1 && isnumeric(info)
    [Nmissed, vimgs] = testit(info);
    return;
end

if nargin<1||isempty(info);     info      = [];     end
if nargin<2||isempty(symbols);  symbols   = [];     end
if nargin<3||isempty(stimuli);  stimuli   = [];     end
if nargin<4||isempty(marker);   marker    = [];     end
if nargin<5||isempty(target);   target    = [];     end
if nargin<6||isempty(edges);    edges     = [];     end
if nargin<7||isempty(save2mp4); save2mp4  = [];     end
if nargin<8||isempty(LOOP);     LOOP      = false;  end
if nargin<9||isempty(cfg);      cfg       = [];     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Defaults info
if isempty(info)
    info = struct('top','','bottom','','completion','');
elseif ischar(info)
    info = struct('top','','bottom',info,'completion','');
else
    if ~isfield(info,'top');        info.top        = ''; end
    if ~isfield(info,'bottom');     info.bottom     = ''; end
    if ~isfield(info,'completion'); info.completion = ''; end
end

% Defaults symbols
if isempty(symbols)
    symbols = get_default_symbols();
end
[N,M] = size(symbols);

% If stimuli or symbol-stimuli undefined, flash once
if ~isfield(stimuli,'symbols') || isempty(stimuli.symbols)
    stimuli.symbols = true(N,1);
else
    stimuli.symbols = logical(stimuli.symbols);
end
nflashes = size(stimuli.symbols,2);
% If framerate undefined, default empty
if ~isfield(stimuli,'framerate');
    stimuli.framerate = [];
else
    stimuli.framerate = logical(stimuli.framerate);
end
% If sync undefined, default empty
if ~isfield(stimuli,'sync');
    stimuli.sync = [];
else
    stimuli.sync = logical(stimuli.sync);
end

% Defaults save2mp4
if ~isempty(save2mp4)
    if ~isfield(save2mp4,'filename')
        error('No filename specified for saving the video frames');
    end
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

% Default cfg
color_text          = uint8(jt_parse_cfg(cfg,'color_text',            [128;128;128]));
color_symbol        = uint8(jt_parse_cfg(cfg,'color_symbol',          [255;255;255]));
color_rsymbol       = uint8(jt_parse_cfg(cfg,'color_rsymbol',         [  0;  0;  0]));
color_background    = uint8(jt_parse_cfg(cfg,'color_background',      [128;128;128]));
color_topinfo       = uint8(jt_parse_cfg(cfg,'color_topinfo',         [  0;  0;  0]));
color_bottominfo    = uint8(jt_parse_cfg(cfg,'color_bottominfo',      [  0;  0;  0]));
color_cmplinfo      = uint8(jt_parse_cfg(cfg,'color_cmplinfo',        [ 64; 64; 64]));
color_fixation_cross= uint8(jt_parse_cfg(cfg,'color_fixation_cross',  [  0;  0;  0]));
textsize_symbols    = jt_parse_cfg(cfg,'textsize_symbols',      50);
textsize_info       = jt_parse_cfg(cfg,'textsize_info',         45);
viewport_stt        = jt_parse_cfg(cfg,'viewport_stt',          [0  0   .05 .07]);
viewport_topinfo    = jt_parse_cfg(cfg,'viewport_topinfo',      [0  0   .7  .05]);
viewport_cmplinfo   = jt_parse_cfg(cfg,'viewport_cmplinfo',     [.7 0   1   .05]);
viewport_symbols    = jt_parse_cfg(cfg,'viewport_symbols',      [0  .07 1   .95]);
viewport_bottominfo = jt_parse_cfg(cfg,'viewport_bottominfo',   [0  .95 1   1   ]);
align_topinfo       = 'right';
align_bottominfo    = 'center';
align_cmplinfo      = 'left';
cfg.params.N        = N;
cfg.params.M        = M;
cfg.params.viewport = viewport_symbols;
if ~isfield(cfg,'function')
    cfg.function = 'jt_arrange_texels_equal';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make sure everything gets cleaned up well
if ~isa(clean,'onCleanup')
    clean = onCleanup(@()cleanup()); % executes at cleanup of local variable clean
end

% Add PsychToolbox
if isempty(which('Screen'))
    addpath(genpath(fullfile('~','bci_code','external_toolboxes','Psychtoolbox')));
end

% Check if we need to initialize Psychtoolbox window
if isempty(w) || ~Screen(w.ptr,'WindowKind')
    w = [];
    w = init_ptb(save2mp4,color_background);
end

Screen('TextStyle', w.ptr, 0);
Screen('TextFont',  w.ptr, 'Helvetica');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define texels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Fixation cross
w.content.cross = define_fixation_cross(viewport_symbols,color_fixation_cross);

% Info texels
w.content.topinfo    = define_info_texels(info.top       ,viewport_topinfo   ,color_topinfo   ,align_topinfo);
w.content.bottominfo = define_info_texels(info.bottom    ,viewport_bottominfo,color_bottominfo,align_bottominfo);
w.content.cmplinfo   = define_info_texels(info.completion,viewport_cmplinfo  ,color_cmplinfo  ,align_cmplinfo);

% Symbols texels
if ~isfield(w,'symbols') || isempty(w.symbols) || (~isempty(symbols) && ~isequal(symbols,w.symbols))
    w.symbols = symbols;
    [w.content.symbols,w.content.rsymbols] = define_symbols_texels;
end

% Sync texel (top-left)
w.content.sync     = define_stt_texels(viewport_stt,[255;255;255]);
% Framerate texel (top-right)
w.content.frame    = define_stt_texels([1-viewport_stt(3) 0 1 viewport_stt(4)],[255;255;255]);

% Combine all texels
% Note: edges must be installed before (r)symbols, therefore set installation order manually!
content_names = {'sync','frame','rsymbols','symbols','topinfo','bottominfo','cmplinfo','cross'};
c = w.content;
for k = 1:numel(content_names)
    fld = content_names{k};
    if isempty(c.(fld).stim); continue; end
    % Preload all textures
    [resident,~] = Screen('PreloadTextures',w.ptr,c.(fld).texels);
    if ~resident
        error('Failed preloading textures');
    end
end

% Set background to grey
Screen('FillRect',w.ptr,color_background);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Bump priority for speed
Priority(MaxPriority(w.ptr));

% Call once to load all functions into memory
% Clear persistent variable Nmissed in draw_texture function
draw_texture(); 
VBLTimestamp=0;

iteration = 0;
user_overriden_symbol_codes = []; % init
checkParmsTime = GetSecs()+0.1; % next moment to check for sent parameter updates
while iteration==0 || LOOP
    iteration = iteration+1;
    for t = 1:nflashes
        if t==nflashes; verb=1; else verb=0; end
        
        % Reload and reset content
        c = w.content;
        
        % Current stimulus pattern/stimuli
        if isempty(user_overriden_symbol_codes)
            curstims = stimuli.symbols(:,t);
        else
            % Once sent, the stimuli will be repeatedly shown
            curstims = user_overriden_symbol_codes;
        end
        
        % Symbols
        c.symbols.stim  = curstims;
        c.rsymbols.stim = ~curstims;
        
        % Framerate stt
        if isempty(stimuli.framerate)
            c.frame.stim = false; % do not show
        elseif stimuli.framerate(t)
            c.frame.stim = true;
            c.frame.color = uint8([255;255;255]); % white, (3,Nsymbols)
        else
            c.frame.stim = true;
            c.frame.color = uint8([0;0;0]); % black, (3,Nsymbols)
        end
        
        % Sync stt
        if isempty(stimuli.sync)
            c.sync.stim = false; % do not show
        elseif stimuli.sync(t)
            c.sync.stim = true;
            c.sync.color = uint8([255;255;255]); % white, (3,Nsymbols)
        else
            c.sync.stim = true;
            c.sync.color = uint8([0;0;0]); % black, (3,Nsymbols)
        end
        
        % Target
        if ~isempty(target)
            c.symbols.color(:,target.index) = target.color;
            c.symbols.stim(target.index)  = true;
            c.rsymbols.stim(target.index) = false;
        end
        
        % Edges
        if ~isempty(edges)
            c.edges.color = edges;
        end
        
        % Merge contents of presented texels
        alltexels   = [];
        allsrcRects = [];
        alldstRects = [];
        allcolors   = [];
        for k = 1:numel(content_names)
            fld = content_names{k};
            if isempty(c.(fld).stim), continue, end
            alltexels   = cat(2,alltexels  ,c.(fld).texels(c.(fld).stim));
            allsrcRects = cat(2,allsrcRects,c.(fld).srcRects(:,c.(fld).stim));
            alldstRects = cat(2,alldstRects,c.(fld).dstRects(:,c.(fld).stim));
            allcolors   = cat(2,allcolors  ,c.(fld).color(:,c.(fld).stim));
        end
        
        % Marker
        mrk = [];
        if t==1
            % Clear Nmissed, reset time
            draw_texture();
            
            % Marker at first stimulus
            if numel(marker)<=1
                mrk = marker;
            else
                mrk = marker(1);
            end
            % Marker at last stimulus
        elseif t==nflashes && numel(marker)==2
            mrk = marker(2);
        end
        
        % Present textures
        [VBLTimestamp, Nmissed] = draw_texture( ...
            w.ptr,alltexels,...
            verb,VBLTimestamp,w.monitorFlipInterval,mrk,...
            double((allsrcRects)),...
            double( alldstRects),[],[],[],allcolors);
        
        % Save frames for video
        if ~isempty(save2mp4)
            % collect video frames
            img = Screen('GetImage',w.ptr);
            if ~iscell(img)
                vimgs{end+1} = img;
            end
        end
        
        % Variables set by user
        try
            Tnow = GetSecs();
            if (Tnow > checkParmsTime)
                % Update time for next check
                checkParmsTime = Tnow+0.1;
                
                % Check if BrainStream sends an early-stopping command (takes less than 1.5 ms)
                % Check for new information in a non-blocking call to the socket
                uservars = bs_recv_user_brainstream([],'stim',0,0);
                while ~isempty(uservars)
                    % Received 'stop' or empty (by BS) will exit the loop
                    if isempty(uservars{1}) || isequal(uservars{1},'stop')
                        % Set priority back to normal
                        Priority(0);
                        % Write frames to mp4-file if necessary
                        write2mp4(vimgs,save2mp4);
                        fprintf('ms_speller: remotely stopped\n');
                        disp(uservars{1});
                        return;
                    end
                    if isnumeric(uservars{1}) && isequal(size(uservars{1}),[3, numel(w.content.edges.texels)])
                        % Assume edge feedback color values received (matrix [3 x num_symbols])
                        edges = uservars{1};
                    elseif isstruct(uservars{1})
                        % Assume structure with update fields
                        updates = uservars{1};
                        if isfield(updates,'codes')
                            user_overriden_symbol_codes = updates.codes;
                        end
                        if isfield(updates,'edges')
                            edges = updates.edges;
                        end
                        if isfield(updates,'topinfo')
                            if w.content.topinfo.texels; Screen('Close',w.content.topinfo.texels); end
                            w.content.topinfo = define_info_texels(updates.topinfo,viewport_topinfo,color_topinfo,align_topinfo);
                        end
                        if isfield(updates,'bottominfo')
                            if w.content.bottominfo.texels; Screen('Close',w.content.bottominfo.texels); end
                            w.content.bottominfo = define_info_texels(updates.bottominfo,viewport_bottominfo,color_bottominfo,align_bottominfo);
                        end
                        if isfield(updates,'cmplinfo')
                            if w.content.tpred.texels; Screen('Close',w.content.tpred.texels); end
                            w.content.tpred = define_info_texels(updates.cmplinfo,viewport_cmplinfo,color_cmplinfo,align_cmplinfo);
                        end
                        if isfield(updates,'target')
                            target = updates.target;
                        end
                    else
                        % If it does not work check incoming result
                    end
                    % Assures empty uservars={} instead of []
                    uservars = {uservars{2:end}};
                end
            end
        catch
            % Make sure it will never break
        end
    end
end

% Write frames to mp4-file
write2mp4(vimgs,save2mp4);

% Set priority back to normal
Priority(0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Help functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
    function c_cross = define_fixation_cross(viewport,color)
        [ScreenWidth,ScreenHeight] = Screen('WindowSize', w.ptr);
        viewport = viewport .* [ScreenWidth ScreenHeight ScreenWidth ScreenHeight];
        cx = mean(viewport([1 3]));
        cy = mean(viewport([2 4]));
        Screen('FillRect',w.ptr,color_background);
        Screen('TextSize',w.ptr,26);
        [~,~,srcRect] = DrawFormattedText(w.ptr,'+',[],[],color);
        imgs = Screen('GetImage',w.ptr,srcRect,'backBuffer');
        texels = Screen('MakeTexture',w.ptr,imgs);
        
        c_cross.texels      = texels;
        c_cross.srcRects    = [0; 0; srcRect(3); srcRect(4)];
        c_cross.dstRects    = [cx-srcRect(3)/2; cy-srcRect(4)/2; cx+srcRect(3)/2; cy+srcRect(4)/2];
        c_cross.color       = uint8(ones(3,1).*255);
        c_cross.stim        = true;
    end

%--------------------------------------------------------------------------
    function [c_stt] = define_stt_texels(viewport,color)
        viewport = viewport.*[w.width w.height w.width w.height];
        
        Screen('FillRect',w.ptr,color);
        image = Screen('GetImage',w.ptr,viewport,'backBuffer');
        texel = Screen('MakeTexture',w.ptr,image);
        
        c_stt.texels    = texel;
        c_stt.srcRects  = viewport';
        c_stt.dstRects  = viewport';
        c_stt.color     = uint8(ones(3,1).*255);
        c_stt.stim      = true;
    end

%--------------------------------------------------------------------------
    function [c_info] = define_info_texels(txt,viewport,color,alignment)
        Screen('TextSize',  w.ptr, textsize_info);
        
        if isempty(txt)
            c_info.texels    = [];
            c_info.srcRects  = [];
            c_info.dstRects  = [];
            c_info.color     = [];
            c_info.stim      = [];
        else
            viewport = viewport.*[w.width w.height w.width w.height];
            
            % Compute source location
            srcRect = zeros(4,1);
            srcRect([1 3]) = viewport([1 3]) - viewport(1);
            srcRect([2 4]) = viewport([2 4]) - viewport(2);
            
            % Compute destiny location
            dstRect = zeros(4,1);
            switch alignment
                case 'right'
                    dstRect(1) = viewport(3)-srcRect(3);
                    dstRect(2) = viewport(2);
                    dstRect(3) = viewport(3);
                    dstRect(4) = viewport(2)+srcRect(4);
                case 'left'
                    dstRect(1) = viewport(1);
                    dstRect(2) = viewport(2);
                    dstRect(3) = viewport(1)+srcRect(3);
                    dstRect(4) = viewport(2)+srcRect(4);
                otherwise
                    dstRect(1) = mean(viewport([1 3]))-srcRect(3)/2;
                    dstRect(2) = mean(viewport([2 4]))-srcRect(4)/2;
                    dstRect(3) = dstRect(1)+srcRect(3);
                    dstRect(4) = dstRect(2)+srcRect(4);
            end
            
            % Fix for bounding box error
            tstStr = 'HGPQhgpqk|_^.';
            charwh = Screen('TextBounds',w.ptr,tstStr,0,0); 
            charwh = [round(charwh(3)./numel(tstStr)) charwh(4)];
            width_chr = floor(floor(viewport(3)./charwh(1))./numel(txt,2));

            Screen('FillRect',w.ptr,color_background);
            DrawFormattedText(w.ptr,txt,alignment,0,color,width_chr,[],[],[],[],srcRect');
            srcRect(4) = ceil(srcRect(4)./charwh(2))*charwh(2);
            image = Screen('GetImage',w.ptr,srcRect,'backBuffer');
            texel = Screen('MakeTexture',w.ptr,image);

            c_info.texels    = texel;
            c_info.srcRects  = srcRect;
            c_info.dstRects  = dstRect;
            c_info.color     = uint8(ones(3,1).*255);
            c_info.stim      = true;
        end
    end


%--------------------------------------------------------------------------
    function [c_symbols, c_rsymbols] = define_symbols_texels
        
        % Symbols
        [texels,srcRects,dstRects] = jt_mkTextureCircle(w.ptr,symbols,...
            'BackGroundColor',color_background,'ViewPort',viewport_symbols,...
            'TextSize',textsize_symbols,'TextColor',color_text,'CircleColor',color_symbol);
        c_symbols.texels     = texels;
        c_symbols.srcRects   = srcRects;
        c_symbols.dstRects   = dstRects;
        c_symbols.color      = uint8(ones(3,N).*255);
        c_symbols.stim       = true(1,N);
        
        % Reversed symbols
        [texels,srcRects,~]  = jt_mkTextureCircle(w.ptr,symbols,...
            'BackGroundColor',color_background,'ViewPort',viewport_symbols,...
            'TextSize',textsize_symbols,'TextColor',color_text,'CircleColor',color_rsymbol);
        c_rsymbols.texels    = texels;
        c_rsymbols.srcRects  = srcRects;
        c_rsymbols.dstRects  = dstRects;
        c_rsymbols.color     = uint8(ones(3,N).*255);
        c_rsymbols.stim      = true(1,N);
    end

%--------------------------------------------------------------------------
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

%--------------------------------------------------------------------------
    function write2mp4(vimgs,save2mp4)
        
        if isempty(save2mp4) || isempty(vimgs)
            return
        end
        
        N = numel(vimgs);
        
        % add date-time timestamp to filename
        timestamp=datestr(now,30);
        [p,f,~] = fileparts(save2mp4.filename);
        filename = fullfile(p,[f '_' timestamp]);
        
        % Prepare the new file.
        vidObj = VideoWriter(filename,save2mp4.format);
        vidObj.FrameRate = save2mp4.framerate;
        open(vidObj);
        
        % writing video frames to file
        fprintf('writing video frames to file....\n');
        
        % Create an animation.
        frame = struct('cdata',[],'colormap',[]);
        for i = 1:N
            frame.cdata=vimgs{i};
            % Write each frame to the file.
            writeVideo(vidObj,frame);
        end
        
        % Close the file.
        close(vidObj);
        
        fprintf('Video file: ''%s'' created\n',filename);
    end

%--------------------------------------------------------------------------
    function symbols = get_default_symbols()
        symbols = {  ...
            'A','B','C','D','E','F'; ...
            'G','H','I','J','K','L'; ...
            'M','N','O','P','Q','R'; ...
            'S','T','U','V','W','X'; ...
            'Y','Z','@','$','%','&'; ...
            '#','<','-','!','?','.'; ...
            };
    end

%--------------------------------------------------------------------------
    function [Nmissed,vimgs] = testit(example)
        % Test defaults
        info            = [];
        symbols         = get_default_symbols();
        stimuli         = [];
        marker          = [];
        target          = [];
        edges           = [];
        save2mp4        = [];
        LOOP            = false;
        cfg             = [];
        
        % Examples
        switch example
            case 0
                % No text displayed
                info = '';
            case 1
                % No text displayed
                info.top        = '';
                info.bottom     = '';
                info.completion = '';
            case 2
                % Info message
                info = 'Central message';
            case 3
                % Top line text
                info.top = 'TOP';
            case 4
                % Bottom line text
                info.bottom = 'BOTTOM';
            case 5
                % Completion text
                info.completion = 'COMPLETION';
            case 6
                % All lines
                info.top        = 'TOP';
                info.bottom     = 'BOTTOM';
                info.completion = 'COMPLETION';
            case 7
                % All stimuli true (flash)
                stimuli.symbols = true(size(symbols,1),1);
            case 8
                % All stimuli false (no flash)
                stimuli.symbols = false(size(symbols,1),1);
            case 9
                % Swapping half set sequence
                stimuli.symbols = true(size(symbols,1),250);
                stimuli.symbols(1:2:end,1:2:end) = false;
                stimuli.symbols(2:2:end,2:2:end) = false;
            case 10
                % One by one sequence
                stimuli.symbols = true(size(symbols,1),size(symbols,1)*10);
                for i=1:size(stimuli.symbols,2); stimuli.symbols(mod(i-1,size(symbols,1))+1,i)=false; end
            case 11
                % Random sequence
                stimuli.symbols = rand(size(symbols,1),size(symbols,1)*10)>0.5;
            case 12
                % Sending a marker
                stimuli.symbols = true(size(symbols,1),250);
                stimuli.symbols(1:2:end,1:2:end) = false;
                stimuli.symbols(2:2:end,2:2:end) = false;
                marker = struct('name','pretrial','source','eeg','type','hardware');
            case 13
                % Display speller with a target
                target.index = 5;
                target.color = 255*[0 0.5 0];
            case 14
                % Display speller set with random edge colors
                edges = rand(3,size(symbols,1)).*255;
            case 15
                % Save video of random sequence
                stimuli.symbols = rand(size(symbols,1),size(symbols,1)*10)>0.5;
                save2mp4 = struct('filename','~/Desktop/test_noisetagging_video');
            case 16
                % Save noise tagging video with sync pulse and framerate
                codes = load('~/BCI_code/own_experiments/visual/noise_tagging/jt_box/code/example/mgold_61_6521.mat');
                stimuli.symbols = ~codes.codes(:,1:numel(symbols))';
                stimuli.sync    = false(1,size(stimuli.symbols,2));
                stimuli.sync(1) = true;
                stimuli.symbols = repmat(stimuli.symbols,[1,5]);
                stimuli.sync    = repmat(stimuli.sync,[1,5]);
                stimuli.symbols = cat(2,true(numel(symbols),1),stimuli.symbols);
                stimuli.sync    = [stimuli.sync false];
                stimuli.framerate = true(1,size(stimuli.symbols,2));
                stimuli.framerate(2:2:end) = false;
                save2mp4 = struct('filename','~/Desktop/noisetagging_video');
            case 17
                % Stimuli only
                stimuli.symbols = rand(size(symbols,1),60*4)>0.5;
            case 18
                % Stimuli with framerate
                stimuli.symbols = rand(size(symbols,1),60*4)>0.5;
                stimuli.framerate = true(1,size(stimuli.symbols,2));
                stimuli.framerate(2:2:end) = false;
            case 19
                % Stimuli with sync
                stimuli.symbols = rand(size(symbols,1),60*4)>0.5;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:60:4*60-1) = true;
            case 20
                % Stimuli with framerate and sync
                stimuli.symbols = rand(size(symbols,1),60*60)>0.5;
                stimuli.framerate = true(1,size(stimuli.symbols,2));
                stimuli.framerate(2:2:end) = false;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:60:4*60-1) = true;

            otherwise
                % Defaults
        end
        
        [Nmissed,vimgs] = hs_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);
        
    end

end