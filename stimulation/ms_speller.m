function [Nmissed,vimgs] = ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg)
%[Nmissed,vimgs] = ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP)
%
% INPUT
%   info     = [struct]
%       .top        = [str] text displayed at top, right-alligned ('')
%       .bottom     = [str] text displayed at bottom, center-alligned ('')
%       .completion = [str] text displayed top, left-alligned ('')
%   symbols  = {n m} character set (6x6 default)
%   stimuli  = [struct]
%       .symbols = [nm t] characters by samples: 1 = character white, background black (false(nm,1))
%       .rate    = [1 t]  right-top, framerate; toggle on/off every frame ([])
%       .sync    = [1 t]  left-top, sync-puls; flash at sync moment ([])
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
nmissed = 0;
vimgs = [];

% If numeric one argument, test examples
if nargin==1 && isnumeric(info)
    [Nmissed,vimgs] = testit(info);
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
nsymbols = N*M;

% If stimuli or symbol-stimuli undefined, flash once
if ~isfield(stimuli,'symbols') || isempty(stimuli.symbols)
    stimuli.symbols = true(nsymbols,1);
else
    stimuli.symbols = logical(stimuli.symbols);
end
nflashes = size(stimuli.symbols,2);
% If rate undefined, default empty
if ~isfield(stimuli,'rate');
    stimuli.rate = [];
else
    stimuli.rate = logical(stimuli.rate);
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
textfont            = 'Helvetica';
color_text          = uint8(jt_parse_cfg(cfg,'color_text',            [128;128;128]));
color_symbol        = uint8(jt_parse_cfg(cfg,'color_symbol',          [255;255;255]));
color_rsymbol       = uint8(jt_parse_cfg(cfg,'color_rsymbol',         [  0;  0;  0]));
color_background    = uint8(jt_parse_cfg(cfg,'color_background',      [128;128;128]));
color_topinfo       = uint8(jt_parse_cfg(cfg,'color_topinfo',         [  0;  0;  0]));
color_bottominfo    = uint8(jt_parse_cfg(cfg,'color_bottominfo',      [  0;  0;  0]));
color_cmplinfo      = uint8(jt_parse_cfg(cfg,'color_cmplinfo',        [ 64; 64; 64]));
edge_size           = jt_parse_cfg(cfg,'edge_size',             .005);
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
add_ptb();

% Check if we need to initialize Psychtoolbox window
if isempty(w) || ~Screen(w.ptr,'WindowKind')
    w = [];
    w = init_ptb(save2mp4,color_background);
end

Screen('TextStyle', w.ptr, 0);
Screen('TextFont',  w.ptr, textfont);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check escape keys
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

KbName('UnifyKeyNames');
kb.space = KbName('LeftShift');
kb.escape = KbName('Escape');
deviceNumber = -1; % query all usb keyboard devices
[isDown,~,keyCode] = KbCheck(deviceNumber);
if isDown
   if keyCode(kb.space) && keyCode(kb.escape)
       cleanup;
       clear Screen;  
       error('ms_peller closed remotely! [LeftShift+Escape]');
   end
end
if IsWin; GetMouse; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define texels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Info texels
w.content.topinfo    = define_info_texels(info.top       ,viewport_topinfo   ,color_topinfo   ,align_topinfo);
w.content.bottominfo = define_info_texels(info.bottom    ,viewport_bottominfo,color_bottominfo,align_bottominfo);
w.content.cmplinfo   = define_info_texels(info.completion,viewport_cmplinfo  ,color_cmplinfo  ,align_cmplinfo);

% Symbols texels
if ~isfield(w,'symbols') || isempty(w.symbols) || (~isempty(symbols) && ~isequal(symbols,w.symbols))
    w.symbols = symbols;
    [w.content.symbols,w.content.rsymbols,w.content.edges] = define_symbols_texels;
end

% Sync texel (top-left)
w.content.sync     = define_stt_texels(viewport_stt,[255;255;255]);
% Framerate texel (top-right)
w.content.frame    = define_stt_texels([1-viewport_stt(3) 0 1 viewport_stt(4)],[255;255;255]);

% Combine all texels
% Note: edges must be installed before (r)symbols, therefore set installation order manually!
content_names = {'sync','frame','edges','rsymbols','symbols','topinfo','bottominfo','cmplinfo'};
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

