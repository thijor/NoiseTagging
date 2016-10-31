function w = init_ptb(save2mp4,bgcolor)
if nargin<1||isempty(save2mp4); save2mp4=[]; end
if nargin<2||isempty(bgcolor); bgcolor=0; end

Screen('Preference', 'SkipSyncTests', 1);

% Handle to screen
screens  = Screen('Screens');
screenid = max(screens);

% Resolution
resolution  = Screen('Resolution', screenid);
w.maxheight = resolution.height;
w.maxwidth  = resolution.width;

% Open window
try
    onescreen = bs_gbv('Experiment','OneScreen',0);
catch
    onescreen = 0;
end
if ~onescreen && (numel(screens)==1 || ~isempty(save2mp4))
    % Assume testing/debugging if only one monitor is connected
    % Or if frames will be written to mp4-file
    if ~isempty(save2mp4)
        w.width  = save2mp4.resolution.x;
        if w.width > w.maxwidth
            error('Requested mp4 video resolution width does not fit the screen');
        end
        w.height = save2mp4.resolution.y;
        if w.height > w.maxheight
            error('Requested mp4 video resolution height does not fit the screen');
        end
        % Set approximately to middle of screen
        o = floor(min(max(0,w.maxheight-w.height),max(0,w.maxwidth-w.width))/2);
    else
        w.width  = 800;
        w.height = 600;
        o = 100; % offset
    end
    winpos   = [o o o+w.width o+w.height];
else
    w.width  = w.maxwidth;
    w.height = w.maxheight;
    winpos   = [];
end
w.ptr = Screen('OpenWindow',screenid,bgcolor,winpos);
w.monitorFlipInterval = Screen('GetFlipInterval',w.ptr);
end