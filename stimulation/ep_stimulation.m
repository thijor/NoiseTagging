function [Nmissed] = ep_stimulation(message,codes,stt,targets,marker)
%[Nmissed] = ep_stimulation(message,codes,colors,sendmarkers)
%
% INPUT
%   message  = [str]    message to present ([])
%   codes    = [n m]    m samples for n stimulation codes ([])
%   stt      = [1 m]    m samples for stimulus timing tester ([])
%   targets  = [n m]    m samples for n pertubation moments ([])
%   marker   = [struct] marker structure with name, source and type ([])

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

if nargin<1||isempty(message);  message     = []; end
if nargin<2||isempty(codes);    codes       = []; end
if nargin<3||isempty(stt);      stt         = []; end
if nargin<4||isempty(targets);  targets     = []; end
if nargin<5||isempty(marker);   marker      = []; end
[ncodes,nflashes] = size(codes);
if ncodes==0; ncodes=1; end % hack

% Constant variables
BackgroundColor   = 125;
TargetColor       = repmat([1;0;0].*255,1,ncodes);
SubjectDistance   = 70;
TextSize          = 30;
NumberChecks      = 1;                              % number of checks in checkerboard
CheckSize         = tand(5.0)*SubjectDistance;      % cm width and height (square)
CheckHDist        = tand(4.0)*SubjectDistance;      % cm horizontal from center
CheckVDist        = tand(2.0)*SubjectDistance;      % cm vertical from center
MonitorWidth      = 53;                             % cm width of monitor Philips-47.5|BenQ-53
MonitorHeight     = 30;                             % cm height of monitor Philips-29.5|BenQ-30

% Make sure codes and colors are logicals
codes = logical(codes);
targets = logical(targets);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make sure everything gets cleaned up well
if ~isa(clean,'onCleanup')
    clean = onCleanup(@()cleanup());
end

% Add PsychToolbox
add_ptb();

% Check if we need to initialize Psychtoolbox window
if isempty(w) || ~Screen(w.ptr,'WindowKind')
    w = [];
    w = init_ptb([],BackgroundColor);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define texels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

w.content = [];

% Checkerboards
[w.content.check,w.content.checkr] = define_checkerboard();

% Stimulus timing tester
w.content.stt = define_stt_texels([0 0 .04 .07],[255;255;255]);

% Combine all texels
content_names = {'check','checkr','stt'};
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
Screen('FillRect',w.ptr,BackgroundColor);

% Draw message always
Screen('TextSize',w.ptr,TextSize);
DrawFormattedText(w.ptr,message,'center','center',255);
Screen('Flip',w.ptr);

% Bump priority for speed
Priority(MaxPriority(w.ptr));

% Load all functions into memory
draw_texture();
VBLTimestamp = 0;

for t = 1:nflashes
    if t==nflashes; verb=1; else verb=0; end
    
    % Reload and reset content
    c = w.content;
    
    % Stimulus
    c.check.stim  = codes(:,t);
    c.checkr.stim = ~codes(:,t);
    if ~isempty(targets)
        target = targets(:,t);
        if any(target)
            c.check.color(:,target) = TargetColor(:,target);
            c.checkr.color(:,target) = TargetColor(:,target);
        end
    end
    
    % Stt
    if isempty(stt)
        c.stt.stim = false; % do not show
    elseif stt(t)
        c.stt.stim = true;
        c.stt.color = uint8([255;255;255]); % white, (3,Nsymbols)
    else
        c.stt.stim = true;
        c.stt.color = uint8([0;0;0]); % black, (3,Nsymbols)
    end
    
    % Merge contents
    alltexels   = [];
    allsrcRects = [];
    alldstRects = [];
    allcolors   = [];
    for j = 1:numel(content_names)
        fld = content_names{j};
        if ~isfield(c,fld)||isempty(c.(fld).stim); continue; end
        alltexels   = cat(2,alltexels   , c.(fld).texels(c.(fld).stim));
        allsrcRects = cat(2,allsrcRects , c.(fld).srcRects(:,c.(fld).stim));
        alldstRects = cat(2,alldstRects , c.(fld).dstRects(:,c.(fld).stim));
        allcolors   = cat(2,allcolors   , c.(fld).color(:,c.(fld).stim));
    end
    
    % Markers
    mrk = [];
    if t==1 
        % Clear Nmissed, reset time
        draw_texture();
        
        % Set marker for start trial
        mrk = marker;
    elseif t==nflashes
        % Send end of stimulation
         mrk = struct('name','end_stimulation','source','eeg','type','hardware');
    end
    
    % Draw textures
    [VBLTimestamp, Nmissed] = draw_texture( ...
            w.ptr,alltexels,...
            verb,VBLTimestamp,w.monitorFlipInterval,mrk,...
            double(allsrcRects),double(alldstRects),[],[],[],allcolors);
end