% Empty uservars
try
    bs_recv_user_brainstream([],'stim',0,0);
catch
    % make sure it will never break
end
                
% Bump priority for speed
Priority(MaxPriority(w.ptr));

% Call once to load all functions into memory
% Clear persistent variable Nmissed in draw_texture function
draw_texture(); 
VBLTimestamp=0;

dostop = false;
iteration = 0;
user_overriden_symbol_codes = [];
checkParmsTime = GetSecs()+0.1; % next moment to check for sent parameter updates
while ~dostop && (iteration==0 || LOOP)
    iteration = iteration+1;
    for t = 1:nflashes
        if dostop; break; end
        if t==nflashes; verbosity=1; else verbosity=0; end
        
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
        if isempty(stimuli.rate)
            c.frame.stim = false; % do not show
        elseif stimuli.rate(t)
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
                        dostop = true;
                        fprintf('ms_speller: remotely stopped\n');
                        verbosity = 1;
                        break;
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
        
        % Present textures
        [VBLTimestamp, Nmissed] = draw_texture( ...
            w.ptr,alltexels,...
            verbosity,VBLTimestamp,w.monitorFlipInterval,mrk,...
            double(allsrcRects),double(alldstRects),[],[],[],allcolors);
        
        % Save frames for video
        if ~isempty(save2mp4)
            % collect video frames
            img = Screen('GetImage',w.ptr);
            if ~iscell(img)
                vimgs{end+1} = img;
            end
        end
    end
end

% Write frames to mp4-file
if ~isempty(save2mp4)
    write2mp4(vimgs,save2mp4);
end

