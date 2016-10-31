function [Nmissed] = bw_cans(message,codes,state,marker)
%[Nmissed] = ep_stimulation(message,codes,colors,sendmarkers)
%
% INPUT
%   message = [str]    message to show (' ')
%   codes   = [6 m]    m samples for 6 codes (false(6,1))
%   state   = [6 1]    m samples for n edge colors (false(6,1))
%   marker  = [struct] data marker ([])
%       .name   = [str] marker name
%       .source = [str] source name

% Persistant variables
persistent w;
persistent clean;
Nmissed = 0;

% Start test examples
if nargin==1 && isnumeric(message)
    Nmissed = start_example(message);
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Defaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<1||isempty(message);  message = ' '; end
if nargin<2||isempty(codes);    codes   = false(6,1); end
if nargin<3||isempty(state);    state   = false(6,1); end
if nargin<4||isempty(marker);   marker  = []; end
codes = logical(codes);
nflashes = size(codes,2);

color_background    = 125;
viewport_cans       = [0 0.2 1 1  ];
viewport_message    = [0 0   1 0.2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make sure everything gets cleaned up well
if ~isa(clean,'onCleanup')
    clean = onCleanup(@()cleanup());
end

% Add PsychToolbox
add_ptb();

% Check need to initialize Psychtoolbox
if isempty(w) || ~Screen(w.ptr, 'WindowKind')
    init_ptb();
    w = init_window();
end

Screen('TextSize',w.ptr,45);
Screen('TextStyle',w.ptr,0);
Screen('TextFont',w.ptr,'Helvetica');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define texels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

w.content = [];

% Message
[w.content.message] = define_message(viewport_message,message);

% Cans
[w.content.cans,w.content.rcans] = define_cans(viewport_cans);

% Combine all texels
content_names = {'message','cans','rcans'};
c = w.content;
for i = 1 : numel(content_names)
    fld = content_names{i};
    if ~isfield(c,fld)||isempty(c.(fld).stim); continue; end
    [res,~] = Screen('PreloadTextures', w.ptr, c.(fld).texels);
    if ~res; error('Failed preloading textures'); end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Reset window
Screen('FillRect',w.ptr,color_background);

% Bump priority for speed
Priority(MaxPriority(w.ptr));

% Load all functions into memory
draw_texture();
VBLTimestamp = 0;
checkParmsTime = GetSecs()+0.1; % next moment to check for sent parameter updates
for t = 1:nflashes
    if t==nflashes; verb=1; else verb=0; end
    
    % Reload and reset content
    c = w.content;
    
    % Current states
    c.cans.stim  = codes(:,t) & state;
    c.rcans.stim = ~codes(:,t) & state;
    
    % Merge contents
    alltexels   = [];
    allsrcRects = [];
    alldstRects = [];
    allcolors   = [];
    for i = 1:numel(content_names)
        fld = content_names{i};
        if ~isfield(c,fld)||isempty(c.(fld).stim); continue; end
        alltexels   = cat(2,alltexels   , c.(fld).texels(c.(fld).stim));
        allsrcRects = cat(2,allsrcRects , c.(fld).srcRects(:,c.(fld).stim));
        alldstRects = cat(2,alldstRects , c.(fld).dstRects(:,c.(fld).stim));
        allcolors   = cat(2,allcolors   , c.(fld).color(:,c.(fld).stim));
    end
    
    % Markers
    if t==1 && ~isempty(marker)
        mrk = marker;
    else
        mrk = [];
    end
    
    % Draw textures
    [VBLTimestamp, Nmissed] = draw_texture(w.ptr,...
        alltexels, verb, VBLTimestamp, w.FlipInterval, mrk,...
        double(allsrcRects), double(alldstRects), [],[],[], allcolors);
    
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
                        fprintf('bw_cans: remotely stopped\n');
                        disp(uservars{1});
                        return;
                    end
                    % Assures empty uservars={} instead of []
                    uservars = {uservars{2:end}};
                end
            end
        catch
            % Make sure it will never break
        end
end

% Set priority back to normal
Priority(0);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Help functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%--------------------------------------------------------------------------
% init_ptb
%--------------------------------------------------------------------------
    function [] = init_ptb()
        if ismac; root='~'; else root='G:'; end
        addpath(genpath(fullfile(root,'Documents','MATLAB','toolboxes','Psychtoolbox')));
        addpath(genpath(fullfile(root,'bci_code','toolboxes','stimbox2')));
        addpath(genpath(fullfile(root,'bci_code','toolboxes','utilities','general')));
    end

%--------------------------------------------------------------------------
% init_window
%--------------------------------------------------------------------------
    function [w] = init_window()
        Screen('Preference', 'SkipSyncTests', 1);
        
        % Select screen
        screens  = Screen('Screens');
        screenid = max(screens);
        
        % Set resolution
        resolution = Screen('Resolution',screenid);
        if numel(screens)==1
            w.height = .75*resolution.height;
            w.width  = .75*resolution.width;
            winpos   = [0 0 w.width w.height];
        else
            w.height = resolution.height;
            w.width  = resolution.width;
            winpos   = [];
        end
        
        % Open window
        w.ptr          = Screen('OpenWindow',screenid,color_background,winpos);
        w.FlipInterval = Screen('GetFlipInterval',w.ptr);
        
        % Reset window
        Screen('FillRect',w.ptr,color_background);
        
    end

%--------------------------------------------------------------------------
% cleanup
%--------------------------------------------------------------------------
    function cleanup()
        % Close screen and its texels
        try
            sca();
        catch
        end
        
        % Reset window
        w = [];
        
        % Reset priority
        Priority(0);
        
    end

%--------------------------------------------------------------------------
% define_message
%--------------------------------------------------------------------------
    function [c_message] = define_message(viewport,message)
        if isempty(message)
            c_message.texels    = [];
            c_message.srcRects  = [];
            c_message.dstRects  = [];
            c_message.color     = [];
            c_message.stim      = [];
        else
            viewport = viewport.*[w.width w.height w.width w.height];
            txt = [message ' ']; % to fix bouding box bug PTB ..
            
            % Compute source location
            srcRect = zeros(4,1);
            srcRect([1 3]) = viewport([1 3]) - viewport(1);
            srcRect([2 4]) = viewport([2 4]) - viewport(2);

            % Draw text
            Screen('FillRect',w.ptr,color_background);
            DrawFormattedText(w.ptr,txt,'center',0,0,[],[],[],[],[],srcRect');
            image = Screen('GetImage',w.ptr,srcRect,'backBuffer');
            texel = Screen('MakeTexture',w.ptr,image);

            % Save texel
            c_message.texels    = texel;
            c_message.srcRects  = srcRect;
            c_message.dstRects  = viewport';
            c_message.color     = ones(3,1)*255;
            c_message.stim      = true;
        end
    end

%--------------------------------------------------------------------------
% define_cans
%--------------------------------------------------------------------------
    function [c_cans,c_rcans] = define_cans(viewport)
        viewport    = viewport.*[w.width w.height w.width w.height];
        can_width   = .1*(viewport(3)-viewport(1));
        can_height  = .2*(viewport(4)-viewport(2));
        can_dist    = .1*min(can_width,can_height);
        can_color   = [255;255;255];
        rcan_color  = [0;0;0];
        
        % Spacing
        srcRect = [0;0;can_width;can_height];
        center  = .5*repmat([viewport(3)+viewport(1);viewport(4)+viewport(2)],[2 1]);
        displ_c = .5*[-can_width;-can_height;can_width;can_height];
        displ_h = [can_width+can_dist;0;can_width+can_dist;0];
        displ_v = [0;can_height+can_dist;0;can_height+can_dist];
        
        % Create texels
        texels  = nan(1,6);
        rtexels = nan(1,6);
        Screen('FillRect',w.ptr,can_color);
        image = Screen('GetImage',w.ptr,srcRect,'backBuffer');
        Screen('FillRect',w.ptr,rcan_color);
        rimage = Screen('GetImage',w.ptr,srcRect,'backBuffer');
        for j = 1:6
            texels(j)  = Screen('MakeTexture',w.ptr,image);
            rtexels(j) = Screen('MakeTexture',w.ptr,rimage);
        end
        srcRects = repmat(srcRect,[1 6]);
        
        % Create destiny locations
        dstRects = nan(size(srcRects));
        dstRects(:,1) = center - displ_v             - displ_c; % Top
        dstRects(:,2) = center           - displ_h   - displ_c; % Middle left
        dstRects(:,3) = center           + displ_h   - displ_c; % Middel right
        dstRects(:,4) = center + displ_v - displ_h*2 - displ_c; % Bottom left
        dstRects(:,5) = center + displ_v             - displ_c; % Bottom middle
        dstRects(:,6) = center + displ_v + displ_h*2 - displ_c; % Bottom right
        
        % Cans
        c_cans.texels     = texels;
        c_cans.srcRects   = srcRects;
        c_cans.dstRects   = dstRects;
        c_cans.color      = ones(3,6)*255;
        c_cans.stim       = true(1,6);
        
        % Reversed cans
        c_rcans.texels    = rtexels;
        c_rcans.srcRects  = srcRects;
        c_rcans.dstRects  = dstRects;
        c_rcans.color     = ones(3,6)*255;
        c_rcans.stim      = true(1,6);
        
        % Reset screen
        Screen('FillRect',w.ptr,color_background);
    end

%--------------------------------------------------------------------------
% start_example
%--------------------------------------------------------------------------
    function [Nmissed] = start_example(option)
        % Defaults
        message = [];
        codes   = [];
        state   = [];
        marker  = [];
        
        % Options
        switch option
            
            case 0
                % Message only
                message = 'Hello there!';
                
            case 1
                % Cans only
                codes   = true(6,1);
                state   = true(6,1);
                
            case 2
                % Message and cans
                message = 'Fair-ground can-toss game';
                codes   = true(6,1);
                state   = true(6,1);
                
            case 3
                % Top can off
                message = 'You hit can 1!';
                codes   = true(6,1);
                state   = [false; true(5,1)];
                
            case 4
                % Flash all cans
                codes   = repmat([true(6,1) false(6,1)],[1 30]);
                state   = true(6,1);
                
            case 5
                % Flash half cans
                codes   = repmat([true(6,1) false(6,1)],[1 30]);
                state   = [1 0 1 0 1 0]';
                
            otherwise
                % Defaults
        end
        
        % Start example
        Nmissed = bw_cans(message,codes,state,marker);
    end

end