% Set priority back to normal
Priority(0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Help functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
% define_checkerboard
%--------------------------------------------------------------------------
    function [check,checkr] = define_checkerboard()
        % Pix per cm
        cm2pixwidth = w.width/MonitorWidth;
        cm2pixheight = w.height/MonitorHeight;
        
        % Dtstances
        CheckWidth  = CheckSize*cm2pixwidth;
        CheckHeight = CheckSize*cm2pixheight;
        CheckHDist  = CheckHDist*cm2pixwidth + .5*CheckWidth;
        CheckVDist  = CheckVDist*cm2pixheight + .5*CheckHeight;
        MidScreen   = .5.*[w.width; w.height; w.width; w.height];
        CheckSize = [CheckWidth; CheckHeight; CheckWidth; CheckHeight];
        
        % Reset window
        Screen('FillRect',w.ptr,BackgroundColor);
        
        % Define check source and colors
        [checkSrc,checkColor] = get_checks(NumberChecks);
        checkSrc = checkSrc .* repmat(CheckSize,[1 NumberChecks]);
        checkColor  = checkColor .* 255;
        checkrColor = abs(checkColor-255);
        
        % Define checkerboard destinations
        srcRect = [0; 0; CheckWidth; CheckHeight];
        switch ncodes
            case 1
                dstRect = MidScreen + .5.*[-1; -1; 1; 1].*CheckSize;
            case 2
                dstRect = repmat(MidScreen,[1 2]) + ...
                    [-CheckHDist, CheckVDist, -CheckHDist, CheckVDist; ...
                    CheckHDist, CheckVDist,  CheckHDist, CheckVDist]' + ...
                    repmat(.5.*[-1; -1; 1; 1].*CheckSize,[1 2]);
            otherwise
                error('Unknown value');
        end
        
        % Draw checkerboard
        Screen('FillRect',w.ptr,checkColor,checkSrc);
        image = Screen('GetImage',w.ptr,srcRect,'backBuffer');
        texels = nan(1,ncodes);
        for k = 1:ncodes
            texels(k) = Screen('MakeTexture',w.ptr,image);
        end
        check.texels      = texels;
        check.srcRects    = repmat(srcRect,[1 ncodes]);
        check.dstRects    = dstRect;
        check.color       = ones(3,ncodes).*255;
        check.stim        = true(1,ncodes);
        Screen('FillRect',w.ptr,BackgroundColor);
        
        % Draw checkerboard reversed
        Screen('FillRect',w.ptr,checkrColor,checkSrc);
        image = Screen('GetImage',w.ptr,srcRect,'backBuffer');
        texels = nan(1,ncodes);
        for k = 1:ncodes
            texels(k) = Screen('MakeTexture',w.ptr,image);
        end
        checkr.texels      = texels;
        checkr.srcRects    = repmat(srcRect,[1 ncodes]);
        checkr.dstRects    = dstRect;
        checkr.color       = ones(3,ncodes).*255;
        checkr.stim        = true(1,ncodes);
        Screen('FillRect',w.ptr,BackgroundColor);
    end

%--------------------------------------------------------------------------
% get_check_positions
%--------------------------------------------------------------------------
    function [pos,col] = get_checks(k)
        k = sqrt(k);
        v = [0:1/k:1-1/k ; zeros(1,k) ; 1/k:1/k:1 ; ones(1,k)/k];
        v = repmat(v,[1 k]);
        d = [zeros(1,k) ; 0:1/k:1-1/k ; zeros(1,k) ; 0:1/k:1-1/k];
        d = jt_upsample(d,k,2);
        pos = v+d;
        if mod(k,2)==1
            col = zeros(size(pos));
            col(:,1:2:end) = 1;
        else
            cola = zeros(4,k);
            cola(:,1:2:end) = 1;
            colb = abs(1-cola);
            col = repmat([cola colb],[1 k/2]);
        end
    end

%--------------------------------------------------------------------------
% define_stt_texels
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
% start_example
%--------------------------------------------------------------------------
    function [Nmissed] = start_example(option)
        % Defaults
        message  = [];
        codes    = [];
        stt      = [];
        marker   = [];
        targets  = [];
        
        % Options
        switch option
            
            case 0
                % Defaults
                
            case 1
                % Message
                message = 'Message!';
                
            case 2
                % One code
                codes = true;
                
            case 3
                % Two codes
                codes = true(2,1);
                
            case 4
                % Flash one code with stt
                codes = repmat([true false],[1 10*30]);
                stt   = codes;
                
            case 5
                % Flash two codes with stt
                codes = cat(1,repmat([true false],[1 10*30]),rand(1,10*60)>.5);
                stt   = codes(1,:);
                
            case 6
                % Flash one code with targets and stt
                codes = repmat([true false],[1 10*30]);
                stt   = codes;
                targets = zeros(size(codes));
                targets(5*60:6*60) = true;
                
            case 7
                % Flash two codes with targets and stt
                codes = cat(1,repmat([true false],[1 10*30]),rand(1,10*60)>.5);
                stt   = codes(1,:);
                targets = zeros(size(codes));
                targets(1,4*60:6*60) = true;
                targets(2,5*60:7*60) = true;
                
            case 8 
                % Very short target
                codes = rand(1,10*60)>.5;
                targets = zeros(size(codes));
                targets(5*60:5*60+.2*60) = true;
                
            otherwise
                % Defaults
        end
        
        % Start example
        Nmissed = ep_stimulation(message,codes,stt,targets,marker);
    end

end