% Set priority back to normal
Priority(0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Help functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
    function [symbols] = get_default_symbols()
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
            txt = [txt ' ']; % to fix bouding box bug PTB ..
            
            % Compute source location
            srcRect = zeros(4,1);
            srcRect([1 3]) = viewport([1 3]) - viewport(1);
            srcRect([2 4]) = viewport([2 4]) - viewport(2);

            Screen('FillRect',w.ptr,color_background);
            DrawFormattedText(w.ptr,txt,alignment,0,color,[],[],[],[],[],srcRect');
            image = Screen('GetImage',w.ptr,srcRect,'backBuffer');
            texel = Screen('MakeTexture',w.ptr,image);

            c_info.texels    = texel;
            c_info.srcRects  = srcRect;
            c_info.dstRects  = viewport';
            c_info.color     = uint8(ones(3,1).*255);
            c_info.stim      = true;
        end
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
    function [c_symbols,c_rsymbols,c_edges] = define_symbols_texels()
        Screen('TextSize',  w.ptr, textsize_symbols);
        
        % Create destiny locations
        dstRects = feval(cfg.function,cfg.params);
        dstRects([1 3],:) = floor(dstRects([1 3],:)*w.width);
        dstRects([2 4],:) = floor(dstRects([2 4],:)*w.height);
        
        % Create source locations
        srcRects = dstRects;
        
        % Create texels
        texels    = nan(1,nsymbols);
        rtexels   = nan(1,nsymbols);
        etexels   = nan(1,nsymbols);
        for i = 1:nsymbols
            srcRects([1 3],i) = srcRects([1 3],i) - srcRects(1,i);
            srcRects([2 4],i) = srcRects([2 4],i) - srcRects(2,i);
            
            % Normal
            Screen('FillRect',w.ptr,color_symbol);
            DrawFormattedText(w.ptr,symbols{i},'center','center',color_text,[],[],[],[],[],srcRects(:,i)');
            image = Screen('GetImage',w.ptr,srcRects(:,i),'backBuffer');
            texels(i) = Screen('MakeTexture',w.ptr,image);
            
            % Reverse
            Screen('FillRect',w.ptr,color_rsymbol);
            DrawFormattedText(w.ptr,symbols{i},'center','center',color_text,[],[],[],[],[],srcRects(:,i)');
            image = Screen('GetImage',w.ptr,srcRects(:,i),'backBuffer');
            rtexels(i) = Screen('MakeTexture',w.ptr,image);
            
            % Edge
            Screen('FillRect',w.ptr,uint8([255;255;255]));
            image = Screen('GetImage',w.ptr,srcRects(:,i),'backBuffer');
            etexels(i) = Screen('MakeTexture',w.ptr,image);
        end
        
        % Symbols
        c_symbols.texels     = texels;
        c_symbols.srcRects   = srcRects;
        c_symbols.dstRects   = dstRects;
        c_symbols.color      = uint8(ones(3,nsymbols).*255);
        c_symbols.stim       = true(1,nsymbols);
        
        % Reversed symbols
        c_rsymbols.texels    = rtexels;
        c_rsymbols.srcRects  = srcRects;
        c_rsymbols.dstRects  = dstRects;
        c_rsymbols.color     = uint8(ones(3,nsymbols).*255);
        c_rsymbols.stim      = true(1,nsymbols);
        
        % Edges
        c_edges.texels       = etexels;
        c_edges.srcRects     = srcRects;
        c_edges.dstRects     = dstRects + repmat([-edge_size;-edge_size;edge_size;edge_size].*[w.width;w.height;w.width;w.height],[1 nsymbols]);
        c_edges.color        = repmat(color_background,[1 nsymbols]);
        c_edges.stim         = true(1,nsymbols);
    end

%--------------------------------------------------------------------------
    function cleanup()
        % Close screen and its texels
        try
            sca();
        catch
        end
        
        % Make sure next call reinitializes ptb window
        w = [];
        
        % Set priority back to normal
        Priority(0);
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
        LOOP            = [];
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
                stimuli.symbols = true(numel(symbols),1);
            case 8
                % All stimuli false (no flash)
                stimuli.symbols = false(numel(symbols),1);
            case 9
                % Swapping half set sequence
                stimuli.symbols = true(numel(symbols),250);
                stimuli.symbols(1:2:end,1:2:end) = false;
                stimuli.symbols(2:2:end,2:2:end) = false;
            case 10
                % One by one sequence
                stimuli.symbols = true(numel(symbols),numel(symbols)*2);
                for i=1:size(stimuli.symbols,2),stimuli.symbols(mod(i-1,numel(symbols))+1,i)=false;end
            case 11
                % Random sequence
                stimuli.symbols = rand(numel(symbols),numel(symbols)*10)>0.5;
            case 12
                % Sending a marker
                stimuli.symbols = true(numel(symbols),250);
                stimuli.symbols(1:2:end,1:2:end) = false;
                stimuli.symbols(2:2:end,2:2:end) = false;
                marker = struct('name','pretrial','source','eeg','type','hardware');
            case 13
                % Display speller with a target
                target.index = 5;
                target.color = 255*[0 0.5 0];
            case 14
                % Display speller set with random edge colors
                edges = rand(3,numel(symbols)).*255;
            case 15
                % Save video of random sequence
                stimuli.symbols = rand(numel(symbols),numel(symbols)*10)>0.5;
                save2mp4 = struct('filename','~/Desktop/test_noisetagging_video');
            case 16
                % Save noise tagging video with sync and rate
                codes = load('~/BCI_code/own_experiments/visual/noise_tagging/jt_box/code/example/mgold_61_6521.mat');
                stimuli.symbols = ~codes.codes(:,1:numel(symbols))';
                stimuli.sync    = false(1,size(stimuli.symbols,2));
                stimuli.sync(1) = true;
                stimuli.symbols = repmat(stimuli.symbols,[1,5]);
                stimuli.sync    = repmat(stimuli.sync,[1,5]);
                stimuli.symbols = cat(2,true(numel(symbols),1),stimuli.symbols);
                stimuli.sync    = [stimuli.sync false];
                stimuli.rate    = true(1,size(stimuli.symbols,2));
                stimuli.rate(2:2:end) = false;
                save2mp4 = struct('filename','~/Desktop/noisetagging_video');
            case 17
                % Stimuli only
                stimuli.symbols = rand(numel(symbols),60*4)>0.5;
            case 18
                % Stimuli with rate
                stimuli.symbols = rand(numel(symbols),60*4)>0.5;
                stimuli.rate = true(1,size(stimuli.symbols,2));
                stimuli.rate(2:2:end) = false;
            case 19
                % Stimuli with sync
                stimuli.symbols = rand(numel(symbols),60*4)>0.5;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:60:4*60-1) = true;
            case 20
                % Stimuli with rate and sync
                stimuli.symbols = rand(numel(symbols),60*60)>0.5;
                stimuli.rate = true(1,size(stimuli.symbols,2));
                stimuli.rate(2:2:end) = false;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:60:4*60-1) = true;
            case 21
                % Random organized symbols
                symbols = cell(randi(5,1)+2, randi(5,1)+2);
                for i=1:numel(symbols); symbols{i}=char('A'+mod(i-1,26)); end
                stimuli.symbols = rand(numel(symbols),60*4)>0.5;
                stimuli.rate = true(1,size(stimuli.symbols,2));
                stimuli.rate(2:2:end) = false;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:60:4*60-1) = true;
            case 22
                % Two choice option horizontal
                symbols = {'Yes', 'No'};
                stimuli.symbols = rand(numel(symbols),120*4)>0.5;
                stimuli.rate = true(1,size(stimuli.symbols,2));
                stimuli.rate(2:2:end) = false;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:120:end) = true;
                cfg.params.texelsize = [.25 .25];
            case 23
                % Two choice option vertical
                symbols = {'Yes'; 'No'};
                stimuli.symbols = rand(numel(symbols),120*4)>0.5;
                stimuli.rate = true(1,size(stimuli.symbols,2));
                stimuli.rate(2:2:end) = false;
                stimuli.sync = false(1,size(stimuli.symbols,2));
                stimuli.sync(1:120:end) = true;
                cfg.params.texelsize = [.25 .25];
            case 24
                % One class
                symbols = {' '};
                stimuli.symbols = rand(1,120*4)>0.5;
                cfg.params.texelsize = [.7 .7];
                info.top        = 'VERY';
                info.bottom     = 'SQUARE';
                info.completion = 'BIG';
            case 25
                % Different symbol colors
                stimuli.symbols = [true(floor(numel(symbols)/2),1); false(ceil(numel(symbols)/2),1)];
                cfg.color_symbol  = [255;0;0];
                cfg.color_rsymbol = [0;0;255];
                edges = repmat(linspace(1,255,numel(symbols)),[3 1]);
            case 26
                % All aspects similar
                info.top        = 'TEST';
                info.bottom     = 'TEST';
                info.completion = 'TEST';
                stimuli.symbols = [true(floor(numel(symbols)/2),1); false(ceil(numel(symbols)/2),1)];
                cfg.color_symbol  = [255;0;0];
                cfg.color_rsymbol = [0;0;255];
                edges = repmat([0;255;0],[1 numel(symbols)]);
            case 27
                % Different symbol colors, all true
                stimuli.symbols = true(numel(symbols),1);
                cfg.color_symbol  = [255;0;0];
                cfg.color_rsymbol = [0;0;255];
            case 28
                % Different symbol colors, all false
                stimuli.symbols = false(numel(symbols),1);
                cfg.color_symbol  = [255;0;0];
                cfg.color_rsymbol = [0;0;255];
            case 29
                % Everything
                info.top        = 'TOP';
                info.bottom     = 'BOTTOM';
                info.completion = 'COMPLETION';
                stimuli.symbols = true(numel(symbols),1);
                stimuli.rate = true;
                stimuli.sync = true;
                edges = rand(3,numel(symbols)).*255;
            case 30 
                % Big layout
                symbols = ...
                    {...
                    '!','@','#','$','%','^','&','*','(',')';...
                    '1','2','3','4','5','6','7','8','9','0';...
                    'Q','W','E','R','T','Y','U','I','O','P';...
                    'A','S','D','F','G','H','J','K','L','~';...
                    'Z','X','C','V','B','N','M','<','>','?';...
                    ',','.','?','+','-','_','/','\',':',';';...
                    };
            case 31
                % Big layout
                symbols = ...
                    {...
                    '!','@','#','$','%','^','&','*','(',')','1','2','3';...
                    'Q','W','E','R','T','Y','U','I','O','P','4','5','6';...
                    'A','S','D','F','G','H','J','K','L','~','7','8','9';...
                    'Z','X','C','V','B','N','M','<','>','?','+','0','-';...
                    ',','.','_','{','}','[',']','/','\',':',';',':)',';)';...
                    };
            case 32
                % One class (small layout)
                symbols = {'+'};
                cfg.params.texelsize = [0.1271, 0.1100];
            case 33
                % Play noise-codes
                codes = [];
                load('mgold_61_6521.mat')
                stimuli.symbols = repmat(codes(:,1:36),[4 1])';

            otherwise
                % Defaults
        end
        [Nmissed,vimgs] = ms_speller(info,symbols,stimuli,marker,target,edges,save2mp4,LOOP,cfg);
    end

end